import 'dart:async';

import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/qibla_compass.dart';
import 'package:equran/prayer/qibla_page.dart';
import 'package:equran/prayer/qibla_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

const PrayerLocation _london = PrayerLocation(
  latitude: 51.5074,
  longitude: -0.1278,
  label: 'London',
  mode: PrayerLocationMode.currentDevice,
);

void main() {
  final double bearing = const QiblaService().calculateBearing(_london)!;

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

  group('AngleSmoother', () {
    test('turns the short way round across north', () {
      final AngleSmoother smoother = AngleSmoother(350)..aimAt(10);
      expect(smoother.target, 370);
      double last = smoother.value;
      for (int i = 0; i < 120; i++) {
        smoother.step(1 / 60);
        expect(smoother.value, greaterThanOrEqualTo(last - 1e-9));
        expect(smoother.value, lessThanOrEqualTo(370.0001));
        last = smoother.value;
      }
      expect(smoother.value, closeTo(370, 0.05));
      expect(smoother.isSettled, isTrue);
    });

    test('turns left when that is shorter', () {
      final AngleSmoother smoother = AngleSmoother(10)..aimAt(350);
      expect(smoother.target, -10);
    });

    test('a long run of small updates never unwinds a full turn', () {
      final AngleSmoother smoother = AngleSmoother(0);
      for (int heading = 0; heading <= 720; heading += 7) {
        smoother.aimAt(heading.toDouble() % 360);
        smoother.step(1 / 60);
      }
      expect(smoother.target, closeTo(720 - 720 % 7, 7));
    });

    test('jumpTo skips the animation', () {
      final AngleSmoother smoother = AngleSmoother(0)..jumpTo(123);
      expect(smoother.value, 123);
      expect(smoother.isSettled, isTrue);
    });
  });

  Future<StreamController<CompassEvent>> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    bool reduceMotion = true,
    double? heading,
    bool withSensor = true,
  }) async {
    final StreamController<CompassEvent> controller =
        StreamController<CompassEvent>.broadcast();
    addTearDown(controller.close);
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
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
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: QiblaPage(
          initialLocation: _london,
          compassEvents: withSensor ? controller.stream : const Stream.empty(),
        ),
      ),
    );
    await tester.pump();
    if (heading != null) {
      controller.add(CompassEvent.fromList(<double>[heading, 0, 15]));
      await tester.pump();
    }
    if (reduceMotion) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(seconds: 2));
    }
    expect(tester.takeException(), isNull);
    return controller;
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(QiblaPage)))!;

  testWidgets('says to turn when the phone is off the Qibla', (tester) async {
    await pump(tester, heading: bearing + 80);
    final AppLocalizations l = l10n(tester);
    expect(find.text(l.turnLeftDegrees(80)), findsOneWidget);
    expect(find.text(l.facingQibla), findsNothing);
  });

  testWidgets('says facing Qibla within five degrees and not at six', (
    tester,
  ) async {
    final StreamController<CompassEvent> sensor = await pump(
      tester,
      heading: bearing + 3,
    );
    final AppLocalizations l = l10n(tester);
    expect(find.text(l.facingQibla), findsOneWidget);
    sensor.add(CompassEvent.fromList(<double>[bearing + 6, 0, 15]));
    await tester.pumpAndSettle();
    expect(find.text(l.facingQibla), findsNothing);
    expect(find.text(l.turnLeftDegrees(6)), findsOneWidget);
  });

  testWidgets('sensor events do not rebuild the page', (tester) async {
    final StreamController<CompassEvent> sensor = await pump(
      tester,
      heading: 10,
    );
    final Element page = tester.element(find.byType(QiblaPage));
    final Element content = tester.element(
      find.byWidgetPredicate(
        (Widget w) => w.runtimeType.toString() == '_QiblaContent',
      ),
    );
    int rebuilds = 0;
    // A rebuild of the content marks it dirty; sample after each event.
    for (final double heading in <double>[40, 80, 120, 160]) {
      sensor.add(CompassEvent.fromList(<double>[heading, 0, 15]));
      await tester.pump();
      if (content.dirty || page.dirty) rebuilds++;
      await tester.pumpAndSettle();
    }
    expect(rebuilds, 0);
  });

  testWidgets('without a sensor it shows the bearing and no heading', (
    tester,
  ) async {
    await pump(tester, withSensor: false);
    final AppLocalizations l = l10n(tester);
    expect(
      find.text(l.bearingDegrees(bearing.round().toString())),
      findsOneWidget,
    );
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('the compass keeps animating smoothly through north', (
    tester,
  ) async {
    final StreamController<CompassEvent> sensor = await pump(
      tester,
      reduceMotion: false,
      heading: 350,
    );
    sensor.add(CompassEvent.fromList(<double>[10, 0, 15]));
    await tester.pump(const Duration(milliseconds: 50));
    final Iterable<Transform> dialTurns = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(QiblaCompass),
        matching: find.byType(Transform),
      ),
    );
    expect(dialTurns, isNotEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

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
    testWidgets('Qibla golden $name turned', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        heading: bearing + 62,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/qibla/$name-turned.png'),
      );
    });
  }

  for (final (String name, EquranColors colors) in <(String, EquranColors)>[
    ('emerald-dark', EquranColors.dark),
    ('emerald-light', EquranColors.light),
  ]) {
    testWidgets('Qibla golden $name aligned', (tester) async {
      await pump(tester, colors: colors, heading: bearing + 1);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/qibla/$name-aligned.png'),
      );
    });
  }

  testWidgets('Qibla golden without a sensor', (tester) async {
    await pump(tester, withSensor: false);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/qibla/emerald-dark-no-sensor.png'),
    );
  });
}
