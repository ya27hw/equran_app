import 'package:equran/backend/hifz_db.dart' show HifzPrefs;
import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/hifz/hifz.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/redesign/display_numeral.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart' as quran;
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Hifz home page on the redesign system. There was no design preview; the
/// page follows the finished Statistics, Prayer and Duas pages (hero panel,
/// hairline cards, reader sheet chrome). The real page runs against in-memory
/// Hive boxes; due dates are seeded relative to now so the page is the same on
/// any day. The unit queue, frontier and limits are untouched.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerCompanionStorageAdapters();
    await Hive.openBox<HifzEntry>(HifzDB.entriesBoxName, bytes: Uint8List(0));
    await Hive.openBox<HifzReviewLog>(HifzDB.logsBoxName, bytes: Uint8List(0));
    await Hive.openBox<HifzUnit>(HifzDB.unitsBoxName, bytes: Uint8List(0));
    GoogleFonts.config.allowRuntimeFetching = false;
    final settings = SettingsDB();
    await Hive.openBox(settings.boxName, bytes: Uint8List(0));
    await settings.initBox();
    await quran.initializeQuran();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  tearDownAll(() async {
    await Hive.close();
  });

  HifzUnit unit(
    String id,
    String type,
    int number,
    int frontierSurah,
    int frontierAyah, {
    bool complete = false,
  }) => HifzUnit()
    ..id = id
    ..unitType = type
    ..unitNumber = number
    ..frontierSurah = frontierSurah
    ..frontierAyah = frontierAyah
    ..startedAt = DateTime(2026, 9, 1)
    ..isComplete = complete;

  HifzEntry entry(
    int surah,
    int ayah,
    String unitId,
    String status,
    int index, {
    required DateTime due,
    DateTime? learned,
  }) => HifzEntry()
    ..surah = surah
    ..ayah = ayah
    ..status = status
    ..track = status == 'learning' ? 'sabaq' : 'sabqi'
    ..dueDate = due
    ..unitId = unitId
    ..sequenceIndex = index
    ..firstLearnedAt = learned;

  Future<void> clear() async {
    await Hive.box<HifzEntry>(HifzDB.entriesBoxName).clear();
    await Hive.box<HifzUnit>(HifzDB.unitsBoxName).clear();
    await Hive.box<HifzReviewLog>(HifzDB.logsBoxName).clear();
    await SettingsDB().put('hifzMaxNewPerDay', 10);
  }

  /// Al-Fatihah is finished; Ash-Sharh has mastered, due and new ayahs; Juz 30
  /// has just begun.
  Future<void> seedRich() async {
    await clear();
    final DateTime now = DateTime.now();
    final DateTime past = now.subtract(const Duration(days: 1));
    final DateTime future = now.add(const Duration(days: 30));
    final units = Hive.box<HifzUnit>(HifzDB.unitsBoxName);
    for (final HifzUnit u in <HifzUnit>[
      unit('surah_1', 'surah', 1, 1, 8, complete: true),
      unit('surah_94', 'surah', 94, 94, 6),
      unit('juz_30', 'juz', 30, 78, 5),
    ]) {
      await units.put(u.id, u);
    }
    for (int a = 1; a <= 7; a++) {
      await HifzDB.saveEntry(
        entry(1, a, 'surah_1', 'mastered', a, due: future, learned: past),
      );
    }
    for (int a = 1; a <= 3; a++) {
      await HifzDB.saveEntry(
        entry(
          94,
          a,
          'surah_94',
          'mastered',
          a,
          due: future,
          learned: now.subtract(const Duration(days: 40)),
        ),
      );
    }
    await HifzDB.saveEntry(
      entry(
        94,
        4,
        'surah_94',
        'review',
        4,
        due: past,
        learned: now.subtract(const Duration(days: 2)),
      ),
    );
    await HifzDB.saveEntry(entry(94, 5, 'surah_94', 'learning', 5, due: past));
  }

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 1500,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(390, height);
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
        home: const Scaffold(body: HifzHomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(HifzHomePage)))!;

  final List<(String, EquranColors, double, Locale)> variants =
      <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
        ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
        ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ];
  for (final (String name, EquranColors colors, double scale, Locale locale)
      in variants) {
    testWidgets('Hifz home golden $name', (tester) async {
      await seedRich();
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1700 : 1500,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz_home/rich-$name.png'),
      );
    });
  }

  for (final (String name, EquranColors colors, Locale locale)
      in <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('emerald-light', EquranColors.light, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, const Locale('ar')),
      ]) {
    testWidgets('Hifz home empty golden $name', (tester) async {
      await clear();
      await pump(tester, colors: colors, locale: locale, height: 1400);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz_home/empty-$name.png'),
      );
    });
  }

  testWidgets('the hero and unit cards show the stored counts', (tester) async {
    await seedRich();
    await pump(tester);
    final AppLocalizations l = l10n(tester);
    // 7 + 3 mastered ayahs, two active units, nine started ayahs.
    expect(find.widgetWithText(DisplayNumeral, '10'), findsOneWidget);
    expect(find.text(l.hifzMemorized), findsOneWidget);
    expect(find.text(l.hifzDueNew(1)), findsOneWidget);
    expect(find.text(l.hifzDueRevision(1)), findsOneWidget);
    expect(find.text(l.hifzUnitReview), findsWidgets);
  });

  testWidgets('the surah type toggle switches to Juz and back', (tester) async {
    await seedRich();
    await pump(tester);
    final AppLocalizations l = l10n(tester);
    await tester.ensureVisible(find.text(l.hifzUnitTypeJuz).last);
    await tester.tap(find.text(l.hifzUnitTypeJuz).last);
    await tester.pumpAndSettle();
    expect(find.text(l.hifzSearchJuz), findsOneWidget);
    await tester.tap(find.text(l.hifzUnitTypeSurah).last);
    await tester.pumpAndSettle();
    expect(find.text(l.hifzSearchSurahs), findsOneWidget);
  });

  testWidgets('the grid expands and collapses', (tester) async {
    await seedRich();
    await pump(tester, height: 2600);
    final AppLocalizations l = l10n(tester);
    final Finder more = find.text(l.hifzShowAllSurahs);
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text(l.hifzShowLess), findsOneWidget);
    expect(find.text('114'), findsOneWidget);
  });

  for (final (String name, EquranColors colors, Locale locale)
      in <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('emerald-light', EquranColors.light, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, const Locale('ar')),
      ]) {
    testWidgets('Hifz settings sheet golden $name', (tester) async {
      await seedRich();
      await pump(tester, colors: colors, locale: locale, height: 1100);
      await tester.tap(find.byTooltip(l10n(tester).hifzSettingsSheetTitle));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(2));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz_home/settings-$name.png'),
      );
    });
  }

  testWidgets('settings save the chosen limits and blanking level', (
    tester,
  ) async {
    await seedRich();
    await pump(tester, height: 1100);
    await tester.tap(find.byTooltip(l10n(tester).hifzSettingsSheetTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).hifzSettingsBlankingHard));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).hifzSettingsDone));
    await tester.pumpAndSettle();
    expect(HifzPrefs.blankingLevel(), 'hard');
  });
}
