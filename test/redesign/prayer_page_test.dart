import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/prayer_preview_main.dart';
import 'package:equran/prayer/prayer_arc_hero.dart';
import 'package:equran/prayer/prayer_sky_scene.dart';
import 'package:equran/prayer/prayer_sky_painter.dart';
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
          .whereType<PrayerSkyPainter>()
          .single;
      expect(
        painter.scene,
        PrayerSkyScene.forInstant(
          day: hero.day,
          followingDay: hero.followingDay,
          now: hero.now,
        ),
      );
      expect(painter.scene.sunProgress, inExclusiveRange(.5, .7));
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
  testWidgets('hero says "Asr in 2h 08m" with zero-padded minutes', (
    tester,
  ) async {
    await pump(tester);
    bool plain(Widget w, RegExp re) =>
        w is RichText && re.hasMatch(w.text.toPlainText());
    expect(
      find.byWidgetPredicate((w) => plain(w, RegExp(r'^Asr in \dh \d\dm$'))),
      findsOneWidget,
    );
    expect(find.textContaining('begins in'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    // 02:00 local is before Dhuhr: the hero still reads "<next> in <time>".
    await pump(tester, now: DateTime.utc(2026, 10, 4, 6, 30));
    expect(
      find.byWidgetPredicate(
        (w) => plain(w, RegExp(r'^Dhuhr in (\dh \d\dm|\d+ min)$')),
      ),
      findsOneWidget,
    );
  });
  testWidgets('week strip shows one-letter weekday initials', (tester) async {
    await pump(tester); // Sunday 4 October 2026 in the centre: Thu to Wed.
    final initials = [
      for (var i = -3; i <= 3; i++)
        tester
            .widget<Text>(
              find
                  .descendant(
                    of: find.byKey(ValueKey('prayer-week-$i')),
                    matching: find.byType(Text),
                  )
                  .first,
            )
            .data,
    ];
    expect(initials, ['T', 'F', 'S', 'S', 'M', 'T', 'W']);
  });
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
    expect(find.textContaining('Ends '), findsNothing);
  });
  testWidgets(
    'sky continues across midnight and transitions through dawn to sunrise',
    (tester) async {
      for (final now in [
        DateTime.utc(2026, 10, 4, 17),
        DateTime.utc(2026, 10, 4, 23),
        DateTime.utc(2026, 10, 5, 1),
        DateTime.utc(2026, 10, 5, 2),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await pump(tester, now: now);
        final hero = tester.widget<PrayerArcHero>(find.byType(PrayerArcHero));
        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<PrayerSkyPainter>()
            .single;
        expect(
          painter.scene,
          PrayerSkyScene.forInstant(
            day: hero.day,
            followingDay: hero.followingDay,
            now: now,
          ),
        );
        final sunrise = hero.day.entryFor(PrayerTimeKind.sunrise).time;
        expect(painter.scene.sunVisibility, now.isBefore(sunrise) ? 0 : 1);
        expect(hero.nextPrayer.countdown.isNegative, isFalse);
        expect(
          find.descendant(
            of: find.byType(PrayerArcHero),
            matching: find.byType(Icon),
          ),
          findsNothing,
        );
      }
    },
  );
  testWidgets('live sky pauses while inactive and catches up on resume', (
    tester,
  ) async {
    await pump(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final initial = prayerPreviewNow();
    await tester.pumpWidget(
      MaterialApp(
        theme: app.theme,
        localizationsDelegates: app.localizationsDelegates,
        supportedLocales: app.supportedLocales,
        home: PrayerTimesPage(initialNow: initial),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 2));
    expect(
      tester.widget<PrayerArcHero>(find.byType(PrayerArcHero)).now,
      initial,
    );
    final before = DateTime.now();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    final now = tester.widget<PrayerArcHero>(find.byType(PrayerArcHero)).now;
    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(DateTime.now()), isFalse);
    await tester.pumpWidget(const SizedBox());
  });
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
