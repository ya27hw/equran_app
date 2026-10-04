import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home/more_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });

  Future<List<String>> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    List<String>? taps,
  }) async {
    final log = taps ?? <String>[];
    VoidCallback tap(String name) =>
        () => log.add(name);
    await tester.binding.setSurfaceSize(const Size(390, 1900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: MorePage(
            onOpenQibla: tap('qibla'),
            onOpenDownloads: tap('downloads'),
            onOpenSearch: tap('search'),
            onOpenReadingPlans: tap('plans'),
            onOpenTasbih: tap('tasbih'),
            onOpenAsmaUlHusna: tap('asma'),
            onOpenSettings: tap('settings'),
            onOpenStats: tap('stats'),
            onOpenZakat: tap('zakat'),
            onOpenCalendar: tap('calendar'),
            onToggleTheme: tap('theme'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return log;
  }

  testWidgets('every shortcut stays reachable and fires its callback', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, taps: taps);
    final l = AppLocalizations.of(tester.element(find.byType(MorePage)))!;
    final rows = <String, String>{
      l.qibla: 'qibla',
      l.tasbih: 'tasbih',
      l.asmaUlHusna: 'asma',
      l.readingRoutine: 'plans',
      l.quranSearch: 'search',
      l.statistics: 'stats',
      l.downloads: 'downloads',
      l.zakatCalculator: 'zakat',
      l.islamicCalendar: 'calendar',
      l.settings: 'settings',
      l.theme: 'theme',
    };
    for (final entry in rows.entries) {
      await tester.ensureVisible(find.text(entry.key).first);
      await tester.tap(find.text(entry.key).first);
      expect(taps.last, entry.value, reason: entry.key);
    }
    // Hifz, About, Share and Feedback navigate or open dialogs; they must exist.
    for (final label in [
      l.hifz,
      l.aboutThisApp,
      l.shareApp,
      l.feedbackContact,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final group in [
      l.moreGroupWorship,
      l.moreGroupReadLearn,
      l.moreGroupTools,
      l.moreGroupApp,
      l.moreGroupAbout,
    ]) {
      expect(find.text(group.toUpperCase()), findsOneWidget, reason: group);
    }
  });

  final variants = [
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
  ];
  for (final (name, colors, scale, locale) in variants) {
    testWidgets('More golden $name', (tester) async {
      await pump(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/more/$name.png'),
      );
    });
  }
}
