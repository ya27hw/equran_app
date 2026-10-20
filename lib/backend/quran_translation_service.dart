import 'dart:convert';
import 'dart:io';

import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/backend/resource_repository.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:quran/quran.dart' as quran;

class QuranTranslationService {
  QuranTranslationService._();

  static final QuranTranslationService instance = QuranTranslationService._();

  quran.Translation selectedTranslation() {
    final dynamic saved = SettingsDB().get('translation', defaultValue: 0);
    if (saved is int && saved >= 0 && saved < quran.Translation.values.length) {
      return quran.Translation.values[saved];
    }
    return quran.Translation.enSaheeh;
  }

  bool isBundled(quran.Translation translation) {
    return translation.isBundled;
  }

  DownloadableResource? resourceForTranslation(
    quran.Translation translation,
    ResourceManifest manifest,
  ) {
    for (final DownloadableResource resource in manifest.resourcesOfType(
      ResourceType.translation,
    )) {
      if (resource.id == translation.resourceId) return resource;
    }
    return null;
  }

  Future<void> preloadSelectedTranslation() async {
    final quran.Translation translation = selectedTranslation();
    if (translation.isBundled) return;
    final DownloadableResource? resource = await ResourceRepository.instance
        .translationResourceForId(translation.resourceId);
    if (resource == null) return;
    await loadInstalledTranslationForResource(resource);
  }

  Future<void> loadInstalledTranslation(quran.Translation translation) async {
    if (translation.isBundled) return;
    final DownloadableResource? resource = await ResourceRepository.instance
        .translationResourceForId(translation.resourceId);
    if (resource == null) {
      quran.clearRegisteredTranslation(translation);
      return;
    }
    await loadInstalledTranslationForResource(resource);
  }

  Future<void> loadInstalledTranslationForResource(
    DownloadableResource resource,
  ) async {
    if (resource.type != ResourceType.translation) return;
    final quran.Translation? translation = _translationForResourceId(
      resource.id,
    );
    if (translation == null || translation.isBundled) return;

    final InstalledResource? installed = ResourceInstallStore.instance
        .installedFor(resource);
    if (installed == null ||
        installed.status != 'installed' ||
        !Directory(installed.localPath).existsSync()) {
      quran.clearRegisteredTranslation(translation);
      return;
    }

    try {
      for (int surah = 1; surah <= quran.totalSurahCount; surah++) {
        final File file = File(
          '${installed.localPath}${Platform.pathSeparator}$surah.json',
        );
        quran.registerTranslationSurah(
          translation: translation,
          surah: surah,
          verses: await _readTranslationFile(file, surah),
        );
      }
    } catch (error) {
      quran.clearRegisteredTranslation(translation);
      if (kDebugMode) {
        debugPrint('Unable to load translation ${resource.id}: $error');
      }
    }
  }

  quran.Translation? _translationForResourceId(String resourceId) {
    final String normalized = resourceId.trim();
    for (final quran.Translation translation in quran.Translation.values) {
      if (translation.resourceId == normalized) return translation;
    }
    return null;
  }

  Future<Map<int, String>> _readTranslationFile(File file, int surah) async {
    final Object? decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map || decoded['ayahs'] is! List) {
      throw const FormatException('Unexpected translation JSON shape.');
    }
    final Map<int, String> mapped = <int, String>{};
    for (final Object? entry in decoded['ayahs'] as List) {
      if (entry is! Map) continue;
      final int? entrySurah =
          _readInt(entry['surah']) ?? _readInt(entry['surahNumber']);
      final int? ayah =
          _readInt(entry['ayah']) ?? _readInt(entry['ayahNumber']);
      final Object? text = entry['text'];
      if (entrySurah == surah && ayah != null && text is String) {
        mapped[ayah] = text;
      }
    }
    return Map<int, String>.unmodifiable(mapped);
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
