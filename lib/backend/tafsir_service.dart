import 'dart:convert';
import 'dart:io';

import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/backend/resource_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

class TafsirVerseResult {
  const TafsirVerseResult({
    required this.resource,
    required this.installed,
    required this.text,
    this.error,
  });

  final DownloadableResource resource;
  final bool installed;
  final String text;
  final String? error;
}

class TafsirService {
  TafsirService._();

  static final TafsirService instance = TafsirService._();

  final Map<String, Future<Map<int, String>>> _surahCache =
      <String, Future<Map<int, String>>>{};

  Future<List<TafsirVerseResult>> selectedVerseTafsirs({
    required int surah,
    required int ayah,
  }) async {
    final ResourceManifest manifest = await ResourceRepository.instance
        .loadManifest();
    final List<String> selectedIds = ResourceInstallStore.instance
        .selectedTafsirResourceIds(manifest);
    final List<DownloadableResource> selectedResources = selectedIds
        .map(manifest.resourceById)
        .whereType<DownloadableResource>()
        .where(
          (DownloadableResource resource) =>
              resource.type == ResourceType.tafsir,
        )
        .toList(growable: false);

    final List<TafsirVerseResult> results = <TafsirVerseResult>[];
    for (final DownloadableResource resource in selectedResources) {
      final InstalledResource? installed = ResourceInstallStore.instance
          .installedFor(resource);
      if (installed == null ||
          !Directory(installed.localPath).existsSync() ||
          installed.status != 'installed') {
        results.add(
          TafsirVerseResult(resource: resource, installed: false, text: ''),
        );
        continue;
      }

      try {
        final Map<int, String> surahTafsir = await _loadSurahTafsir(
          resource: resource,
          installed: installed,
          surah: surah,
        );
        results.add(
          TafsirVerseResult(
            resource: resource,
            installed: true,
            text: surahTafsir[ayah]?.trim() ?? '',
          ),
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Unable to load tafsir ${resource.id}/$surah: $error');
        }
        results.add(
          TafsirVerseResult(
            resource: resource,
            installed: true,
            text: '',
            error: 'Unable to read this Tafsir.',
          ),
        );
      }
    }
    return results;
  }

  Future<Map<int, String>> _loadSurahTafsir({
    required DownloadableResource resource,
    required InstalledResource installed,
    required int surah,
  }) {
    final int normalizedSurah = surah.clamp(1, 114).toInt();
    final String cacheKey =
        '${resource.rawType}/${resource.id}/${installed.version}/$normalizedSurah';
    return _surahCache.putIfAbsent(cacheKey, () async {
      final File file = File(
        '${installed.localPath}${Platform.pathSeparator}$normalizedSurah.json',
      );
      final String raw = await file.readAsString();
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['ayahs'] is! List) {
        throw const FormatException('Unexpected Tafsir JSON shape.');
      }

      final Map<int, String> mapped = <int, String>{};
      for (final Object? entry in decoded['ayahs'] as List) {
        if (entry is! Map) continue;
        final int? ayahNumber = _readInt(entry['ayah']);
        if (ayahNumber == null) continue;
        final String text = _readTafsirText(entry['text']).trim();
        if (text.isNotEmpty) mapped[ayahNumber] = text;
      }
      return Map<int, String>.unmodifiable(mapped);
    });
  }

  void clearCache() {
    _surahCache.clear();
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String _readTafsirText(Object? value) {
    if (value is String) return value;
    if (value is Map) {
      final Object? nested = value['text'];
      if (nested is String) return nested;
    }
    return '';
  }
}
