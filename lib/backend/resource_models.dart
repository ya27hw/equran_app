import 'dart:convert';

enum ResourceType {
  tafsir('tafsir'),
  timings('timings'),
  quranFonts('quran_fonts'),
  translation('translation'),
  wordByWord('word_by_word'),
  unknown('unknown');

  const ResourceType(this.value);

  final String value;

  static ResourceType fromString(String value) {
    final String normalized = value.trim().toLowerCase();
    return ResourceType.values.firstWhere(
      (ResourceType type) => type.value == normalized,
      orElse: () => ResourceType.unknown,
    );
  }
}

class ResourceManifest {
  const ResourceManifest({required this.version, required this.resources});

  final int version;
  final List<DownloadableResource> resources;

  factory ResourceManifest.fromJson(Map<String, Object?> json) {
    final Object? rawResources = json['resources'];
    return ResourceManifest(
      version: _readInt(json['version']) ?? 1,
      resources: rawResources is List
          ? rawResources
                .whereType<Map>()
                .map(
                  (Map<dynamic, dynamic> item) =>
                      DownloadableResource.fromJson(_stringKeyedMap(item)),
                )
                .where(
                  (DownloadableResource resource) => resource.id.isNotEmpty,
                )
                .toList(growable: false)
          : const <DownloadableResource>[],
    );
  }

  factory ResourceManifest.fromJsonString(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Resource manifest must be a JSON object.');
    }
    return ResourceManifest.fromJson(_stringKeyedMap(decoded));
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': version,
      'resources': resources
          .map((DownloadableResource resource) => resource.toJson())
          .toList(growable: false),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  List<DownloadableResource> resourcesOfType(ResourceType type) {
    return resources
        .where((DownloadableResource resource) => resource.type == type)
        .toList(growable: false);
  }

  DownloadableResource? resourceById(String id) {
    final String normalizedId = id.trim();
    for (final DownloadableResource resource in resources) {
      if (resource.id == normalizedId) return resource;
    }
    return null;
  }
}

class DownloadableResource {
  const DownloadableResource({
    required this.id,
    required this.rawType,
    required this.name,
    required this.version,
    required this.url,
    this.language,
    this.reciterCode,
    this.sha256,
    this.sizeBytes,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String rawType;
  final String name;
  final String version;
  final String url;
  final String? language;
  final String? reciterCode;
  final String? sha256;
  final int? sizeBytes;
  final Map<String, Object?> metadata;

  ResourceType get type => ResourceType.fromString(rawType);

  String get typeLabel {
    return switch (type) {
      ResourceType.tafsir => 'Tafsir',
      ResourceType.timings => 'Audio Timings',
      ResourceType.quranFonts => 'Quran Fonts',
      ResourceType.translation => 'Translation',
      ResourceType.wordByWord => 'Word by Word',
      ResourceType.unknown => rawType.isEmpty ? 'Resource' : rawType,
    };
  }

  factory DownloadableResource.fromJson(Map<String, Object?> json) {
    final Set<String> knownKeys = <String>{
      'id',
      'type',
      'name',
      'language',
      'reciterCode',
      'version',
      'url',
      'sha256',
      'sizeBytes',
    };
    return DownloadableResource(
      id: _readString(json['id']),
      rawType: _readString(json['type']),
      name: _readString(json['name']),
      language: _readOptionalString(json['language']),
      reciterCode: _readOptionalString(json['reciterCode']),
      version: _readString(json['version'], fallback: '1.0.0'),
      url: _readString(json['url']),
      sha256: _readOptionalString(json['sha256']),
      sizeBytes: _readInt(json['sizeBytes']),
      metadata: Map<String, Object?>.unmodifiable(
        Map<String, Object?>.fromEntries(
          json.entries.where((MapEntry<String, Object?> entry) {
            return !knownKeys.contains(entry.key);
          }),
        ),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...metadata,
      'id': id,
      'type': rawType,
      'name': name,
      if (language != null) 'language': language,
      if (reciterCode != null) 'reciterCode': reciterCode,
      'version': version,
      'url': url,
      if (sha256 != null) 'sha256': sha256,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
    };
  }
}

class InstalledResource {
  const InstalledResource({
    required this.id,
    required this.rawType,
    required this.version,
    required this.installedAt,
    required this.localPath,
    required this.status,
    this.sha256,
    this.sizeBytes,
  });

  final String id;
  final String rawType;
  final String version;
  final DateTime installedAt;
  final String localPath;
  final String status;
  final String? sha256;
  final int? sizeBytes;

  ResourceType get type => ResourceType.fromString(rawType);

  factory InstalledResource.fromJson(Map<String, Object?> json) {
    return InstalledResource(
      id: _readString(json['id']),
      rawType: _readString(json['type']),
      version: _readString(json['version']),
      installedAt:
          DateTime.tryParse(_readString(json['installedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      localPath: _readString(json['localPath']),
      sha256: _readOptionalString(json['sha256']),
      sizeBytes: _readInt(json['sizeBytes']),
      status: _readString(json['status'], fallback: 'installed'),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'type': rawType,
      'version': version,
      'installedAt': installedAt.toIso8601String(),
      'localPath': localPath,
      if (sha256 != null) 'sha256': sha256,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      'status': status,
    };
  }
}

enum ResourceInstallState {
  notDownloaded,
  installed,
  updateAvailable,
  downloading;

  String get label {
    return switch (this) {
      ResourceInstallState.notDownloaded => 'Not downloaded',
      ResourceInstallState.installed => 'Installed',
      ResourceInstallState.updateAvailable => 'Update available',
      ResourceInstallState.downloading => 'Downloading',
    };
  }
}

Map<String, Object?> _stringKeyedMap(Map<dynamic, dynamic> map) {
  return map.map(
    (dynamic key, dynamic value) =>
        MapEntry<String, Object?>(key.toString(), value),
  );
}

String _readString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value.trim();
  return value.toString().trim();
}

String? _readOptionalString(Object? value) {
  final String text = _readString(value);
  return text.isEmpty ? null : text;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
