import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/backend/settings_db.dart';
import 'package:equran/home/hijri_calendar_page.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Hijri calendar page (opened from the Home date line) on the redesign
/// system. There is no design preview; the look follows the Islamic calendar
/// and the finished Prayer and Statistics pages. A fixed clock (the page's
/// optional `now`) keeps today the same on every run. Dates come from the one
/// shared `HijriCalendar` in `lib/prayer/hijri_calendar.dart`: 7 Oct 2026 is
/// 24 Rabi' al-Thani 1448 and that Hijri month runs 14 Sep to 12 Oct 2026.
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
  });
  tearDownAll(Hive.close);

  final DateTime fixedNow = DateTime(2026, 10, 7, 10);

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 900,
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
        home: Scaffold(body: HijriCalendarPage(now: () => fixedNow)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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
    testWidgets('Hijri calendar golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1050 : 900,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hijri_calendar/month-$name.png'),
      );
    });
  }

  testWidgets('shows the correct Hijri date, month and Gregorian range', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text("24 Rabi' al-Thani 1448"), findsOneWidget);
    expect(find.text("Rabi' al-Thani 1448"), findsOneWidget);
    expect(find.text('Sep 14, 2026 - Oct 12, 2026'), findsOneWidget);
    // 29 day cells, 1 to 29, and the Gregorian day under each.
    expect(find.text('29'), findsNWidgets(2)); // Hijri 29 and Gregorian 29
    expect(find.text('30'), findsOneWidget); // Gregorian 30 Sep only
  });

  testWidgets('arrows cross month and year boundaries', (tester) async {
    await pump(tester);
    // Walk forward to Dhu al-Hijjah 1448 then into 1449 and back.
    for (int i = 0; i < 8; i++) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Dhu al-Hijjah 1448'), findsOneWidget);
    expect(find.text('May 8, 2027 - Jun 5, 2027'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('Muharram 1449'), findsOneWidget);
    expect(find.text('Jun 6, 2027 - Jul 5, 2027'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('Dhu al-Hijjah 1448'), findsOneWidget);
  });

  testWidgets('the saved sighting offset moves the dates', (tester) async {
    await SettingsDB().put('hijri_offset', 1);
    await pump(tester);
    expect(find.text("25 Rabi' al-Thani 1448"), findsOneWidget);
    expect(find.text('Sep 13, 2026 - Oct 11, 2026'), findsOneWidget);
  });

  testWidgets('arrows change the month and the Today button returns', (
    tester,
  ) async {
    await pump(tester);
    final HijriCalendar today = HijriCalendar.fromDate(fixedNow);
    final String start = '${today.monthName} ${today.hYear}';
    expect(find.text(start), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text(start), findsNothing);
    await tester.tap(find.byTooltip('Today'));
    await tester.pumpAndSettle();
    expect(find.text(start), findsOneWidget);
  });
}
