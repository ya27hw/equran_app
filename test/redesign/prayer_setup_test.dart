import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_arc_hero.dart';
import 'package:equran/prayer/prayer_map_location_page.dart'
    show PrayerLocationPicker;
import 'package:equran/prayer/prayer_location_service.dart';
import 'package:equran/prayer/prayer_location_setup_page.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_page.dart';
import 'package:equran/services/device_capability_profile.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// Keeps the flow off the network and the platform geocoder: the place keeps
/// the label it was given.
class _FakeLocationService extends PrayerLocationService {
  const _FakeLocationService();

  @override
  Future<PrayerLocation> resolveLocationForSave(
    PrayerLocation location, {
    PrayerLocation? previousLocation,
    bool preserveCustomLabel = false,
  }) async => location;
}

/// The Prayer page before a location is saved: the page frame, the setup sky
/// hero, the explanation card and the single action (the map picker).
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
    DeviceCapabilityService.instance.value = const DeviceCapabilityProfile(
      lowRam: true,
      processorCount: 4,
    );
  });
  setUp(() async {
    // No saved location: the key is `prayerLocation`.
    await SettingsDB().clear();
  });
  tearDownAll(Hive.close);

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    PrayerLocationPicker? picker,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
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
          backgroundColor: colors.background,
          body: PrayerTimesPage(
            enableLiveCountdown: false,
            initialNow: DateTime.utc(2026, 10, 4, 9, 12),
            mapLocationPicker: picker ?? (context, initial) async => null,
            locationService: const _FakeLocationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('first visit shows the setup without opening anything', (
    tester,
  ) async {
    var opened = 0;
    await pump(
      tester,
      picker: (context, initial) async {
        opened++;
        return null;
      },
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(PrayerTimesPage)),
    )!;
    expect(opened, 0, reason: 'no picker is pushed on first frame');
    expect(find.byType(PrayerArcSetupHero), findsOneWidget);
    expect(find.text(l.prayerTimesNeedLocation), findsOneWidget);
    expect(find.text(l.timesCalculatedLocally), findsOneWidget);
    expect(find.byType(PrayerLocationSetupPage), findsNothing);
  });

  testWidgets('the hero and the button both start the guided setup', (
    tester,
  ) async {
    await pump(tester);
    final l = AppLocalizations.of(
      tester.element(find.byType(PrayerTimesPage)),
    )!;
    await tester.tap(find.byKey(const Key('prayer-arc-setup-hero')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerLocationSetupPage), findsOneWidget);
    expect(find.text(l.locationSetupTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('location-setup-current')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('location-setup-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('location-setup-manual')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('prayer-setup-location')));
    await tester.tap(find.byKey(const Key('prayer-setup-location')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerLocationSetupPage), findsOneWidget);
  });

  testWidgets('map pick goes to a confirm step and saves the place', (
    tester,
  ) async {
    final store = PrayerSettingsStore();
    await pump(
      tester,
      picker: (context, initial) async {
        expect(initial, isNull, reason: 'first setup has no saved place');
        return const PrayerLocation(
          latitude: 23.588,
          longitude: 58.3829,
          label: 'Sample City',
          mode: PrayerLocationMode.manual,
        );
      },
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(PrayerTimesPage)),
    )!;
    await tester.tap(find.byKey(const Key('prayer-setup-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('location-setup-map')));
    await tester.pumpAndSettle();
    // The confirm step shows the place and one clear way to save it.
    expect(find.text(l.confirmLocationTitle), findsOneWidget);
    expect(find.text('Sample City'), findsOneWidget);
    expect(find.text('23.5880, 58.3829'), findsOneWidget);
    expect(find.byKey(const ValueKey('location-setup-save')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('location-setup-save')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerLocationSetupPage), findsNothing);
    expect(store.getLocation()?.label, 'Sample City');
  });

  testWidgets('back from confirm returns to the choices, not out of setup', (
    tester,
  ) async {
    await pump(
      tester,
      picker: (context, initial) async => const PrayerLocation(
        latitude: 23.588,
        longitude: 58.3829,
        label: 'Sample City',
        mode: PrayerLocationMode.manual,
      ),
    );
    await tester.tap(find.byKey(const Key('prayer-setup-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('location-setup-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('location-setup-change')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('location-setup-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('location-setup-save')), findsNothing);
  });

  testWidgets('Prayer location setup: choices and confirm golden', (
    tester,
  ) async {
    await pump(
      tester,
      picker: (context, initial) async => const PrayerLocation(
        latitude: 23.588,
        longitude: 58.3829,
        label: 'Sample City',
        mode: PrayerLocationMode.manual,
      ),
    );
    await tester.tap(find.byKey(const Key('prayer-setup-location')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/prayer_setup/location-choices.png'),
    );
    await tester.tap(find.byKey(const ValueKey('location-setup-map')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/prayer_setup/location-confirm.png'),
    );
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
    testWidgets('Prayer setup golden $name', (tester) async {
      await pump(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_setup/$name.png'),
      );
    });
  }
}
