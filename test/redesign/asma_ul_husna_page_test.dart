import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/duas/asma_ul_husna_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'gallery_test_support.dart' show loadGalleryFonts;

/// Asma ul-Husna on the redesign system. There was no design preview; the page
/// moved onto the shared page frame and the hairline card language of Duas and
/// Statistics. The real page loads its bundled JSON. Goldens show the viewport
/// (header and the first rows of names), not all 99 cards.
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
    // The 99 names and hero use AmiriQuran; without it they render as tofu.
    await (FontLoader('AmiriQuran')..addFont(
          rootBundle.load(
            'assets/media/fonts/amiri-quran/AmiriQuran-Regular.ttf',
          ),
        ))
        .load();
  });

  // The bundle caches the future of the first read, which belongs to the first
  // test's clock; drop it so each test reads the asset itself.
  setUp(() => rootBundle.evict('assets/data/dua/asma_al_husna.json'));

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
        home: const Scaffold(body: AsmaUlHusnaPage(showAppBar: false)),
      ),
    );
    await tester.pump();
    // The bundled JSON is read on the real clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(AsmaUlHusnaPage)))!;

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
    testWidgets('Asma ul-Husna golden $name', (tester) async {
      await pump(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/asma_ul_husna/page-$name.png'),
      );
    });
  }

  testWidgets('all 99 names load and search filters them', (tester) async {
    await pump(tester);
    expect(
      find.text(l10n(tester).allNamesCount(99).toUpperCase()),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'rahm');
    await tester.pumpAndSettle();
    expect(find.text('Ar Rahmaan'), findsOneWidget);
    expect(find.text('Ar Raheem'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).noNamesFound), findsOneWidget);
  });

  testWidgets('Asma ul-Husna no results golden', (tester) async {
    await pump(tester, height: 900);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/asma_ul_husna/no-results-emerald-dark.png'),
    );
  });

  for (final (String name, EquranColors colors, Locale locale)
      in <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('emerald-light', EquranColors.light, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, const Locale('ar')),
      ]) {
    testWidgets('Asma ul-Husna name sheet golden $name', (tester) async {
      await pump(tester, colors: colors, locale: locale, height: 844);
      await tester.tap(find.text('Ar Rahmaan'));
      await tester.pumpAndSettle();
      expect(find.text(l10n(tester).reciteThisNameInDua), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/asma_ul_husna/sheet-$name.png'),
      );
      await tester.tap(find.text(l10n(tester).close));
      await tester.pumpAndSettle();
      expect(find.text(l10n(tester).reciteThisNameInDua), findsNothing);
    });
  }
}
