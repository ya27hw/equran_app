import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:equran/backend/download_notifications.dart';
import 'package:equran/backend/quran_stream_url.dart';
import 'package:equran/utils/reciter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

typedef AudioDownloadProgressCallback =
    void Function(DownloadProgress progress);

class AudioDownloadEntry {
  const AudioDownloadEntry({
    required this.file,
    required this.type,
    required this.reciterCode,
    required this.surah,
    required this.sizeBytes,
    this.ayah,
    this.additionalFiles = const <File>[],
  });

  final File file;
  final AudioDownloadType type;
  final String reciterCode;
  final int surah;
  final int? ayah;
  final int sizeBytes;
  final List<File> additionalFiles;

  String get title =>
      type == AudioDownloadType.surah || type == AudioDownloadType.ayahSurah
      ? quran.getSurahName(surah)
      : '${quran.getSurahName(surah)} • Ayah $ayah';

  String get subtitle => type == AudioDownloadType.surah
      ? ''
      : type == AudioDownloadType.ayahSurah
      ? '${quran.getVerseCount(surah)} ayahs'
      : 'Ayah $ayah';

  int get ayahCount => type == AudioDownloadType.surah
      ? 0
      : type == AudioDownloadType.ayahSurah
      ? quran.getVerseCount(surah)
      : 1;

  List<File> get files => <File>[file, ...additionalFiles];
}

enum AudioDownloadType { surah, ayah, ayahSurah }

class AudioDownloadsSummary {
  const AudioDownloadsSummary({
    required this.surahDownloads,
    required this.ayahDownloads,
  });

  final List<AudioDownloadEntry> surahDownloads;
  final List<AudioDownloadEntry> ayahDownloads;

  List<AudioDownloadEntry> get allDownloads => <AudioDownloadEntry>[
    ...surahDownloads,
    ...ayahDownloads,
  ];

  int get totalSizeBytes =>
      allDownloads.fold<int>(0, (total, entry) => total + entry.sizeBytes);

  int get surahCount {
    final explicit = surahDownloads.length;
    final completeAyahSets = ayahDownloads
        .where((e) => e.type == AudioDownloadType.ayahSurah)
        .length;
    return explicit + completeAyahSets;
  }

  int get ayahCount {
    int count = 0;

    // Ayahs covered by full surah downloads (one big file per surah)
    for (final entry in surahDownloads) {
      count += quran.getVerseCount(entry.surah);
    }

    // Ayahs from complete ayah bundles (ayahSurah)
    count += ayahDownloads
        .where((e) => e.type == AudioDownloadType.ayahSurah)
        .fold<int>(0, (total, entry) => total + entry.ayahCount);

    // Remaining individual ayah files
    count += ayahDownloads
        .where((e) => e.type == AudioDownloadType.ayah)
        .fold<int>(0, (total, entry) => total + entry.ayahCount);

    return count;
  }
}

class AudioDownloadService {
  static const String _surahDirectoryName = 'surah_audio';
  static const String _ayahDirectoryName = 'ayah_audio';
  static const String _tempAyahDirectoryName = 'ayah_audio_cache';
  static const int _maxTempCachedAyahs = 10;
  static final Map<String, Future<List<File>>> _surahAyahDownloads =
      <String, Future<List<File>>>{};
  static final Map<String, Future<File>> _tempAyahDownloads =
      <String, Future<File>>{};

