import 'package:quran/quran.dart' as quran;

class JourneyReference {
  const JourneyReference({
    required this.surah,
    required this.ayah,
    required this.order,
  });

  final int surah;
  final int ayah;
  final int order;

  String get id => '$surah:$ayah';

  Map<String, Object?> toMap() => <String, Object?>{
    'surah': surah,
    'ayah': ayah,
    'order': order,
  };
}

class QuranJourneyPack {
  const QuranJourneyPack({
    required this.id,
    required this.title,
    required this.version,
    required this.references,
    required this.sourceIds,
    required this.license,
    required this.reviewStatus,
    this.navigationText = const <String, String>{},
  });

  final String id;
  final String title;
  final String version;
  final List<JourneyReference> references;
  final List<String> sourceIds;
  final String license;
  final String reviewStatus;
  final Map<String, String> navigationText;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'title': title,
    'version': version,
    'references': references
        .map((JourneyReference reference) => reference.toMap())
        .toList(growable: false),
    'sourceIds': sourceIds,
    'license': license,
    'reviewStatus': reviewStatus,
    'navigationText': navigationText,
  };

  static QuranJourneyPack? fromMap(Object? raw) {
    if (raw is! Map || raw['references'] is! List) return null;
    final List<JourneyReference> references = <JourneyReference>[];
    for (final Object? item in raw['references'] as List) {
      if (item is! Map ||
          item['surah'] is! num ||
          item['ayah'] is! num ||
          item['order'] is! num) {
        return null;
      }
      references.add(
        JourneyReference(
          surah: (item['surah'] as num).toInt(),
          ayah: (item['ayah'] as num).toInt(),
          order: (item['order'] as num).toInt(),
        ),
      );
    }
    final List<String> sourceIds =
        (raw['sourceIds'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    final Map<String, String> navigationText = raw['navigationText'] is Map
        ? (raw['navigationText'] as Map).map<String, String>(
            (Object? key, Object? value) =>
                MapEntry(key.toString(), value.toString()),
          )
        : const <String, String>{};
    final QuranJourneyPack pack = QuranJourneyPack(
      id: raw['id']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      version: raw['version']?.toString() ?? '',
      references: List<JourneyReference>.unmodifiable(references),
      sourceIds: sourceIds,
      license: raw['license']?.toString() ?? '',
      reviewStatus: raw['reviewStatus']?.toString() ?? '',
      navigationText: Map<String, String>.unmodifiable(navigationText),
    );
    try {
      const QuranJourneyPackValidator().validate(pack);
    } on JourneyPackValidationException {
      return null;
    }
    return pack;
  }
}

class JourneyPackValidationException implements Exception {
  const JourneyPackValidationException(this.message);

  final String message;

  @override
  String toString() => 'JourneyPackValidationException: $message';
}

class QuranJourneyPackValidator {
  const QuranJourneyPackValidator();

  void validate(QuranJourneyPack pack) {
    if (pack.id.trim().isEmpty || pack.title.trim().isEmpty) {
      throw const JourneyPackValidationException(
        'Journey identity is missing.',
      );
    }
    if (pack.version.trim().isEmpty || pack.license.trim().isEmpty) {
      throw const JourneyPackValidationException(
        'Journey provenance is incomplete.',
      );
    }
    if (pack.reviewStatus != 'reviewed') {
      throw const JourneyPackValidationException(
        'Journey pack is not reviewed.',
      );
    }
    if (pack.sourceIds.isEmpty) {
      throw const JourneyPackValidationException(
        'Journey sources are missing.',
      );
    }
    int previousOrder = 0;
    final Set<String> ids = <String>{};
    for (final JourneyReference reference in pack.references) {
      if (reference.surah < 1 ||
          reference.surah > 114 ||
          reference.ayah < 1 ||
          reference.ayah > quran.getVerseCount(reference.surah)) {
        throw const JourneyPackValidationException(
          'Journey reference is out of range.',
        );
      }
      if (reference.order <= previousOrder || !ids.add(reference.id)) {
        throw const JourneyPackValidationException(
          'Journey references are not ordered uniquely.',
        );
      }
      previousOrder = reference.order;
    }
  }
}
