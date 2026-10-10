import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_arc_hero.dart';
import 'package:equran/prayer/prayer_map_location_page.dart'
    show PrayerLocationPicker;
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('the hero and the button both open the map picker', (
    tester,
  ) async {
    var opened = 0;
    await pump(
      tester,
      picker: (context, initial) async {
        opened++;
        expect(initial, isNull);
        return null;
      },
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(PrayerTimesPage)),
    )!;
    expect(opened, 1, reason: 'the page offers the picker on first frame');
    expect(find.byType(PrayerArcSetupHero), findsOneWidget);
    expect(find.text(l.prayerTimesNeedLocation), findsOneWidget);
    expect(find.text(l.prayerTimesLocationSubtitle), findsOneWidget);
    expect(find.text(l.locationUseNotice), findsOneWidget);
    expect(find.text(l.timesCalculatedLocally), findsOneWidget);
    await tester.tap(find.byKey(const Key('prayer-arc-setup-hero')));
    await tester.pumpAndSettle();
    expect(opened, 2);
    await tester.ensureVisible(find.byKey(const Key('prayer-setup-location')));
    await tester.tap(find.byKey(const Key('prayer-setup-location')));
    await tester.pumpAndSettle();
    expect(opened, 3);
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
