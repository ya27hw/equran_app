import 'package:equran/backend/library.dart';
import 'package:equran/debug/prayer_preview_main.dart'
    show prayerPreviewNow, seedPrayerPreview;
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/duas/daily_dua_repository.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/home_dashboard/home_dashboard_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran/quran.dart' as quran;
import 'gallery_test_support.dart' show loadGalleryFonts;

ThemeData _theme(EquranColors colors) {
  final base = savedPreviewTheme(colors);
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamilyFallback: const ['NotoNaskhArabic'],
    ),
  );
}

late DailyDuaRepository _duaRepository;

Future<void> _seed({required bool rich}) async {
  await seedPrayerPreview();
  // Pin the daily ayah (Ash-Sharh 94:5); it is otherwise random per day.
  var globalAyah = 5;
  for (var surah = 1; surah < 94; surah++) {
    globalAyah += quran.getVerseCount(surah);
  }
  await SettingsDB().put('dailyAyahDate', '2026-10-04');
  await SettingsDB().put('dailyAyahGlobalAyah', globalAyah);
  await ResumeStateDB().clear();
  await QuranActivityDB().clear();
  await QuranStatsDB().clear();
  await BookmarkDB().clear();
  if (!rich) {
    await PrayerSettingsStore().clearLocation();
    return;
  }
  final now = prayerPreviewNow();
  await ResumeStateDB().put(
    'reading:latest',
    ResumeStateEntry(
      id: 'reading:latest',
      kind: 'reading',
      surah: 2,
      ayah: 142,
      updatedAt: now,
    ),
  );
  await QuranActivityDB().put(
    '2026-10-04',
    QuranActivityDay(
      dateKey: '2026-10-04',
      updatedAt: now,
      ayahsRead: 14,
      readAyahKeys: const ['2:142'],
    ),
  );
  await QuranStatsDB().put(
    'summary',
    QuranStatsSnapshot(
      id: 'summary',
      updatedAt: now,
      totalAyahsRead: 1420,
      estimatedLettersRead: 5400,
      currentStreak: 12,
    ),
  );
}

/// The Home screen has a looping card shimmer and an asset-backed dua, so a plain
/// pumpAndSettle never ends. Let real I/O finish, then pump fixed frames.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUpAll(() async {
    registerCompanionStorageAdapters();
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SurahAdapter());
    await Hive.openBox<HifzEntry>(HifzDB.entriesBoxName, bytes: Uint8List(0));
    await Hive.openBox<HifzUnit>(HifzDB.unitsBoxName, bytes: Uint8List(0));
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final db in [
      SettingsDB(),
      ResumeStateDB(),
      QuranBookmarksDB(),
      QuranBookmarkFoldersDB(),
      FavouritesDB(),
      ReadingPlansDB(),
      QuranActivityDB(),
      QuranStatsDB(),
      BookmarkDB(),
      SurahDB(),
    ]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await initializeDateFormatting();
    await quran.initializeQuran();
    _duaRepository = DailyDuaRepository(repository: HisnAlMuslimRepository());
    await _duaRepository.getDailyDua(DateTime(2026, 10, 4));
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
    await (FontLoader('UthmanicHafs')
          ..addFont(rootBundle.load('assets/media/fonts/UthmanicHafs_V22.ttf')))
        .load();
  });
  tearDownAll(Hive.close);

  Future<List<String>> pump(
    WidgetTester tester, {
    required bool rich,
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
  }) async {
    await _seed(rich: rich);
    final taps = <String>[];
    VoidCallback tap(String name) =>
        () => taps.add(name);
    await tester.binding.setSurfaceSize(const Size(390, 2300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(colors),
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
          body: HomeDashboardPage(
            clock: prayerPreviewNow,
            dailyDuaRepository: _duaRepository,
            onOpenMore: tap('more'),
            onOpenQuran: tap('quran'),
            onOpenZakat: tap('zakat'),
            onOpenPrayerTimes: tap('prayer'),
            onOpenQibla: tap('qibla'),
            onOpenDuas: tap('duas'),
            onOpenTasbih: tap('tasbih'),
            onOpenReadingPlans: tap('plans'),
            onOpenDownloads: tap('downloads'),
            onOpenSearch: tap('search'),
            onOpenStats: tap('stats'),
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.runAsync(() async {
      final context = tester.element(find.byType(HomeDashboardPage));
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context);
      }
    });
    await _settle(tester);
    expect(tester.takeException(), isNull);
    return taps;
  }

  testWidgets('header shows weekday, Hijri date and the city only', (
    tester,
  ) async {
    await pump(tester, rich: true);
    expect(find.text("SUNDAY · 21 RABI' AL-THANI 1448"), findsOneWidget);
    expect(find.text('Muscat'), findsOneWidget);
    expect(find.text('السلام عليكم'), findsNothing);
  });

  testWidgets('shortcuts keep their callbacks', (tester) async {
    final taps = await pump(tester, rich: true);
    final l = AppLocalizations.of(
      tester.element(find.byType(HomeDashboardPage)),
    )!;
    await tester.tap(find.text(l.exploreAllFeatures));
    expect(taps.last, 'more');
    for (final (label, name) in [
      (l.qibla, 'qibla'),
      (l.tasbih, 'tasbih'),
      (l.search, 'search'),
    ]) {
      final finder = find.text(label);
      if (finder.evaluate().isEmpty) continue;
      await tester.ensureVisible(finder.first);
      await tester.tap(finder.first);
      expect(taps.last, name, reason: label);
    }
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
    for (final rich in [true, false]) {
      testWidgets('Home ${rich ? 'rich' : 'fresh'} golden $name', (
        tester,
      ) async {
        await pump(
          tester,
          rich: rich,
          colors: colors,
          scale: scale,
          locale: locale,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/home/${rich ? 'rich' : 'fresh'}-$name.png',
          ),
        );
      });
    }
  }
}
