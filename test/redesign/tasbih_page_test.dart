import 'package:equran/backend/base_db.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/duas/tasbih_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Tasbih counter on the redesign system. There was no design preview; the
/// page follows the finished Statistics (serif numerals, hairline cards) and
/// the reader sheet chrome. The real page is pumped against in-memory boxes.
/// Counting, presets, completion and storage are untouched; the tests below
/// drive them to show it. Sessions are seeded relative to now so the stats are
/// the same on any day.
void main() {
  setUpAll(() async {
    registerCompanionStorageAdapters();
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final BaseDB db in <BaseDB>[SettingsDB(), DhikrSessionsDB()]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await loadGalleryFonts();
    for (final (String family, String asset) in <(String, String)>[
      (
        'NotoNaskhArabic',
        'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
      ),
      ('UthmanicHafs', 'assets/media/fonts/UthmanicHafs_V22.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });
  tearDownAll(Hive.close);

  setUp(() async {
    await SettingsDB().put('tasbih.selectedPreset', 0);
    await SettingsDB().put('tasbih.currentCount', 12);
    await SettingsDB().put('tasbih.hapticsEnabled', true);
    await DhikrSessionsDB().box.clear();
    final DateTime now = DateTime.now();
    DhikrSessionEntry session(
      String id,
      String label,
      int count,
      int target, {
      required int daysAgo,
      required bool done,
    }) {
      final DateTime at = now.subtract(Duration(days: daysAgo));
      return DhikrSessionEntry(
        id: id,
        label: label,
        targetCount: target,
        count: count,
        startedAt: at,
        completedAt: done ? at : null,
      );
    }

    for (final DhikrSessionEntry e in <DhikrSessionEntry>[
      session('a', 'SubhanAllah', 33, 33, daysAgo: 0, done: true),
      session('b', 'Alhamdulillah', 20, 33, daysAgo: 0, done: false),
      session('c', 'Allahu Akbar', 34, 34, daysAgo: 1, done: true),
      session('d', 'Astaghfirullah', 100, 100, daysAgo: 2, done: true),
    ]) {
      await DhikrSessionsDB().put(e.id, e);
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 1150,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(390, height);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const Scaffold(body: TasbihPage(showAppBar: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(TasbihPage)))!;

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
    testWidgets('Tasbih golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1400 : 1150,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tasbih/page-$name.png'),
      );
    });
  }

  testWidgets('tapping the counter adds one and persists it', (tester) async {
    await pump(tester);
    expect(find.text('12'), findsOneWidget);
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    expect(SettingsDB().get('tasbih.currentCount'), 13);
  });

  testWidgets('presets cycle and reset clears the count', (tester) async {
    await pump(tester);
    final AppLocalizations l = l10n(tester);
    await tester.tap(find.byTooltip(l.nextDhikr));
    await tester.pumpAndSettle();
    expect(find.text(l.alhamdulillah), findsWidgets);
    expect(find.text('0'), findsWidgets);
    expect(SettingsDB().get('tasbih.selectedPreset'), 1);
    await tester.tap(find.byTooltip(l.previousDhikr));
    await tester.tap(find.byTooltip(l.previousDhikr));
    await tester.pumpAndSettle();
    // Previous wraps from the first preset to the last (Custom).
    expect(find.text(l.custom), findsWidgets);
    await tester.tap(find.byTooltip(l.resetCounter));
    await tester.pumpAndSettle();
    expect(SettingsDB().get('tasbih.currentCount'), 0);
  });

  testWidgets('the haptics row saves its switch', (tester) async {
    await pump(tester);
    await tester.tap(find.text(l10n(tester).haptics));
    await tester.pumpAndSettle();
    expect(SettingsDB().get('tasbih.hapticsEnabled'), false);
  });

  testWidgets('today stats count the seeded sessions', (tester) async {
    await pump(tester);
    // 33 + 20 saved today plus the 12 counted on the page, one finished
    // round, a three day streak.
    expect(find.text('65'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3d'), findsOneWidget);
  });

  for (final (String name, EquranColors colors, Locale locale)
      in <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('emerald-light', EquranColors.light, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, const Locale('ar')),
      ]) {
    testWidgets('Tasbih recent sessions sheet golden $name', (tester) async {
      // Fixed dates, so the times and dates in the sheet never change.
      await DhikrSessionsDB().box.clear();
      for (final (String, String, int, int, DateTime, bool) e
          in <(String, String, int, int, DateTime, bool)>[
            ('a', 'SubhanAllah', 33, 33, DateTime(2026, 9, 20, 9, 30), true),
            ('b', 'Alhamdulillah', 20, 33, DateTime(2026, 9, 20, 9, 42), false),
            ('c', 'Allahu Akbar', 34, 34, DateTime(2026, 9, 19, 21, 5), true),
            (
              'd',
              'Astaghfirullah',
              100,
              100,
              DateTime(2026, 9, 18, 6, 15),
              true,
            ),
          ]) {
        await DhikrSessionsDB().put(
          e.$1,
          DhikrSessionEntry(
            id: e.$1,
            label: e.$2,
            count: e.$3,
            targetCount: e.$4,
            startedAt: e.$5,
            completedAt: e.$6 ? e.$5 : null,
          ),
        );
      }
      await pump(tester, colors: colors, locale: locale, height: 1150);
      final Finder button = find.text(l10n(tester).recentSessions);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(ReaderSheetFrame), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tasbih/sessions-$name.png'),
      );
    });
  }
}
