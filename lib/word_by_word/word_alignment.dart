import 'package:flutter/foundation.dart';

/// Half-open `[start, end)` range of one word inside the rendered ayah string.
@immutable
class WordRange {
  const WordRange(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is WordRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'WordRange($start, $end)';
}

/// Script ids as stored by `SettingsDB.quranScriptStyle`.
const String wordScriptHafs = 'qpc-hafs';
const String wordScriptIndoPak = 'indopak';
const String wordScriptQpcV4 = 'qpc-v4';

/// Maps the words of a rendered ayah onto a word-by-word gloss list.
///
/// The gloss data segments the Quran into words the way Quran.com does. Each
/// bundled script spells and spaces the same text differently, so the rendered
/// string is normalised to that segmentation:
///
/// * whitespace separates tokens;
/// * tokens made only of annotation marks (stop signs, the hizb marker) are
///   not words;
/// * QPC v4 text ends with one glyph for the ayah number, which is not a word;
/// * IndoPak writes the vocative particle apart from the word it calls
///   ("يَا أَيُّهَا"), which the gloss data counts as one word.
///
/// Returns `null`, so the caller keeps the plain text, unless the result has
/// exactly [wordCount] words. A wrong gloss on a Quran word is worse than none,
/// so any ayah the rules do not explain stays unglossed instead of guessed.
List<WordRange>? alignWordRanges({
  required String text,
  required String script,
  required int wordCount,
}) {
  if (wordCount <= 0) return null;
  final List<WordRange> tokens = <WordRange>[
    for (final RegExpMatch match in _tokenPattern.allMatches(text))
      WordRange(match.start, match.end),
  ];

  final List<WordRange> words;
  switch (script) {
    case wordScriptQpcV4:
      if (tokens.isEmpty) return null;
      words = tokens.sublist(0, tokens.length - 1);
    case wordScriptHafs:
      words = _withoutMarkOnlyTokens(text, tokens);
    case wordScriptIndoPak:
      words = _joinVocatives(text, _withoutMarkOnlyTokens(text, tokens));
    default:
      return null;
  }

  if (words.length != wordCount) return null;
  return List<WordRange>.unmodifiable(words);
}

final RegExp _tokenPattern = RegExp(r'\S+');

List<WordRange> _withoutMarkOnlyTokens(String text, List<WordRange> tokens) {
  return <WordRange>[
    for (final WordRange token in tokens)
      if (!_isMarkOnly(text.substring(token.start, token.end))) token,
  ];
}

List<WordRange> _joinVocatives(String text, List<WordRange> words) {
  final List<WordRange> joined = <WordRange>[];
  for (int i = 0; i < words.length; i++) {
    final WordRange word = words[i];
    final bool isVocative =
        _letters(text.substring(word.start, word.end)) == 'يا';
    if (isVocative && i + 1 < words.length) {
      joined.add(WordRange(word.start, words[i + 1].end));
      i++;
    } else {
      joined.add(word);
    }
  }
  return joined;
}

String _letters(String token) {
  return String.fromCharCodes(
    token.runes.where((int rune) => !_isDiacritic(rune)),
  );
}

bool _isMarkOnly(String token) {
  return token.runes.every(_isAnnotationRune);
}

bool _isAnnotationRune(int rune) {
  return _isDiacritic(rune) ||
      rune == 0x0640 ||
      rune == 0x06DD ||
      (rune >= 0x0660 && rune <= 0x0669) ||
      (rune >= 0x06F0 && rune <= 0x06F9);
}

bool _isDiacritic(int rune) {
  return (rune >= 0x0610 && rune <= 0x061A) ||
      (rune >= 0x064B && rune <= 0x065F) ||
      rune == 0x0670 ||
      (rune >= 0x06D6 && rune <= 0x06ED) ||
      (rune >= 0x08D3 && rune <= 0x08FF);
}
