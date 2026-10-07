import 'package:equran/backend/base_db.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/reading_plans/reading_plans_page.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Reading routine page on the redesign system. There is no design
/// preview; the look follows the finished Downloads, Statistics and Duas
/// pages. The real page is pumped against in-memory Hive boxes with a fixed
/// clock (the page's optional `now`), so today's portion is the same every day.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerCompanionStorageAdapters();
    for (final BaseDB db in <BaseDB>[
      SettingsDB(),
      ReadingPlansDB(),
      RoutineDayProgressDB(),
    ]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await initializeDateFormatting();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  tearDownAll(Hive.close);

  final DateTime fixedNow = DateTime(2026, 10, 5, 10);

  ReadingPlanEntry plan({
    required String id,
    required String type,
    required DateTime start,
    required int days,
    required int completed,
    bool active = true,
  }) => ReadingPlanEntry(
    id: id,
    type: type,
    title: type,
    startedAt: start,
    finishBy: DateTime(start.year, start.month, start.day + days - 1),
    startGlobalAyah: 1,
    targetGlobalAyah: 6236,
    lastCompletedGlobalAyah: completed,
    active: active,
  );

  Future<void> seed({bool withActive = true, bool withPast = true}) async {
    await ReadingPlansDB().box.clear();
    await RoutineDayProgressDB().box.clear();
    if (withActive) {
      final ReadingPlanEntry p = plan(
        id: 'plan:complete_30_days:1',
        type: 'complete_30_days',
        start: DateTime(2026, 10, 1),
        days: 30,
        completed: 640,
      );
      await ReadingPlansDB().put(p.id, p);
    }
    if (withPast) {
      final ReadingPlanEntry p = plan(
        id: 'plan:complete_7_days:0',
        type: 'complete_7_days',
        start: DateTime(2026, 9, 1),
        days: 7,
        completed: 1800,
        active: false,
      );
      await ReadingPlansDB().put(p.id, p);
    }
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(body: ReadingPlansPage(now: () => fixedNow)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ReadingPlansPage)))!;

  Future<void> expandPast(WidgetTester tester) async {
    final Finder past = find.text(l10n(tester).pastRoutines);
    await tester.ensureVisible(past);
    await tester.tap(past);
    await tester.pumpAndSettle();
  }

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
    testWidgets('Reading plans golden $name', (tester) async {
      await seed();
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 2100 : 1700,
      );
      await expandPast(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/reading_plans/active-$name.png'),
      );
    });
  }

  for (final (String name, EquranColors colors, double scale, Locale locale)
      in <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ]) {
    testWidgets('Reading plans empty golden $name', (tester) async {
      await seed(withActive: false, withPast: false);
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1500 : 1250,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/reading_plans/empty-$name.png'),
      );
    });
  }

  testWidgets('figures come from the routine summary, unchanged', (
    tester,
  ) async {
    await seed();
    await pump(tester);
    final AppLocalizations l = l10n(tester);
    // 640 of 6236 ayahs done; 5596 remain over 26 days from the 5th.
    expect(find.text(l.routineCompletedAyahs(640, 6236)), findsWidgets);
    expect(find.text(l.todaysPortionAyahs(216)), findsOneWidget);
    expect(find.text(l.resume), findsOneWidget);
    expect(find.text('${l.allLabel} 1'), findsOneWidget);
    expect(find.text('${l.skippedLabel} 0'), findsOneWidget);
  });

  testWidgets('deleting asks first and removes the routine', (tester) async {
    await seed();
    await pump(tester);
    await tester.tap(find.byTooltip(l10n(tester).deleteRoutineTooltip).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.text(l10n(tester).cancel));
    await tester.pumpAndSettle();
    expect(ReadingPlansDB().box.length, 2);
    await tester.tap(find.byTooltip(l10n(tester).deleteRoutineTooltip).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n(tester).delete));
    await tester.pumpAndSettle();
    expect(ReadingPlansDB().box.length, 1);
  });

  for (final (String name, EquranColors colors, Locale locale)
      in <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('arabic-rtl', EquranColors.light, const Locale('ar')),
      ]) {
    testWidgets('Reading plans delete dialog golden $name', (tester) async {
      await seed();
      await pump(tester, colors: colors, locale: locale, height: 844);
      await tester.tap(find.byTooltip(l10n(tester).deleteRoutineTooltip).first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/reading_plans/delete-$name.png'),
      );
    });
  }

  testWidgets('choosing a preset starts it and retires the old one', (
    tester,
  ) async {
    await seed(withPast: false);
    await pump(tester);
    final Finder sixty = find.text(l10n(tester).preset60DaysTitle);
    await tester.ensureVisible(sixty);
    await tester.tap(sixty);
    await tester.pumpAndSettle();
    final List<ReadingPlanEntry> plans = ReadingPlansDB().box.values
        .whereType<ReadingPlanEntry>()
        .toList();
    expect(plans, hasLength(2));
    expect(plans.where((p) => p.active).single.type, 'complete_60_days');
  });
}
