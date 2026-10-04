import 'package:equran/backend/library.dart';
import 'package:equran/debug/statistics_preview_main.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/home/quran_stats_page.dart';
import 'package:equran/home/read.dart';
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

class _UnavailableHifzRepository extends StatisticsPreviewRepository {
  @override
  Future<HifzSectionData> getHifzData() async =>
      throw StateError('Hifz unavailable');
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerCompanionStorageAdapters();
    for (final db in [
      SettingsDB(),
      QuranActivityDB(),
      DhikrSessionsDB(),
      DuaInteractionsDB(),
      DuaFavouritesDB(),
      SalahLogDB(),
    ]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await initializeDateFormatting();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  setUp(seedStatisticsPreview);
  tearDownAll(Hive.close);
  Future<StatisticsPreviewRepository> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    List<NavigatorObserver> observers = const [],
    StatisticsPreviewRepository? fixture,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = fixture ?? StatisticsPreviewRepository();
    await tester.pumpWidget(
      StatisticsPreviewApp(
        repository: repository,
        colors: colors,
        scale: scale,
        locale: locale,
        navigatorObservers: observers,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return repository;
  }

  Future<void> scrollTo(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(key)),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Hifz load failure leaves Today and prayer logging available', (
    tester,
  ) async {
    await pump(tester, fixture: _UnavailableHifzRepository());
    expect(find.byKey(const ValueKey('statistics-today')), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('statistics-log-asr')));
    await tester.pumpAndSettle();
    expect(find.text("Today's Prayers"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'range filters load the existing enum; section headers scroll with content',
    (tester) async {
      final repo = await pump(tester);
      expect(find.byType(SliverPersistentHeader), findsNothing);
      for (final range in [
        StatRange.month,
        StatRange.year,
        StatRange.allTime,
      ]) {
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(ValueKey('statistics-range-${range.name}')),
        );
        await tester.pumpAndSettle();
        await scrollTo(tester, 'statistics-quran');
        expect(repo.loadedRanges, contains(range));
        expect(find.text('319'), findsOneWidget);
        expect(
          tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .where(
                (w) =>
                    w.painter.runtimeType.toString() ==
                    '_StatisticsGoalPainter',
              ),
          isEmpty,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'today prayer logging saves through the existing sheet and refreshes overview',
    (tester) async {
      final repo = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('statistics-log-asr')));
      await tester.pumpAndSettle();
      expect(find.text("Today's Prayers"), findsOneWidget);
      final asrRow = find
          .byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_SalahLogPrayerRow',
          )
          .at(2);
      await tester.tap(
        find.descendant(of: asrRow, matching: find.text('On time')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect((await SalahLogDB().getEntry('2026-10-04'))!.asr, 'onTime');
      expect(repo.clearCount, greaterThan(0));
      final ring = tester
          .widgetList<ProgressRing>(find.byType(ProgressRing))
          .first;
      expect(ring.innerValue, .6);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tracking opt-in, dismiss and re-enable retain settings behavior',
    (tester) async {
      await SettingsDB().put('prayerTrackingEnabled', false);
      await pump(tester);
      await tester.scrollUntilVisible(
        find.text('Maybe later'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(SettingsDB().get('prayerTrackingEnabled'), false);
      final enable = find.text('Enable prayer tracking →');
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        enable,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(enable);
      await tester.pumpAndSettle();
      expect(SettingsDB().get('prayerTrackingEnabled'), true);
      expect(find.byKey(const ValueKey('statistics-prayer')), findsOneWidget);
    },
  );
  testWidgets(
    'all 114 map cells open their surah and expanded map remains available',
    (tester) async {
      final observer = _Observer();
      await pump(tester, observers: [observer]);
      await scrollTo(tester, 'statistics-map-toggle-quran');
      await tester.tap(
        find.byKey(const ValueKey('statistics-map-toggle-quran')),
      );
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('statistics-surah-map-quran')),
      );
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        6,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('statistics-surah-quran-18')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('statistics-surah-quran-18')));
      final route = observer.pushed! as MaterialPageRoute<void>;
      final page =
          route.builder(tester.element(find.byType(StatisticsPage)))
              as ReadPage;
      expect(page.chapter, 18);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('next review retains navigation to the Hifz home page', (
    tester,
  ) async {
    final observer = _Observer();
    await pump(tester, observers: [observer]);
    await scrollTo(tester, 'statistics-next-review');
    await tester.tap(find.byKey(const ValueKey('statistics-next-review')));
    final route = observer.pushed! as MaterialPageRoute<void>;
    expect(
      route.builder(tester.element(find.byType(StatisticsPage))),
      isA<HifzHomePage>(),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets(
    'history previous/next, swipe and day-detail sheet survive redesign',
    (tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.byTooltip('Previous month'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      final month = find.byType(GridView).last;
      await tester.ensureVisible(month);
      await tester.drag(month, const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
      final firstDay = find.descendant(
        of: find.byType(GridView).last,
        matching: find.text('1'),
      );
      await tester.ensureVisible(firstDay);
      await tester.tap(firstDay);
      await tester.pumpAndSettle();
      expect(find.text('Sep 1, 2026'), findsOneWidget);
      expect(find.textContaining('10 ayahs'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('logging sheet stays usable with Arabic and enlarged text', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('ar'), scale: 1.3);
    expect(
      tester.widget<Text>(find.text('/ 20')).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester
          .getCenter(
            find.byWidgetPredicate(
              (w) => w is DisplayNumeral && w.text == '14',
            ),
          )
          .dx,
      lessThan(tester.getCenter(find.text('/ 20')).dx),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('statistics-log-asr')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('statistics-log-asr')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final save = find.text('حفظ');
    expect(save, findsOneWidget);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final variant in [
    (
      name: 'emerald-dark',
      colors: EquranColors.dark,
      scale: 1.0,
      locale: const Locale('en'),
    ),
    (
      name: 'emerald-light',
      colors: EquranColors.light,
      scale: 1.0,
      locale: const Locale('en'),
    ),
    (
      name: 'black-dark',
      colors: EquranColors.blackDark,
      scale: 1.0,
      locale: const Locale('en'),
    ),
    (
      name: 'red-dark',
      colors: EquranColors.redDark,
      scale: 1.0,
      locale: const Locale('en'),
    ),
    (
      name: 'scale-1.3',
      colors: EquranColors.dark,
      scale: 1.3,
      locale: const Locale('en'),
    ),
    (
      name: 'arabic',
      colors: EquranColors.dark,
      scale: 1.0,
      locale: const Locale('ar'),
    ),
    (
      name: 'arabic-1.3',
      colors: EquranColors.dark,
      scale: 1.3,
      locale: const Locale('ar'),
    ),
  ]) {
    testWidgets('Statistics ${variant.name} all sections at 390 px', (
      tester,
    ) async {
      await pump(
        tester,
        colors: variant.colors,
        scale: variant.scale,
        locale: variant.locale,
      );
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/statistics-${variant.name}-today.png'),
      );
      for (final section in [
        'prayer',
        'quran',
        'map-quran',
        'hifz',
        'tasbih',
        'history',
        'streaks',
      ]) {
        await scrollTo(tester, 'statistics-$section');
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile('goldens/statistics-${variant.name}-$section.png'),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
