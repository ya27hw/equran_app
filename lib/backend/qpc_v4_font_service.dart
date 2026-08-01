import 'dart:async';
import 'dart:io';
import 'dart:ui' show Brightness, PlatformDispatcher;

import 'package:equran/backend/qcf_cpal_patcher.dart';
import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:flutter/services.dart';

class QpcV4FontService {
  QpcV4FontService._privateConstructor();
  static final QpcV4FontService instance =
      QpcV4FontService._privateConstructor();

  static const String tajweedFontsResourceId = 'qpc_v4_tajweed_fonts';
  static const DownloadableResource tajweedFontsResource = DownloadableResource(
    id: tajweedFontsResourceId,
    rawType: 'quran_fonts',
    name: 'QPC V4 Tajweed fonts',
    version: '1.0.0',
    url:
        'https://github.com/ya27hw/equran-assets/releases/download/1.0.0/tajweed.zip',
    sizeBytes: 69230903,
    metadata: <String, Object?>{'requiredPages': 604},
  );

  final Set<int> _loadedPages = <int>{};
  final Map<String, Future<bool>> _loadingPages = <String, Future<bool>>{};
  Map<int, File>? _fontFileIndex;
  String? _fontFileIndexRoot;

  /// Preloads a list of pages.
  Future<void> preloadFontsForPages(List<int> pages) async {
    final List<int> boundedPages = pages
        .toSet()
        .take(3)
        .toList(growable: false);
    for (final int page in boundedPages) {
      unawaited(ensureFontLoadedForPage(page));
    }
  }

  /// Dynamically loads a font for a specific page if not already loaded.
  /// Returns true only when the page font is installed and loaded.
  Future<bool> ensureFontLoadedForPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return false;

    final bool darkMode = _isDarkMode();
    final String variant = darkMode ? 'dark' : 'light';
    final String loadKey = '$pageNumber:$variant';
    if (_loadedPages.contains(pageNumber)) {
      return await fontFileForPage(pageNumber) != null;
    }

    // Avoid duplicate download/load requests for the same page
    final Future<bool>? activeLoad = _loadingPages[loadKey];
    if (activeLoad != null) {
      return activeLoad;
    }

    final Future<bool> load = _loadVariant(pageNumber, darkMode: darkMode);
    _loadingPages[loadKey] = load;
    try {
      return await load;
    } finally {
      if (identical(_loadingPages[loadKey], load)) {
        _loadingPages.remove(loadKey);
      }
    }
  }

  Future<bool> _loadVariant(int pageNumber, {required bool darkMode}) async {
    try {
      final File? fontFile = await fontFileForPage(pageNumber);
      if (fontFile == null) return false;
      final Uint8List bytes = await fontFile.readAsBytes();
      final Uint8List activeBytes = darkMode
          ? QcfCpalPatcher.patchForDarkMode(Uint8List.fromList(bytes))
          : bytes;
      final FontLoader loader = FontLoader(
        'QPCV4_Page_${pageNumber}_${darkMode ? 'dark' : 'light'}',
      );
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(activeBytes)));
      await loader.load();
      _loadedPages.add(pageNumber);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasAllPageFonts() async {
    final Map<int, File> index = await _installedFontFileIndex();
    for (int page = 1; page <= 604; page++) {
      if (!index.containsKey(page)) return false;
    }
    return true;
  }

  Future<File?> fontFileForPage(int pageNumber) async {
    final Map<int, File> index = await _installedFontFileIndex();
    return index[pageNumber];
  }

  void clearCache() {
    // In-flight work is owned by its future and will finish safely; removing
    // the map entries prevents stale requests from blocking a new theme load.
    _loadingPages.clear();
    _loadedPages.clear();
    _fontFileIndex = null;
    _fontFileIndexRoot = null;
  }

  bool _isDarkMode() {
    final String? themeMode = SettingsDB().get('themeMode') as String?;
    return themeMode == 'dark' ||
        (themeMode == null) ||
        (themeMode == 'auto' &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);
  }

  Future<Map<int, File>> _installedFontFileIndex() async {
    final InstalledResource? installed = ResourceInstallStore.instance
        .installedFor(tajweedFontsResource);
    if (installed == null || installed.status != 'installed') {
      _fontFileIndex = const <int, File>{};
      _fontFileIndexRoot = null;
      return _fontFileIndex!;
    }

    final Directory directory = Directory(installed.localPath);
    if (!await directory.exists()) {
      _fontFileIndex = const <int, File>{};
      _fontFileIndexRoot = null;
      return _fontFileIndex!;
    }

    if (_fontFileIndexRoot == directory.path && _fontFileIndex != null) {
      return _fontFileIndex!;
    }

    final Map<int, File> index = <int, File>{};
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
        index.putIfAbsent(page, () => entity);
      }
    }

    _fontFileIndex = Map<int, File>.unmodifiable(index);
    _fontFileIndexRoot = directory.path;
    return _fontFileIndex!;
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
}
