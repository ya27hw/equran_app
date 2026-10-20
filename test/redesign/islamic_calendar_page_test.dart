import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/prayer/islamic_calendar_page.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Islamic calendar on the redesign system. The page is pumped with a fixed
/// clock (its optional `now`), set in March 2026 so the month holds Ramadan,
/// Laylat al-Qadr nights and Eid al-Fitr. Hijri dates come from the unchanged
/// `HijriCalendar`.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
    await initializeDateFormatting();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  setUp(() async {
    await SettingsDB().put('hijri_offset', 0);
    await SettingsDB().put('fasting_reminders_enabled', false);
  });
  tearDownAll(Hive.close);

  final DateTime fixedNow = DateTime(2026, 3, 14, 10);

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double width = 390,
    double height = 1900,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
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
        home: Scaffold(body: IslamicCalendarPage(now: () => fixedNow)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(IslamicCalendarPage)))!;

  String hijriText(DateTime date) =>
      HijriCalendar.fromDate(date).toLocalizedDateString('en');

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
    testWidgets('Islamic calendar golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 2700 : 1900,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/islamic_calendar/month-$name.png'),
      );
    });
  }

  testWidgets('Eid and today stay lighter than the selected day', (
    tester,
  ) async {
    await pump(tester);
    // 1 Shawwal 1447 falls on 20 March 2026 in the unchanged calculation.
    final HijriCalendar eid = HijriCalendar.fromDate(DateTime(2026, 3, 20));
    expect((eid.hMonth, eid.hDay), (10, 1));
    final Finder eidCell = find.bySemanticsLabel(RegExp('^March 20, 2026'));
    expect(eidCell, findsOneWidget);
    await tester.tap(eidCell);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/islamic_calendar/eid-selected.png'),
    );
    expect(find.text(l10n(tester).occasionEidAlFitr), findsWidgets);
  });

  testWidgets('the selected day is shown above the fold on a phone', (
    tester,
  ) async {
    await pump(tester, height: 844);
    final DateTime picked = DateTime(2026, 3, 20);
    await tester.tap(find.bySemanticsLabel(RegExp('^March 20, 2026')));
    await tester.pumpAndSettle();
    final Finder heading = find.text(hijriText(picked));
    expect(heading, findsOneWidget);
    expect(tester.getBottomLeft(heading).dy, lessThan(844));
    expect(
      find.text(DateFormat('EEEE, d MMMM yyyy', 'en').format(picked)),
      findsOneWidget,
    );
  });

  testWidgets('the month arrows move the month', (tester) async {
    await pump(tester);
    expect(find.text('March 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('February 2026'), findsOneWidget);
  });

  testWidgets('swiping the grid changes the month, and reverses in RTL', (
    tester,
  ) async {
    await pump(tester);
    await tester.fling(find.byType(GridView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);

    await tester.fling(find.byType(GridView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('March 2026'), findsOneWidget);

    // In Arabic a swipe to the right goes forward.
    await pump(tester, locale: const Locale('ar'));
    await tester.fling(find.byType(GridView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(
      find.text(DateFormat('MMMM yyyy', 'ar').format(DateTime(2026, 4))),
      findsOneWidget,
    );
  });

  testWidgets('the Today button returns to today after navigating', (
    tester,
  ) async {
    await pump(tester);
    // Today is on screen, so there is nothing to return to yet.
    expect(find.byType(ChipButton), findsNothing);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChipButton, l10n(tester).todayLegend));
    await tester.pumpAndSettle();
    expect(find.text('March 2026'), findsOneWidget);
  });

  testWidgets('the month header names every Hijri month the grid touches', (
    tester,
  ) async {
    await pump(tester);
    // March 2026 runs from the last days of Ramadan into Shawwal 1447.
    expect(
      find.text(
        '${HijriCalendar.monthNameFor(9, 'en')} – '
        '${HijriCalendar.monthNameFor(10, 'en')} 1447',
      ),
      findsOneWidget,
    );
  });

  testWidgets('coming up lists the next key dates and jumps to one', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(l10n(tester).comingUp), findsOneWidget);
    expect(find.text(l10n(tester).occasionEidAlAdha), findsOneWidget);
    await tester.ensureVisible(find.text(l10n(tester).occasionEidAlAdha));
    await tester.tap(find.text(l10n(tester).occasionEidAlAdha));
    await tester.pumpAndSettle();
    expect(find.text('May 2026'), findsOneWidget);
    expect(
      find.text(
        DateFormat('EEEE, d MMMM yyyy', 'en').format(DateTime(2026, 5, 27)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('month label follows the locale', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    expect(find.text('March 2026'), findsNothing);
  });

  testWidgets('the layout holds at 320 pixels wide without exceptions', (
    tester,
  ) async {
    await pump(tester, width: 320, scale: 1.3, height: 2800);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('the offset control saves the sighting offset', (tester) async {
    await pump(tester);
    final Finder plusOne = find.text('+${l10n(tester).daySingular(1)}');
    await tester.ensureVisible(plusOne);
    await tester.tap(plusOne);
    await tester.pumpAndSettle();
    expect(SettingsDB().get('hijri_offset'), 1);
    expect(plusOne, findsOneWidget);
  });

  testWidgets('a day with two events names both', (tester) async {
    await pump(tester);
    // 15 Sha'ban 1447 is a blessed night and also a white day of fasting.
    DateTime date = DateTime(2026, 1, 1);
    while (HijriCalendar.fromDate(date).hMonth != 8 ||
        HijriCalendar.fromDate(date).hDay != 15) {
      date = date.add(const Duration(days: 1));
    }
    final int steps = (date.year - 2026) * 12 + date.month - 3;
    final String tooltip = steps > 0 ? 'Next month' : 'Previous month';
    for (int i = 0; i < steps.abs(); i++) {
      await tester.tap(find.byTooltip(tooltip));
      await tester.pumpAndSettle();
    }
    final AppLocalizations l = l10n(tester);
    final Finder cell = find.bySemanticsLabel(
      RegExp(
        '^${RegExp.escape(DateFormat.yMMMMd('en').format(date))}.*'
        '${RegExp.escape(l.occasionShabEBaratBlessed)}.*'
        '${RegExp.escape(l.occasionAyyamAlBid)}',
      ),
    );
    expect(cell, findsOneWidget);
  });
}
