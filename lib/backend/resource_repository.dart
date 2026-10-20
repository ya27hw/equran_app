import 'dart:io';
import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/utils/reciter.dart';
import 'package:http/http.dart' as http;

class ResourceRepository {
  ResourceRepository._();

  static final ResourceRepository instance = ResourceRepository._();

  static const String _manifestCacheKey = 'downloadableResourceManifest.v1';
  static const String _manifestFetchedAtKey =
      'downloadableResourceManifestFetchedAt.v1';
  static const String _assetLatestDownloadBase =
      'https://github.com/ya27hw/equran-assets/releases/latest/download';
  static const String _asset100DownloadBase =
      'https://github.com/ya27hw/equran-assets/releases/download/1.0.0';
  static const List<String> _remoteManifestUrls = <String>[
    '$_assetLatestDownloadBase/resource_manifest.json',
    '$_assetLatestDownloadBase/manifest.json',
  ];

  ResourceManifest? _cachedManifest;

  Future<ResourceManifest> loadManifest({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedManifest != null) return _cachedManifest!;

    if (forceRefresh || _cachedManifest == null) {
      final ResourceManifest? remoteManifest = await _loadRemoteManifest();
      if (remoteManifest != null) {
        _cachedManifest = remoteManifest;
        return remoteManifest;
      }
    }

    final ResourceManifest? storedManifest = _loadCachedManifest();
    if (storedManifest != null) {
      _cachedManifest = storedManifest;
      return storedManifest;
    }

    final ResourceManifest fallback = ResourceManifest.fromJson(
      _fallbackManifest,
    );
    _cachedManifest = fallback;
    return fallback;
  }

  Future<ResourceManifest> refreshManifest() {
    return loadManifest(forceRefresh: true);
  }

  Future<DownloadableResource?> resourceById(String id) async {
    return (await loadManifest()).resourceById(id);
  }

  Future<DownloadableResource?> timingResourceForReciter(
    String reciterCode,
  ) async {
    final String rawCode = reciterCode.trim().toLowerCase();
    if (rawCode.isEmpty) return null;
    final ResourceManifest manifest = await loadManifest();

    // First try exact match (case-insensitive) to prevent incorrect legacy normalizations
    for (final DownloadableResource resource in manifest.resourcesOfType(
      ResourceType.timings,
    )) {
      final String? rCode = resource.reciterCode?.trim().toLowerCase();
      if (rCode == rawCode || resource.id.toLowerCase() == rawCode) {
        return resource;
      }
    }

    // Fallback to legacy normalization match for backward compatibility
    final String normalized = AppReciter.normalizeCode(rawCode);
    for (final DownloadableResource resource in manifest.resourcesOfType(
      ResourceType.timings,
    )) {
      final String? rawResourceReciterCode = resource.reciterCode?.trim();
      final String resourceReciterCode =
          rawResourceReciterCode == null || rawResourceReciterCode.isEmpty
          ? ''
          : AppReciter.normalizeCode(rawResourceReciterCode);
      if (resourceReciterCode == normalized || resource.id == normalized) {
        return resource;
      }
    }
    return null;
  }

  Future<DownloadableResource?> translationResourceForId(String id) async {
    final String normalized = id.trim();
    if (normalized.isEmpty) return null;
    final ResourceManifest manifest = await loadManifest();
    for (final DownloadableResource resource in manifest.resourcesOfType(
      ResourceType.translation,
    )) {
      if (resource.id == normalized) return resource;
    }
    return null;
  }

