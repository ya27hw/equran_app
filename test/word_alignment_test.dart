import 'dart:convert';
import 'dart:io';

import 'package:equran/utils/quran_text.dart';
import 'package:equran/word_by_word/word_alignment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;

/// Per-ayah word counts of the gloss segmentation (integers only).
List<List<int>> _loadCounts() {
  final Map<String, Object?> json =
      jsonDecode(File('test/fixtures/wbw_word_counts.json').readAsStringSync())
          as Map<String, Object?>;
  return (json['counts']! as List<Object?>)
      .map((Object? row) => (row! as List<Object?>).cast<int>())
      .toList();
}

/// What the reader card renders for each ayah of [script], aligned or null.
Map<String, List<String>?> _alignAll(String script, List<List<int>> counts) {
  quran.setQuranTextAssetBase('assets/data/quran/text/$script');
  final Map<String, List<String>?> result = <String, List<String>?>{};
  for (int surah = 1; surah <= 114; surah++) {
    for (int ayah = 1; ayah <= counts[surah - 1].length; ayah++) {
      final String text = quranVerseText(surah, ayah);
      final List<WordRange>? ranges = alignWordRanges(
        text: text,
        script: script,
        wordCount: counts[surah - 1][ayah - 1],
      );
      result['$surah:$ayah'] = ranges
          ?.map((WordRange range) => text.substring(range.start, range.end))
          .toList();
    }
  }
  return result;
}

int _unaligned(Map<String, List<String>?> aligned) =>
    aligned.values.where((List<String>? words) => words == null).length;

/// Letter skeleton: drops marks and folds spelling variants between scripts.
String _skeleton(String word) {
  const Map<String, String> fold = <String, String>{
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ی': 'ي', 'ئ': 'ي', //
    'ک': 'ك', 'ہ': 'ه', 'ۃ': 'ه', 'ة': 'ه', 'ؤ': 'و', 'ۓ': 'ي', 'ے': 'ي',
  };
  final StringBuffer out = StringBuffer();
  for (final int rune in word.runes) {
    final bool mark =
        (rune >= 0x0610 && rune <= 0x061A) ||
        (rune >= 0x064B && rune <= 0x065F) ||
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        (rune >= 0x08D3 && rune <= 0x08FF) ||
        rune == 0x0670 ||
        rune == 0x0640 ||
        rune == 0x0621 ||
        rune == 0x20;
    if (mark) continue;
    final String char = String.fromCharCode(rune);
    out.write(fold[char] ?? char);
  }
  return out.toString();
}

/// Longest-common-subsequence similarity in [0, 1].
double _similarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1;
  final List<List<int>> table = List<List<int>>.generate(
    a.length + 1,
    (_) => List<int>.filled(b.length + 1, 0),
  );
  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      table[i][j] = a[i - 1] == b[j - 1]
          ? table[i - 1][j - 1] + 1
          : (table[i - 1][j] > table[i][j - 1]
                ? table[i - 1][j]
                : table[i][j - 1]);
    }
  }
  return 2 * table[a.length][b.length] / (a.length + b.length);
}

void main() {
  late List<List<int>> counts;
  late Map<String, List<String>?> hafs;
  late Map<String, List<String>?> indopak;
  late Map<String, List<String>?> v4;

  setUpAll(() {
    counts = _loadCounts();
    hafs = _alignAll(wordScriptHafs, counts);
    indopak = _alignAll(wordScriptIndoPak, counts);
    v4 = _alignAll(wordScriptQpcV4, counts);
  });

  test('fixture covers the canonical 6236 ayahs and 77429 words', () {
    expect(counts, hasLength(114));
    expect(counts.expand((List<int> row) => row).length, 6236);
    expect(
      counts.expand((List<int> row) => row).reduce((a, b) => a + b),
      77429,
    );
  });

  test('QPC Hafs aligns every ayah except a known handful', () {
    expect(_unaligned(hafs), 7);
  });

  test('QPC v4 aligns every ayah except a known handful', () {
    expect(_unaligned(v4), 3);
  });

  test('IndoPak aligns all but a known set of ayahs', () {
    expect(_unaligned(indopak), 18);
  });

  test('unknown script and bad counts never produce an alignment', () {
    expect(
      alignWordRanges(text: 'بِسْمِ ٱللَّهِ', script: 'nope', wordCount: 2),
      isNull,
    );
    expect(
      alignWordRanges(
        text: 'بِسْمِ ٱللَّهِ',
        script: wordScriptHafs,
        wordCount: 3,
      ),
      isNull,
    );
    expect(
      alignWordRanges(
        text: 'بِسْمِ ٱللَّهِ',
        script: wordScriptHafs,
        wordCount: 0,
      ),
      isNull,
    );
  });

  test('stop signs and the hizb marker are not counted as words', () {
    final List<WordRange>? ranges = alignWordRanges(
      text: '۞ قَالَ ۖ رَبِّ',
      script: wordScriptHafs,
      wordCount: 2,
    );
    expect(ranges, hasLength(2));
  });

  test('IndoPak vocative particle joins the word it calls', () {
    const String text = 'يَا أَيُّهَا النَّاسُ';
    final List<WordRange>? ranges = alignWordRanges(
      text: text,
      script: wordScriptIndoPak,
      wordCount: 2,
    );
    expect(ranges, isNotNull);
    expect(text.substring(ranges![0].start, ranges[0].end), 'يَا أَيُّهَا');
  });

  test('QPC v4 drops only the trailing ayah-number glyph', () {
    final List<WordRange>? ranges = alignWordRanges(
      text: 'ﭑ ﭒ ﭓ',
      script: wordScriptQpcV4,
      wordCount: 2,
    );
    expect(ranges, hasLength(2));
  });

  test('Hafs and IndoPak agree word-for-word wherever both align '
      '(guards against equal counts with shifted words)', () {
    int compared = 0;
    final List<String> weak = <String>[];
    for (final String key in hafs.keys) {
      final List<String>? a = hafs[key];
      final List<String>? b = indopak[key];
      if (a == null || b == null) continue;
      compared++;
      double worst = 1;
      for (int i = 0; i < a.length; i++) {
        final double s = _similarity(_skeleton(a[i]), _skeleton(b[i]));
        if (s < worst) worst = s;
      }
      // Spelling variants alone stay above 0.5; a shifted word would not.
      expect(worst, greaterThanOrEqualTo(0.5), reason: 'ayah $key');
      if (worst < 0.7) weak.add(key);
    }
    expect(compared, greaterThan(6000));
    expect(weak.length, lessThanOrEqualTo(10), reason: weak.join(', '));
  });
}
