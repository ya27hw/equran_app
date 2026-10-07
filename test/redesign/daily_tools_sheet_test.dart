import 'package:equran/backend/daily_tools_config.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home_dashboard/daily_tools_edit_sheet.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Daily tools edit sheet on the reader-sheet chrome. There is no design
/// preview; the look follows the finished sheets and the Home tool icons.
/// Reordering and the pinned list still go through `onReorderItem` and
/// `SettingsDB().setVisibleDailyTools`.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final settings = SettingsDB();
    await Hive.openBox(settings.boxName, bytes: Uint8List(0));
    await settings.initBox();
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
  setUp(() => SettingsDB().delete('daily_tools_visible'));

  Future<void> openSheet(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => DailyToolsEditSheet.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('switches pin and unpin tools and keep at least one', (
    tester,
  ) async {
    await SettingsDB().setVisibleDailyTools([DailyToolType.quran]);
    await openSheet(tester);
    // The only pinned tool cannot be switched off.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(SettingsDB().getVisibleDailyTools(), [DailyToolType.quran]);
    expect(find.byType(SnackBar), findsOneWidget);
    // A hidden tool can be pinned.
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(SettingsDB().getVisibleDailyTools().length, 2);
  });

  testWidgets('dragging a row by its handle reorders the pinned tools', (
    tester,
  ) async {
    await SettingsDB().setVisibleDailyTools([
      DailyToolType.quran,
      DailyToolType.prayer,
      DailyToolType.qibla,
    ]);
    await openSheet(tester);
    final handle = find.byIcon(Icons.drag_handle_rounded).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final order = SettingsDB().getVisibleDailyTools();
    expect(order.first, DailyToolType.prayer);
    expect(order.contains(DailyToolType.quran), isTrue);
  });

  final variants = <(String, EquranColors, double, Locale)>[
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
  ];
  for (final (name, colors, scale, locale) in variants) {
    testWidgets('daily tools sheet golden $name', (tester) async {
      await openSheet(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/daily_tools/$name.png'),
      );
    });
  }
}
