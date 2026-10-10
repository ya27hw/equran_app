import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/search/quran_text_search_results.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart' as quran;
import 'gallery_test_support.dart' show loadGalleryFonts;

/// Quran text search results on the redesign system. There is no design
/// preview; the look follows the Saved tab's verse rows. Search behaviour and
/// pagination are the unchanged service and list.
void main() {
  setUpAll(() async {
    registerCompanionStorageAdapters();
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final db in [SettingsDB(), RecentSearchesDB()]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await SettingsDB().put('quranScriptStyle', 'qpc-hafs');
    await quran.initializeQuran();
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
  tearDownAll(() async {
    await Hive.close();
  });

  Future<List<String>> pump(
    WidgetTester tester,
    String query, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
  }) async {
    final selected = <String>[];
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
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: RedesignPageTypography(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: KeyedSubtree(
                  key: UniqueKey(),
                  child: QuranTextSearchResults(
                    searchQuery: query,
                    onSearchSelected: selected.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return selected;
  }

  setUp(() => RecentSearchesDB().clear());

  testWidgets('results show the surah pill, Arabic and translation', (
    tester,
  ) async {
    await pump(tester, 'patience');
    expect(find.byType(InkWell), findsWidgets);
    expect(find.textContaining('Baqarah'), findsWidgets);
    // The search is also stored in the recents, as before.
    expect(RecentSearchesDB().box.values.length, greaterThanOrEqualTo(1));
  });

  testWidgets('no match shows the empty state', (tester) async {
    await pump(tester, 'zzzzqqqq');
    final l = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l.noQuranTextResults), findsOneWidget);
  });

  testWidgets('recent searches list and select a query', (tester) async {
    await RecentSearchesDB().put(
      'quran_text:mercy',
      RecentSearchEntry(
        id: 'quran_text:mercy',
        query: 'mercy',
        mode: 'quran_text',
        searchedAt: DateTime(2026, 10, 1),
        resultCount: 42,
      ),
    );
    final selected = await pump(tester, '');
    await tester.tap(find.text('mercy'));
    await tester.pumpAndSettle();
    expect(selected, ['mercy']);
  });

  testWidgets('nothing searched yet shows the hint state', (tester) async {
    await pump(tester, '');
    final l = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l.searchQuranText), findsOneWidget);
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
    testWidgets('search results, recents and empty golden $name', (
      tester,
    ) async {
      await pump(
        tester,
        'patience',
        colors: colors,
        scale: scale,
        locale: locale,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/search/$name-results.png'),
      );
      await RecentSearchesDB().clear();
      for (final (query, count) in [('patience', 18), ('mercy', 114)]) {
        await RecentSearchesDB().put(
          'quran_text:$query',
          RecentSearchEntry(
            id: 'quran_text:$query',
            query: query,
            mode: 'quran_text',
            searchedAt: DateTime(2026, 10, 1).add(Duration(hours: count)),
            resultCount: count,
          ),
        );
      }
      await pump(tester, '', colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/search/$name-recents.png'),
      );
      await pump(
        tester,
        'zzzzqqqq',
        colors: colors,
        scale: scale,
        locale: locale,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/search/$name-empty.png'),
      );
    });
  }
}
