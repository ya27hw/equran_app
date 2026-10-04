import 'dart:io';

import 'package:equran/backend/settings_db.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/widgets/read_quran_card.dart';
import 'package:equran/word_by_word/word_alignment.dart';
import 'package:equran/word_by_word/word_by_word_pack.dart';
import 'package:equran/word_by_word/word_by_word_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const String _verse = 'قُلۡ هُوَ ٱللَّهُ أَحَدٌ';
const List<WordGloss> _fourGlosses = <WordGloss>[
  WordGloss(meaning: 'Say', transliteration: 'qul'),
  WordGloss(meaning: 'He', transliteration: 'huwa'),
  WordGloss(meaning: 'Allah', transliteration: 'allahu'),
  WordGloss(meaning: 'the One', transliteration: 'ahadun'),
];
const WordByWordPackMeta _meta = WordByWordPackMeta(
  schema: 1,
  id: 'word_by_word_en',
  language: 'en',
  version: '1.0.0',
  source: 'Test Source',
  license: 'Test-License',
  attribution: 'x',
  reviewStatus: 'reviewed',
);

Widget _card({
  ValueChanged<bool>? onOverlay,
  List<WordGloss>? glosses,
  WordByWordPackMeta? meta,
  String? script,
  bool shareImageMode = false,
}) {
  return MaterialApp(
    theme: AppTheme.buildLightTheme(Colors.green),
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: ReadQuranCard(
          currentChapter: 112,
          currentVerse: 1,
          totalVerses: 4,
          fontSize: 28,
          fontSizeTranslation: 16,
          juzNumber: 30,
          translation: 'Say, He is Allah, One.',
          verse: _verse,
          showActions: false,
          shareImageMode: shareImageMode,
          wordGlosses: glosses,
          wordByWordMeta: meta,
          quranScript: script,
          onVisualOverlayChanged: onOverlay,
        ),
      ),
    ),
  );
}

void main() {
  late Directory temp;

  setUpAll(() async {
    temp = Directory.systemTemp.createTempSync('wbw_card_');
    Hive.init(temp.path);
    await SettingsDB().initBox();
  });

  tearDownAll(() async {
    await Hive.close();
    temp.deleteSync(recursive: true);
  });

  testWidgets('reader translation uses the Daily Dua display font', (
    tester,
  ) async {
    await tester.pumpWidget(_card());
    final Text text = tester.widget(find.text('Say, He is Allah, One.'));
    expect(text.style!.fontFamily, 'Newsreader');
    expect(text.style!.fontStyle, FontStyle.italic);
    expect(text.style!.fontSize, 16);
  });

  testWidgets('share translation retains its existing font', (tester) async {
    await tester.pumpWidget(_card(shareImageMode: true));
    final Text text = tester.widget(find.text('Say, He is Allah, One.'));
    expect(text.style!.fontFamily, isNot('Newsreader'));
    expect(text.style!.fontStyle, isNot(FontStyle.italic));
  });

  testWidgets('aligned glosses make the ayah words tappable', (tester) async {
    await tester.pumpWidget(
      _card(glosses: _fourGlosses, meta: _meta, script: 'qpc-hafs'),
    );
    expect(find.byType(WordByWordText), findsOneWidget);
  });

  testWidgets('tapping a word opens the sheet inside the overlay bracket', (
    tester,
  ) async {
    final List<bool> overlay = <bool>[];
    await tester.pumpWidget(
      _card(
        glosses: _fourGlosses,
        meta: _meta,
        script: 'qpc-hafs',
        onOverlay: overlay.add,
      ),
    );
    final List<WordRange> ranges = alignWordRanges(
      text: _verse,
      script: 'qpc-hafs',
      wordCount: 4,
    )!;
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byType(WordByWordText),
            matching: find.byType(RichText),
          )
          .first,
    );
    final Offset secondWord = paragraph.localToGlobal(
      paragraph
          .getBoxesForSelection(
            TextSelection(
              baseOffset: ranges[1].start,
              extentOffset: ranges[1].end,
            ),
          )
          .first
          .toRect()
          .center,
    );

    await tester.tapAt(secondWord);
    await tester.pumpAndSettle();
    expect(find.text('He'), findsOneWidget, reason: 'meaning of word 2');
    expect(overlay, <bool>[true], reason: 'sheet is open');

    await tester.tapAt(const Offset(5, 5)); // dismiss via the scrim
    await tester.pumpAndSettle();
    expect(find.text('He'), findsNothing);
    expect(overlay, <bool>[true, false]);
    // The overlay helper arms an idle timer; let it expire.
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('a gloss count that does not match keeps plain text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(
        glosses: _fourGlosses.sublist(0, 3),
        meta: _meta,
        script: 'qpc-hafs',
      ),
    );
    expect(find.byType(WordByWordText), findsNothing);
    expect(find.text(_verse), findsOneWidget);
  });

  testWidgets('share images are never tappable', (tester) async {
    await tester.pumpWidget(
      _card(
        glosses: _fourGlosses,
        meta: _meta,
        script: 'qpc-hafs',
        shareImageMode: true,
      ),
    );
    expect(find.byType(WordByWordText), findsNothing);
    expect(find.text(_verse), findsOneWidget);
  });

  testWidgets('without a pack the card is unchanged plain text', (
    tester,
  ) async {
    await tester.pumpWidget(_card());
    expect(find.byType(WordByWordText), findsNothing);
    expect(find.text(_verse), findsOneWidget);
  });

  testWidgets('a missing script keeps plain text', (tester) async {
    await tester.pumpWidget(_card(glosses: _fourGlosses, meta: _meta));
    expect(find.byType(WordByWordText), findsNothing);
  });
}
