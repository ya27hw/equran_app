import 'dart:io';
import 'dart:ui' as ui;

import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_arc_hero.dart';
import 'package:equran/prayer/prayer_sky_painter.dart';
import 'package:equran/prayer/prayer_sky_scene.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'prayer_sky_scene_test.dart' show skyTestDay;

void main() {
  final PrayerDay day = skyTestDay(4), following = skyTestDay(5);
  final DateTime noon = day.entryFor(PrayerTimeKind.dhuhr).time;
  const Key boundaryKey = ValueKey<String>('sky-shot');
  Widget card({
    DateTime? now,
    double width = 350,
    double scale = 1,
    Locale locale = const Locale('en'),
    bool reduceMotion = false,
    bool today = true,
    VoidCallback? onTap,
    String? title,
    String? subtitle,
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(brightness: brightness),
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduceMotion,
        textScaler: TextScaler.linear(scale),
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: RepaintBoundary(
              key: boundaryKey,
              child: PrayerArcHero(
                day: day,
                followingDay: following,
                now: now ?? noon,
                currentPrayer: day.entryFor(PrayerTimeKind.dhuhr),
                nextPrayer: NextPrayer(
                  entry: day.entryFor(PrayerTimeKind.asr),
                  countdown: const Duration(hours: 3, minutes: 15),
                ),
                onTap: onTap ?? () {},
                titleOverride: title,
                subtitleOverride: subtitle,
                isViewingToday: today,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  PrayerSkyPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<PrayerSkyPainter>()
      .single;

  setUpAll(() async {
    final FontLoader loader = FontLoader(
      'Newsreader',
    )..addFont(rootBundle.load('assets/media/fonts/newsreader/Newsreader.ttf'));
    await loader.load();
    final String? bodyFont = Platform.environment['PRAYER_SKY_BODY_FONT'];
    if (bodyFont != null) {
      await (FontLoader('Roboto')..addFont(
            Future<ByteData>.value(
              ByteData.sublistView(File(bodyFont).readAsBytesSync()),
            ),
          ))
          .load();
    }
  });

  testWidgets(
    'compact card has no clock or endpoint icons, and opens settings',
    (tester) async {
      int tapped = 0;
      await tester.pumpWidget(card(onTap: () => tapped++));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PrayerArcHero)), const Size(350, 176));
      expect(find.text('Dhuhr'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(find.textContaining('PM'), findsNothing);
      await tester.tap(find.text('Dhuhr'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    },
  );

  testWidgets(
    'minute updates animate once then stop; reduce motion jumps immediately',
    (tester) async {
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      final PrayerSkyScene initial = painter(tester).scene;
      final DateTime later = noon.add(const Duration(minutes: 1));
      await tester.pumpWidget(card(now: later));
      expect(painter(tester).scene, initial);
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        painter(tester).scene.sunProgress,
        greaterThan(initial.sunProgress),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(card(now: noon, reduceMotion: true));
      expect(painter(tester).scene.sunProgress, 0.5);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'Arabic, large text, wide layout and prohibited-time overrides fit',
    (tester) async {
      for (final (double width, double scale, Locale locale)
          in <(double, double, Locale)>[
            (280, 1, const Locale('ar')),
            (280, 2.5, const Locale('en')),
            (1040, 1, const Locale('en')),
          ]) {
        await tester.pumpWidget(
          card(
            width: width,
            scale: scale,
            locale: locale,
            title: locale.languageCode == 'ar' ? 'وقت الزوال' : 'Zawal',
            subtitle: locale.languageCode == 'ar'
                ? 'ينتهي الوقت المنهي عنه خلال ٥ دقائق'
                : 'Prohibited time ends in 5 min',
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          painter(tester).textDirection,
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      }
    },
  );

  testWidgets(
    'historical scene stays static and lite mode removes costly decoration',
    (tester) async {
      await tester.pumpWidget(card(today: false));
      await tester.pumpAndSettle();
      final PrayerSkyScene scene = painter(tester).scene;
      await tester.pumpWidget(
        card(today: false, now: noon.add(const Duration(hours: 5))),
      );
      expect(painter(tester).scene, scene);
      final service = DeviceCapabilityService.instance,
          previous = service.value;
      addTearDown(() => service.value = previous);
      service.value = previous.copyWith(lowRam: true);
      await tester.pump();
      expect(painter(tester).decorativeEffects, isFalse);
    },
  );

  testWidgets('render sky stages for optional visual verification', (
    tester,
  ) async {
    final String? destination = Platform.environment['PRAYER_SKY_SHOTS'];
    if (destination == null) return;
    Directory(destination).createSync(recursive: true);
    final Map<String, DateTime> stages = <String, DateTime>{
      'dawn': day.entryFor(PrayerTimeKind.fajr).time,
      'sunrise': day.entryFor(PrayerTimeKind.sunrise).time,
      'noon': noon,
      'sunset': following.entryFor(PrayerTimeKind.maghrib).time,
      'night': day.date,
    };
    for (final entry in stages.entries) {
      await tester.pumpWidget(card(now: entry.value));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final RenderRepaintBoundary boundary = tester.renderObject(
          find.byKey(boundaryKey),
        );
        final ui.Image image = await boundary.toImage(pixelRatio: 2);
        final ByteData bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!;
        File(
          '$destination/${entry.key}.png',
        ).writeAsBytesSync(bytes.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  testWidgets(
    'setup hero holds the sunrise sky, shows default copy, opens setup',
    (tester) async {
      int tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: PrayerArcSetupHero(onTap: () => tapped++),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painter(tester).scene, PrayerSkyScene.sunrisePeak);
      expect(painter(tester).scene.sunVisibility, 1);
      expect(find.text('Prayer Times'), findsOneWidget);
      expect(
        find.text('Choose a location to show the next prayer time here.'),
        findsOneWidget,
      );
      expect(find.text('Set up location'), findsOneWidget);
      await tester.tap(find.byKey(const Key('prayer-arc-setup-hero')));
      expect(tapped, 1);
    },
  );
}
