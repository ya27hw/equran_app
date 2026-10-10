import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/zakat/metal_price_service.dart';
import 'package:equran/zakat/zakat_db.dart';
import 'package:equran/zakat/zakat_page.dart';
import 'package:equran/zakat/zakat_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Zakat calculator on the redesign system. There is no design preview;
/// the look follows the finished Downloads, Statistics and Duas pages. The page
/// is pumped for real. The live price request fails in the test binding (HTTP
/// is blocked), so the page falls back to a seeded cached snapshot, which keeps
/// every figure deterministic. The golden numbers are the page's own
/// calculations, asserted below so a restyle cannot change them.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
    // An already-open box is returned by `initialize`, so this one is in memory.
    await Hive.openBox<dynamic>('zakah_history_box_v1', bytes: Uint8List(0));
    await ZakatHistoryDB.instance.initialize();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  tearDownAll(Hive.close);

  setUp(() async {
    await ZakatHistoryDB.instance.exportBox().clear();
    await SettingsDB().put('zakat_currency', 'USD');
    // Local wall time, so the status line reads the same in every time zone.
    await SettingsDB().put(
      'zakat_metal_rates',
      MetalRateSnapshot(
        goldPricePerGram: 75.80,
        silverPricePerGram: 0.95,
        source: 'Metals.Live',
        fetchedAt: DateTime(2026, 10, 1, 9, 30),
        currency: 'USD',
      ).toMap(),
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 3000,
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
        home: const Scaffold(body: ZakatCalculatorPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ZakatCalculatorPage)))!;

  /// Cash, gold grams and liabilities, plus two sheep: an eligible case.
  Future<void> fill(WidgetTester tester) async {
    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '12000'); // cash
    await tester.enterText(fields.at(1), '40'); // gold grams
    await tester.enterText(fields.at(7), '500'); // liabilities
    await tester.pumpAndSettle();
    final Finder plus = find.byTooltip(
      l10n(tester).increaseLabel(l10n(tester).livestockSheepGoats),
    );
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pump();
    await tester.tap(plus);
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
    testWidgets('Zakat calculator golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 3900 : 3000,
      );
      await fill(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/zakat/calculator-$name.png'),
      );
    });
  }

  testWidgets('figures are the calculator\'s own, unchanged', (tester) async {
    await pump(tester);
    // Nisab values come from the cached rates: 612.36 g silver and 87.48 g gold.
    expect(find.text('\$581.74'), findsOneWidget);
    expect(find.text('\$6630.98'), findsOneWidget);
    expect(find.text('\$75.80/g'), findsOneWidget);
    expect(find.text('\$0.95/g'), findsOneWidget);
    await fill(tester);
    // 12000 cash + 40 g gold + 2 sheep, less 500 liabilities.
    expect(find.text('\$14892.00'), findsOneWidget);
    expect(find.text('\$372.30'), findsOneWidget);
    expect(find.text(l10n(tester).eligible), findsOneWidget);
    // Cash, gold and livestock show as breakdown rows.
    expect(find.text('\$12000.00'), findsWidgets);
    expect(find.text('\$3032.00'), findsWidgets);
    expect(find.text('\$360.00'), findsWidgets);
  });

  testWidgets('below the nisab shows the explanation and no heart', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '100');
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).belowNisab), findsOneWidget);
    expect(find.textContaining('\$581.74'), findsWidgets);
    expect(find.text('\$0.00'), findsWidgets);
  });

  testWidgets('category names follow the locale', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    final AppLocalizations l = l10n(tester);
    expect(find.text(l.zakatCategoryCash), findsOneWidget);
    expect(find.text(l.zakatCategoryBusiness), findsOneWidget);
    expect(find.text('Cash & Receivables'), findsNothing);
  });

  testWidgets('the nisab choice switches to gold', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '1000');
    await tester.pumpAndSettle();
    // 1000 is above the silver nisab (581.74) and below the gold one (6631.18).
    expect(find.text(l10n(tester).eligible), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(ZakatNisabChoice),
        matching: find.text(l10n(tester).gold),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).belowNisab), findsOneWidget);
  });

  testWidgets('saving a calculation opens History with the record', (
    tester,
  ) async {
    await pump(tester);
    await fill(tester);
    final Finder save = find.text(l10n(tester).saveToHistory);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(ZakatHistoryDB.instance.getAllRecords(), hasLength(1));
    expect(ZakatHistoryDB.instance.getAllRecords().single.zakatDue, 372.30);
    expect(find.text(l10n(tester).zakatPaidDistributed), findsOneWidget);
  });

  Future<void> seedHistory() async {
    final DateTime base = DateTime(2026, 9, 14);
    for (int i = 0; i < 2; i++) {
      await ZakatHistoryDB.instance.saveRecord(
        ZakatRecord(
          id: 'r$i',
          date: base.add(Duration(days: i * 20)),
          cash: 12000.0 + i * 1500,
          investments: 800,
          goldGrams: 40,
          goldPrice: 75.80,
          silverGrams: 100.5,
          silverPrice: 0.95,
          liabilities: 500,
          nisabType: 'silver',
          nisabValue: 581.74,
          zakatDue: 372.30 + i * 37.5,
          zakatPaid: i == 0 ? 0 : 200,
        ),
      );
    }
  }

  final List<(String, EquranColors, double, Locale)> historyVariants =
      <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
        ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
        ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ];
  for (final (String name, EquranColors colors, double scale, Locale locale)
      in historyVariants) {
    testWidgets('Zakat history golden $name', (tester) async {
      await seedHistory();
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: 1300,
      );
      await tester.tap(find.text(l10n(tester).historyTab));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/zakat/history-$name.png'),
      );
    });
  }

  testWidgets('Zakat history empty golden', (tester) async {
    await pump(tester, height: 700);
    await tester.tap(find.text(l10n(tester).historyTab));
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).noHistoricalCalculations), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/zakat/history-empty.png'),
    );
  });

  testWidgets('history rows delete and update the paid amount', (tester) async {
    await seedHistory();
    await pump(tester, height: 1300);
    await tester.tap(find.text(l10n(tester).historyTab));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n(tester).edit).first);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '150');
    await tester.tap(find.widgetWithText(FilledButton, l10n(tester).save));
    await tester.pumpAndSettle();
    final ZakatRecord newest = ZakatHistoryDB.instance.getAllRecords().first;
    expect(newest.zakatPaid, 150);
    // Deleting asks first; Cancel keeps the record, Delete removes it.
    await tester.tap(find.byTooltip(l10n(tester).delete).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).zakatDeleteRecordQuestion), findsOneWidget);
    expect(ZakatHistoryDB.instance.getAllRecords(), hasLength(2));
    await tester.tap(find.widgetWithText(TextButton, l10n(tester).cancel));
    await tester.pumpAndSettle();
    expect(ZakatHistoryDB.instance.getAllRecords(), hasLength(2));
    await tester.tap(find.byTooltip(l10n(tester).delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l10n(tester).delete));
    await tester.pumpAndSettle();
    expect(ZakatHistoryDB.instance.getAllRecords(), hasLength(1));
  });

  testWidgets('the paid-amount hint follows the currency, not USD', (
    tester,
  ) async {
    await SettingsDB().put('zakat_currency', 'EUR');
    await seedHistory();
    await pump(tester, height: 1300);
    await tester.tap(find.text(l10n(tester).historyTab));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n(tester).edit).first);
    await tester.pumpAndSettle();
    expect(find.text('Enter paid amount in EUR'), findsOneWidget);
    expect(find.textContaining('USD'), findsNothing);
  });

  testWidgets('without metal rates the nisab message shows no number', (
    tester,
  ) async {
    // Cached rates in another currency cannot be used, and the live request
    // is blocked in the test binding: no nisab figure exists.
    await SettingsDB().put(
      'zakat_metal_rates',
      MetalRateSnapshot(
        goldPricePerGram: 70,
        silverPricePerGram: 0.9,
        source: 'Metals.Live',
        fetchedAt: DateTime(2026, 10, 1, 9, 30),
        currency: 'EUR',
      ).toMap(),
    );
    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '100');
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).zakatNisabNeedsRates), findsOneWidget);
    expect(find.textContaining('Infinity'), findsNothing);
    expect(find.textContaining('∞'), findsNothing);
  });

  testWidgets('the tola unit label is localized', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('تولة'), findsWidgets);
    expect(find.text('tola'), findsNothing);
  });

  final List<(String, EquranColors, Locale)> dialogVariants =
      <(String, EquranColors, Locale)>[
        ('emerald-dark', EquranColors.dark, const Locale('en')),
        ('emerald-light', EquranColors.light, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, const Locale('ar')),
      ];
  for (final (String name, EquranColors colors, Locale locale)
      in dialogVariants) {
    testWidgets('Zakat price override dialog golden $name', (tester) async {
      await pump(tester, colors: colors, locale: locale, height: 844);
      final Finder button = find.text(l10n(tester).overridePrices);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/zakat/override-$name.png'),
      );
    });

    testWidgets('Zakat currency picker golden $name', (tester) async {
      await pump(tester, colors: colors, locale: locale, height: 844);
      await tester.tap(find.text(l10n(tester).currency));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/zakat/currency-$name.png'),
      );
    });
  }

  testWidgets('overriding the prices changes the nisab values', (tester) async {
    await pump(tester);
    final Finder button = find.text(l10n(tester).overridePrices);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final Finder fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '1');
    await tester.tap(find.widgetWithText(FilledButton, l10n(tester).save));
    await tester.pumpAndSettle();
    // 612.36 g x 1 and 87.48 g x 100.
    expect(find.text('\$612.36'), findsOneWidget);
    expect(find.text('\$8748.00'), findsOneWidget);
    expect(find.text(l10n(tester).reset), findsOneWidget);
  });
}
