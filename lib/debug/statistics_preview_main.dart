import 'package:equran/backend/library.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/home/quran_stats_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

DateTime statisticsPreviewNow() => DateTime(2026, 10, 4, 13, 12);

Future<void> seedStatisticsPreview() async {
  for (final db in [
    SettingsDB(),
    QuranActivityDB(),
    DhikrSessionsDB(),
    DuaInteractionsDB(),
    DuaFavouritesDB(),
    SalahLogDB(),
  ]) {
    await db.clear();
  }
  await SettingsDB().put('prayerTrackingEnabled', true);
  await SettingsDB().put('dailyQuranGoalAyahs', 20);
  for (int i = 0; i < 7; i++) {
    final date = statisticsPreviewNow().subtract(Duration(days: i));
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await SalahLogDB().saveEntry(
      SalahLogEntry(
        date: key,
        fajr: i == 2 ? 'notPrayed' : 'onTime',
        dhuhr: i == 1 ? 'late' : 'onTime',
        asr: i == 0 ? 'unlogged' : 'onTime',
        maghrib: i == 0
            ? 'unlogged'
            : i == 3
            ? 'notPrayed'
            : 'onTime',
        isha: i == 0
            ? 'unlogged'
            : i == 4
            ? 'late'
            : 'onTime',
      ),
    );
  }
  final keys = <String>[];
  for (int surah = 1; surah <= 114; surah++) {
    final count = surah == 1 || surah >= 105
        ? 7
        : surah % 3 == 0
        ? 4
        : surah % 7 == 0
        ? 1
        : 0;
    keys.addAll([for (int verse = 1; verse <= count; verse++) '$surah:$verse']);
  }
  await QuranActivityDB().put(
    'preview-reading',
    QuranActivityDay(
      dateKey: '2026-10-04',
      updatedAt: statisticsPreviewNow(),
      ayahsRead: 14,
      readAyahKeys: keys,
    ),
  );
}

/// Fixed data shapes for repeatable visual checks; production repository is unchanged.
class StatisticsPreviewRepository extends StatisticsRepository {
  final List<StatRange> loadedRanges = [];
  int clearCount = 0;
  @override
  void clearCache() {
    clearCount++;
    super.clearCache();
  }

  SalahLogEntry get todayEntry =>
      SalahLogEntry.fromStored(SalahLogDB().get('2026-10-04')) ??
      const SalahLogEntry(date: '2026-10-04');
  @override
  Future<OverviewStats> overview(AppLocalizations localizations) async {
    final enabled = SettingsDB().get('prayerTrackingEnabled') == true;
    final entry = todayEntry;
    final prayed = [
      entry.fajr,
      entry.dhuhr,
      entry.asr,
      entry.maghrib,
      entry.isha,
    ].where((s) => s == 'onTime' || s == 'late').length;
    return OverviewStats(
      quranAyahs: 14,
      tasbihCount: 66,
      duasViewed: 4,
      prayerTrackingEnabled: enabled,
      salahPrayersToday: enabled ? prayed : 0,
      todaySalahEntry: entry,
      quranGoalProgress: .7,
      progress: .55,
      motivation: localizations.continueYourJourneyToday,
      highestStreak: 12,
    );
  }

  @override
  Future<SalahSectionData> getSalahData(StatRange range) async {
    loadedRanges.add(range);
    if (SettingsDB().get('prayerTrackingEnabled') != true) {
      return SalahSectionData.disabled(todayEntry: todayEntry);
    }
    return SalahSectionData(
      enabled: true,
      todayEntry: todayEntry,
      prayedToday: 2,
      onTimeThisWeek: 29,
      lateThisWeek: 2,
      bestPrayer: SalahPrayer.dhuhr,
      fajrStreak: 4,
      prayerStats: [
        for (final prayer in SalahPrayer.values)
          SalahPrayerStats(
            prayer: prayer,
            onTimeCount: prayer.index == 0 ? 5 : 6,
            lateCount: prayer.index == 1 || prayer.index == 4 ? 1 : 0,
            notPrayedCount: prayer.index == 0 || prayer.index == 3 ? 1 : 0,
          ),
      ],
    );
  }

