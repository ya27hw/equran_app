import 'package:equran/backend/base_db.dart';
import 'package:quran/quran.dart' as quran;

class JourneyCapsule {
  const JourneyCapsule({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.createdAt,
    this.reflection = '',
    this.voicePath,
    this.resurfaceAt,
    this.action,
    this.mood,
    this.tags = const <String>[],
  });

  final String id;
  final int surah;
  final int ayah;
  final String reflection;
  final String? voicePath;
  final DateTime createdAt;
  final DateTime? resurfaceAt;
  final String? action;
  final String? mood;
  final List<String> tags;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'surah': surah,
    'ayah': ayah,
    'reflection': reflection,
    'voicePath': voicePath,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'resurfaceAt': resurfaceAt?.toUtc().toIso8601String(),
    'action': action,
    'mood': mood,
    'tags': tags,
  };

  static JourneyCapsule? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final int? parsedSurah = _intValue(raw['surah']);
    final int? parsedAyah = _intValue(raw['ayah']);
    final String? parsedId = _text(raw['id'], maxLength: 128);
    final DateTime? parsedCreated = _date(raw['createdAt']);
    if (parsedSurah == null ||
        parsedAyah == null ||
        parsedSurah < 1 ||
        parsedSurah > 114 ||
        parsedAyah < 1 ||
        parsedAyah > quran.getVerseCount(parsedSurah) ||
        parsedId == null ||
        parsedCreated == null) {
      return null;
    }
    return JourneyCapsule(
      id: parsedId,
      surah: parsedSurah,
      ayah: parsedAyah,
      reflection: _text(raw['reflection'], maxLength: 10000) ?? '',
      voicePath: _text(raw['voicePath'], maxLength: 4096),
      createdAt: parsedCreated,
      resurfaceAt: _date(raw['resurfaceAt']),
      action: _text(raw['action'], maxLength: 2000),
      mood: _text(raw['mood'], maxLength: 128),
      tags:
          (raw['tags'] as List?)
              ?.whereType<String>()
              .map((String tag) => tag.trim())
              .where((String tag) => tag.isNotEmpty && tag.length <= 64)
              .take(32)
              .toList(growable: false) ??
          const <String>[],
    );
  }

  static int? _intValue(Object? value) => value is num ? value.toInt() : null;

  static String? _text(Object? value, {required int maxLength}) {
    if (value is! String) return null;
    final String normalized = value.trim();
    return normalized.length <= maxLength ? normalized : null;
  }

  static DateTime? _date(Object? value) {
    if (value is DateTime) return value.toUtc();
    return value is String ? DateTime.tryParse(value)?.toUtc() : null;
  }
}

class JourneyCapsulesDB extends BaseDB {
  JourneyCapsulesDB._() : super('journey_capsules');

  static final JourneyCapsulesDB instance = JourneyCapsulesDB._();

  Future<void> save(JourneyCapsule capsule) async {
    if (capsule.id.trim().isEmpty ||
        capsule.surah < 1 ||
        capsule.surah > 114 ||
        capsule.ayah < 1 ||
        capsule.ayah > quran.getVerseCount(capsule.surah)) {
      throw ArgumentError('Journey capsule reference is invalid.');
    }
    await put(capsule.id, capsule.toMap());
  }

  JourneyCapsule? find(String id) => JourneyCapsule.fromMap(get(id));

  List<JourneyCapsule> all() {
    return box.values
        .map(JourneyCapsule.fromMap)
        .whereType<JourneyCapsule>()
        .toList(growable: false);
  }

  Future<void> deleteCapsule(String id) => delete(id);

  List<Map<dynamic, dynamic>> due(DateTime now) {
    return all()
        .where((JourneyCapsule capsule) {
          final DateTime? at = capsule.resurfaceAt;
          return at != null && !at.isAfter(now);
        })
        .map((JourneyCapsule capsule) => capsule.toMap())
        .toList(growable: false);
  }

  Future<void> reset() => clear();
}
