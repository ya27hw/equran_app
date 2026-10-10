import 'dart:typed_data';

import 'package:equran/backend/library.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/widgets/number_badge.dart';
import 'package:equran/widgets/read_quran_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:like_button/like_button.dart';

/// The ayah card's header actions are drawn at 34 px (38 px on wide screens)
/// but take hits in a 44 px box each, without growing the header.
void main() {
  setUpAll(() async {
    registerCompanionStorageAdapters();
    for (final db in [
      SettingsDB(),
      QuranBookmarksDB(),
      FavouritesDB(),
      QuranBookmarkFoldersDB(),
    ]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
  });

  tearDownAll(Hive.close);

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required double width,
    required List<String> taps,
    bool shareImageMode = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
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
              verse: 'قُلۡ هُوَ ٱللَّهُ أَحَدٌ',
              shareImageMode: shareImageMode,
              onPlay: () => taps.add('play'),
              onTafsir: () => taps.add('tafsir'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return AppLocalizations.of(tester.element(find.byType(ReadQuranCard)))!;
  }

  for (final width in [390.0, 800.0]) {
    testWidgets('action targets are 44 px and never overlap at $width px', (
      tester,
    ) async {
      final taps = <String>[];
      final l = await pump(tester, width: width, taps: taps);
      final visual = width >= 700 ? 38.0 : 34.0;
      final play = find.byTooltip(l.play).first;
      final tafsir = find.byTooltip(l.tafsir).first;
      // The visible button keeps its size.
      expect(tester.getSize(play), Size.square(visual));
      expect(tester.getSize(tafsir), Size.square(visual));

      // A tap in the ring just outside the visible button still lands.
      final reach = visual / 2 + 2.5;
      await tester.tapAt(tester.getCenter(play) + Offset(reach, 0));
      await tester.tapAt(tester.getCenter(play) + Offset(0, -reach));
      await tester.tapAt(tester.getCenter(play) + Offset(0, reach));
      expect(taps, ['play', 'play', 'play']);
      taps.clear();
      await tester.tapAt(tester.getCenter(tafsir) + Offset(-reach, 0));
      await tester.tapAt(tester.getCenter(tafsir) + Offset(reach, 0));
      expect(taps, ['tafsir', 'tafsir'], reason: 'no overlap with play');

      // The favourite's own tap area (LikeButton) fills 44 px as well.
      final likeArea = find.descendant(
        of: find.byType(LikeButton),
        matching: find.byType(GestureDetector),
      );
      expect(tester.getSize(likeArea.first), const Size.square(44));

      // The header is still as tall as its 44 px badge.
      final header = find.ancestor(
        of: find.byType(SurahNumberBadge),
        matching: find.byType(Row),
      );
      expect(tester.getSize(header.first).height, 44);
    });
  }

  testWidgets('the share image has no header actions', (tester) async {
    final taps = <String>[];
    final l = await pump(tester, width: 390, taps: taps, shareImageMode: true);
    expect(find.byTooltip(l.play), findsNothing);
    expect(find.byType(LikeButton), findsNothing);
  });
}
