import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

typedef ResourceDownloadProgressCallback =
    void Function(ResourceDownloadProgress progress);

enum ResourceDownloadPhase {
  queued,
  downloading,
  verifying,
  extracting,
  installing,
  complete,
  failed;

  String get label {
    return switch (this) {
      ResourceDownloadPhase.queued => 'Starting',
      ResourceDownloadPhase.downloading => 'Downloading',
      ResourceDownloadPhase.verifying => 'Verifying',
      ResourceDownloadPhase.extracting => 'Extracting',
      ResourceDownloadPhase.installing => 'Installing',
      ResourceDownloadPhase.complete => 'Installed',
      ResourceDownloadPhase.failed => 'Failed',
    };
  }
}

class ResourceDownloadProgress {
  const ResourceDownloadProgress({
    required this.resourceId,
    required this.phase,
    this.receivedBytes = 0,
    this.totalBytes,
    this.message,
    this.error,
  });

  final String resourceId;
  final ResourceDownloadPhase phase;
  final int receivedBytes;
  final int? totalBytes;
  final String? message;
  final String? error;

  double? get fraction {
    final int? total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }
}

class ResourceInstallException implements Exception {
  const ResourceInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ResourceDownloadService {
  ResourceDownloadService._();

  static final ResourceDownloadService instance = ResourceDownloadService._();

  final ValueNotifier<Map<String, ResourceDownloadProgress>> downloads =
      ValueNotifier<Map<String, ResourceDownloadProgress>>(
        const <String, ResourceDownloadProgress>{},
      );
  final Map<String, Future<InstalledResource>> _activeDownloads =
      <String, Future<InstalledResource>>{};

  bool isDownloading(DownloadableResource resource) {
    return _activeDownloads.containsKey(_downloadKey(resource));
  }

  ResourceDownloadProgress? progressFor(DownloadableResource resource) {
    return downloads.value[_downloadKey(resource)];
  }

  Future<InstalledResource> downloadAndInstall(
    DownloadableResource resource, {
    ResourceDownloadProgressCallback? onProgress,
  }) {
    final String key = _downloadKey(resource);
    final Future<InstalledResource>? active = _activeDownloads[key];
    if (active != null) return active;

    final Future<InstalledResource> task = _downloadAndInstall(
      resource,
      onProgress: onProgress,
    );
    _activeDownloads[key] = task;
    return task.whenComplete(() {
      _activeDownloads.remove(key);
    });
  }

  Future<void> uninstall(DownloadableResource resource) {
    if (resource.type == ResourceType.translation) {
      for (final quran.Translation translation in quran.Translation.values) {
        if (translation.resourceId == resource.id) {
          quran.clearRegisteredTranslation(translation);
          break;
        }
      }
    }
    return ResourceInstallStore.instance.uninstall(resource);
  }

  Future<InstalledResource> _downloadAndInstall(
    DownloadableResource resource, {
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    File? zipFile;
    Directory? stagingDirectory;

    void update(ResourceDownloadProgress progress) {
      _setProgress(progress);
      onProgress?.call(progress);
    }

    try {
      if (resource.url.trim().isEmpty) {
        throw const ResourceInstallException(
          'This resource does not have a download URL yet.',
        );
      }

      update(
        ResourceDownloadProgress(
          resourceId: resource.id,
          phase: ResourceDownloadPhase.queued,
          totalBytes: resource.sizeBytes,
        ),
      );

      final Directory tempRoot = await _resourceTempDirectory();
      zipFile = File(
        '${tempRoot.path}${Platform.pathSeparator}${_safePathSegment(resource.rawType)}_${_safePathSegment(resource.id)}_${DateTime.now().microsecondsSinceEpoch}.zip',
      );
      stagingDirectory = Directory('${zipFile.path}.extract');
      if (await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
      await stagingDirectory.create(recursive: true);

      final int downloadedSize = await _downloadZip(
        resource: resource,
        destination: zipFile,
        onProgress: update,
      );

      update(
        ResourceDownloadProgress(
          resourceId: resource.id,
          phase: ResourceDownloadPhase.verifying,
          receivedBytes: downloadedSize,
          totalBytes: resource.sizeBytes ?? downloadedSize,
        ),
      );
      final String? verifiedSha = await _verifyZip(resource, zipFile);

      update(
        ResourceDownloadProgress(
          resourceId: resource.id,
          phase: ResourceDownloadPhase.extracting,
          receivedBytes: downloadedSize,
          totalBytes: resource.sizeBytes ?? downloadedSize,
        ),
      );
      await _extractZip(zipFile, stagingDirectory);
      await _validateExtractedResource(resource, stagingDirectory);

      update(
        ResourceDownloadProgress(
          resourceId: resource.id,
          phase: ResourceDownloadPhase.installing,
          receivedBytes: downloadedSize,
          totalBytes: resource.sizeBytes ?? downloadedSize,
        ),
      );

      final Directory installDirectory = await ResourceInstallStore.instance
          .installDirectory(resource);
      await _replaceDirectory(stagingDirectory, installDirectory);
      await ResourceInstallStore.instance.markInstalled(
        resource: resource,
        directory: installDirectory,
        sha256: verifiedSha ?? resource.sha256,
        sizeBytes: downloadedSize,
      );

      final InstalledResource installed = ResourceInstallStore.instance
          .installedFor(resource)!;
      update(
        ResourceDownloadProgress(
          resourceId: resource.id,
          phase: ResourceDownloadPhase.complete,
          receivedBytes: downloadedSize,
          totalBytes: resource.sizeBytes ?? downloadedSize,
        ),
      );
      return installed;
    } on ResourceInstallException catch (error) {
      _setProgress(
        ResourceDownloadProgress(
          resourceId: resource.id,
          phase: ResourceDownloadPhase.failed,
          totalBytes: resource.sizeBytes,
          error: error.message,
        ),
      );
      rethrow;
    } catch (error) {
      final ResourceInstallException wrapped = ResourceInstallException(
        _friendlyDownloadError(error),
      );
      _setProgress(
        ResourceDownloadProgress(
          resourceId: resource.id,
          phase: ResourceDownloadPhase.failed,
          totalBytes: resource.sizeBytes,
          error: wrapped.message,
        ),
      );
      throw wrapped;
    } finally {
      if (zipFile != null && await zipFile.exists()) {
        await zipFile.delete();
      }
      if (stagingDirectory != null && await stagingDirectory.exists()) {
        await stagingDirectory.delete(recursive: true);
      }
    }
  }

  Future<int> _downloadZip({
    required DownloadableResource resource,
    required File destination,
    required ValueChanged<ResourceDownloadProgress> onProgress,
  }) async {
    final Uri? uri = Uri.tryParse(resource.url);
    if (uri == null || !uri.hasScheme) {
      throw const ResourceInstallException('The download URL is invalid.');
    }

    final http.Client client = http.Client();
    IOSink? sink;
    try {
      final http.StreamedResponse response = await client
          .send(http.Request('GET', uri))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ResourceInstallException(
          'Download failed (${response.statusCode}). Please try again later.',
        );
      }

      final int? responseLength = response.contentLength;
      final int? totalBytes = responseLength != null && responseLength > 0
          ? responseLength
          : resource.sizeBytes;
      int receivedBytes = 0;
      sink = destination.openWrite();
      await for (final List<int> chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        onProgress(
          ResourceDownloadProgress(
            resourceId: resource.id,
            phase: ResourceDownloadPhase.downloading,
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
          ),
        );
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (receivedBytes <= 0) {
        throw const ResourceInstallException('The downloaded ZIP was empty.');
      }
      return receivedBytes;
    } on SocketException {
      throw const ResourceInstallException(
        'No internet connection. Please check your connection and try again.',
      );
    } on TimeoutException {
      throw const ResourceInstallException(
        'The download timed out. Please try again.',
      );
    } finally {
      client.close();
      await sink?.close();
    }
  }

  Future<String?> _verifyZip(
    DownloadableResource resource,
    File zipFile,
  ) async {
    final String? expectedSha = resource.sha256?.trim().toLowerCase();
    final Digest digest = await sha256.bind(zipFile.openRead()).first;
    final String actualSha = digest.toString();
    if (expectedSha != null &&
        expectedSha.isNotEmpty &&
        actualSha != expectedSha) {
      throw const ResourceInstallException(
        'The downloaded file did not pass verification.',
      );
    }
    return actualSha;
  }

  Future<void> _extractZip(File zipFile, Directory destination) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    } catch (_) {
      throw const ResourceInstallException(
        'The downloaded ZIP could not be opened.',
      );
    }

    final List<ArchiveFile> files = archive.files
        .where((ArchiveFile entry) => entry.isFile && !entry.isSymbolicLink)
        .toList(growable: false);
    if (files.isEmpty) {
      throw const ResourceInstallException('The ZIP did not contain files.');
    }
    if (files.length > 2000) {
      throw const ResourceInstallException(
        'The ZIP contains too many files.',
      );
    }

    int totalDecompressedBytes = 0;
    final String? rootToStrip = _singleArchiveRoot(files);
    for (final ArchiveFile entry in files) {
      if (entry.size > 50 * 1024 * 1024) {
        throw const ResourceInstallException(
          'The ZIP contains an entry that is too large.',
        );
      }
      totalDecompressedBytes += entry.size;
      if (totalDecompressedBytes > 300 * 1024 * 1024) {
        throw const ResourceInstallException(
          'The decompressed ZIP exceeds maximum allowed size.',
        );
      }

      final List<String> pathSegments = _safeArchiveSegments(
        entry.name,
        rootToStrip: rootToStrip,
      );
      if (pathSegments.isEmpty) continue;

      final File outputFile = File(
        '${destination.path}${Platform.pathSeparator}${pathSegments.join(Platform.pathSeparator)}',
      );
      final String destinationPrefix =
          '${destination.path}${Platform.pathSeparator}';
      if (!outputFile.path.startsWith(destinationPrefix)) {
        throw const ResourceInstallException('The ZIP contains unsafe paths.');
      }
      await outputFile.parent.create(recursive: true);
      final OutputFileStream output = OutputFileStream(outputFile.path);
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
    }
  }

  Future<void> _validateExtractedResource(
    DownloadableResource resource,
    Directory directory,
  ) async {
    switch (resource.type) {
      case ResourceType.tafsir:
        await _validateTafsir(directory);
        return;
      case ResourceType.timings:
        await _validateTimings(directory);
        return;
      case ResourceType.quranFonts:
        await _validateQpcV4Fonts(directory);
        return;
      case ResourceType.translation:
        await _validateTranslation(directory);
        return;
      case ResourceType.unknown:
        await _validateGeneric(directory);
        return;
    }
  }

  Future<void> _validateTafsir(Directory directory) async {
    for (int surah = 1; surah <= 114; surah++) {
      final File file = File(
        '${directory.path}${Platform.pathSeparator}$surah.json',
      );
      if (!await file.exists()) {
        throw ResourceInstallException(
          'The Tafsir ZIP is missing $surah.json.',
        );
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(await file.readAsString());
      } catch (_) {
        throw ResourceInstallException(
          'The Tafsir file $surah.json contains invalid JSON.',
        );
      }
      if (decoded is! Map || decoded['ayahs'] is! List) {
        throw ResourceInstallException(
          'The Tafsir file $surah.json has an unexpected format.',
        );
      }
    }
  }

  Future<void> _validateTimings(Directory directory) async {
    for (int surah = 1; surah <= 114; surah++) {
      final String fileName = '${surah.toString().padLeft(3, '0')}.txt';
      final File file = File(
        '${directory.path}${Platform.pathSeparator}$fileName',
      );
      if (!await file.exists()) {
        throw ResourceInstallException('The timing ZIP is missing $fileName.');
      }
      final List<String> lines = (await file.readAsString())
          .split(RegExp(r'\r?\n'))
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .toList(growable: false);
      final int expectedAyahs = quran.getVerseCount(surah);
      if (lines.length < expectedAyahs) {
        throw ResourceInstallException(
          'The timing file $fileName does not include every ayah.',
        );
      }
      for (final String line in lines) {
        final int? milliseconds = int.tryParse(line);
        if (milliseconds == null || milliseconds < 0) {
          throw ResourceInstallException(
            'The timing file $fileName contains invalid timestamps.',
          );
        }
      }
    }
  }

  Future<void> _validateTranslation(Directory directory) async {
    for (int surah = 1; surah <= 114; surah++) {
      final File file = File(
        '${directory.path}${Platform.pathSeparator}$surah.json',
      );
      if (!await file.exists()) {
        throw ResourceInstallException(
          'The translation ZIP is missing $surah.json.',
        );
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(await file.readAsString());
      } catch (_) {
        throw ResourceInstallException(
          'The translation file $surah.json contains invalid JSON.',
        );
      }
      if (decoded is! Map || decoded['ayahs'] is! List) {
        throw ResourceInstallException(
          'The translation file $surah.json has an unexpected format.',
        );
      }
      final int expectedAyahs = quran.getVerseCount(surah);
      final List<dynamic> ayahs = decoded['ayahs'] as List<dynamic>;
      if (ayahs.length < expectedAyahs) {
        throw ResourceInstallException(
          'The translation file $surah.json does not include every ayah.',
        );
      }
    }
  }

  Future<void> _validateQpcV4Fonts(Directory directory) async {
    final Map<int, String> pages = <int, String>{};
    await for (final FileSystemEntity entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final String name = entity.uri.pathSegments
          .where((String segment) => segment.isNotEmpty)
          .last;
      final int? page = _qpcV4FontPageNumber(name);
      if (page != null) {
        pages.putIfAbsent(page, () => name);
      }
    }

    for (int page = 1; page <= 604; page++) {
      if (!pages.containsKey(page)) {
        throw ResourceInstallException(
          'The Tajweed font ZIP is missing page $page.',
        );
      }
    }
  }

  Future<void> _validateGeneric(Directory directory) async {
    await for (final FileSystemEntity entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) return;
    }
    throw const ResourceInstallException(
      'The resource ZIP did not contain files.',
    );
  }