  Future<Directory> _audioDirectory(String directoryName) async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${baseDir.path}/$directoryName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _tempAudioDirectory(String directoryName) async {
    final Directory baseDir = await getTemporaryDirectory();
    final Directory dir = Directory('${baseDir.path}/$directoryName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> surahDirectory() => _audioDirectory(_surahDirectoryName);

  Future<Directory> ayahDirectory() => _audioDirectory(_ayahDirectoryName);

  Future<Directory> tempAyahDirectory() =>
      _tempAudioDirectory(_tempAyahDirectoryName);

  String _reciterCode() => QuranAudioService().selectedReciter.code;

  String ayahFileName(int surah, int ayah) {
    return '${_reciterCode()}_${surah.toString().padLeft(3, '0')}_${ayah.toString().padLeft(3, '0')}.mp3';
  }

  Future<File> ayahFile(int surah, int ayah) async {
    final Directory dir = await ayahDirectory();
    return File('${dir.path}/${ayahFileName(surah, ayah)}');
  }

  Future<File> tempAyahFile(int surah, int ayah) async {
    final Directory dir = await tempAyahDirectory();
    return File('${dir.path}/${ayahFileName(surah, ayah)}');
  }

  Future<bool> hasAyah(int surah, int ayah) async {
    final File file = await ayahFile(surah, ayah);
    return _isCompleteDownload(file);
  }

  Future<bool> hasTempAyah(int surah, int ayah) async {
    final File file = await tempAyahFile(surah, ayah);
    return _isCompleteDownload(file);
  }

  Future<File?> playbackAyahFile(int surah, int ayah) async {
    final File downloadedFile = await ayahFile(surah, ayah);
    if (_isCompleteDownload(downloadedFile)) {
      return downloadedFile;
    }

    final File tempFile = await tempAyahFile(surah, ayah);
    if (_isCompleteDownload(tempFile)) {
      await _touchFile(tempFile);
      return tempFile;
    }

    return null;
  }

  bool isSurahAyahsDownloadInProgress(int surah) {
    return _surahAyahDownloads.containsKey('${_reciterCode()}-$surah');
  }

  Future<File> downloadAyah(
    int surah,
    int ayah, {
    AudioDownloadProgressCallback? onProgress,
  }) async {
    final File file = await ayahFile(surah, ayah);
    if (_isCompleteDownload(file)) {
      return file;
    }

    final File tempFile = await tempAyahFile(surah, ayah);
    if (_isCompleteDownload(tempFile)) {
      await _copyFile(tempFile, file);
      onProgress?.call(
        const DownloadProgress(
          receivedBytes: 1,
          totalBytes: 1,
          completedFiles: 1,
          totalFiles: 1,
        ),
      );
      return file;
    }

    final String reciterCode = _reciterCode();
    final ReciterProfile reciterProfile = QuranAudioCatalog.findById(
      reciterCode,
    );
    final String url = QuranAudioStreamResolver.buildAyahUrl(
      reciter: reciterProfile,
      surah: surah,
      ayah: ayah,
    );
    await _downloadToFile(
      url,
      file,
      onProgress: onProgress == null
          ? null
          : (receivedBytes, totalBytes) => onProgress(
              DownloadProgress(
                receivedBytes: receivedBytes,
                totalBytes: totalBytes,
                completedFiles: 0,
                totalFiles: 1,
              ),
            ),
    );
    return file;
  }

  Future<File> cacheAyah(int surah, int ayah) async {
    final File? playbackFile = await playbackAyahFile(surah, ayah);
    if (playbackFile != null) {
      await _enforceTempAyahCacheLimit();
      return playbackFile;
    }

    final String downloadKey = '${_reciterCode()}-$surah-$ayah';
    final Future<File>? activeDownload = _tempAyahDownloads[downloadKey];
    if (activeDownload != null) {
      return activeDownload;
    }

    final Future<File> download = _cacheAyahFile(surah, ayah);
    _tempAyahDownloads[downloadKey] = download;
    void clearActiveDownload() {
      if (identical(_tempAyahDownloads[downloadKey], download)) {
        _tempAyahDownloads.remove(downloadKey);
      }
    }

    download.then<void>(
      (_) => clearActiveDownload(),
      onError: (_, _) => clearActiveDownload(),
    );
    return download;
  }

  Future<File> _cacheAyahFile(int surah, int ayah) async {
    final String reciterCode = _reciterCode();
    final ReciterProfile reciterProfile = QuranAudioCatalog.findById(
      reciterCode,
    );
    final String url = QuranAudioStreamResolver.buildAyahUrl(
      reciter: reciterProfile,
      surah: surah,
      ayah: ayah,
    );
    final File file = await tempAyahFile(surah, ayah);
    await _downloadToFile(url, file);
    await _touchFile(file);
    await _enforceTempAyahCacheLimit();
    return file;
  }

  Future<List<File>> downloadSurahAyahs(
    int surah, {
    AudioDownloadProgressCallback? onProgress,
  }) async {
    final String downloadKey = '${_reciterCode()}-$surah';
    final Future<List<File>>? activeDownload = _surahAyahDownloads[downloadKey];
    if (activeDownload != null) {
      return activeDownload;
    }

    final Future<List<File>> download = _downloadMissingSurahAyahs(
      surah,
      onProgress: onProgress,
    );
    _surahAyahDownloads[downloadKey] = download;
    void clearActiveDownload() {
      if (identical(_surahAyahDownloads[downloadKey], download)) {
        _surahAyahDownloads.remove(downloadKey);
      }
    }

    download.then<void>(
      (_) => clearActiveDownload(),
      onError: (_, _) => clearActiveDownload(),
    );
    return download;
  }

  Future<List<File>> _downloadMissingSurahAyahs(
    int surah, {
    AudioDownloadProgressCallback? onProgress,
  }) async {
    final int totalAyahs = quran.getVerseCount(surah);
    final List<File?> files = List<File?>.filled(totalAyahs, null);
    bool anyMissing = false;

    for (int ayah = 1; ayah <= totalAyahs; ayah++) {
      final File file = await ayahFile(surah, ayah);
      if (_isCompleteDownload(file)) {
        files[ayah - 1] = file;
        continue;
      }

      final File tempFile = await tempAyahFile(surah, ayah);
      if (_isCompleteDownload(tempFile)) {
        await _copyFile(tempFile, file);
        files[ayah - 1] = file;
        continue;
      }

      anyMissing = true;
    }

    if (!anyMissing) {
      return files.whereType<File>().toList(growable: false);
    }

    final String reciterCode = _reciterCode();
    final ReciterProfile reciterProfile = QuranAudioCatalog.findById(
      reciterCode,
    );
    final String paddedSurah = surah.toString().padLeft(3, '0');
    final String zipUrl =
        'https://everyayah.com/data/${reciterProfile.everyAyahFolder}/zips/$paddedSurah.zip';

    final Directory tempDir = await tempAyahDirectory();
    final File zipFile = File('${tempDir.path}/$reciterCode-$paddedSurah.zip');
    final Directory extractDir = Directory(
      '${tempDir.path}/extract-$reciterCode-$paddedSurah',
    );

    try {
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // 1. Download ZIP file
      await _downloadToFile(
        zipUrl,
        zipFile,
        onProgress: onProgress == null
            ? null
            : (receivedBytes, totalBytes) => onProgress(
                DownloadProgress(
                  receivedBytes: receivedBytes,
                  totalBytes: totalBytes,
                  completedFiles: 0,
                  totalFiles: 1,
                ),
              ),
      );

      // 2. Decode and extract ZIP
      // Update progress to indeterminate/extracting state
      onProgress?.call(
        const DownloadProgress(
          receivedBytes: 0,
          totalBytes: null,
          completedFiles: 0,
          totalFiles: 1,
        ),
      );

      // Decode lazily from disk instead of duplicating the whole ZIP in a
      // UI-isolate byte array. Each selected ayah is decompressed directly to
      // its temporary output file.
      final InputFileStream zipInput = InputFileStream(zipFile.path);
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(zipInput);
      } catch (_) {
        zipInput.closeSync();
        rethrow;
      }
      if (archive.files.length > totalAyahs * 2 + 32) {
        zipInput.closeSync();
        throw const FormatException('Audio archive contains too many files.');
      }
      try {
        for (final ArchiveFile entry in archive.files) {
          if (!entry.isFile || entry.isSymbolicLink) continue;
          if (entry.size > 25 * 1024 * 1024) {
            throw const FormatException('Audio archive entry is too large.');
          }

          final RegExpMatch? match = RegExp(
            r'(\d{3})(\d{3})\.mp3$',
          ).firstMatch(entry.name);
          if (match == null) continue;

          final int? entrySurah = int.tryParse(match.group(1)!);
          final int? entryAyah = int.tryParse(match.group(2)!);
          if (entrySurah == null || entryAyah == null) continue;
          if (entrySurah != surah) continue;
          if (entryAyah < 1 || entryAyah > totalAyahs) continue;

          final File finalFile = await ayahFile(surah, entryAyah);
          final File tempExtractFile = File(
            '${extractDir.path}${Platform.pathSeparator}${entrySurah}_$entryAyah.mp3',
          );
          await tempExtractFile.parent.create(recursive: true);

          final OutputFileStream output = OutputFileStream(
            tempExtractFile.path,
          );
          try {
            entry.writeContent(output, freeMemory: true);
          } finally {
            output.closeSync();
          }

          if (await finalFile.exists()) {
            await finalFile.delete();
          }
          try {
            await tempExtractFile.rename(finalFile.path);
          } on FileSystemException {
            await tempExtractFile.copy(finalFile.path);
            await tempExtractFile.delete();
          }
          files[entryAyah - 1] = finalFile;
        }
      } finally {
        zipInput.closeSync();
      }
    } finally {
      try {
        if (await zipFile.exists()) {
          await zipFile.delete();
        }
        if (await extractDir.exists()) {
          await extractDir.delete(recursive: true);
        }
      } catch (_) {}
    }

    return files.whereType<File>().toList(growable: false);
  }

  Future<void> _downloadToFile(
    String url,
    File file, {
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final Uri uri = Uri.parse(url);
    final File partialFile = File('${file.path}.part');
    final http.Client client = http.Client();
    try {
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      final http.StreamedResponse response = await client.send(
        http.Request('GET', uri),
      );
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      final int? totalBytes = response.contentLength;
      int receivedBytes = 0;
      final IOSink sink = partialFile.openWrite();
      try {
        await for (final List<int> chunk in response.stream) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          onProgress?.call(receivedBytes, totalBytes);
        }
      } finally {
        await sink.close();
      }
      if (await file.exists()) {
        await file.delete();
      }
      await partialFile.rename(file.path);
    } catch (_) {
      if (partialFile.existsSync()) {
        await partialFile.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> _copyFile(File source, File destination) async {
    final File partialFile = File('${destination.path}.part');
    if (await partialFile.exists()) {
      await partialFile.delete();
    }
    await source.copy(partialFile.path);
    if (await destination.exists()) {
      await destination.delete();
    }
    await partialFile.rename(destination.path);
  }

  Future<void> _touchFile(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {
      // Cache ordering is best-effort; playback should not depend on it.
    }
  }

  Future<void> _enforceTempAyahCacheLimit() async {
    final Directory dir = await tempAyahDirectory();
    final List<File> files = <File>[];
    for (final FileSystemEntity entity in dir.listSync()) {
      if (entity is! File) continue;
      if (entity.path.endsWith('.part')) {
        try {
          await entity.delete();
        } catch (_) {
          // Temporary cache cleanup is best-effort.
        }
        continue;
      }
      if (!_isCompleteDownload(entity)) continue;
      files.add(entity);
    }

    files.sort((File a, File b) {
      return a.lastModifiedSync().compareTo(b.lastModifiedSync());
    });

    while (files.length > _maxTempCachedAyahs) {
      final File oldest = files.removeAt(0);
      try {
        await oldest.delete();
      } catch (_) {
        // Temporary cache cleanup is best-effort and must never affect user
        // downloads, which live in a separate documents directory.
      }
    }
  }

  Future<void> deleteAyah(int surah, int ayah) async {
    final File file = await ayahFile(surah, ayah);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> deleteEntry(AudioDownloadEntry entry) async {
    if (entry.file.existsSync()) {
      await entry.file.delete();
    }
    for (final File file in entry.additionalFiles) {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  Future<void> clearAll() async {
    final AudioDownloadsSummary downloadsSummary = await summary();
    for (final AudioDownloadEntry entry in downloadsSummary.allDownloads) {
      await deleteEntry(entry);
    }
  }

  Future<AudioDownloadsSummary> summary() async {
    final List<AudioDownloadEntry> surahs = await _scanSurahs();
    final List<AudioDownloadEntry> ayahs = _bundleCompleteAyahSurahs(
      await _scanAyahs(),
    );
    surahs.sort(_compareEntries);
    ayahs.sort(_compareEntries);
    return AudioDownloadsSummary(surahDownloads: surahs, ayahDownloads: ayahs);
  }

  int _compareEntries(AudioDownloadEntry a, AudioDownloadEntry b) {
    final int surahCompare = a.surah.compareTo(b.surah);
    if (surahCompare != 0) return surahCompare;
    return (a.ayah ?? 0).compareTo(b.ayah ?? 0);
  }

  Future<List<AudioDownloadEntry>> _scanSurahs() async {
    final Directory dir = await surahDirectory();
    final RegExp pattern = RegExp(r'^(.+)_(\d{3})\.mp3$');
    final List<AudioDownloadEntry> entries = <AudioDownloadEntry>[];

    for (final FileSystemEntity entity in dir.listSync()) {
      if (entity is! File) continue;
      if (!_isCompleteDownload(entity)) continue;
      final RegExpMatch? match = pattern.firstMatch(_basename(entity.path));
      if (match == null) continue;
      final int? surah = int.tryParse(match.group(2)!);
      if (surah == null || surah < 1 || surah > 114) continue;
      entries.add(
        AudioDownloadEntry(
          file: entity,
          type: AudioDownloadType.surah,
          reciterCode: match.group(1)!,
          surah: surah,
          sizeBytes: entity.lengthSync(),
        ),
      );
    }
    return entries;
  }

  Future<List<AudioDownloadEntry>> _scanAyahs() async {
    final Directory dir = await ayahDirectory();
    final RegExp pattern = RegExp(r'^(.+)_(\d{3})_(\d{3})\.mp3$');
    final List<AudioDownloadEntry> entries = <AudioDownloadEntry>[];

    for (final FileSystemEntity entity in dir.listSync()) {
      if (entity is! File) continue;
      if (!_isCompleteDownload(entity)) continue;
      final RegExpMatch? match = pattern.firstMatch(_basename(entity.path));
      if (match == null) continue;
      final int? surah = int.tryParse(match.group(2)!);
      final int? ayah = int.tryParse(match.group(3)!);
      if (surah == null || ayah == null) continue;
      if (surah < 1 || surah > 114 || ayah < 1) continue;
      entries.add(
        AudioDownloadEntry(
          file: entity,
          type: AudioDownloadType.ayah,
          reciterCode: match.group(1)!,
          surah: surah,
          ayah: ayah,
          sizeBytes: entity.lengthSync(),
        ),
      );
    }
    return entries;
  }

  List<AudioDownloadEntry> _bundleCompleteAyahSurahs(
    List<AudioDownloadEntry> entries,
  ) {
    final Map<String, List<AudioDownloadEntry>> grouped =
        <String, List<AudioDownloadEntry>>{};
    for (final AudioDownloadEntry entry in entries) {
      grouped
          .putIfAbsent(
            '${entry.reciterCode}-${entry.surah}',
            () => <AudioDownloadEntry>[],
          )
          .add(entry);
    }

    final List<AudioDownloadEntry> bundled = <AudioDownloadEntry>[];
    for (final List<AudioDownloadEntry> group in grouped.values) {
      group.sort(_compareEntries);
      final int surah = group.first.surah;
      final int totalAyahs = quran.getVerseCount(surah);
      final bool isComplete =
          group.length == totalAyahs &&
          group.every((entry) => entry.ayah != null) &&
          group.map((entry) => entry.ayah).toSet().length == totalAyahs;

      if (!isComplete) {
        bundled.addAll(group);
        continue;
      }

      final AudioDownloadEntry first = group.first;
      bundled.add(
        AudioDownloadEntry(
          file: first.file,
          type: AudioDownloadType.ayahSurah,
          reciterCode: first.reciterCode,
          surah: surah,
          sizeBytes: group.fold<int>(
            0,
            (total, entry) => total + entry.sizeBytes,
          ),
          additionalFiles: group.skip(1).map((entry) => entry.file).toList(),
        ),
      );
    }
    return bundled;
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
    final int unitIndex = min(
      units.length - 1,
      (log(bytes) / log(1024)).floor(),
    );
    final double value = bytes / pow(1024, unitIndex);
    final String formatted = unitIndex == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(value >= 10 ? 1 : 2);
    return '$formatted ${units[unitIndex]}';
  }

  String _basename(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  bool isCompleteDownload(File file) {
    return _isCompleteDownload(file);
  }

  bool _isCompleteDownload(File file) {
    return file.existsSync() && file.lengthSync() > 0;
  }
}
