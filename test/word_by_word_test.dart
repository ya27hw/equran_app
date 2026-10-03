import 'dart:convert';
import 'dart:io';

import 'package:equran/backend/resource_models.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/word_by_word/word_alignment.dart';
import 'package:equran/word_by_word/word_by_word_pack.dart';
import 'package:equran/word_by_word/word_by_word_service.dart';
import 'package:equran/word_by_word/word_by_word_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;

Map<String, Object?> _meta({
  String reviewStatus = 'reviewed',
  String license = 'Test-License',
  int? wordCount,
}) => <String, Object?>{
  'schema': 1,
  'id': 'word_by_word_en',
  'language': 'en',
  'version': '1.0.0',
  'source': 'Test Source',
  'license': license,
  'attribution': 'Test attribution',
  'reviewStatus': reviewStatus,
  'wordCount': ?wordCount,
};

/// Writes a complete synthetic pack: two placeholder words per ayah.
Directory _writePack(Directory root, {Map<String, Object?>? meta}) {
  File('${root.path}/meta.json').writeAsStringSync(jsonEncode(meta ?? _meta()));
  for (int surah = 1; surah <= 114; surah++) {
    final Map<String, Object?> ayahs = <String, Object?>{
      for (int ayah = 1; ayah <= quran.getVerseCount(surah); ayah++)
        '$ayah': <Object?>[
          <String>['gloss $surah:$ayah a', 'tr a'],
          <String>['gloss $surah:$ayah b', 'tr b'],
        ],
    };
    File('${root.path}/$surah.json').writeAsStringSync(
      jsonEncode(<String, Object?>{'surah': surah, 'ayahs': ayahs}),
    );
  }
  return root;
}

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('wbw_test_'));
  tearDown(() => temp.deleteSync(recursive: true));

  test('manifest entries of type word_by_word are recognised', () {
    final ResourceManifest manifest = ResourceManifest.fromJson(
      <String, Object?>{
        'version': 1,
        'resources': <Object?>[
          <String, Object?>{
            'id': 'word_by_word_en',
            'type': 'word_by_word',
            'name': 'Word by word (English)',
            'version': '1.0.0',
            'url': 'https://example.invalid/word_by_word_en.zip',
          },
        ],
      },
    );
    expect(
      manifest.resourcesOfType(ResourceType.wordByWord).single.id,
      WordByWordService.resourceId,
    );
  });

  group('WordByWordPackMeta', () {
    test('accepts complete provenance', () {
      final WordByWordPackMeta meta = WordByWordPackMeta.fromJson(_meta());
      expect(meta.isUsable, isTrue);
      expect(meta.license, 'Test-License');
    });

    test('rejects a pack with no license', () {
      expect(
        () => WordByWordPackMeta.fromJson(_meta(license: '')),
        throwsA(isA<WordByWordPackException>()),
      );
    });

    test('an unreviewed pack parses but is not usable', () {
      expect(
        WordByWordPackMeta.fromJson(_meta(reviewStatus: 'unreviewed')).isUsable,
        isFalse,
      );
    });
  });

  group('validateWordByWordPack', () {
    test('accepts a complete reviewed pack', () async {
      _writePack(temp);
      final WordByWordPackMeta meta = await validateWordByWordPack(temp);
      expect(meta.source, 'Test Source');
    });

    test('rejects an unreviewed pack', () async {
      _writePack(temp, meta: _meta(reviewStatus: 'draft'));
      await expectLater(
        validateWordByWordPack(temp),
        throwsA(isA<WordByWordPackException>()),
      );
    });

    test('rejects a missing surah file', () async {
      _writePack(temp);
      File('${temp.path}/57.json').deleteSync();
      await expectLater(
        validateWordByWordPack(temp),
        throwsA(
          isA<WordByWordPackException>().having(
            (WordByWordPackException e) => e.message,
            'message',
            contains('57.json'),
          ),
        ),
      );
    });

    test('rejects a surah that omits an ayah', () async {
      _writePack(temp);
      final File file = File('${temp.path}/1.json');
      final Map<String, Object?> json =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      (json['ayahs']! as Map<String, Object?>).remove('3');
      file.writeAsStringSync(jsonEncode(json));
      await expectLater(
        validateWordByWordPack(temp),
        throwsA(isA<WordByWordPackException>()),
      );
    });

    test('rejects a malformed word entry', () async {
      _writePack(temp);
      final File file = File('${temp.path}/1.json');
      final Map<String, Object?> json =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      (json['ayahs']! as Map<String, Object?>)['1'] = <Object?>[
        <Object?>['only one field'],
      ];
      file.writeAsStringSync(jsonEncode(json));
      await expectLater(
        validateWordByWordPack(temp),
        throwsA(isA<WordByWordPackException>()),
      );
    });

    test('rejects a declared word count that does not match', () async {
      _writePack(temp, meta: _meta(wordCount: 5));
      await expectLater(
        validateWordByWordPack(temp),
        throwsA(isA<WordByWordPackException>()),
      );
    });
  });

  group('WordByWordService', () {
    test('has nothing when no pack is installed', () async {
      final WordByWordService service = WordByWordService.forTesting(
        () => null,
      );
      await service.ensureMeta();
      expect(service.isAvailable, isFalse);
      await service.prepare(1);
      expect(service.glossesFor(1, 1), isNull);
    });

    test('serves glosses per surah from an installed pack', () async {
      _writePack(temp);
      final WordByWordService service = WordByWordService.forTesting(
        () => temp,
      );
      await service.ensureMeta();
      expect(service.isAvailable, isTrue);
      expect(service.glossesFor(2, 5), isNull, reason: 'not prepared yet');

      await service.prepare(2);
      expect(service.isPrepared(2), isTrue);
      expect(service.glossesFor(2, 5)!.first.meaning, 'gloss 2:5 a');
      expect(service.glossesFor(1, 1), isNull, reason: 'other surah');
    });

    test('keeps a unreviewed pack disabled', () async {
      _writePack(temp, meta: _meta(reviewStatus: 'unreviewed'));
      final WordByWordService service = WordByWordService.forTesting(
        () => temp,
      );
      await service.ensureMeta();
      expect(service.isAvailable, isFalse);
    });

    test('a damaged surah file leaves that surah unglossed only', () async {
      _writePack(temp);
      File('${temp.path}/3.json').writeAsStringSync('{ not json');
      final WordByWordService service = WordByWordService.forTesting(
        () => temp,
      );
      await service.ensureMeta();
      await service.prepare(3);
      expect(service.isPrepared(3), isTrue, reason: 'prevents a reload loop');
      expect(service.glossesFor(3, 1), isNull);
      await service.prepare(4);
      expect(service.glossesFor(4, 1), isNotNull);
    });

    test('refresh drops cached data and notifies listeners', () async {
      _writePack(temp);
      final WordByWordService service = WordByWordService.forTesting(
        () => temp,
      );
      await service.ensureMeta();
      await service.prepare(1);
      int notified = 0;
      service.addListener(() => notified++);
      service.refresh();
      expect(notified, 1);
      expect(service.isAvailable, isFalse);
      expect(service.isPrepared(1), isFalse);
    });
  });

  group('WordByWordText', () {
    const String text = 'قَالَ ۖ رَبِّ ٱغۡفِرۡ';
    final List<WordRange> ranges = alignWordRanges(
      text: text,
      script: wordScriptHafs,
      wordCount: 3,
    )!;
    const List<WordGloss> glosses = <WordGloss>[
      WordGloss(meaning: 'he said', transliteration: 'qāla'),
      WordGloss(meaning: 'my Lord', transliteration: 'rabbi'),
      WordGloss(meaning: 'forgive', transliteration: 'igh-fir'),
    ];
    final WordByWordPackMeta meta = WordByWordPackMeta.fromJson(_meta());

    Offset centerOfWord(WidgetTester tester, int index) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText).first,
      );
      final List<TextBox> boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: ranges[index].start,
          extentOffset: ranges[index].end,
        ),
      );
      return paragraph.localToGlobal(boxes.first.toRect().center);
    }

    testWidgets('tapping a word reports that word, not its neighbour', (
      WidgetTester tester,
    ) async {
      final List<int> taps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WordByWordText(
                text: text,
                ranges: ranges,
                glosses: glosses,
                style: const TextStyle(fontSize: 30),
                meta: meta,
                onWordTap: taps.add,
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(centerOfWord(tester, 1));
      await tester.tapAt(centerOfWord(tester, 2));
      await tester.tapAt(centerOfWord(tester, 0));
      expect(taps, <int>[1, 2, 0]);
    });

    testWidgets('renders exactly the original text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordByWordText(
              text: text,
              ranges: ranges,
              glosses: glosses,
              style: const TextStyle(fontSize: 30),
              meta: meta,
            ),
          ),
        ),
      );
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText).first,
      );
      expect(paragraph.text.toPlainText(), text);
    });

    testWidgets('default tap shows meaning, transliteration and provenance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Center(
              child: WordByWordText(
                text: text,
                ranges: ranges,
                glosses: glosses,
                style: const TextStyle(fontSize: 30),
                meta: meta,
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(centerOfWord(tester, 1));
      await tester.pumpAndSettle();
      expect(find.text('my Lord'), findsOneWidget);
      expect(find.text('rabbi'), findsOneWidget);
      expect(find.textContaining('Test Source'), findsOneWidget);
      expect(find.textContaining('Test-License'), findsOneWidget);
    });
  });
}
