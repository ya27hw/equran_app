import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;

/// One word's English gloss and transliteration.
@immutable
class WordGloss {
  const WordGloss({required this.meaning, required this.transliteration});

  final String meaning;
  final String transliteration;
}

class WordByWordPackException implements Exception {
  const WordByWordPackException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Provenance of an installed word-by-word pack (`meta.json`).
///
/// Mirrors the religious-content policy: a pack must declare its source,
/// license and review status, and unreviewed or unlicensed packs stay disabled.
@immutable
class WordByWordPackMeta {
  const WordByWordPackMeta({
    required this.schema,
    required this.id,
    required this.language,
    required this.version,
    required this.source,
    required this.license,
    required this.attribution,
    required this.reviewStatus,
    this.wordCount,
  });

  static const int supportedSchema = 1;
  static const String reviewedStatus = 'reviewed';

  final int schema;
  final String id;
  final String language;
  final String version;
  final String source;
  final String license;
  final String attribution;
  final String reviewStatus;
  final int? wordCount;

  /// Only reviewed packs of a known schema may power the UI.
  bool get isUsable =>
      schema == supportedSchema && reviewStatus == reviewedStatus;

  factory WordByWordPackMeta.fromJson(Object? json) {
    if (json is! Map) {
      throw const WordByWordPackException('meta.json must be a JSON object.');
    }
    String text(String key) {
      final Object? value = json[key];
      return value is String ? value.trim() : '';
    }

    final Object? schema = json['schema'];
    if (schema is! int) {
      throw const WordByWordPackException('meta.json has no schema number.');
    }
    final WordByWordPackMeta meta = WordByWordPackMeta(
      schema: schema,
      id: text('id'),
      language: text('language'),
      version: text('version'),
      source: text('source'),
      license: text('license'),
      attribution: text('attribution'),
      reviewStatus: text('reviewStatus'),
      wordCount: json['wordCount'] is int ? json['wordCount'] as int : null,
    );
    for (final MapEntry<String, String> field in <String, String>{
      'id': meta.id,
      'language': meta.language,
      'version': meta.version,
      'source': meta.source,
      'license': meta.license,
      'attribution': meta.attribution,
      'reviewStatus': meta.reviewStatus,
    }.entries) {
      if (field.value.isEmpty) {
        throw WordByWordPackException(
          'meta.json is missing "${field.key}"; packs need full provenance.',
        );
      }
    }
    return meta;
  }
}

/// Parses one surah file: `{"ayahs": {"1": [["meaning", "translit"], ...]}}`.
///
/// Throws [WordByWordPackException] unless every ayah of [surah] is present
/// with at least one well-formed gloss.
Map<int, List<WordGloss>> parseWordByWordSurah(Object? decoded, int surah) {
  final String name = '$surah.json';
  if (decoded is! Map || decoded['ayahs'] is! Map) {
    throw WordByWordPackException('$name has an unexpected format.');
  }
  final Map<dynamic, dynamic> ayahs = decoded['ayahs'] as Map<dynamic, dynamic>;
  final int expected = quran.getVerseCount(surah);
  final Map<int, List<WordGloss>> parsed = <int, List<WordGloss>>{};
  for (int ayah = 1; ayah <= expected; ayah++) {
    final Object? rawWords = ayahs['$ayah'];
    if (rawWords is! List || rawWords.isEmpty) {
      throw WordByWordPackException('$name is missing ayah $ayah.');
    }
    final List<WordGloss> words = <WordGloss>[];
    for (final Object? rawWord in rawWords) {
      if (rawWord is! List ||
          rawWord.length != 2 ||
          rawWord[0] is! String ||
          rawWord[1] is! String ||
          (rawWord[0] as String).trim().isEmpty) {
        throw WordByWordPackException('$name has a malformed word in $ayah.');
      }
      words.add(
        WordGloss(
          meaning: (rawWord[0] as String).trim(),
          transliteration: (rawWord[1] as String).trim(),
        ),
      );
    }
    parsed[ayah] = List<WordGloss>.unmodifiable(words);
  }
  if (ayahs.length != expected) {
    throw WordByWordPackException('$name has unexpected extra ayahs.');
  }
  return Map<int, List<WordGloss>>.unmodifiable(parsed);
}

/// Validates an extracted pack directory and returns its provenance.
Future<WordByWordPackMeta> validateWordByWordPack(Directory directory) async {
  final String sep = Platform.pathSeparator;
  final File metaFile = File('${directory.path}${sep}meta.json');
  if (!await metaFile.exists()) {
    throw const WordByWordPackException('The pack is missing meta.json.');
  }
  final WordByWordPackMeta meta;
  try {
    meta = WordByWordPackMeta.fromJson(
      jsonDecode(await metaFile.readAsString()),
    );
  } on FormatException {
    throw const WordByWordPackException('meta.json contains invalid JSON.');
  }
  if (!meta.isUsable) {
    throw const WordByWordPackException(
      'This word-by-word pack is not marked as reviewed, so it is disabled.',
    );
  }

  int words = 0;
  for (int surah = 1; surah <= 114; surah++) {
    final File file = File('${directory.path}$sep$surah.json');
    if (!await file.exists()) {
      throw WordByWordPackException('The pack is missing $surah.json.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException {
      throw WordByWordPackException('$surah.json contains invalid JSON.');
    }
    for (final List<WordGloss> ayah in parseWordByWordSurah(
      decoded,
      surah,
    ).values) {
      words += ayah.length;
    }
  }
  final int? declared = meta.wordCount;
  if (declared != null && declared != words) {
    throw WordByWordPackException(
      'meta.json declares $declared words but the pack has $words.',
    );
  }
  return meta;
}
