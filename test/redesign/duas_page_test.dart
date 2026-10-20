import 'dart:async';
import 'package:equran/backend/library.dart';
import 'package:equran/debug/duas_preview_main.dart';
import 'package:equran/duas/duas_category_page.dart';
import 'package:equran/duas/duas_favourites_page.dart';
import 'package:equran/duas/duas_page.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/duas/tasbih_page.dart';
import 'package:equran/duas/widgets/dua_browser_widgets.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart' show PillTag;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

class _Observer extends NavigatorObserver {
  Route<dynamic>? pushed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed = route;
  }
}

class _Repository extends HisnAlMuslimRepository {
  _Repository(this.result);
  final Future<List<DuaCategoryIndex>> result;
  @override
  Future<List<DuaCategoryIndex>> loadCategoryIndex() => result;
}

void main() {
  late List<DuaCategoryIndex> index;
  late HisnAlMuslimRepository repository;
  const location = PrayerLocation(
    latitude: 23.588,
    longitude: 58.3829,
    label: 'Muscat',
    mode: PrayerLocationMode.manual,
    countryCode: 'OM',
    timezoneId: 'Asia/Muscat',
  );
  final settings = PrayerTimeSettings.fromJson(null);
  setUpAll(() async {
    registerCompanionStorageAdapters();
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final db in [
      SettingsDB(),
      DuaFavouritesDB(),
      DuaInteractionsDB(),
      DhikrSessionsDB(),
    ]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    repository = HisnAlMuslimRepository();
    index = await repository.loadCategoryIndex();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  setUp(seedDuasPreview);
  tearDownAll(Hive.close);

  test('real index groups cover every category once, with correct totals', () {
    expect(index.length, 134);
    expect(index.fold<int>(0, (sum, c) => sum + c.duaCount), 298);
    final daily = index.where((c) => c.group == DuaGroup.dailyAthkar);
    expect(daily.length, 7);
    expect(daily.fold<int>(0, (sum, c) => sum + c.duaCount), 54);
    expect(DuaCategoryGroupMapper.orderedGroups.length, 13);
    for (final group in DuaCategoryGroupMapper.orderedGroups) {
      expect(index.any((c) => c.group == group), isTrue);
    }
  });
  test(
    'approved suggestion boundaries, real history, fallback and location timezone',
    () {
      DuaSuggestion resolve(
        DateTime now, {
        PrayerLocation? place = location,
        Iterable<dynamic> history = const [],
      }) => DuaSuggestion.resolve(
        categories: index,
        now: now,
        location: place,
        settings: settings,
        history: history,
      )!;
      final day = const PrayerTimesService().calculateDay(
        date: DateTime(2026, 10, 3),
        location: location,
        settings: settings,
      );
      final asr = day.entryFor(PrayerTimeKind.asr).time;
      final noon = DateTime.utc(
        2026,
        10,
        3,
        8,
      ); // Muscat noon, regardless of host timezone.
      final records = [
        {
          'categoryId': '030',
          'updatedAt': noon
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
        {
          'categoryId': '033',
          'updatedAt': noon
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
        },
        {'categoryId': '999', 'updatedAt': noon.toIso8601String()},
        {'categoryId': '003', 'updatedAt': 'invalid'},
        {
          'categoryId': '003',
          'updatedAt': noon.add(const Duration(days: 1)).toIso8601String(),
        },
        'legacy-invalid',
      ];
      expect(
        resolve(
          noon.subtract(const Duration(seconds: 1)),
          history: records,
        ).label,
        DuaSuggestionLabel.morning,
      );
      final resumed = resolve(noon, history: records);
      expect(resumed.label, DuaSuggestionLabel.resume);
      expect(resumed.category.id, '033');
      expect(
        resolve(
          asr.subtract(const Duration(seconds: 1)),
          history: records,
        ).label,
        DuaSuggestionLabel.resume,
      );
      expect(resolve(asr, history: records).label, DuaSuggestionLabel.evening);
      expect(
        resolve(
          asr.add(const Duration(hours: 6)),
          history: records,
        ).category.id,
        '029',
      );
      expect(resolve(noon).label, DuaSuggestionLabel.morning);
      expect(resolve(noon).category.id, '029');
      expect(
        resolve(noon, place: null, history: records).label,
        DuaSuggestionLabel.suggested,
      );
    },
  );

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    List<NavigatorObserver> observers = const [],
    HisnAlMuslimRepository? repo,
    DateTime Function() now = duasPreviewNow,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      DuasPreviewApp(
        repository: repo ?? repository,
        colors: colors,
        locale: locale,
        textScale: scale,
        navigatorObservers: observers,
        now: now,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> openDaily(WidgetTester tester) async {
    final tile = find.byKey(const ValueKey('dua-theme-dailyAthkar'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'all themes navigate to their real filtered list; General spans both columns',
    (tester) async {
      await pump(tester);
      for (final group in DuaCategoryGroupMapper.orderedGroups) {
        final tile = find.byKey(ValueKey('dua-theme-${group.name}'));
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        final width = tester.getSize(tile).width;
        expect(width, group == DuaGroup.misc ? 350 : 169);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(
          tester.widget<DuasThemePage>(find.byType(DuasThemePage)).group,
          group,
        );
        final categories = index.where((c) => c.group == group).toList();
        for (final c in categories) {
          expect(find.byKey(ValueKey('dua-category-${c.id}')), findsOneWidget);
        }
        await tester.tap(find.byTooltip('Back to Duas'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('home search supports English and Arabic, clear and no matches', (
    tester,
  ) async {
    await pump(tester);
    final search = find.descendant(
      of: find.byKey(const Key('duas-search')),
      matching: find.byType(TextField),
    );
    for (final query in ['Morning and evening', 'أذكار الصباح']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dua-search-029')), findsOneWidget);
      expect(find.byType(DuaSuggestionHero), findsNothing);
    }
    await tester.enterText(search, 'missing-category');
    await tester.pumpAndSettle();
    expect(find.text('No matching categories'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.byType(DuaSuggestionHero), findsOneWidget);
  });
  testWidgets('theme search preserves row positions and bilingual titles', (
    tester,
  ) async {
    await pump(tester);
    await openDaily(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('duas-theme-search')),
        matching: find.byType(TextField),
      ),
      'Morning and evening',
    );
    await tester.pumpAndSettle();
    expect(find.byType(DuaCategoryRow), findsOneWidget);
    expect(
      tester.widget<DuaCategoryRow>(find.byType(DuaCategoryRow)).position,
      3,
    );
    expect(find.text('أذكار الصباح والمساء'), findsOneWidget);
    expect(find.text('For this evening'), findsOneWidget);
  });
  testWidgets(
    'history/settings react without writing storage, and favourites react',
    (tester) async {
      final noon = DateTime.utc(2026, 10, 3, 8);
      await pump(tester, now: () => noon);
      expect(find.text('FOR THIS MORNING'), findsOneWidget);
      await tester.runAsync(
        () => DuaInteractionsDB().recordCategoryView(
          categoryId: '030',
          categoryTitle: 'Sleep',
          duaCount: 13,
          viewedAt: noon.subtract(const Duration(minutes: 1)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.text('Remembrance of sleep'), findsOneWidget);
      expect(DuaInteractionsDB().length, 1);
      await tester.runAsync(() => PrayerSettingsStore().clearLocation());
      await tester.pumpAndSettle();
      expect(find.text('SUGGESTED FOR YOU'), findsOneWidget);
      await tester.runAsync(() => DuaFavouritesDB().put('030_000', true));
      await tester.pumpAndSettle();
      final tile = find.byKey(const Key('duas-favourites'));
      expect(
        find.descendant(of: tile, matching: find.text('13')),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'begin, list rows, favourites and Tasbih preserve destination parameters',
    (tester) async {
      final observer = _Observer();
      await pump(tester, observers: [observer]);
      Future<Widget> target(Finder button) async {
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        // Inspect the real route without invoking unrelated reader/audio services.
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        // Inspect the destination before a frame invokes its services.
        await tester.tap(button);
        final route = observer.pushed! as MaterialPageRoute<void>;
        final destination = route.builder(
          tester.element(find.byType(DuasPage)),
        );
        navigator.pop();
        await tester.pumpAndSettle();
        return destination;
      }

      final begin =
          await target(find.widgetWithText(FilledButton, 'Begin'))
              as DuasCategoryPage;
      expect(begin.categoryIndex.id, '029');
      expect(begin.repository, same(repository));
      final favourites =
          await target(find.byKey(const Key('duas-favourites')))
              as DuasFavouritesPage;
      expect(favourites.categoryIndex.length, 134);
      expect(favourites.repository, same(repository));
      final tasbih =
          await target(find.byKey(const Key('duas-tasbih'))) as TasbihPage;
      expect(tasbih.showAppBar, isTrue);
      await openDaily(tester);
      final row = find.byKey(const ValueKey('dua-category-030'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      final reader =
          (observer.pushed! as MaterialPageRoute<void>).builder(
                tester.element(find.byType(DuasThemePage)),
              )
              as DuasCategoryPage;
      expect(reader.categoryIndex.id, '030');
      expect(reader.repository, same(repository));
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    },
  );
  testWidgets('loading, failure/retry and empty states remain reachable', (
    tester,
  ) async {
    final pending = Completer<List<DuaCategoryIndex>>();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      DuasPreviewApp(repository: _Repository(pending.future)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(const FormatException('fixture failure'));
    await tester.pumpAndSettle();
    expect(find.text('Duas unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, repo: _Repository(Future.value([])));
    expect(find.text('No duas found'), findsOneWidget);
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
    testWidgets('Duas home, theme grid and category golden $name', (
      tester,
    ) async {
      await pump(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/duas-home-$name.png'),
      );
      final daily = find.byKey(const ValueKey('dua-theme-dailyAthkar'));
      await tester.ensureVisible(daily);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/duas-grid-$name.png'),
      );
      await tester.tap(daily);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/duas-category-$name.png'),
      );
      if (locale.languageCode == 'ar') {
        final badgeText = tester.widget<RichText>(
          find
              .descendant(
                of: find.byType(PillTag),
                matching: find.byType(RichText),
              )
              .first,
        );
        expect(
          (badgeText.text as TextSpan).style!.fontFamilyFallback,
          contains('NotoNaskhArabic'),
        );
      }
      // Check all long labels at both scales, not just the first screenful.
      for (final c in index.where((c) => c.group == DuaGroup.dailyAthkar)) {
        await tester.ensureVisible(
          find.byKey(ValueKey('dua-category-${c.id}')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