  ResourceManifest? _loadCachedManifest() {
    final Object? raw = SettingsDB().get(_manifestCacheKey);
    if (raw is! String || raw.trim().isEmpty) return null;
    try {
      return ResourceManifest.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  Future<ResourceManifest?> _loadRemoteManifest() async {
    for (final String manifestUrl in _remoteManifestUrls) {
      try {
        final http.Response response = await http
            .get(Uri.parse(manifestUrl))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200 || response.body.trim().isEmpty) {
          continue;
        }

        final ResourceManifest manifest = ResourceManifest.fromJsonString(
          response.body,
        );
        if (manifest.resources.isEmpty) continue;

        await SettingsDB().put(_manifestCacheKey, manifest.toJsonString());
        await SettingsDB().put(
          _manifestFetchedAtKey,
          DateTime.now().toUtc().toIso8601String(),
        );
        return manifest;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static final Map<String, Object?> _fallbackManifest = <String, Object?>{
    'version': 1,
    'resources': <Map<String, Object?>>[
      <String, Object?>{
        'id': 'en_al_jalalayn',
        'type': 'tafsir',
        'name': 'Al-Jalalayn',
        'language': 'en',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/en_al_jalalayn.zip',
        'sizeBytes': 856901,
      },
      <String, Object?>{
        'id': 'en_al_mukhtasar',
        'type': 'tafsir',
        'name': 'Al-Mukhtasar',
        'language': 'en',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/en_al_mukhtasar.zip',
        'sizeBytes': 666054,
      },
      <String, Object?>{
        'id': '2',
        'type': 'timings',
        'name': 'Abu Bakr Al Shatri timings',
        'reciterCode': '2',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/2.zip',
        'sizeBytes': 35778,
      },
      <String, Object?>{
        'id': '3',
        'type': 'timings',
        'name': 'Nasser Al Qatami timings',
        'reciterCode': '3',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/3.zip',
        'sizeBytes': 36122,
      },
      <String, Object?>{
        'id': '4',
        'type': 'timings',
        'name': 'Yasser Al Dosari timings',
        'reciterCode': '4',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/4.zip',
        'sizeBytes': 35905,
      },
      <String, Object?>{
        'id': 'en_clear_quran',
        'type': 'translation',
        'name': 'English Clear Quran',
        'language': 'en',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/en_clear_quran.zip',
        'sizeBytes': 394045,
      },
      <String, Object?>{
        'id': 'qpc_v4_tajweed_fonts',
        'type': 'quran_fonts',
        'name': 'QPC V4 Tajweed fonts',
        'version': '1.0.0',
        'url': '$_asset100DownloadBase/tajweed.zip',
        'sizeBytes': 69230903,
        'requiredPages': 604,
      },
      <String, Object?>{
        'id': 'tr_saheeh',
        'type': 'translation',
        'name': 'Turkish Saheeh',
        'language': 'tr',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/tr_saheeh.zip',
        'sizeBytes': 374009,
      },
      <String, Object?>{
        'id': 'ml_abdul_hameed',
        'type': 'translation',
        'name': 'Malayalam Abdul Hameed',
        'language': 'ml',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/ml_abdul_hameed.zip',
        'sizeBytes': 560936,
      },
      <String, Object?>{
        'id': 'fa_hussein_dari',
        'type': 'translation',
        'name': 'Persian Hussein Dari',
        'language': 'fa',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/fa_hussein_dari.zip',
        'sizeBytes': 463000,
      },
      <String, Object?>{
        'id': 'fr_hamidullah',
        'type': 'translation',
        'name': 'French Hamidullah',
        'language': 'fr',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/fr_hamidullah.zip',
        'sizeBytes': 417681,
      },
      <String, Object?>{
        'id': 'it_piccardo',
        'type': 'translation',
        'name': 'Italian Piccardo',
        'language': 'it',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/it_piccardo.zip',
        'sizeBytes': 379499,
      },
      <String, Object?>{
        'id': 'nl_siregar',
        'type': 'translation',
        'name': 'Dutch Siregar',
        'language': 'nl',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/nl_siregar.zip',
        'sizeBytes': 398706,
      },
      <String, Object?>{
        'id': 'portuguese',
        'type': 'translation',
        'name': 'Portuguese',
        'language': 'pt',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/portuguese.zip',
        'sizeBytes': 420000,
      },
      <String, Object?>{
        'id': 'ru_kuliev',
        'type': 'translation',
        'name': 'Russian Kuliev',
        'language': 'ru',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/ru_kuliev.zip',
        'sizeBytes': 453329,
      },
      <String, Object?>{
        'id': 'urdu',
        'type': 'translation',
        'name': 'Urdu',
        'language': 'ur',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/urdu.zip',
        'sizeBytes': 491574,
      },
      <String, Object?>{
        'id': 'bengali',
        'type': 'translation',
        'name': 'Bengali',
        'language': 'bn',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/bengali.zip',
        'sizeBytes': 474157,
      },
      <String, Object?>{
        'id': 'chinese',
        'type': 'translation',
        'name': 'Chinese',
        'language': 'zh',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/chinese.zip',
        'sizeBytes': 372520,
      },
      <String, Object?>{
        'id': 'indonesian',
        'type': 'translation',
        'name': 'Indonesian',
        'language': 'id',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/indonesian.zip',
        'sizeBytes': 407684,
      },
      <String, Object?>{
        'id': 'spanish',
        'type': 'translation',
        'name': 'Spanish',
        'language': 'es',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/spanish.zip',
        'sizeBytes': 410751,
      },
      <String, Object?>{
        'id': 'swedish',
        'type': 'translation',
        'name': 'Swedish',
        'language': 'sv',
        'version': '1.0.0',
        'url': '$_assetLatestDownloadBase/swedish.zip',
        'sizeBytes': 455052,
      },
      <String, Object?>{
        'id': 'de_bubenheim',
        'type': 'translation',
        'name': 'German (Bubenheim)',
        'language': 'de',
        'version': '1.0.0',
        'url':
            'https://github.com/ya27hw/equran-assets/releases/download/1.0.0/de_bubenheim.zip',
        'sizeBytes': 428148,
      },
      <String, Object?>{
        'id': 'de_nadeem',
        'type': 'translation',
        'name': 'German (Nadeem)',
        'language': 'de',
        'version': '1.0.0',
        'url':
            'https://github.com/ya27hw/equran-assets/releases/download/1.0.0/de_nadeem.zip',
        'sizeBytes': 427435,
      },
      <String, Object?>{
        'id': 'de_aburida',
        'type': 'translation',
        'name': 'German (Abu Rida)',
        'language': 'de',
        'version': '1.0.0',
        'url':
            'https://github.com/ya27hw/equran-assets/releases/download/1.0.0/de_aburida.zip',
        'sizeBytes': 430441,
      },
    ],
  };
}

int? getResourceSize(DownloadableResource resource) {
  // 1. Try to get size from installed metadata
  final InstalledResource? installed = ResourceInstallStore.instance
      .installedFor(resource);
  if (installed != null &&
      installed.sizeBytes != null &&
      installed.sizeBytes! > 0) {
    return installed.sizeBytes;
  }
  // 2. Try to get size from actual disk files if installed
  if (installed != null) {
    try {
      final Directory dir = Directory(installed.localPath);
      if (dir.existsSync()) {
        int total = 0;
        for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
          if (entity is File) {
            total += entity.lengthSync();
          }
        }
        if (total > 0) return total;
      }
    } catch (_) {}
  }
  // 3. Try to get size from manifest resource
  if (resource.sizeBytes != null && resource.sizeBytes! > 0) {
    return resource.sizeBytes;
  }
  // 4. Try to get size from hardcoded fallbacks
  final String id = resource.id;
  final int? fallbackSize = switch (id) {
    'en_al_jalalayn' => 856901,
    'en_al_mukhtasar' => 666054,
    '2' => 35778,
    '3' => 36122,
    '4' => 35905,
    'en_clear_quran' => 394045,
    'qpc_v4_tajweed_fonts' => 69230903,
    'tr_saheeh' => 374009,
    'ml_abdul_hameed' => 560936,
    'fa_hussein_dari' => 463000,
    'fr_hamidullah' => 417681,
    'it_piccardo' => 379499,
    'nl_siregar' => 398706,
    'portuguese' => 420000,
    'ru_kuliev' => 453329,
    'urdu' => 491574,
    'bengali' => 474157,
    'chinese' => 372520,
    'indonesian' => 407684,
    'spanish' => 410751,
    'swedish' => 455052,
    _ => null,
  };
  return fallbackSize;
}

String prettyBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return 'Size unknown';
  const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
  double value = bytes.toDouble();
  int unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final String formatted = unitIndex == 0 || value >= 10
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}
