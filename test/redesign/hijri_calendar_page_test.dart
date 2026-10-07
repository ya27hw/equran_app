import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home/hijri_calendar_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Hijri calendar page (opened from the Home date line) on the redesign
/// system. There is no design preview; the look follows the Islamic calendar
/// and the finished Prayer and Statistics pages. A fixed clock (the page's
/// optional `now`) keeps today the same on every run. The conversion class in
/// the page file is untouched.
///
/// KNOWN BUG, NOT FIXED HERE (computation is out of scope): that conversion
/// (`HijriCalendar.fromGregorian` in `hijri_calendar_page.dart`) is wrong. For
/// 7 Oct 2026 it returns day 8160 of Dhu al-Hijjah 1470 and a Gregorian range
/// in the year 54097, so the goldens show those wrong figures. The correct
/// algorithm is `lib/prayer/hijri_calendar.dart`. Regenerate these goldens
/// after the owner fixes the page's conversion.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });

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

  testWidgets('arrows change the month and the Today button returns', (
    tester,
  ) async {
    await pump(tester);
    final HijriCalendar today = HijriCalendar.fromGregorian(fixedNow);
    final String start = '${today.getMonthName('en')} ${today.year}';
    expect(find.text(start), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text(start), findsNothing);
    await tester.tap(find.byTooltip('Today'));
    await tester.pumpAndSettle();
    expect(find.text(start), findsOneWidget);
  });
}
