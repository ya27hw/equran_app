import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/prayer/islamic_calendar_page.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Islamic calendar on the redesign system. There is no design preview;
/// the look follows the finished Prayer, Statistics and Duas pages. The real
/// page is pumped with a fixed clock (its optional `now`), set in March 2026
/// so the month holds Ramadan, Laylat al-Qadr nights and Eid al-Fitr. Hijri
/// dates come from the unchanged `HijriCalendar`.
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
    double height = 1300,
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
        home: Scaffold(body: IslamicCalendarPage(now: () => fixedNow)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(IslamicCalendarPage)))!;

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
        height: scale > 1 ? 1750 : 1300,
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

  testWidgets('month arrows move the month and quick jumps select a day', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Mar 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('Apr 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('Feb 2026'), findsOneWidget);
    // Quick jumps search forward from today: 1 Ramadan 1448 is in Feb 2027.
    await tester.tap(find.text(l10n(tester).occasionRamadanBegins));
    await tester.pumpAndSettle();
    expect(find.text('Feb 2027'), findsOneWidget);
  });

  testWidgets('month label follows the locale', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    expect(find.text('Mar 2026'), findsNothing);
  });

  for (final (String name, EquranColors colors, Locale locale)
      in <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('emerald-light', EquranColors.light, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, const Locale('ar')),
      ]) {
    testWidgets('Islamic calendar settings sheet golden $name', (tester) async {
      await pump(tester, colors: colors, locale: locale, height: 844);
      await tester.tap(find.text(l10n(tester).moonSighting));
      await tester.pumpAndSettle();
      expect(find.text(l10n(tester).calendarSettings), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/islamic_calendar/settings-$name.png'),
      );
    });
  }

  testWidgets('the offset control saves the sighting offset', (tester) async {
    await pump(tester);
    await tester.tap(find.text(l10n(tester).moonSighting));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+${l10n(tester).daySingular(1)}'));
    await tester.pumpAndSettle();
    expect(SettingsDB().get('hijri_offset'), 1);
    expect(find.text('+${l10n(tester).daySingular(1)}'), findsOneWidget);
  });
}