  Future<void> _replaceDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.parent.create(recursive: true);
    final Directory backup = Directory(
      '${destination.path}.old.${DateTime.now().microsecondsSinceEpoch}',
    );
    bool backupCreated = false;

    if (await destination.exists()) {
      await destination.rename(backup.path);
      backupCreated = true;
    }

    try {
      try {
        await source.rename(destination.path);
      } on FileSystemException {
        await _copyDirectory(source, destination);
        await source.delete(recursive: true);
      }
      if (backupCreated && await backup.exists()) {
        await backup.delete(recursive: true);
      }
    } catch (_) {
      if (await destination.exists()) {
        await destination.delete(recursive: true);
      }
      if (backupCreated && await backup.exists()) {
        await backup.rename(destination.path);
      }
      rethrow;
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final FileSystemEntity entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final String name = entity.uri.pathSegments
          .where((String segment) => segment.isNotEmpty)
          .last;
      final String targetPath =
          '${destination.path}${Platform.pathSeparator}$name';
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(targetPath));
      } else if (entity is File) {
        await entity.copy(targetPath);
      }
    }
  }

  Future<Directory> _resourceTempDirectory() async {
    final Directory temp = await getTemporaryDirectory();
    final Directory directory = Directory(
      '${temp.path}${Platform.pathSeparator}downloadable_resources',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  void _setProgress(ResourceDownloadProgress progress) {
    final Map<String, ResourceDownloadProgress> next =
        <String, ResourceDownloadProgress>{...downloads.value};
    next[_downloadKeyFromParts(progress.resourceId)] = progress;
    downloads.value = Map<String, ResourceDownloadProgress>.unmodifiable(next);
  }

  static String _downloadKey(DownloadableResource resource) {
    return _downloadKeyFromParts(resource.id);
  }

  static String _downloadKeyFromParts(String resourceId) => resourceId;

  static String _safePathSegment(String value) {
    final String sanitized = value.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    return sanitized.isEmpty ? 'resource' : sanitized;
  }

  static String? _singleArchiveRoot(List<ArchiveFile> files) {
    String? root;
    for (final ArchiveFile file in files) {
      final List<String> segments = _rawArchiveSegments(file.name);
      if (segments.length <= 1) return null;
      root ??= segments.first;
      if (segments.first != root) return null;
    }
    return root;
  }

  static List<String> _safeArchiveSegments(
    String path, {
    required String? rootToStrip,
  }) {
    final List<String> segments = _rawArchiveSegments(path);
    if (segments.isEmpty) return const <String>[];
    final List<String> stripped =
        rootToStrip != null && segments.first == rootToStrip
        ? segments.skip(1).toList(growable: false)
        : segments;
    for (final String segment in stripped) {
      if (segment == '.' ||
          segment == '..' ||
          segment.contains(':') ||
          segment.startsWith('/')) {
        throw const ResourceInstallException('The ZIP contains unsafe paths.');
      }
    }
    return stripped;
  }

  static List<String> _rawArchiveSegments(String path) {
    return path
        .replaceAll('\\', '/')
        .split('/')
        .map((String segment) => segment.trim())
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);
  }

  static int? _qpcV4FontPageNumber(String fileName) {
    final RegExpMatch? match = RegExp(
      r'^(?:p|page)?0*([1-9][0-9]{0,2})\.ttf$',
      caseSensitive: false,
    ).firstMatch(fileName.trim());
    if (match == null) return null;
    final int? page = int.tryParse(match.group(1)!);
    if (page == null || page < 1 || page > 604) return null;
    return page;
  }

  static String _friendlyDownloadError(Object error) {
    if (error is ResourceInstallException) return error.message;
    if (error is FileSystemException) {
      return 'Unable to store this resource. Please check available storage and try again.';
    }
    return 'Unable to install this resource. Please try again.';
  }
}
