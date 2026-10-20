import 'dart:io';

import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/manual_prayer_location_page.dart';
import 'package:equran/prayer/prayer_map_location_page.dart';
import 'package:equran/prayer/prayer_map_widgets.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The two location pickers. The manual page is pumped for real. The map page
/// is pumped for real too, with a saved location so geolocation never runs;
/// tiles cannot load in tests (they come back blank), and the pulsing user
/// marker is frozen by pumping fixed durations instead of settling. The map
/// chrome is also tested on its own as `PrayerMapInfoCard`. There is no design
/// preview; both follow the reader sheet chrome and the Settings fields.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // flutter_map's tile cache asks path_provider for a folder.
    final Directory cache = Directory.systemTemp.createTempSync('map_cache');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall call) async => cache.path,
        );
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    required EquranColors colors,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 844,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(390 * 2, height * 2);
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
        home: Scaffold(body: home),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // The map's user marker pulses forever; step a fixed time instead.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }
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

  const PrayerLocation saved = PrayerLocation(
    latitude: 23.588,
    longitude: 58.3829,
    label: 'Sample City',
    mode: PrayerLocationMode.manual,
  );

  for (final (String name, EquranColors colors, double scale, Locale locale)
      in variants) {
    testWidgets('Manual location golden $name', (tester) async {
      await pumpApp(
        tester,
        const ManualPrayerLocationPage(initialLocation: saved),
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1200 : 900,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_location/manual-$name.png'),
      );
    });

    testWidgets('Map picker golden $name', (tester) async {
      await pumpApp(
        tester,
        const PrayerMapLocationPage(initialLocation: saved),
        colors: colors,
        scale: scale,
        locale: locale,
        settle: false,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_location/map-$name.png'),
      );
    });

    testWidgets('Map info card golden $name', (tester) async {
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(14),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PrayerMapInfoCard(
              locationLabel: 'Selected location',
              coordinates: '23.58800, 58.38290',
              qiblaLine: 'Qibla: 268.4° • 1,330 km to the Kaaba',
              picker: PrayerMapPickerActions(
                usePinLabel: 'Use this spot',
                onUsePin: () {},
              ),
            ),
          ),
        ),
        colors: colors,
        scale: scale,
        locale: locale,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_location/card-$name.png'),
      );
    });
  }

  testWidgets('the Qibla map has no picker buttons', (tester) async {
    await pumpApp(
      tester,
      const PrayerMapLocationPage(initialLocation: saved, isPicker: false),
      colors: EquranColors.dark,
      settle: false,
    );
    final AppLocalizations l = AppLocalizations.of(
      tester.element(find.byType(PrayerMapLocationPage)),
    )!;
    expect(find.text(l.usePinLocation), findsNothing);
    expect(find.byType(PrayerMapInfoCard), findsOneWidget);
  });

  testWidgets('the picker keeps its first-use rule: no pin, no save', (
    tester,
  ) async {
    await pumpApp(
      tester,
      PrayerMapInfoCard(
        locationLabel: 'x',
        coordinates: '—',
        picker: PrayerMapPickerActions(usePinLabel: 'Use pin', onUsePin: null),
      ),
      colors: EquranColors.dark,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('manual page validates coordinates and returns the location', (
    tester,
  ) async {
    PrayerLocation? result;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await Navigator.of(context).push(
            MaterialPageRoute<PrayerLocation>(
              builder: (_) => const ManualPrayerLocationPage(),
            ),
          ),
          child: const Text('open'),
        ),
      ),
      colors: EquranColors.dark,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final AppLocalizations l = AppLocalizations.of(
      tester.element(find.byType(ManualPrayerLocationPage)),
    )!;
    await tester.tap(find.text(l.saveLocation));
    await tester.pumpAndSettle();
    expect(result, isNull);
    final Finder fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '95');
    await tester.enterText(fields.at(2), '10');
    await tester.tap(find.text(l.saveLocation));
    await tester.pumpAndSettle();
    expect(find.byType(ManualPrayerLocationPage), findsOneWidget);
    await tester.enterText(fields.at(1), '25.2');
    await tester.tap(find.text(l.saveLocation));
    await tester.pumpAndSettle();
    expect(result?.latitude, 25.2);
    expect(result?.mode, PrayerLocationMode.manual);
  });
}
