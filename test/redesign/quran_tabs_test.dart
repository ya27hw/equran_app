import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/home/main_page.dart';
import 'package:equran/home/read.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/favourites_list.dart' show SavedQuranHeader;
import 'package:equran/widgets/quran_reading_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran/quran.dart' as quran;
import 'gallery_test_support.dart' show loadGalleryFonts;

ThemeData _theme(EquranColors colors) {
  final base = savedPreviewTheme(colors);
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamilyFallback: const ['NotoNaskhArabic'],
    ),
  );
}

class _ReadingObserver extends NavigatorObserver {
  Route<dynamic>? pushed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed = route;
  }
}

void main() {
  setUpAll(() async {
    registerCompanionStorageAdapters();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReadingEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SurahAdapter());
    await Hive.openBox<HifzEntry>(HifzDB.entriesBoxName, bytes: Uint8List(0));
    await Hive.openBox<HifzUnit>(HifzDB.unitsBoxName, bytes: Uint8List(0));
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final db in [
      SettingsDB(),
      QuranBookmarksDB(),
      FavouritesDB(),
      QuranBookmarkFoldersDB(),
      BookmarkDB(),
      SurahDB(),
    ]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await initializeDateFormatting();
    await quran.initializeQuran();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
    await (FontLoader('UthmanicHafs')
          ..addFont(rootBundle.load('assets/media/fonts/UthmanicHafs_V22.ttf')))
        .load();
  });
  setUp(() async {
    await seedSavedPreview();
    await SettingsDB().put('showLastRead', false);
    await BookmarkDB().clear();
  });
  tearDownAll(Hive.close);

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    int tab = 0,
    List<NavigatorObserver> observers = const [],
    double width = 390,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(colors),
        navigatorObservers: observers,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ColoredBox(color: colors.background, child: const MainPage()),
      ),
    );
    await tester.pumpAndSettle();
    if (tab != 0) {
      final l = AppLocalizations.of(tester.element(find.byType(MainPage)))!;
      await tester.tap(
        find.descendant(
          of: find.byType(SavedQuranHeader),
          matching: find.text([l.surahs, l.juz, l.pages, l.saved][tab]),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets('one header serves all four tabs and tracks the selection', (
    tester,
  ) async {
    await pump(tester);
    for (final tab in [0, 1, 2, 3]) {
      final l = AppLocalizations.of(tester.element(find.byType(MainPage)))!;
      await tester.tap(
        find.descendant(
          of: find.byType(SavedQuranHeader),
          matching: find.text([l.surahs, l.juz, l.pages, l.saved][tab]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SavedQuranHeader), findsOneWidget);
      expect(
        tester
            .widget<SavedQuranHeader>(find.byType(SavedQuranHeader))
            .selectedIndex,
        tab,
      );
    }
  });

  testWidgets('surah search keeps working inside the shared header', (
    tester,
  ) async {
    await pump(tester);
    final l = AppLocalizations.of(tester.element(find.byType(MainPage)))!;
    await tester.tap(find.byTooltip(l.searchQuran));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('header-search')), findsOneWidget);
    expect(find.text(l.surahs), findsOneWidget, reason: 'tabs stay visible');
    await tester.enterText(find.byType(TextField), 'baqarah');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(find.textContaining('Baqarah'), findsWidgets);
    expect(find.textContaining('Fatiha'), findsNothing);
    await tester.tap(find.byTooltip(l.closeSearch));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('header-search')), findsNothing);
    expect(find.textContaining('Fatiha'), findsWidgets);
  });

  testWidgets('first-read hero opens Al Fatiha at ayah one', (tester) async {
    await SettingsDB().put('showLastRead', true);
    final observer = _ReadingObserver();
    await pump(tester, observers: [observer]);
    expect(find.byType(QuranReadingHero), findsOneWidget);
    expect(find.text('Begin with Quran'), findsOneWidget);
    expect(find.text('Start with Al Fatiha'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quran-reading-hero')));
    final target =
        (observer.pushed! as MaterialPageRoute<void>).builder(
              tester.element(find.byType(MainPage)),
            )
            as ReadPage;
    expect(target.chapter, 1);
    expect(target.startVerse, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resume carousel preserves each saved reading position', (
    tester,
  ) async {
    await SettingsDB().put('showLastRead', true);
    await BookmarkDB().put(
      1,
      ReadingEntry(surah: 1, verse: 4, timestamp: DateTime(2026, 10, 4)),
    );
    await BookmarkDB().put(
      2,
      ReadingEntry(surah: 2, verse: 50, timestamp: DateTime(2026, 10, 3)),
    );
    final observer = _ReadingObserver();
    await pump(tester, observers: [observer]);
    expect(find.text('Ayah 4'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('quran-reading-hero')).hitTestable(),
      const Offset(-330, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ayah 50'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quran-reading-hero')).hitTestable());
    final target =
        (observer.pushed! as MaterialPageRoute<void>).builder(
              tester.element(find.byType(MainPage)),
            )
            as ReadPage;
    expect(target.chapter, 2);
    expect(target.startVerse, 50);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'hero grows for large text, long titles and RTL at narrow widths',
    (tester) async {
      await SettingsDB().put('showLastRead', true);
      await BookmarkDB().put(
        3,
        ReadingEntry(surah: 3, verse: 12, timestamp: DateTime(2026, 10, 4)),
      );
      for (final locale in const [Locale('en'), Locale('ar'), Locale('de')]) {
        await tester.pumpWidget(const SizedBox());
        await pump(tester, scale: 2, locale: locale, width: 320);
        expect(
          tester.getSize(find.byType(QuranReadingHero)).height,
          greaterThan(200),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  final variants = [
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
  ];
  for (final (name, colors, scale, locale) in variants) {
    for (final firstRead in [false, true]) {
      testWidgets('Quran hero ${firstRead ? "first" : "resume"} golden $name', (
        tester,
      ) async {
        await SettingsDB().put('showLastRead', true);
        if (!firstRead) {
          await BookmarkDB().put(
            1,
            ReadingEntry(surah: 1, verse: 4, timestamp: DateTime(2026, 10, 4)),
          );
        }
        await pump(tester, colors: colors, scale: scale, locale: locale);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/quran/hero-${firstRead ? "first" : "resume"}-$name.png',
          ),
        );
      });
    }
    for (final (tab, tabName) in [(0, 'surahs'), (1, 'juz'), (2, 'pages')]) {
      testWidgets('Quran $tabName golden $name', (tester) async {
        await pump(
          tester,
          colors: colors,
          scale: scale,
          locale: locale,
          tab: tab,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/quran/$tabName-$name.png'),
        );
      });
    }
  }
}
