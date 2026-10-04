import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/prayer_preview_main.dart';
import 'package:equran/prayer/prayer_arc_hero.dart';
import 'package:equran/prayer/prayer_hero_card.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_time_thumb_card.dart';
import 'package:equran/prayer/prayer_times_page.dart';
import 'package:equran/prayer/prayer_times_settings_page.dart';
import 'package:equran/prayer/qibla_page.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

class _Observer extends NavigatorObserver {
  Route<dynamic>? pushed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed = route;
  }
}

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
  });
  setUp(seedPrayerPreview);
  tearDownAll(Hive.close);
  test(
    'sun arc endpoints, midpoint, RTL and clamping match design geometry',
    () {
      final start = DateTime.utc(2026, 10, 4, 2);
      final end = start.add(const Duration(hours: 12));
      expect(prayerArcFraction(start, start, end), 0);
      expect(prayerArcFraction(end, start, end), 1);
      expect(
        prayerArcFraction(start.add(const Duration(hours: 6)), start, end),
        .5,
      );
      expect(
        prayerArcFraction(start.subtract(const Duration(hours: 1)), start, end),
        0,
      );
      expect(
        prayerArcFraction(end.add(const Duration(hours: 1)), start, end),
        1,
      );
      expect(prayerArcFraction(end, end, start), 0);
      expect(prayerArcPoint(0).dx, closeTo(31, .001));
      expect(prayerArcPoint(0).dy, closeTo(150, .001));
      expect(prayerArcPoint(.5).dx, closeTo(171, .001));
      expect(prayerArcPoint(.5).dy, closeTo(10, .001));
      expect(prayerArcPoint(1), const Offset(311, 150));
      expect(prayerArcPoint(0, rtl: true).dx, closeTo(311, .001));
      expect(prayerArcPoint(0, rtl: true).dy, closeTo(150, .001));
    },
  );
  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    DateTime? now,
    List<NavigatorObserver> observers = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      PrayerPreviewApp(
        colors: colors,
        scale: scale,
        locale: locale,
        now: now,
        navigatorObservers: observers,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(PrayerTimesPage));
      for (final name in [
        'fajr',
        'sunrise',
        'dhuhr',
        'asr',
        'maghrib',
        'isha',
      ]) {
        await precacheImage(
          AssetImage('assets/media/images/app/$name.webp'),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'daylight uses the next Islamic day Maghrib, retaining prayer grouping',
    (tester) async {
      await pump(tester);
      final hero = tester.widget<PrayerArcHero>(find.byType(PrayerArcHero));
      final sunrise = hero.day.entryFor(PrayerTimeKind.sunrise).time;
      final maghrib = hero.followingDay.entryFor(PrayerTimeKind.maghrib).time;
      expect(maghrib.year, sunrise.year);
      expect(maghrib.month, sunrise.month);
      expect(maghrib.day, sunrise.day);
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<PrayerArcPainter>()
          .single;
      expect(
        painter.fraction,
        closeTo(prayerArcFraction(hero.now, sunrise, maghrib), .0001),
      );
      expect(painter.fraction, inExclusiveRange(.5, .7));
      expect(
        hero.day.entryFor(PrayerTimeKind.maghrib).time.isBefore(hero.now),
        isTrue,
      );
    },
  );
  testWidgets(
    'Maghrib and Isha rows are dated to today, never "Passed" before they begin',
    (tester) async {
      // Muscat is UTC+4. 13:12, 18:30 and 02:00 local.
      for (final (now, passedRows, activeKind) in [
        (DateTime.utc(2026, 10, 4, 9, 12), 2, PrayerTimeKind.dhuhr),
        (DateTime.utc(2026, 10, 4, 14, 30), 0, PrayerTimeKind.maghrib),
        (DateTime.utc(2026, 10, 4, 22), 1, PrayerTimeKind.isha),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await pump(tester, now: now);
        expect(find.text('Passed'), findsNWidgets(passedRows), reason: '$now');
        final rows = tester
            .widgetList<PrayerTimeThumbCard>(find.byType(PrayerTimeThumbCard))
            .toList();
        expect(rows.where((r) => r.isActive).single.entry.kind, activeKind);
        final hero = tester.widget<PrayerArcHero>(find.byType(PrayerArcHero));
        final fajr = hero.day.entryFor(PrayerTimeKind.fajr).time;
        for (final kind in [PrayerTimeKind.maghrib, PrayerTimeKind.isha]) {
          final row = rows.singleWhere((r) => r.entry.kind == kind);
          // Before Fajr the list keeps the evening that just happened; from
          // Fajr on it looks ahead to this evening (the hero's own Maghrib).
          expect(
            row.entry.time,
            now.isBefore(fajr)
                ? hero.day.entryFor(kind).time
                : hero.followingDay.entryFor(kind).time,
            reason: '$kind at $now',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
      await pump(tester);
      expect(find.textContaining(RegExp(r'^In 4h \d\dm$')), findsOneWidget);
    },
  );
  testWidgets(
    'week strip drives existing date state; Today restores live period',
    (tester) async {
      await pump(tester);
      expect(find.byType(PrayerArch), findsNWidgets(6));
      final initial = tester
          .widget<PrayerHeroCard>(find.byType(PrayerHeroCard))
          .day!;
      await tester.tap(find.byKey(const ValueKey('prayer-week-2')));
      await tester.pumpAndSettle();
      var hero = tester.widget<PrayerHeroCard>(find.byType(PrayerHeroCard));
      expect(hero.day!.date.day, initial.date.day + 2);
      expect(hero.isViewingToday, isFalse);
      expect(find.textContaining('Began '), findsNothing);
      expect(find.byType(PrayerTimeThumbCard), findsNWidgets(6));
      await tester.tap(find.widgetWithText(TextButton, 'Today'));
      await tester.pumpAndSettle();
      hero = tester.widget<PrayerHeroCard>(find.byType(PrayerHeroCard));
      expect(hero.isViewingToday, isTrue);
      final caption = find.byTooltip('Select prayer date').first;
      await tester.tap(caption);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'header and hero keep settings navigation, Qibla remains reachable',
    (tester) async {
      final observer = _Observer();
      await pump(tester, observers: [observer]);
      for (final (button, type) in [
        (find.byTooltip('Prayer Times Settings'), PrayerTimesSettingsPage),
        (find.byKey(const Key('prayer-arc-hero')), PrayerTimesSettingsPage),
        (find.byTooltip('Qibla'), QiblaPage),
      ]) {
        await tester.tap(button);
        final target = (observer.pushed! as MaterialPageRoute<void>).builder(
          tester.element(find.byType(PrayerTimesPage)),
        );
        expect(target.runtimeType, type);
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'prohibited period labels remain supplied by existing calculation service',
    (tester) async {
      await pump(tester, now: DateTime.utc(2026, 10, 4, 2, 5));
      final hero = tester.widget<PrayerHeroCard>(find.byType(PrayerHeroCard));
      // Verify the existing period result is kept, rather than deriving a new prayer rule in painting.
      expect(hero.periodEndsAt, isNotNull);
      expect(hero.useRedesign, isTrue);
      expect(
        hero.day!.settings.toJson(),
        PrayerSettingsStore().getSettings().toJson(),
      );
      expect(hero.titleOverride, 'Sunrise');
      expect(hero.subtitleOverride, contains('Prohibited'));
    },
  );
  testWidgets('morning without a current prayer does not invent a began time', (
    tester,
  ) async {
    await pump(tester, now: DateTime.utc(2026, 10, 4, 6, 30));
    final hero = tester.widget<PrayerHeroCard>(find.byType(PrayerHeroCard));
    expect(hero.titleOverride, 'Morning');
    expect(hero.currentPrayer, isNull);
    expect(find.textContaining('Began '), findsNothing);
    expect(find.textContaining('Ends '), findsOneWidget);
  });
  testWidgets(
    'moon arc advances across midnight and stays complete from Fajr to sunrise',
    (tester) async {
      for (final now in [
        DateTime.utc(2026, 10, 4, 17),
        DateTime.utc(2026, 10, 4, 23),
        DateTime.utc(2026, 10, 5, 1),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await pump(tester, now: now);
        final hero = tester.widget<PrayerArcHero>(find.byType(PrayerArcHero));
        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<PrayerArcPainter>()
            .single;
        final maghrib = hero.day.entryFor(PrayerTimeKind.maghrib).time;
        final fajr = hero.day.entryFor(PrayerTimeKind.fajr).time;
        expect(painter.night, isTrue);
        expect(painter.markers, isEmpty);
        expect(
          painter.fraction,
          closeTo(prayerArcFraction(now, maghrib, fajr), .0001),
        );
        if (!now.isBefore(fajr)) expect(painter.fraction, 1);
        expect(hero.nextPrayer.countdown.isNegative, isFalse);
      }
      await tester.pumpWidget(const SizedBox());
      await pump(tester, now: DateTime.utc(2026, 10, 5, 2));
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<PrayerArcPainter>()
          .single;
      expect(painter.night, isFalse);
      expect(painter.fraction, greaterThan(0));
    },
  );
  for (final (name, colors, scale, locale) in [
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('scale-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic', EquranColors.dark, 1.0, const Locale('ar')),
    ('arabic-scale-1.3', EquranColors.dark, 1.3, const Locale('ar')),
  ]) {
    testWidgets('Prayer page and night details golden $name', (tester) async {
      await pump(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer-page-$name.png'),
      );
      await tester.ensureVisible(find.byKey(const Key('prayer-night-times')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer-details-$name.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        now: DateTime.utc(2026, 10, 4, 17),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer-night-$name.png'),
      );
    });
  }
}
