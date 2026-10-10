import 'package:equran/backend/resource_models.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/word_by_word/word_by_word_download_card.dart';
import 'package:equran/word_by_word/word_by_word_pack.dart';
import 'package:equran/word_by_word/word_by_word_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The word-by-word download card (Settings) and the word meaning sheet on the
/// redesign system. There is no design preview; the card sits inside a
/// Settings group, so it is an inset panel, and the sheet uses the reader
/// sheet chrome. Alignment, packs and install logic are not touched.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadGalleryFonts();
    for (final (family, asset) in [
      (
        'NotoNaskhArabic',
        'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
      ),
      ('UthmanicHafs', 'assets/media/fonts/UthmanicHafs_V22.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  Future<void> pump(
    WidgetTester tester,
    Widget Function(BuildContext) home, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Builder(builder: home),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  WordByWordPackRow row(
    ResourceInstallState state,
    List<String> log, {
    double? progress,
  }) => WordByWordPackRow(
    name: 'Word by word (English)',
    details: 'EN • v1.0.0 • 1.8 MB',
    state: state,
    progress: progress,
    onDownload: () => log.add('download'),
    onDelete: () => log.add('delete'),
  );

  Widget card(List<WordByWordPackRow> rows) => Builder(
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      return Scaffold(
        body: RedesignPageTypography(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: WordByWordDownloadCard(
                  title: l.wordByWord,
                  description: l.wordByWordDescription,
                  downloadTooltip: l.download,
                  updateTooltip: l.update,
                  deleteTooltip: l.delete,
                  rows: rows,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  testWidgets('the card offers download, update and delete per state', (
    tester,
  ) async {
    final log = <String>[];
    await pump(
      tester,
      (_) => card([
        row(ResourceInstallState.notDownloaded, log),
        row(ResourceInstallState.updateAvailable, log),
        row(ResourceInstallState.installed, log),
        row(ResourceInstallState.downloading, log, progress: .4),
      ]),
    );
    await tester.tap(find.byTooltip('Download'));
    await tester.tap(find.byTooltip('Update'));
    await tester.tap(find.byTooltip('Delete'));
    expect(log, ['download', 'download', 'delete']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('Update available'), findsOneWidget);
  });

  const gloss = WordGloss(meaning: 'my Lord', transliteration: 'rabbi');
  const meta = WordByWordPackMeta(
    schema: 1,
    id: 'word_by_word_en',
    language: 'en',
    version: '1.0.0',
    source: 'Test Source',
    license: 'Test-License',
    attribution: 'Test attribution',
    reviewStatus: 'reviewed',
  );
  Widget sheetHost(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showWordMeaningSheet(
          context,
          arabic: 'رَبِّ',
          gloss: gloss,
          meta: meta,
          arabicStyle: const TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 28,
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );

  testWidgets('the word sheet shows meaning, transliteration, provenance', (
    tester,
  ) async {
    await pump(tester, sheetHost);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('my Lord'), findsOneWidget);
    expect(find.text('rabbi'), findsOneWidget);
    expect(find.textContaining('Test Source'), findsOneWidget);
  });

  final variants = <(String, EquranColors, double, Locale)>[
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
  ];
  for (final (name, colors, scale, locale) in variants) {
    testWidgets('word by word card and sheet golden $name', (tester) async {
      await pump(
        tester,
        (_) => card([
          row(ResourceInstallState.installed, const []),
          row(ResourceInstallState.downloading, const [], progress: .4),
        ]),
        colors: colors,
        scale: scale,
        locale: locale,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/word_by_word/$name-card.png'),
      );
      await pump(
        tester,
        sheetHost,
        colors: colors,
        scale: scale,
        locale: locale,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/word_by_word/$name-sheet.png'),
      );
    });
  }
}