  @override
  Future<QuranStatsData> quranStats(
    StatRange range,
    AppLocalizations localizations,
  ) async {
    loadedRanges.add(range);
    final labels = [
      localizations.monday,
      localizations.tuesday,
      localizations.wednesday,
      localizations.thursday,
      localizations.friday,
      localizations.saturday,
      localizations.sunday,
    ];
    final counts = range == StatRange.week
        ? [20, 24, 12, 20, 32, 20, 14]
        : [72, 94, 65, 88];
    return QuranStatsData(
      buckets: [
        for (int i = 0; i < counts.length; i++)
          ActivityBucket(
            label: range == StatRange.week
                ? labels[i].characters.take(1).toString()
                : '${i + 1}',
            detailLabel: labels[i],
            count: counts[i],
            isCurrent: i == counts.length - 1,
          ),
      ],
      totalAyahs: 1840,
      totalLetters: 196420,
      activeDays: 46,
      mostActiveWeekday: 5,
      mostReadSurah: 18,
      mostReadSurahAyahs: 120,
      insights: [
        InsightData(
          icon: Icons.trending_up,
          label: localizations.readingUpFromLastWeek(12),
        ),
      ],
      completedSurahs: {1, 108, 112, 113, 114},
      khatmCompletionDates: [],
    );
  }

  @override
  Future<HifzSectionData> getHifzData() async => HifzSectionData(
    totalMemorized: 82,
    totalReviews: 146,
    currentStreak: 8,
    retentionRate: .86,
    masteredPerSurah: {1: 7, 18: 60, 112: 4, 113: 5, 114: 6},
    nextDueEntry: HifzEntry()
      ..surah = 67
      ..ayah = 1
      ..dueDate = DateTime(2026, 10, 4)
      ..status = 'review'
      ..track = 'sabqi',
  );
  @override
  Future<TasbihStatsData> tasbih(StatRange range) async =>
      const TasbihStatsData(
        hasData: true,
        totalDhikr: 2840,
        dailyAverage: 405.7,
        activeDays: 7,
        mostRecitedName: 'SubhanAllah',
        mostRecitedCount: 1140,
      );
  @override
  Future<DuasStatsData> duas(StatRange range) async => const DuasStatsData(
    hasData: true,
    viewedCount: 28,
    favouriteCount: 12,
    mostViewedCategory: 'Morning and evening remembrances',
    mostViewedCategoryId: '029',
    mostViewedCategoryCount: 11,
  );
  @override
  Future<StreakStats> streaks() async =>
      const StreakStats(quran: 12, tasbih: 8, overall: 12);
  @override
  Future<MonthlyActivityData> monthlyActivity(int year, int month) async =>
      MonthlyActivityData(
        month: DateTime(year, month),
        days: {
          for (int day = 1; day <= DateTime(year, month + 1, 0).day; day++)
            day: MonthlyActivityDay(
              date: DateTime(year, month, day),
              quran: day > 4 && month == 10 ? 0 : day % 4 * 10,
              tasbih: day > 4 && month == 10 ? 0 : day % 3 * 33,
              duas: day > 4 && month == 10 ? 0 : day % 5,
              salah: day > 4 && month == 10 ? 0 : 5,
              hifz: day > 4 && month == 10 ? 0 : 1,
            ),
        },
      );
}

Future<void> main() async {
  if (!kDebugMode) return;
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init('redesign_statistics_preview');
  registerCompanionStorageAdapters();
  for (final db in [
    SettingsDB(),
    QuranActivityDB(),
    DhikrSessionsDB(),
    DuaInteractionsDB(),
    DuaFavouritesDB(),
    SalahLogDB(),
  ]) {
    await db.initBox();
  }
  await seedStatisticsPreview();
  final params = Uri.base.queryParameters;
  runApp(
    StatisticsPreviewApp(
      repository: StatisticsPreviewRepository(),
      colors: switch (params['palette']) {
        'emerald-light' => EquranColors.light,
        'black-dark' => EquranColors.blackDark,
        'red-dark' => EquranColors.redDark,
        _ => EquranColors.dark,
      },
      locale: Locale(params['locale'] ?? 'en'),
      scale: double.tryParse(params['scale'] ?? '') ?? 1,
    ),
  );
}

class StatisticsPreviewApp extends StatelessWidget {
  const StatisticsPreviewApp({
    super.key,
    required this.repository,
    this.colors = EquranColors.dark,
    this.locale = const Locale('en'),
    this.scale = 1,
    this.navigatorObservers = const [],
    this.now,
  });
  final StatisticsRepository repository;
  final DateTime? now;
  final EquranColors colors;
  final Locale locale;
  final double scale;
  final List<NavigatorObserver> navigatorObservers;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: colors.background.computeLuminance() < .5
          ? Brightness.dark
          : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorSchemeSeed: colors.primary,
      fontFamily: 'Inter',
      extensions: [colors, EquranTokens.fromColors(colors)],
    ),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: navigatorObservers,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: StatisticsPage(
        previewRepository: repository,
        previewNow: now ?? statisticsPreviewNow(),
      ),
    ),
  );
}
