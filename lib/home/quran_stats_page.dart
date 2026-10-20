import 'dart:math' as math;

import 'package:equran/backend/library.dart';
import 'package:equran/duas/hisn_category_translations.dart';
import 'package:equran/home/read.dart';
import 'package:equran/home/settings_dialogs.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart' as prayer_models;
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/number_formatting.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart' as quran;
import 'package:equran/theme/inter_optical_size.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';

part 'statistics_redesign.dart';

const int _totalSurahs = 114;

final Map<String, int> _letterCountCache = <String, int>{};

enum StatRange { week, month, year, allTime }

enum SalahStatus {
  onTime('onTime'),
  late('late'),
  notPrayed('notPrayed'),
  unlogged('unlogged');

  const SalahStatus(this.storageValue);

  final String storageValue;

  bool get countsAsPrayer =>
      this == SalahStatus.onTime || this == SalahStatus.late;

  static SalahStatus fromValue(String value) {
    return switch (value) {
      'onTime' => SalahStatus.onTime,
      'late' => SalahStatus.late,
      'notPrayed' => SalahStatus.notPrayed,
      _ => SalahStatus.unlogged,
    };
  }
}

enum SalahPrayer {
  fajr('fajr'),
  dhuhr('dhuhr'),
  asr('asr'),
  maghrib('maghrib'),
  isha('isha');

  const SalahPrayer(this.key);

  final String key;

  SalahStatus statusFor(SalahLogEntry entry) {
    return SalahStatus.fromValue(switch (this) {
      SalahPrayer.fajr => entry.fajr,
      SalahPrayer.dhuhr => entry.dhuhr,
      SalahPrayer.asr => entry.asr,
      SalahPrayer.maghrib => entry.maghrib,
      SalahPrayer.isha => entry.isha,
    });
  }

  SalahLogEntry updateEntry(SalahLogEntry entry, SalahStatus status) {
    return switch (this) {
      SalahPrayer.fajr => entry.copyWith(fajr: status.storageValue),
      SalahPrayer.dhuhr => entry.copyWith(dhuhr: status.storageValue),
      SalahPrayer.asr => entry.copyWith(asr: status.storageValue),
      SalahPrayer.maghrib => entry.copyWith(maghrib: status.storageValue),
      SalahPrayer.isha => entry.copyWith(isha: status.storageValue),
    };
  }
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.previewRepository, this.previewNow});

  /// Debug fixtures supply existing data types without changing production loads.
  @visibleForTesting
  final StatisticsRepository? previewRepository;
  @visibleForTesting
  final DateTime? previewNow;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final StatisticsRepository _repository;
  late final ValueNotifier<StatRange> _rangeNotifier;
  late final ValueNotifier<int> _refreshNotifier;
  late final ScrollController _scrollController;
  late final ValueListenable<Box<dynamic>> _quranListener;
  late final ValueListenable<Box<dynamic>> _dhikrListener;
  late final ValueListenable<Box<dynamic>> _duasListener;
  late final ValueListenable<Box<dynamic>> _favouritesListener;
  late final ValueListenable<Box<dynamic>> _settingsListener;
  late final ValueListenable<Box<dynamic>> _salahListener;
  final GlobalKey _surahProgressKey = GlobalKey();
  bool _surahGridExpanded = false;
  bool _prayerTrackingOptInDismissed = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.previewRepository ?? StatisticsRepository();
    _rangeNotifier = ValueNotifier<StatRange>(StatRange.week);
    _refreshNotifier = ValueNotifier<int>(0);
    _scrollController = ScrollController();
    _quranListener = QuranActivityDB().listener;
    _dhikrListener = DhikrSessionsDB().listener;
    _duasListener = DuaInteractionsDB().listener;
    _favouritesListener = DuaFavouritesDB().listener;
    _settingsListener = SettingsDB().listener;
    _salahListener = SalahLogDB().listener;
    for (final ValueListenable<Box<dynamic>> listener
        in <ValueListenable<Box<dynamic>>>[
          _quranListener,
          _dhikrListener,
          _duasListener,
          _favouritesListener,
          _settingsListener,
          _salahListener,
        ]) {
      listener.addListener(_handleDataChanged);
    }
  }

  @override
  void dispose() {
    for (final ValueListenable<Box<dynamic>> listener
        in <ValueListenable<Box<dynamic>>>[
          _quranListener,
          _dhikrListener,
          _duasListener,
          _favouritesListener,
          _settingsListener,
          _salahListener,
        ]) {
      listener.removeListener(_handleDataChanged);
    }
    _surahGridExpanded = false;
    _scrollController.dispose();
    _rangeNotifier.dispose();
    _refreshNotifier.dispose();
    super.dispose();
  }

  void _handleDataChanged() {
    _repository.clearCache();
    _refreshNotifier.value++;
  }

  Future<void> _enablePrayerTracking() async {
    await SettingsDB().put('prayerTrackingEnabled', true);
    if (!mounted) return;
    _repository.clearCache();
    _refreshNotifier.value++;
  }

  void _dismissPrayerTrackingOptIn() {
    setState(() {
      _prayerTrackingOptInDismissed = true;
    });
  }

  /// Same dialog and storage key as the Settings tile. The settings box
  /// listener refreshes this page and the dashboard after the save.
  Future<void> _editDailyGoal(BuildContext context) async {
    final int? value = await showReaderDialog<int>(
      context: context,
      builder: (dialogContext) => DailyGoalDialog(initialGoal: _dailyGoal()),
    );
    if (value == null || !mounted) return;
    await SettingsDB().put('dailyQuranGoalAyahs', value);
  }

  void _openSurah(int surah) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReadPage(chapter: surah, startVerse: 1),
      ),
    );
  }

  void _toggleSurahGridExpanded() {
    final bool nextExpanded = !_surahGridExpanded;
    final double? targetOffset = nextExpanded
        ? null
        : _surahProgressScrollOffset();
    setState(() {
      _surahGridExpanded = nextExpanded;
    });
    if (nextExpanded || targetOffset == null || !_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      targetOffset,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  double? _surahProgressScrollOffset() {
    final BuildContext? sectionContext = _surahProgressKey.currentContext;
    final RenderObject? sectionObject = sectionContext?.findRenderObject();
    final RenderObject? pageObject = context.findRenderObject();
    if (sectionObject is! RenderBox || pageObject is! RenderBox) return null;

    final double sectionTop = sectionObject.localToGlobal(Offset.zero).dy;
    final double pageTop = pageObject.localToGlobal(Offset.zero).dy;
    final double target = _scrollController.offset + sectionTop - pageTop - 36;
    final ScrollPosition position = _scrollController.position;
    return target.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ColoredBox(
      color: context.equranColors.background,
      child: RedesignPageTypography(
        child: SafeArea(
          child: ValueListenableBuilder<int>(
            valueListenable: _refreshNotifier,
            builder: (context, refreshToken, _) => CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // No title or greeting band above the content. A pushed route
                // keeps only its back button, because the stats page draws
                // no app bar of its own.
                // The top row holds the back button (when pushed) and the
                // daily goal setter, so the goal is one tap away.
                _PageContentSliver(
                  topPadding: 8,
                  child: Row(
                    children: <Widget>[
                      if (Navigator.of(context).canPop())
                        IconButton44(
                          icon: Icons.arrow_back_rounded,
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      const Spacer(),
                      IconButton44(
                        icon: Icons.settings_rounded,
                        tooltip: l.dailyQuranGoal,
                        onPressed: () => _editDailyGoal(context),
                      ),
                    ],
                  ),
                ),
                _PageContentSliver(
                  topPadding: 12,
                  child: _RangeToggle(rangeListenable: _rangeNotifier),
                ),
                _PageContentSliver(
                  topPadding: 22,
                  child:
                      _DataSection<
                        ({OverviewStats overview, HifzSectionData? hifz})
                      >(
                        refreshToken: refreshToken,
                        placeholderHeight: 340,
                        load: () async {
                          final overview = await _repository.overview(l);
                          HifzSectionData? hifz;
                          try {
                            hifz = await _repository.getHifzData();
                          } catch (_) {
                            // Keep overview/logging available when this separate
                            // section fails; an unknown count is not zero.
                          }
                          return (overview: overview, hifz: hifz);
                        },
                        builder: (context, data) => _StatisticsToday(
                          data: data.overview,
                          mastered: data.hifz?.totalMemorized,
                        ),
                      ),
                ),
                _FlowSectionHeader(label: l.prayer),
                _PageContentSliver(
                  child: _RangeAwareSection<SalahSectionData>(
                    refreshToken: refreshToken,
                    rangeListenable: _rangeNotifier,
                    load: _repository.getSalahData,
                    placeholderHeight: 500,
                    builder: (context, data) => _SalahSectionHost(
                      data: data,
                      optInDismissed: _prayerTrackingOptInDismissed,
                      onEnable: _enablePrayerTracking,
                      onMaybeLater: _dismissPrayerTrackingOptIn,
                      onLogSaved: _handleDataChanged,
                      now: widget.previewNow,
                    ),
                  ),
                ),
                _FlowSectionHeader(label: l.quran),
                _PageContentSliver(
                  child: _RangeAwareSection<QuranStatsData>(
                    refreshToken: refreshToken,
                    rangeListenable: _rangeNotifier,
                    load: (range) => _repository.quranStats(range, l),
                    placeholderHeight: 850,
                    builder: (context, data) => _StatisticsQuran(
                      data: data,
                      range: _rangeNotifier.value,
                      sectionKey: _surahProgressKey,
                      expanded: _surahGridExpanded,
                      onOpenSurah: _openSurah,
                      onToggle: _toggleSurahGridExpanded,
                    ),
                  ),
                ),
                _FlowSectionHeader(label: l.hifzStatsSection),
                _PageContentSliver(
                  child: _DataSection<HifzSectionData>(
                    refreshToken: refreshToken,
                    load: _repository.getHifzData,
                    placeholderHeight: 350,
                    builder: (context, data) => _StatisticsHifz(
                      data: data,
                      now: widget.previewNow,
                      expanded: _surahGridExpanded,
                      onToggle: _toggleSurahGridExpanded,
                    ),
                  ),
                ),
                _FlowSectionHeader(label: l.tasbihAndDuas),
                _PageContentSliver(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RangeAwareSection<TasbihStatsData>(
                          refreshToken: refreshToken,
                          rangeListenable: _rangeNotifier,
                          load: _repository.tasbih,
                          placeholderHeight: 280,
                          builder: (context, data) =>
                              _StatisticsTasbih(data: data),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RangeAwareSection<DuasStatsData>(
                          refreshToken: refreshToken,
                          rangeListenable: _rangeNotifier,
                          load: _repository.duas,
                          placeholderHeight: 280,
                          builder: (context, data) =>
                              _StatisticsDuas(data: data),
                        ),
                      ),
                    ],
                  ),
                ),
                _FlowSectionHeader(label: l.activityHistory),
                _PageContentSliver(
                  child: _MonthlyActivitySection(
                    refreshToken: refreshToken,
                    repository: _repository,
                    now: widget.previewNow,
                  ),
                ),
                _FlowSectionHeader(label: l.streaksLabel),
                _PageContentSliver(
                  bottomPadding: 32,
                  child: _DataSection<StreakStats>(
                    refreshToken: refreshToken,
                    load: _repository.streaks,
                    placeholderHeight: 280,
                    builder: (context, data) => _StatisticsStreaks(data: data),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HifzSectionData {
  final int totalMemorized;
  final int totalReviews;
  final int currentStreak;
  final double retentionRate; // 0.0 to 1.0
  final HifzEntry? nextDueEntry; // null if none due
  final Map<int, int> masteredPerSurah;
  // key: surah number, value: mastered ayah count

  const HifzSectionData({
    required this.totalMemorized,
    required this.totalReviews,
    required this.currentStreak,
    required this.retentionRate,
    required this.nextDueEntry,
    required this.masteredPerSurah,
  });
}

class StatisticsRepository {
  final Map<String, Future<OverviewStats>> _overviewCache =
      <String, Future<OverviewStats>>{};
  final Map<String, Future<QuranStatsData>> _quranCache =
      <String, Future<QuranStatsData>>{};
  final Map<StatRange, Future<TasbihStatsData>> _tasbihCache =
      <StatRange, Future<TasbihStatsData>>{};
  final Map<StatRange, Future<DuasStatsData>> _duasCache =
      <StatRange, Future<DuasStatsData>>{};
  final Map<StatRange, Future<SalahSectionData>> _salahCache =
      <StatRange, Future<SalahSectionData>>{};
  final Map<String, Future<MonthlyActivityData>> _monthlyActivityCache =
      <String, Future<MonthlyActivityData>>{};
  final Map<StatRange, Future<StreakStats>> _streakCache =
      <StatRange, Future<StreakStats>>{};
  Future<HifzSectionData>? _hifzCache;

  void clearCache() {
    _overviewCache.clear();
    _quranCache.clear();
    _tasbihCache.clear();
    _duasCache.clear();
    _salahCache.clear();
    _monthlyActivityCache.clear();
    _streakCache.clear();
    _hifzCache = null;
  }

  Future<HifzSectionData> getHifzData() {
    return _hifzCache ??= (() async {
      final entries = HifzDB.getAllEntries();
      final mastered = entries.where((e) => e.status == 'mastered').length;
      final totalReviews = HifzDB.getLogsForRange(
        DateTime(2000),
        DateTime.now(),
      ).length;
      final retention = HifzDB.getRetentionRate();
      // Find the next due ayah across all units
      // in sequential order (lowest sequenceIndex
      // of the unit with earliest dueDate)
      HifzEntry? nextDue;
      for (final unit in HifzDB.getActiveUnits()) {
        final candidate = _nextDueForUnit(unit);
        if (candidate != null) {
          if (nextDue == null || candidate.dueDate.isBefore(nextDue.dueDate)) {
            nextDue = candidate;
          }
        }
      }

      final masteredMap = HifzDB.getMasteredPerSurah();
      final streak = _computeHifzStreak();

      return HifzSectionData(
        totalMemorized: mastered,
        totalReviews: totalReviews,
        currentStreak: streak,
        retentionRate: retention,
        nextDueEntry: nextDue,
        masteredPerSurah: masteredMap,
      );
    })();
  }

  HifzEntry? _nextDueForUnit(HifzUnit unit) {
    final sabqi = HifzDB.getSabqiAyahs(unit.id);
    if (sabqi.isNotEmpty) return sabqi.first;

    final manzil = HifzDB.getManzilAyahs(unit.id);
    if (manzil.isNotEmpty) return manzil.first;

    final newAyahs = HifzDB.getNewAyahsForUnit(unit.id, 1);
    if (newAyahs.isNotEmpty) return newAyahs.first;

    return null;
  }

  int _computeHifzStreak() {
    // Count consecutive days (going back from today)
    // where HifzDB.hasActivityOnDate returns true
    int streak = 0;
    DateTime day = _getShiftedNow();
    while (HifzDB.hasActivityOnDate(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<OverviewStats> overview(AppLocalizations localizations) {
    final String cacheKey = localizations.localeName;
    return _overviewCache.putIfAbsent(cacheKey, () async {
      final DateTime now = _getShiftedNow();
      final String todayKey = _dateKey(now);
      final Map<String, QuranActivityDay> quranDays = _quranDaysByDate();
      final List<DhikrSessionEntry> sessions = _dhikrSessions();
      final List<DuaInteractionEntry> duaViews = _duaInteractions();
      final List<SalahLogEntry> salahLogs = _salahLogs();
      final bool prayerTrackingEnabled = _prayerTrackingEnabled();
      final SalahLogEntry todaySalah =
          await SalahLogDB().getEntry(todayKey) ??
          SalahLogEntry(date: todayKey);
      final int quranAyahs = _dayAyahCount(quranDays[todayKey]);
      final int tasbihCount = sessions
          .where((entry) => _dateKey(_dhikrDate(entry)) == todayKey)
          .fold<int>(0, (sum, entry) => sum + entry.count);
      final int duasViewed = duaViews
          .where((entry) => entry.dateKey == todayKey)
          .fold<int>(0, (sum, entry) => sum + entry.count);
      final int salahPrayersToday = prayerTrackingEnabled
          ? _loggedPrayerCount(todaySalah)
          : 0;
      final int dailyGoal = _dailyGoal();
      final List<double> progressParts = <double>[
        (quranAyahs / dailyGoal).clamp(0.0, 1.0),
        (tasbihCount / 100).clamp(0.0, 1.0),
        duasViewed > 0 ? 1.0 : 0.0,
        if (prayerTrackingEnabled) (salahPrayersToday / 5).clamp(0.0, 1.0),
      ];
      final double progress =
          progressParts.fold<double>(0, (sum, value) => sum + value) /
          progressParts.length;
      final StreakStats streakStats = _buildStreaks(
        quranDays.values.toList(growable: false),
        sessions,
        duaViews,
        salahLogs,
        now,
      );
      return OverviewStats(
        quranAyahs: quranAyahs,
        tasbihCount: tasbihCount,
        duasViewed: duasViewed,
        prayerTrackingEnabled: prayerTrackingEnabled,
        salahPrayersToday: salahPrayersToday,
        todaySalahEntry: todaySalah,
        quranGoalProgress: (quranAyahs / dailyGoal).clamp(0.0, 1.0),
        progress: progress,
        motivation: _worshipMotivation(localizations, progress),
        highestStreak: streakStats.highest,
      );
    });
  }

  Future<QuranStatsData> quranStats(
    StatRange range,
    AppLocalizations localizations,
  ) {
    final String cacheKey = '${range.name}:${localizations.localeName}';
    return _quranCache.putIfAbsent(cacheKey, () async {
      final DateTime now = _getShiftedNow();
      final List<QuranActivityDay> activityDays = _quranDays();
      final Map<String, QuranActivityDay> byDate = <String, QuranActivityDay>{
        for (final QuranActivityDay day in activityDays) day.dateKey: day,
      };
      final int totalAyahs = activityDays.fold<int>(
        0,
        (sum, day) => sum + _dayAyahCount(day),
      );
      final int totalLetters = _estimatedLettersRead(activityDays);
      final Map<int, int> surahCounts = _surahCounts(activityDays);
      final MapEntry<int, int>? mostRead = surahCounts.entries.isEmpty
          ? null
          : surahCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final int? mostActiveWeekday = _mostActiveWeekday(
        activityDays
            .map(
              (day) => ActivityDayCount(
                date: _activityDayDate(day),
                count: _dayAyahCount(day),
              ),
            )
            .toList(growable: false),
      );
      final Map<int, Set<int>> ayahsBySurah = _readAyahsBySurah(activityDays);
      final Map<int, int> surahVisitCounts = _surahVisitCounts(activityDays);
      return QuranStatsData(
        buckets: _quranBuckets(range, byDate, now, localizations),
        totalAyahs: totalAyahs,
        totalLetters: totalLetters,
        activeDays: activityDays.where(hasQuranReadingActivity).length,
        mostActiveWeekday: mostActiveWeekday,
        mostReadSurah: mostRead?.key,
        mostReadSurahAyahs: mostRead?.value ?? 0,
        insights: _buildInsights(
          activityDays: activityDays,
          activityByDate: byDate,
          now: now,
          surahVisitCounts: surahVisitCounts,
          localizations: localizations,
        ),
        completedSurahs: _completedSurahs(ayahsBySurah),
        khatmCompletionDates: _khatmCompletionDates(activityDays),
      );
    });
  }

  Future<TasbihStatsData> tasbih(StatRange range) {
    return _tasbihCache.putIfAbsent(range, () async {
      final DateTime now = _getShiftedNow();
      final List<DhikrSessionEntry> sessions = _dhikrSessions()
          .where((entry) => _inRange(_dhikrDate(entry), range, now))
          .toList(growable: false);
      final int total = sessions.fold<int>(
        0,
        (sum, entry) => sum + entry.count,
      );
      final Set<String> activeDays = sessions
          .where((entry) => entry.count > 0)
          .map((entry) => _dateKey(_dhikrDate(entry)))
          .toSet();
      final Map<String, int> labelCounts = <String, int>{};
      for (final DhikrSessionEntry session in sessions) {
        final String label = session.label.trim().isEmpty
            ? ''
            : session.label.trim();
        labelCounts[label] = (labelCounts[label] ?? 0) + session.count;
      }
      final MapEntry<String, int>? mostRecited = labelCounts.entries.isEmpty
          ? null
          : labelCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      return TasbihStatsData(
        hasData: sessions.isNotEmpty,
        totalDhikr: total,
        dailyAverage: activeDays.isEmpty ? 0 : total / activeDays.length,
        activeDays: activeDays.length,
        mostRecitedName: mostRecited?.key ?? '',
        mostRecitedCount: mostRecited?.value ?? 0,
      );
    });
  }

  Future<DuasStatsData> duas(StatRange range) {
    return _duasCache.putIfAbsent(range, () async {
      final DateTime now = _getShiftedNow();
      final List<DuaInteractionEntry> interactions = _duaInteractions()
          .where((entry) => _inRange(entry.date, range, now))
          .toList(growable: false);
      final int viewed = interactions.fold<int>(
        0,
        (sum, entry) => sum + entry.count,
      );
      final Map<String, _DuaCategoryCount> categoryCounts =
          <String, _DuaCategoryCount>{};
      for (final DuaInteractionEntry interaction in interactions) {
        final _DuaCategoryCount existing =
            categoryCounts[interaction.categoryId] ??
            _DuaCategoryCount(title: interaction.categoryTitle, count: 0);
        categoryCounts[interaction.categoryId] = _DuaCategoryCount(
          title: existing.title,
          count: existing.count + interaction.count,
        );
      }
      final MapEntry<String, _DuaCategoryCount>? mostViewedEntry =
          categoryCounts.entries.isEmpty
          ? null
          : categoryCounts.entries.reduce(
              (a, b) => a.value.count >= b.value.count ? a : b,
            );
      final _DuaCategoryCount? mostViewed = mostViewedEntry?.value;
      final String? mostViewedId = mostViewedEntry?.key;
      final int favourites = DuaFavouritesDB().length;
      return DuasStatsData(
        hasData: viewed > 0 || favourites > 0,
        viewedCount: viewed,
        favouriteCount: favourites,
        mostViewedCategory: mostViewed?.title ?? '',
        mostViewedCategoryCount: mostViewed?.count ?? 0,
        mostViewedCategoryId: mostViewedId,
      );
    });
  }

  Future<SalahSectionData> getSalahData(StatRange range) {
    return _salahCache.putIfAbsent(range, () async {
      final DateTime now = _getShiftedNow();
      final String todayKey = _dateKey(now);
      final bool enabled = _prayerTrackingEnabled();
      final SalahLogEntry todayEntry =
          await SalahLogDB().getEntry(todayKey) ??
          SalahLogEntry(date: todayKey);
      if (!enabled) {
        return SalahSectionData.disabled(todayEntry: todayEntry);
      }

      final List<SalahLogEntry> allLogs = _salahLogs();
      final DateTime rangeStart = _salahRangeStart(range, now, allLogs);
      final List<SalahLogEntry> rangeLogs = await SalahLogDB().getRange(
        rangeStart,
        now,
      );
      final DateTime weekStart = _weekStart(now);
      final List<SalahLogEntry> weekLogs = await SalahLogDB().getRange(
        weekStart,
        now,
      );
      final List<SalahPrayerStats> prayerStats = <SalahPrayerStats>[
        for (final SalahPrayer prayer in SalahPrayer.values)
          _salahPrayerStats(prayer, rangeLogs),
      ];
      final List<SalahPrayerStats> loggedStats = prayerStats
          .where((stats) => stats.loggedCount > 0)
          .toList(growable: false);
      final SalahPrayerStats? bestPrayer = loggedStats.isEmpty
          ? null
          : loggedStats.reduce((a, b) => a.onTimeRate >= b.onTimeRate ? a : b);

      return SalahSectionData(
        enabled: true,
        todayEntry: todayEntry,
        prayedToday: _loggedPrayerCount(todayEntry),
        onTimeThisWeek: _salahStatusTotal(weekLogs, SalahStatus.onTime),
        lateThisWeek: _salahStatusTotal(weekLogs, SalahStatus.late),
        bestPrayer: bestPrayer?.prayer,
        fajrStreak: _fajrOnTimeStreak(allLogs, now),
        prayerStats: prayerStats,
      );
    });
  }

  Future<MonthlyActivityData> monthlyActivity(int year, int month) {
    final DateTime monthStart = DateTime(year, month);
    final String cacheKey = _monthCacheKey(monthStart.year, monthStart.month);
    return _monthlyActivityCache.putIfAbsent(cacheKey, () async {
      final Map<String, QuranActivityDay> quranDays = _quranDaysByDate();
      final Map<String, int> tasbihByDate = _tasbihCountsByDate(
        _dhikrSessions(),
      );
      final Map<String, int> duasByDate = _duaCountsByDate(_duaInteractions());
      final Map<String, int> salahByDate = _salahCountsByDate(_salahLogs());
      final int daysInMonth = DateTime(
        monthStart.year,
        monthStart.month + 1,
        0,
      ).day;
      final Map<int, MonthlyActivityDay> days = <int, MonthlyActivityDay>{};
      for (int day = 1; day <= daysInMonth; day++) {
        final DateTime date = DateTime(monthStart.year, monthStart.month, day);
        days[day] = _monthlyActivityDay(
          date,
          quranDays,
          tasbihByDate,
          duasByDate,
          salahByDate,
        );
      }
      return MonthlyActivityData(month: monthStart, days: days);
    });
  }

  Future<Map<int, int>> getMonthlyCellData(int year, int month) async {
    final MonthlyActivityData activity = await monthlyActivity(year, month);
    return <int, int>{
      for (final MapEntry<int, MonthlyActivityDay> entry
          in activity.days.entries)
        entry.key: entry.value.total,
    };
  }

  Future<StreakStats> streaks() {
    return _streakCache.putIfAbsent(StatRange.allTime, () async {
      return _buildStreaks(
        _quranDays(),
        _dhikrSessions(),
        _duaInteractions(),
        _salahLogs(),
        _getShiftedNow(),
      );
    });
  }

  List<QuranActivityDay> _quranDays() {
    return QuranActivityDB().box.values.whereType<QuranActivityDay>().toList(
      growable: false,
    );
  }

  Map<String, QuranActivityDay> _quranDaysByDate() {
    return <String, QuranActivityDay>{
      for (final QuranActivityDay day in _quranDays()) day.dateKey: day,
    };
  }

  List<DhikrSessionEntry> _dhikrSessions() {
    return DhikrSessionsDB().box.values.whereType<DhikrSessionEntry>().toList(
      growable: false,
    );
  }

  List<DuaInteractionEntry> _duaInteractions() {
    return DuaInteractionsDB().box.values
        .map(DuaInteractionEntry.fromStored)
        .whereType<DuaInteractionEntry>()
        .toList(growable: false);
  }

  List<SalahLogEntry> _salahLogs() {
    return SalahLogDB().box.values
        .map(SalahLogEntry.fromStored)
        .whereType<SalahLogEntry>()
        .toList(growable: false);
  }
}

class _PageContentSliver extends StatelessWidget {
  const _PageContentSliver({
    required this.child,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final Widget child;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        EquranSpacing.pagePadding,
        topPadding,
        EquranSpacing.pagePadding,
        bottomPadding,
      ),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}

class _DataSection<T> extends StatefulWidget {
  const _DataSection({
    required this.refreshToken,
    required this.load,
    required this.builder,
    required this.placeholderHeight,
  });

  final int refreshToken;
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final double placeholderHeight;

  @override
  State<_DataSection<T>> createState() => _DataSectionState<T>();
}

class _DataSectionState<T> extends State<_DataSection<T>> {
  T? _data;
  Future<T>? _pending;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _DataSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.load != widget.load) {
      _load();
    }
  }

  void _load() {
    final Future<T> pending = widget.load();
    _pending = pending;
    setState(() => _loading = true);
    pending.then(
      (T value) {
        if (!mounted || _pending != pending) return;
        setState(() {
          _data = value;
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted || _pending != pending) return;
        setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final T? data = _data;
    if (data == null) {
      return _ShimmerPlaceholder(height: widget.placeholderHeight);
    }
    return _LoadingOverlay(
      loading: _loading,
      child: widget.builder(context, data),
    );
  }
}

class _RangeAwareSection<T> extends StatefulWidget {
  const _RangeAwareSection({
    required this.refreshToken,
    required this.rangeListenable,
    required this.load,
    required this.builder,
    required this.placeholderHeight,
  });

  final int refreshToken;
  final ValueNotifier<StatRange> rangeListenable;
  final Future<T> Function(StatRange range) load;
  final Widget Function(BuildContext context, T data) builder;
  final double placeholderHeight;

  @override
  State<_RangeAwareSection<T>> createState() => _RangeAwareSectionState<T>();
}

class _RangeAwareSectionState<T> extends State<_RangeAwareSection<T>> {
  T? _data;
  Future<T>? _pending;
  late StatRange _range;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _range = widget.rangeListenable.value;
    widget.rangeListenable.addListener(_handleRangeChanged);
    _load(_range);
  }

  @override
  void didUpdateWidget(covariant _RangeAwareSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rangeListenable != widget.rangeListenable) {
      oldWidget.rangeListenable.removeListener(_handleRangeChanged);
      widget.rangeListenable.addListener(_handleRangeChanged);
      _range = widget.rangeListenable.value;
      _load(_range);
      return;
    }
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.load != widget.load) {
      _load(_range);
    }
  }

  @override
  void dispose() {
    widget.rangeListenable.removeListener(_handleRangeChanged);
    super.dispose();
  }

  void _handleRangeChanged() {
    _range = widget.rangeListenable.value;
    _load(_range);
  }

  void _load(StatRange range) {
    final Future<T> pending = widget.load(range);
    _pending = pending;
    setState(() => _loading = true);
    pending.then(
      (T value) {
        if (!mounted || _pending != pending) return;
        setState(() {
          _data = value;
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted || _pending != pending) return;
        setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final T? data = _data;
    if (data == null) {
      return _ShimmerPlaceholder(height: widget.placeholderHeight);
    }
    return _LoadingOverlay(
      loading: _loading,
      child: widget.builder(context, data),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.loading, required this.child});

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!loading) return child;
    final EquranColors colors = context.equranColors;
    return Stack(
      children: <Widget>[
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: colors.background.withAlpha(128),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SalahSectionHost extends StatelessWidget {
  const _SalahSectionHost({
    required this.data,
    required this.optInDismissed,
    required this.onEnable,
    required this.onMaybeLater,
    required this.onLogSaved,
    this.now,
  });

  final SalahSectionData data;
  final bool optInDismissed;
  final Future<void> Function() onEnable;
  final VoidCallback onMaybeLater;
  final VoidCallback onLogSaved;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: data.enabled
          ? _SalahSection(
              key: const ValueKey<String>('salah-section'),
              data: data,
              onLogSaved: onLogSaved,
              now: now,
            )
          : optInDismissed
          ? _PrayerTrackingMiniEnable(
              key: const ValueKey<String>('salah-mini-enable'),
              onEnable: onEnable,
            )
          : _PrayerTrackingOptInCard(
              key: const ValueKey<String>('salah-opt-in'),
              onEnable: onEnable,
              onMaybeLater: onMaybeLater,
            ),
    );
  }
}

class _PrayerTrackingOptInCard extends StatelessWidget {
  const _PrayerTrackingOptInCard({
    super.key,
    required this.onEnable,
    required this.onMaybeLater,
  });

  final Future<void> Function() onEnable;
  final VoidCallback onMaybeLater;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.equranTokens.hair),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.equranTokens.emWash,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mosque_rounded,
                  color: context.equranTokens.emText,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.trackYourDailyPrayers,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.trackYourDailyPrayersDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            _PrimaryPillButton(
              label: localizations.enablePrayerTracking,
              onPressed: onEnable,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onMaybeLater,
              style: TextButton.styleFrom(
                foregroundColor: context.equranTokens.muted,
                textStyle: theme.textTheme.bodySmall,
              ),
              child: Text(localizations.maybeLater),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTrackingMiniEnable extends StatelessWidget {
  const _PrayerTrackingMiniEnable({super.key, required this.onEnable});

  final Future<void> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    return Center(
      child: TextButton(
        onPressed: onEnable,
        style: TextButton.styleFrom(
          foregroundColor: context.equranTokens.muted,
          textStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(localizations.enablePrayerTrackingLabel),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.onPressed});

  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppRadii.pill);
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: context.equranTokens.filled,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalahLogAvailability {
  const _SalahLogAvailability({
    required this.unlockTimes,
    required this.use24HourFormat,
  });

  const _SalahLogAvailability.unrestricted({required this.use24HourFormat})
    : unlockTimes = const <SalahPrayer, DateTime>{};

  final Map<SalahPrayer, DateTime> unlockTimes;
  final bool use24HourFormat;

  bool isLoggable(SalahPrayer prayer, {DateTime? now}) {
    final DateTime? unlockTime = unlockTimes[prayer];
    if (unlockTime == null) return true;
    return !(now ?? DateTime.now()).isBefore(unlockTime);
  }

  String? unlockLabelFor(SalahPrayer prayer) {
    final DateTime? unlockTime = unlockTimes[prayer];
    if (unlockTime == null) return null;
    return _formatSalahLogTime(unlockTime, use24HourFormat);
  }
}

class _SalahLogSheetResult {
  const _SalahLogSheetResult({required this.removedUnavailableStatuses});

  final bool removedUnavailableStatuses;
}

class _SanitizedSalahLog {
  const _SanitizedSalahLog({
    required this.entry,
    required this.removedUnavailableStatuses,
  });

  final SalahLogEntry entry;
  final bool removedUnavailableStatuses;
}

_SalahLogAvailability _salahLogAvailabilityForNow({DateTime? now}) {
  final DateTime effectiveNow = now ?? DateTime.now();
  final PrayerSettingsStore store = PrayerSettingsStore();
  final prayer_models.PrayerTimeSettings settings = store.getSettings();
  final prayer_models.PrayerLocation? location = store.getLocation();
  if (location == null) {
    return _SalahLogAvailability.unrestricted(
      use24HourFormat: settings.use24HourFormat,
    );
  }

  final PrayerTimesService service = const PrayerTimesService();
  final DateTime today = service.calendarDateForInstant(
    instant: effectiveNow,
    location: location,
    settings: settings,
  );
  final prayer_models.PrayerDay day = service.calculateDay(
    date: today,
    location: location,
    settings: settings,
  );

  return _SalahLogAvailability(
    use24HourFormat: settings.use24HourFormat,
    unlockTimes: <SalahPrayer, DateTime>{
      for (final SalahPrayer salahPrayer in SalahPrayer.values)
        salahPrayer: day.entryFor(_prayerTimeKindFor(salahPrayer)).time,
    },
  );
}

_SanitizedSalahLog _sanitizeSalahLogEntry(
  SalahLogEntry entry, {
  required _SalahLogAvailability availability,
}) {
  bool removedUnavailableStatuses = false;
  SalahLogEntry sanitized = SalahLogEntry(date: entry.date);
  for (final SalahPrayer prayer in SalahPrayer.values) {
    final SalahStatus status = prayer.statusFor(entry);
    final bool unavailableStatus =
        status != SalahStatus.unlogged && !availability.isLoggable(prayer);
    if (unavailableStatus) {
      removedUnavailableStatuses = true;
    }
    sanitized = prayer.updateEntry(
      sanitized,
      unavailableStatus ? SalahStatus.unlogged : status,
    );
  }
  return _SanitizedSalahLog(
    entry: sanitized,
    removedUnavailableStatuses: removedUnavailableStatuses,
  );
}

prayer_models.PrayerTimeKind _prayerTimeKindFor(SalahPrayer prayer) {
  return switch (prayer) {
    SalahPrayer.fajr => prayer_models.PrayerTimeKind.fajr,
    SalahPrayer.dhuhr => prayer_models.PrayerTimeKind.dhuhr,
    SalahPrayer.asr => prayer_models.PrayerTimeKind.asr,
    SalahPrayer.maghrib => prayer_models.PrayerTimeKind.maghrib,
    SalahPrayer.isha => prayer_models.PrayerTimeKind.isha,
  };
}

String _formatSalahLogTime(DateTime time, bool use24HourFormat) {
  final int hour = time.hour;
  final int minute = time.minute;
  if (use24HourFormat) {
    return '${_twoDigits(hour)}:${_twoDigits(minute)}';
  }

  final String lang =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final String period = switch (lang) {
    'ar' => hour >= 12 ? 'م' : 'ص',
    'fa' => hour >= 12 ? 'ب.ظ' : 'ق.ظ',
    'ur' => hour >= 12 ? 'ش' : 'ص',
    _ => hour >= 12 ? 'PM' : 'AM',
  };
  final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${_twoDigits(minute)} $period';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _salahStatusLabel(AppLocalizations localizations, SalahStatus status) {
  return switch (status) {
    SalahStatus.onTime => localizations.onTime,
    SalahStatus.late => localizations.late,
    SalahStatus.notPrayed => localizations.missed,
    SalahStatus.unlogged => localizations.log,
  };
}

String _salahPrayerLabel(AppLocalizations localizations, SalahPrayer prayer) {
  return switch (prayer) {
    SalahPrayer.fajr => localizations.fajr,
    SalahPrayer.dhuhr => localizations.dhuhr,
    SalahPrayer.asr => localizations.asr,
    SalahPrayer.maghrib => localizations.maghrib,
    SalahPrayer.isha => localizations.isha,
  };
}

class _SalahSection extends StatelessWidget {
  const _SalahSection({
    super.key,
    required this.data,
    required this.onLogSaved,
    this.now,
  });

  final SalahSectionData data;
  final VoidCallback onLogSaved;
  final DateTime? now;

  /// Opens the sheet for one prayer only. Tapping a status saves that prayer
  /// alone; the other four entries are kept as they are in storage.
  Future<void> _openPrayerSheet(
    BuildContext context,
    SalahPrayer prayer,
  ) async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String dateKey = data.todayEntry.date;
    final _SalahLogSheetResult? result =
        await showModalBottomSheet<_SalahLogSheetResult>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => _SalahPrayerSheet(
            prayer: prayer,
            dateKey: dateKey,
            initialStatus: prayer.statusFor(data.todayEntry),
            availability: _salahLogAvailabilityForNow(),
            onSelected: (status) => _savePrayerStatus(
              prayer: prayer,
              status: status,
              dateKey: dateKey,
            ),
          ),
        );
    if (result == null || !context.mounted) return;
    final EquranColors colors = context.equranColors;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (result.removedUnavailableStatuses) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: colors.warningSurface,
          duration: const Duration(seconds: 3),
          content: Text(
            localizations.somePrayersNotYetAvailable,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.warning, fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: colors.primary,
        content: Row(
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: colors.onPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              localizations.prayerLogSaved,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Writes one prayer's status. The entry is read fresh from storage so a
  /// save never overwrites the other prayers with stale values.
  Future<_SalahLogSheetResult> _savePrayerStatus({
    required SalahPrayer prayer,
    required SalahStatus status,
    required String dateKey,
  }) async {
    final SalahLogEntry current =
        await SalahLogDB().getEntry(dateKey) ?? SalahLogEntry(date: dateKey);
    final _SanitizedSalahLog sanitized = _sanitizeSalahLogEntry(
      prayer.updateEntry(current, status),
      availability: _salahLogAvailabilityForNow(),
    );
    await SalahLogDB().saveEntry(sanitized.entry);
    onLogSaved();
    return _SalahLogSheetResult(
      removedUnavailableStatuses: sanitized.removedUnavailableStatuses,
    );
  }

  @override
  Widget build(BuildContext context) => _StatisticsPrayer(
    data: data,
    now: now,
    onPrayerTap: (prayer) => _openPrayerSheet(context, prayer),
  );
}

/// A single prayer's status choice for today. Choosing a status saves it and
/// closes the sheet; the other prayers are not shown or changed here.
class _SalahPrayerSheet extends StatefulWidget {
  const _SalahPrayerSheet({
    required this.prayer,
    required this.dateKey,
    required this.initialStatus,
    required this.availability,
    required this.onSelected,
  });

  final SalahPrayer prayer;
  final String dateKey;
  final SalahStatus initialStatus;
  final _SalahLogAvailability availability;
  final Future<_SalahLogSheetResult> Function(SalahStatus status) onSelected;

  @override
  State<_SalahPrayerSheet> createState() => _SalahPrayerSheetState();
}

class _SalahPrayerSheetState extends State<_SalahPrayerSheet> {
  bool _saving = false;

  Future<void> _select(SalahStatus status) async {
    if (_saving) return;
    setState(() => _saving = true);
    final _SalahLogSheetResult result = await widget.onSelected(status);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    final bool loggable = widget.availability.isLoggable(widget.prayer);
    final bool hasSavedStatus = widget.initialStatus != SalahStatus.unlogged;
    final String? unlockLabel = widget.availability.unlockLabelFor(
      widget.prayer,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: const SizedBox(width: 32, height: 4),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _salahPrayerLabel(localizations, widget.prayer),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateChipLabel(DateTime.parse(widget.dateKey), localizations),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                if (!loggable)
                  Column(
                    children: <Widget>[
                      if (unlockLabel != null)
                        Text(
                          localizations.availableAfter(unlockLabel),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (hasSavedStatus) ...<Widget>[
                        const SizedBox(height: 12),
                        Center(
                          child: _SalahReadOnlyStatusChip(
                            status: widget.initialStatus,
                          ),
                        ),
                      ],
                    ],
                  )
                else ...<Widget>[
                  IgnorePointer(
                    ignoring: _saving,
                    child: Row(
                      children: <Widget>[
                        for (final SalahStatus status in const <SalahStatus>[
                          SalahStatus.onTime,
                          SalahStatus.late,
                          SalahStatus.notPrayed,
                        ]) ...<Widget>[
                          if (status != SalahStatus.onTime)
                            const SizedBox(width: 8),
                          Expanded(
                            child: _SalahStatusButton(
                              status: status,
                              selected: widget.initialStatus == status,
                              onTap: () => _select(status),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasSavedStatus)
                    Align(
                      alignment: AlignmentDirectional.center,
                      child: TextButton(
                        onPressed: _saving
                            ? null
                            : () => _select(SalahStatus.unlogged),
                        style: TextButton.styleFrom(
                          foregroundColor: context.equranTokens.muted,
                          textStyle: theme.textTheme.bodySmall,
                        ),
                        child: Text(localizations.clear),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SalahReadOnlyStatusChip extends StatelessWidget {
  const _SalahReadOnlyStatusChip({required this.status});

  final SalahStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ColorScheme colorScheme = theme.colorScheme;
    final EquranColors colors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(AppRadii.pill);
    final IconData? icon = _salahStatusIcon(status);
    final bool notPrayed = status == SalahStatus.notPrayed;
    final Color foreground = _salahStatusColor(colorScheme, colors, status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _salahStatusBackground(colorScheme, colors, status),
        borderRadius: radius,
        border: Border.all(
          color: notPrayed ? colorScheme.error : colors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(
              _salahStatusLabel(localizations, status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalahStatusButton extends StatelessWidget {
  const _SalahStatusButton({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final SalahStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ColorScheme colorScheme = theme.colorScheme;
    final EquranColors colors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(AppRadii.pill);
    final IconData? icon = selected ? _salahStatusIcon(status) : null;
    final Color background = selected
        ? switch (status) {
            SalahStatus.onTime => colors.primary,
            SalahStatus.late => colors.goldSoft,
            SalahStatus.notPrayed => colorScheme.error,
            SalahStatus.unlogged => colors.surfaceAlt,
          }
        : colors.surfaceAlt;
    final Color foreground = selected
        ? switch (status) {
            SalahStatus.onTime => colors.onPrimary,
            SalahStatus.late => colors.warning,
            SalahStatus.notPrayed => colorScheme.onError,
            SalahStatus.unlogged => colors.textMuted,
          }
        : colors.textMuted;
    final Color? borderColor = selected
        ? switch (status) {
            SalahStatus.late => colors.accentGold,
            SalahStatus.notPrayed => colorScheme.error,
            _ => null,
          }
        : null;
    return Material(
      color: background,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: borderColor == null ? null : Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 14, color: foreground),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    _salahStatusLabel(localizations, status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.insights});

  final List<InsightData> insights;

  @override
  Widget build(BuildContext context) {
    // Chips wrap onto new lines instead of scrolling sideways, so every
    // insight stays visible on narrow phones.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final InsightData insight in insights)
          _InsightChip(insight: insight),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.insight});

  final InsightData insight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.equranTokens.emWash,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(insight.icon, color: context.equranTokens.emText, size: 16),
            const SizedBox(width: 8),
            Text(
              insight.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.equranTokens.emText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyActivitySection extends StatefulWidget {
  const _MonthlyActivitySection({
    required this.refreshToken,
    required this.repository,
    this.now,
  });

  final int refreshToken;
  final StatisticsRepository repository;
  final DateTime? now;

  @override
  State<_MonthlyActivitySection> createState() =>
      _MonthlyActivitySectionState();
}

class _MonthlyActivitySectionState extends State<_MonthlyActivitySection> {
  static const double _swipeThreshold = 36;

  late DateTime _displayedMonth;
  MonthlyActivityData? _data;
  Future<MonthlyActivityData>? _pending;
  bool _loading = false;
  int _slideDirection = 1;
  double _dragOffset = 0;
  MonthlyActivityDay? _selectedDay;

  @override
  void initState() {
    super.initState();
    _displayedMonth = _monthStart(widget.now ?? DateTime.now());
    _load(notify: false);
  }

  @override
  void didUpdateWidget(covariant _MonthlyActivitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  void _load({bool notify = true}) {
    final Future<MonthlyActivityData> pending = widget.repository
        .monthlyActivity(_displayedMonth.year, _displayedMonth.month);
    _pending = pending;
    if (notify) {
      setState(() => _loading = true);
    } else {
      _loading = true;
    }
    pending.then(
      (MonthlyActivityData value) {
        if (!mounted || _pending != pending) return;
        setState(() {
          _data = value;
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted || _pending != pending) return;
        setState(() => _loading = false);
      },
    );
  }

  void _changeMonth(int monthOffset) {
    if (monthOffset == 0) return;
    final DateTime target = _monthStart(
      DateTime(_displayedMonth.year, _displayedMonth.month + monthOffset),
    );
    if (monthOffset > 0 &&
        (widget.now == null
            ? _isFutureMonth(target)
            : target.isAfter(_monthStart(widget.now!)))) {
      return;
    }
    setState(() {
      _displayedMonth = target;
      _slideDirection = monthOffset > 0 ? 1 : -1;
      _loading = true;
      _selectedDay = null;
    });
    _load(notify: false);
  }

  void _handleDragStart(DragStartDetails _) {
    _dragOffset = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragOffset += details.primaryDelta ?? 0;
  }

  void _handleDragEnd(DragEndDetails _) {
    if (_dragOffset.abs() < _swipeThreshold) return;
    _changeMonth(_dragOffset < 0 ? 1 : -1);
    _dragOffset = 0;
  }

  /// Tapping a day selects it and shows its breakdown inline; tapping the
  /// selected day again clears the selection.
  void _toggleDaySelection(MonthlyActivityDay day) {
    setState(() {
      _selectedDay = _selectedDay?.date == day.date ? null : day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MonthlyActivityData? data = _data;
    if (data == null) {
      return const _ShimmerPlaceholder(height: 360);
    }

    final String targetKey = _monthCacheKey(data.month.year, data.month.month);
    return _LoadingOverlay(
      loading: _loading,
      child: HairlineCard(
        key: const ValueKey('statistics-history'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _MonthlyActivityHeader(
                month: data.month,
                activeDays: data.activeDays,
                onPrevious: () => _changeMonth(-1),
                onNext:
                    (widget.now == null
                        ? _isCurrentMonth(_displayedMonth)
                        : _displayedMonth == _monthStart(widget.now!))
                    ? null
                    : () => _changeMonth(1),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        final bool entering =
                            child.key == ValueKey<String>(targetKey);
                        final double direction = _slideDirection.toDouble();
                        final Animation<Offset> position =
                            Tween<Offset>(
                              begin: Offset(
                                entering ? direction : -direction,
                                0,
                              ),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            );
                        return SlideTransition(
                          position: position,
                          child: child,
                        );
                      },
                  child: _MonthlyActivityBody(
                    key: ValueKey<String>(targetKey),
                    data: data,
                    selectedDay: _selectedDay,
                    onDayTap: _toggleDaySelection,
                    now: widget.now,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyActivityHeader extends StatelessWidget {
  const _MonthlyActivityHeader({
    required this.month,
    required this.activeDays,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final int activeDays;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: localizations.previousMonth,
          onPressed: onPrevious,
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            color: colors.textSecondary,
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _monthYearLabel(month, localizations),
                textAlign: TextAlign.center,
                style: redesignDisplayStyle(context, size: 20),
              ),
              const SizedBox(height: 2),
              _StatsText(
                localizations.activeDaysCount(activeDays),
                size: 12,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: localizations.nextMonth,
          onPressed: onNext,
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            color: onNext == null ? colors.textMuted : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MonthlyActivityBody extends StatelessWidget {
  const _MonthlyActivityBody({
    super.key,
    required this.data,
    required this.selectedDay,
    required this.onDayTap,
    this.now,
  });

  final MonthlyActivityData data;
  final MonthlyActivityDay? selectedDay;
  final ValueChanged<MonthlyActivityDay> onDayTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    final MonthlyActivityDay? selected = selectedDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthlyCalendarGrid(
          data: data,
          selectedDay: selected,
          onDayTap: onDayTap,
          now: now,
        ),
        const SizedBox(height: 14),
        Text(
          _monthlySummaryLabel(data, localizations),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (selected != null) ...<Widget>[
          const SizedBox(height: 14),
          _MonthlyDayDetail(day: selected),
        ],
      ],
    );
  }
}

/// The breakdown for the selected day: one row per activity type.
class _MonthlyDayDetail extends StatelessWidget {
  const _MonthlyDayDetail({required this.day});

  final MonthlyActivityDay day;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final TextStyle? labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    final TextStyle? valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w800,
    );

    Widget row({
      required IconData icon,
      required String label,
      required String value,
      required bool active,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: active ? tokens.emText : tokens.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: labelStyle)),
            Text(value, style: active ? valueStyle : labelStyle),
          ],
        ),
      );
    }

    return DecoratedBox(
      key: const ValueKey<String>('statistics-day-detail'),
      decoration: BoxDecoration(
        color: tokens.emWash,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: tokens.hair2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _dateChipLabel(day.date, l),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            row(
              icon: Icons.menu_book_outlined,
              label: l.quran,
              value: l.ayahsCount(day.quran),
              active: day.quran > 0,
            ),
            row(
              icon: Icons.schedule_outlined,
              label: l.salah,
              value: '${day.salah}/5',
              active: day.salah > 0,
            ),
            row(
              icon: Icons.auto_awesome_outlined,
              label: l.tasbih,
              value: l.dhikrCount(day.tasbih),
              active: day.tasbih > 0,
            ),
            row(
              icon: Icons.auto_stories_outlined,
              label: l.duas,
              value: l.duasCount(day.duas),
              active: day.duas > 0,
            ),
            row(
              icon: Icons.bookmark_outline_rounded,
              label: l.hifzTitle,
              // The monthly data records whether any Hifz work happened.
              value: day.hifz > 0 ? '✓' : '–',
              active: day.hifz > 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyCalendarGrid extends StatelessWidget {
  const _MonthlyCalendarGrid({
    required this.data,
    required this.selectedDay,
    required this.onDayTap,
    this.now,
  });

  final MonthlyActivityData data;
  final MonthlyActivityDay? selectedDay;
  final ValueChanged<MonthlyActivityDay> onDayTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<MonthlyActivityDay?> cells = _monthlyCalendarCells(data);
    final List<String> dayLabels = _weekdayInitials(localizations);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: <Widget>[
              for (final String label in dayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.equranTokens.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final MonthlyActivityDay? day = cells[index];
            final DateTime today = now ?? _getShiftedNow();
            return _MonthlyCalendarCell(
              day: day,
              isToday: day != null && _isSameDate(day.date, today),
              isSelected:
                  day != null &&
                  selectedDay != null &&
                  _isSameDate(day.date, selectedDay!.date),
              isFuture: day != null && day.date.isAfter(today),
              onTap: onDayTap,
            );
          },
        ),
      ],
    );
  }
}

class _MonthlyCalendarCell extends StatelessWidget {
  const _MonthlyCalendarCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.onTap,
  });

  final MonthlyActivityDay? day;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final ValueChanged<MonthlyActivityDay> onTap;

  @override
  Widget build(BuildContext context) {
    final MonthlyActivityDay? activity = day;
    if (activity == null) return const SizedBox.expand();

    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(12);
    final tokens = context.equranTokens;
    final Color background = activity.total == 0
        ? tokens.hair
        : activity.total < 11
        ? Color.alphaBlend(tokens.filled.withValues(alpha: .3), colors.surface)
        : activity.total < 31
        ? Color.alphaBlend(tokens.filled.withValues(alpha: .6), colors.surface)
        : tokens.filled;
    final Color foreground = EquranTokens.ensure(
      tokens.text2,
      against: [background],
      target: 4.5,
      toward: background.computeLuminance() > .5 ? Colors.black : Colors.white,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: isSelected
            ? Border.all(color: tokens.emText, width: 2)
            : isToday
            ? Border.all(color: tokens.gold)
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isFuture ? null : () => onTap(activity),
            child: Center(
              child: Text(
                '${activity.date.day}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OverviewStats {
  const OverviewStats({
    required this.quranAyahs,
    required this.tasbihCount,
    required this.duasViewed,
    required this.prayerTrackingEnabled,
    required this.salahPrayersToday,
    required this.todaySalahEntry,
    required this.quranGoalProgress,
    required this.progress,
    required this.motivation,
    required this.highestStreak,
  });

  final int quranAyahs;
  final int tasbihCount;
  final int duasViewed;
  final bool prayerTrackingEnabled;
  final int salahPrayersToday;
  final SalahLogEntry todaySalahEntry;
  final double quranGoalProgress;
  final double progress;
  final String motivation;
  final int highestStreak;
}

class QuranStatsData {
  const QuranStatsData({
    required this.buckets,
    required this.totalAyahs,
    required this.totalLetters,
    required this.activeDays,
    required this.mostActiveWeekday,
    required this.mostReadSurah,
    required this.mostReadSurahAyahs,
    required this.insights,
    required this.completedSurahs,
    required this.khatmCompletionDates,
  });

  final List<ActivityBucket> buckets;
  final int totalAyahs;
  final int totalLetters;
  final int activeDays;
  final int? mostActiveWeekday;
  final int? mostReadSurah;
  final int mostReadSurahAyahs;
  final List<InsightData> insights;
  final Set<int> completedSurahs;
  final List<DateTime> khatmCompletionDates;
}

class TasbihStatsData {
  const TasbihStatsData({
    required this.hasData,
    required this.totalDhikr,
    required this.dailyAverage,
    required this.activeDays,
    required this.mostRecitedName,
    required this.mostRecitedCount,
  });

  final bool hasData;
  final int totalDhikr;
  final double dailyAverage;
  final int activeDays;
  final String mostRecitedName;
  final int mostRecitedCount;
}

class DuasStatsData {
  const DuasStatsData({
    required this.hasData,
    required this.viewedCount,
    required this.favouriteCount,
    required this.mostViewedCategory,
    required this.mostViewedCategoryCount,
    this.mostViewedCategoryId,
  });

  final bool hasData;
  final int viewedCount;
  final int favouriteCount;
  final String mostViewedCategory;
  final int mostViewedCategoryCount;
  final String? mostViewedCategoryId;
}

class SalahSectionData {
  const SalahSectionData({
    required this.enabled,
    required this.todayEntry,
    required this.prayedToday,
    required this.onTimeThisWeek,
    required this.lateThisWeek,
    required this.bestPrayer,
    required this.fajrStreak,
    required this.prayerStats,
  });

  factory SalahSectionData.disabled({required SalahLogEntry todayEntry}) {
    return SalahSectionData(
      enabled: false,
      todayEntry: todayEntry,
      prayedToday: 0,
      onTimeThisWeek: 0,
      lateThisWeek: 0,
      bestPrayer: null,
      fajrStreak: 0,
      prayerStats: <SalahPrayerStats>[
        for (final SalahPrayer prayer in SalahPrayer.values)
          SalahPrayerStats.empty(prayer),
      ],
    );
  }

  final bool enabled;
  final SalahLogEntry todayEntry;
  final int prayedToday;
  final int onTimeThisWeek;
  final int lateThisWeek;
  final SalahPrayer? bestPrayer;
  final int fajrStreak;
  final List<SalahPrayerStats> prayerStats;

  Map<String, double> get perPrayerOnTimePct {
    return <String, double>{
      for (final SalahPrayerStats stats in prayerStats)
        if (stats.loggedCount > 0) stats.prayer.key: stats.onTimeRate,
    };
  }
}

class SalahPrayerStats {
  const SalahPrayerStats({
    required this.prayer,
    required this.onTimeCount,
    required this.lateCount,
    required this.notPrayedCount,
  });

  factory SalahPrayerStats.empty(SalahPrayer prayer) {
    return SalahPrayerStats(
      prayer: prayer,
      onTimeCount: 0,
      lateCount: 0,
      notPrayedCount: 0,
    );
  }

  final SalahPrayer prayer;
  final int onTimeCount;
  final int lateCount;
  final int notPrayedCount;

  int get loggedCount => onTimeCount + lateCount + notPrayedCount;

  double get onTimeRate => loggedCount == 0 ? 0 : onTimeCount / loggedCount;

  double get lateRate => loggedCount == 0 ? 0 : lateCount / loggedCount;
}

class StreakStats {
  const StreakStats({
    required this.quran,
    required this.tasbih,
    required this.overall,
  });

  final int quran;
  final int tasbih;
  final int overall;

  int get highest => math.max(quran, math.max(tasbih, overall));
}

class MonthlyActivityData {
  const MonthlyActivityData({required this.month, required this.days});

  final DateTime month;
  final Map<int, MonthlyActivityDay> days;

  int get activeDays =>
      days.values.where((MonthlyActivityDay day) => day.total > 0).length;

  int get totalActions => days.values.fold<int>(
    0,
    (int sum, MonthlyActivityDay day) => sum + day.total,
  );

  MonthlyActivityDay? get bestDay {
    final List<MonthlyActivityDay> active = days.values
        .where((MonthlyActivityDay day) => day.total > 0)
        .toList(growable: false);
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.total >= b.total ? a : b);
  }
}

class MonthlyActivityDay {
  const MonthlyActivityDay({
    required this.date,
    required this.quran,
    required this.tasbih,
    required this.duas,
    required this.salah,
    required this.hifz,
  });

  final DateTime date;
  final int quran;
  final int tasbih;
  final int duas;
  final int salah;
  final int hifz;

  int get total => quran + tasbih + duas + salah + hifz;
}

class ActivityBucket {
  const ActivityBucket({
    required this.label,
    required this.detailLabel,
    required this.count,
    required this.isCurrent,
  });

  final String label;
  final String detailLabel;
  final int count;
  final bool isCurrent;
}

class InsightData {
  const InsightData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class ActivityDayCount {
  const ActivityDayCount({required this.date, required this.count});

  final DateTime date;
  final int count;
}

class DuaInteractionEntry {
  const DuaInteractionEntry({
    required this.dateKey,
    required this.categoryId,
    required this.categoryTitle,
    required this.count,
    required this.updatedAt,
  });

  final String dateKey;
  final String categoryId;
  final String categoryTitle;
  final int count;
  final DateTime updatedAt;

  DateTime get date => DateTime.parse(dateKey);

  static DuaInteractionEntry? fromStored(Object? value) {
    if (value is! Map) return null;
    final String? dateKey = _stringOrNull(value['dateKey']);
    final String? categoryId = _stringOrNull(value['categoryId']);
    final String? categoryTitle = _stringOrNull(value['categoryTitle']);
    final int count = _intValue(value['count']);
    final DateTime? updatedAt = _dateTimeOrNull(value['updatedAt']);
    if (dateKey == null ||
        DateTime.tryParse(dateKey) == null ||
        categoryId == null ||
        categoryTitle == null) {
      return null;
    }
    return DuaInteractionEntry(
      dateKey: dateKey,
      categoryId: categoryId,
      categoryTitle: categoryTitle,
      count: count,
      updatedAt: updatedAt ?? DateTime.parse(dateKey),
    );
  }
}

class _ReadAyahRef {
  const _ReadAyahRef({required this.surah, required this.verse});

  final int surah;
  final int verse;

  String get key => '$surah:$verse';
}

class _DuaCategoryCount {
  const _DuaCategoryCount({required this.title, required this.count});

  final String title;
  final int count;
}

MonthlyActivityDay _monthlyActivityDay(
  DateTime date,
  Map<String, QuranActivityDay> quranDays,
  Map<String, int> tasbihByDate,
  Map<String, int> duasByDate,
  Map<String, int> salahByDate,
) {
  final String key = _dateKey(date);
  final bool hasHifz = HifzDB.hasActivityOnDate(date);
  return MonthlyActivityDay(
    date: DateTime(date.year, date.month, date.day),
    quran: _dayAyahCount(quranDays[key]),
    tasbih: tasbihByDate[key] ?? 0,
    duas: duasByDate[key] ?? 0,
    salah: salahByDate[key] ?? 0,
    hifz: hasHifz ? 1 : 0,
  );
}

Map<String, int> _tasbihCountsByDate(List<DhikrSessionEntry> sessions) {
  final Map<String, int> counts = <String, int>{};
  for (final DhikrSessionEntry session in sessions) {
    final String key = _dateKey(_dhikrDate(session));
    counts[key] = (counts[key] ?? 0) + session.count;
  }
  return counts;
}

Map<String, int> _duaCountsByDate(List<DuaInteractionEntry> interactions) {
  final Map<String, int> counts = <String, int>{};
  for (final DuaInteractionEntry interaction in interactions) {
    counts[interaction.dateKey] =
        (counts[interaction.dateKey] ?? 0) + interaction.count;
  }
  return counts;
}

Map<String, int> _salahCountsByDate(List<SalahLogEntry> entries) {
  final Map<String, int> counts = <String, int>{};
  for (final SalahLogEntry entry in entries) {
    final int count = _loggedPrayerCount(entry);
    if (count <= 0) continue;
    counts[entry.date] = (counts[entry.date] ?? 0) + count;
  }
  return counts;
}

StreakStats _buildStreaks(
  List<QuranActivityDay> quranDays,
  List<DhikrSessionEntry> sessions,
  List<DuaInteractionEntry> duaViews,
  List<SalahLogEntry> salahLogs,
  DateTime now,
) {
  final Set<String> quranActiveDays = quranDays
      .where(hasQuranReadingActivity)
      .map((day) => day.dateKey)
      .toSet();
  final Set<String> tasbihActiveDays = sessions
      .where((entry) => entry.count > 0)
      .map((entry) => _dateKey(_dhikrDate(entry)))
      .toSet();
  final Set<String> duaActiveDays = duaViews
      .where((entry) => entry.count > 0)
      .map((entry) => entry.dateKey)
      .toSet();
  final Set<String> salahActiveDays = salahLogs
      .where((entry) => _loggedPrayerCount(entry) > 0)
      .map((entry) => entry.date)
      .toSet();
  return StreakStats(
    quran: _currentStreak(quranActiveDays, now),
    tasbih: _currentStreak(tasbihActiveDays, now),
    overall: _currentStreak(
      <String>{
        ...quranActiveDays,
        ...tasbihActiveDays,
        ...duaActiveDays,
        ...salahActiveDays,
      },
      now,
      includeHifz: true,
    ),
  );
}

int _currentStreak(
  Set<String> activeDays,
  DateTime now, {
  bool includeHifz = false,
}) {
  int streak = 0;
  DateTime cursor = DateTime(now.year, now.month, now.day);
  while (activeDays.contains(_dateKey(cursor)) ||
      (includeHifz && HifzDB.hasActivityOnDate(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

List<ActivityBucket> _quranBuckets(
  StatRange range,
  Map<String, QuranActivityDay> byDate,
  DateTime now,
  AppLocalizations localizations,
) {
  return switch (range) {
    StatRange.week => _quranWeekBuckets(byDate, now, localizations),
    StatRange.month => _quranMonthBuckets(byDate, now, localizations),
    StatRange.year => _quranYearBuckets(byDate, now, localizations),
    StatRange.allTime => _quranAllTimeBuckets(byDate, now),
  };
}

List<ActivityBucket> _quranWeekBuckets(
  Map<String, QuranActivityDay> byDate,
  DateTime now,
  AppLocalizations localizations,
) {
  final List<String> labels = _weekdayInitials(localizations);
  return <ActivityBucket>[
    for (int offset = 6; offset >= 0; offset--)
      _bucketForDates(
        label: labels[now.subtract(Duration(days: offset)).weekday - 1],
        detailLabel: _monthDayLabel(
          now.subtract(Duration(days: offset)),
          localizations,
        ),
        dates: <DateTime>[now.subtract(Duration(days: offset))],
        current: offset == 0,
        byDate: byDate,
      ),
  ];
}

List<ActivityBucket> _quranMonthBuckets(
  Map<String, QuranActivityDay> byDate,
  DateTime now,
  AppLocalizations localizations,
) {
  final DateTime currentWeekStart = _weekStart(now);
  return <ActivityBucket>[
    for (int offset = 3; offset >= 0; offset--)
      _bucketForDates(
        label: localizations.weekShortLabel(4 - offset),
        detailLabel: _dateRangeLabel(
          currentWeekStart.subtract(Duration(days: offset * 7)),
          currentWeekStart
              .subtract(Duration(days: offset * 7))
              .add(const Duration(days: 6)),
          localizations,
        ),
        dates: <DateTime>[
          for (int day = 0; day < 7; day++)
            currentWeekStart
                .subtract(Duration(days: offset * 7))
                .add(Duration(days: day)),
        ],
        current: offset == 0,
        byDate: byDate,
      ),
  ];
}

List<ActivityBucket> _quranYearBuckets(
  Map<String, QuranActivityDay> byDate,
  DateTime now,
  AppLocalizations localizations,
) {
  return <ActivityBucket>[
    for (int offset = 11; offset >= 0; offset--)
      _bucketForMonth(
        DateTime(now.year, now.month - offset),
        byDate,
        now,
        localizations,
      ),
  ];
}

List<ActivityBucket> _quranAllTimeBuckets(
  Map<String, QuranActivityDay> byDate,
  DateTime now,
) {
  final Iterable<DateTime> dates = byDate.values.map(_activityDayDate);
  final int firstYear = dates.isEmpty
      ? now.year
      : dates.map((date) => date.year).reduce(math.min);
  return <ActivityBucket>[
    for (int year = firstYear; year <= now.year; year++)
      _bucketForDates(
        label: '$year',
        detailLabel: '$year',
        dates: <DateTime>[
          for (
            DateTime date = DateTime(year);
            date.year == year;
            date = date.add(const Duration(days: 1))
          )
            date,
        ],
        current: year == now.year,
        byDate: byDate,
      ),
  ];
}

ActivityBucket _bucketForMonth(
  DateTime month,
  Map<String, QuranActivityDay> byDate,
  DateTime now,
  AppLocalizations localizations,
) {
  final DateTime start = DateTime(month.year, month.month);
  final DateTime end = DateTime(month.year, month.month + 1, 0);
  final bool current = month.year == now.year && month.month == now.month;
  return _bucketForDates(
    label: _shortMonthLabel(month, localizations),
    detailLabel: _monthLabel(month, localizations),
    dates: <DateTime>[
      for (int day = 0; day < end.day; day++) start.add(Duration(days: day)),
    ],
    current: current,
    byDate: byDate,
  );
}

ActivityBucket _bucketForDates({
  required String label,
  required String detailLabel,
  required List<DateTime> dates,
  required bool current,
  required Map<String, QuranActivityDay> byDate,
}) {
  int count = 0;
  for (final DateTime date in dates) {
    count += _dayAyahCount(byDate[_dateKey(date)]);
  }
  return ActivityBucket(
    label: label,
    detailLabel: detailLabel,
    count: count,
    isCurrent: current,
  );
}

bool _inRange(DateTime date, StatRange range, DateTime now) {
  final DateTime day = DateTime(date.year, date.month, date.day);
  final DateTime today = DateTime(now.year, now.month, now.day);
  return switch (range) {
    StatRange.week =>
      !day.isBefore(today.subtract(const Duration(days: 6))) &&
          !day.isAfter(today),
    StatRange.month =>
      !day.isBefore(today.subtract(const Duration(days: 29))) &&
          !day.isAfter(today),
    StatRange.year => day.year == today.year,
    StatRange.allTime => true,
  };
}

DateTime _salahRangeStart(
  StatRange range,
  DateTime now,
  List<SalahLogEntry> entries,
) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  return switch (range) {
    StatRange.week => today.subtract(const Duration(days: 6)),
    StatRange.month => today.subtract(const Duration(days: 29)),
    StatRange.year => DateTime(today.year),
    StatRange.allTime =>
      entries.isEmpty
          ? today
          : entries
                .map((entry) => DateTime.parse(entry.date))
                .reduce((a, b) => a.isBefore(b) ? a : b),
  };
}

bool _prayerTrackingEnabled() {
  return SettingsDB().get('prayerTrackingEnabled', defaultValue: false) == true;
}

SalahPrayerStats _salahPrayerStats(
  SalahPrayer prayer,
  List<SalahLogEntry> entries,
) {
  int onTime = 0;
  int late = 0;
  int notPrayed = 0;
  for (final SalahLogEntry entry in entries) {
    switch (prayer.statusFor(entry)) {
      case SalahStatus.onTime:
        onTime++;
        break;
      case SalahStatus.late:
        late++;
        break;
      case SalahStatus.notPrayed:
        notPrayed++;
        break;
      case SalahStatus.unlogged:
        break;
    }
  }
  return SalahPrayerStats(
    prayer: prayer,
    onTimeCount: onTime,
    lateCount: late,
    notPrayedCount: notPrayed,
  );
}

int _salahStatusTotal(List<SalahLogEntry> entries, SalahStatus status) {
  int total = 0;
  for (final SalahLogEntry entry in entries) {
    for (final SalahPrayer prayer in SalahPrayer.values) {
      if (prayer.statusFor(entry) == status) total++;
    }
  }
  return total;
}

int _loggedPrayerCount(SalahLogEntry? entry) {
  if (entry == null) return 0;
  int total = 0;
  for (final SalahPrayer prayer in SalahPrayer.values) {
    if (prayer.statusFor(entry).countsAsPrayer) total++;
  }
  return total;
}

int _fajrOnTimeStreak(List<SalahLogEntry> entries, DateTime now) {
  final Map<String, SalahLogEntry> byDate = <String, SalahLogEntry>{
    for (final SalahLogEntry entry in entries) entry.date: entry,
  };
  int streak = 0;
  DateTime cursor = DateTime(now.year, now.month, now.day);
  while (SalahPrayer.fajr.statusFor(
        byDate[_dateKey(cursor)] ?? SalahLogEntry(date: _dateKey(cursor)),
      ) ==
      SalahStatus.onTime) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

IconData? _salahStatusIcon(SalahStatus status) {
  return switch (status) {
    SalahStatus.onTime => Icons.check_circle_rounded,
    SalahStatus.late => Icons.schedule_rounded,
    SalahStatus.notPrayed => Icons.close_rounded,
    SalahStatus.unlogged => null,
  };
}

Color _salahStatusColor(
  ColorScheme colorScheme,
  EquranColors colors,
  SalahStatus status,
) {
  return switch (status) {
    SalahStatus.onTime => colors.primary,
    SalahStatus.late => colors.accentGold,
    SalahStatus.notPrayed => colorScheme.onError,
    SalahStatus.unlogged => colors.textMuted,
  };
}

Color _salahStatusBackground(
  ColorScheme colorScheme,
  EquranColors colors,
  SalahStatus status,
) {
  return switch (status) {
    SalahStatus.onTime => colors.primary.withAlpha(38),
    SalahStatus.late => colors.accentGold.withAlpha(38),
    SalahStatus.notPrayed => colorScheme.error,
    SalahStatus.unlogged => colors.surfaceAlt,
  };
}

int _dailyGoal() {
  final dynamic saved = SettingsDB().get('dailyQuranGoalAyahs');
  if (saved is int) return saved.clamp(1, 1000).toInt();
  if (saved is String) {
    return (int.tryParse(saved) ?? 20).clamp(1, 1000).toInt();
  }
  return 20;
}

String _worshipMotivation(AppLocalizations localizations, double progress) {
  if (progress >= 1) return localizations.dailyWorshipComplete;
  if (progress >= 0.5) return localizations.greatProgressKeepGoing;
  if (progress > 0) return localizations.everyDeedCountsKeepGoing;
  return localizations.startYourWorshipForToday;
}

int _dayAyahCount(QuranActivityDay? day) {
  if (day == null) return 0;
  return math.max(day.ayahsRead, day.readAyahKeys.length);
}

DateTime _dhikrDate(DhikrSessionEntry entry) {
  return entry.completedAt ?? entry.startedAt;
}

int _estimatedLettersRead(List<QuranActivityDay> activityDays) {
  int total = 0;
  for (final QuranActivityDay day in activityDays) {
    for (final String key in day.readAyahKeys) {
      final _ReadAyahRef? ref = _parseReadAyahKey(key);
      if (ref == null) continue;
      total += _letterCountCache.putIfAbsent(
        ref.key,
        () => quranVerseArabicLetterCount(ref.surah, ref.verse),
      );
    }
  }
  return total;
}

Map<int, int> _surahCounts(List<QuranActivityDay> activityDays) {
  final Map<int, int> counts = <int, int>{};
  for (final QuranActivityDay day in activityDays) {
    for (final String key in day.readAyahKeys) {
      final _ReadAyahRef? ref = _parseReadAyahKey(key);
      if (ref == null) continue;
      counts[ref.surah] = (counts[ref.surah] ?? 0) + 1;
    }
  }
  return counts;
}

Map<int, int> _surahVisitCounts(List<QuranActivityDay> activityDays) {
  final Map<int, int> counts = <int, int>{};
  for (final QuranActivityDay day in activityDays) {
    for (final int surah in _surahsForDay(day)) {
      counts[surah] = (counts[surah] ?? 0) + 1;
    }
  }
  return counts;
}

Set<int> _surahsForDay(QuranActivityDay day) {
  final Set<int> surahs = <int>{};
  for (final String key in day.readAyahKeys) {
    final _ReadAyahRef? ref = _parseReadAyahKey(key);
    if (ref == null) continue;
    surahs.add(ref.surah);
  }
  return surahs;
}

Map<int, Set<int>> _readAyahsBySurah(List<QuranActivityDay> activityDays) {
  final Map<int, Set<int>> ayahsBySurah = <int, Set<int>>{};
  for (final QuranActivityDay day in activityDays) {
    for (final String key in day.readAyahKeys) {
      final _ReadAyahRef? ref = _parseReadAyahKey(key);
      if (ref == null) continue;
      ayahsBySurah.putIfAbsent(ref.surah, () => <int>{}).add(ref.verse);
    }
  }
  return ayahsBySurah;
}

Set<int> _completedSurahs(Map<int, Set<int>> ayahsBySurah) {
  final Set<int> completed = <int>{};
  for (int surah = 1; surah <= _totalSurahs; surah++) {
    final int readAyahCount = ayahsBySurah[surah]?.length ?? 0;
    if (readAyahCount >= quran.getVerseCount(surah)) {
      completed.add(surah);
    }
  }
  return completed;
}

List<DateTime> _khatmCompletionDates(List<QuranActivityDay> activityDays) {
  final List<QuranActivityDay> sortedDays = activityDays.toList(growable: false)
    ..sort((a, b) => _activityDayDate(a).compareTo(_activityDayDate(b)));
  final Map<int, Set<int>> cycleAyahsBySurah = <int, Set<int>>{};
  final List<DateTime> completions = <DateTime>[];
  for (final QuranActivityDay day in sortedDays) {
    for (final String key in day.readAyahKeys) {
      final _ReadAyahRef? ref = _parseReadAyahKey(key);
      if (ref == null) continue;
      cycleAyahsBySurah.putIfAbsent(ref.surah, () => <int>{}).add(ref.verse);
    }
    if (_completedSurahs(cycleAyahsBySurah).length >= _totalSurahs) {
      completions.add(_activityDayDate(day));
      cycleAyahsBySurah.clear();
    }
  }
  return completions;
}

_ReadAyahRef? _parseReadAyahKey(String key) {
  final List<String> parts = key.split(':');
  if (parts.length != 2) return null;
  final int? surah = int.tryParse(parts.first);
  final int? verse = int.tryParse(parts.last);
  if (surah == null || verse == null) return null;
  if (surah < 1 || surah > _totalSurahs) return null;
  if (verse < 1 || verse > quran.getVerseCount(surah)) return null;
  return _ReadAyahRef(surah: surah, verse: verse);
}

List<InsightData> _buildInsights({
  required List<QuranActivityDay> activityDays,
  required Map<String, QuranActivityDay> activityByDate,
  required DateTime now,
  required Map<int, int> surahVisitCounts,
  required AppLocalizations localizations,
}) {
  final List<InsightData> insights = <InsightData>[];
  final int? activeDay = _mostActiveWeekday(
    activityDays
        .map(
          (day) => ActivityDayCount(
            date: _activityDayDate(day),
            count: _dayAyahCount(day),
          ),
        )
        .toList(growable: false),
  );
  if (activeDay != null) {
    insights.add(
      InsightData(
        icon: Icons.calendar_month_rounded,
        label: localizations.youReadMostOn(
          _weekdayPlural(activeDay, localizations),
        ),
      ),
    );
  }
  final InsightData? trend = _readingTrendInsight(
    activityByDate,
    now,
    localizations,
  );
  if (trend != null) insights.add(trend);
  final InsightData? favourite = _favouriteSurahInsight(
    surahVisitCounts,
    localizations,
  );
  if (favourite != null) insights.add(favourite);
  if (insights.isEmpty) {
    return <InsightData>[
      InsightData(
        icon: Icons.auto_awesome_rounded,
        label: localizations.startReadingToUnlockInsights,
      ),
    ];
  }
  return insights.take(3).toList(growable: false);
}

int? _mostActiveWeekday(List<ActivityDayCount> days) {
  final List<int> counts = List<int>.filled(8, 0);
  for (final ActivityDayCount day in days) {
    if (day.count <= 0) continue;
    counts[day.date.weekday] += day.count;
  }
  int bestWeekday = 0;
  int bestCount = 0;
  for (int weekday = 1; weekday < counts.length; weekday++) {
    if (counts[weekday] > bestCount) {
      bestWeekday = weekday;
      bestCount = counts[weekday];
    }
  }
  return bestWeekday == 0 ? null : bestWeekday;
}

InsightData? _readingTrendInsight(
  Map<String, QuranActivityDay> activityByDate,
  DateTime now,
  AppLocalizations localizations,
) {
  final DateTime currentWeekStart = _weekStart(now);
  final int daysElapsed = now.difference(currentWeekStart).inDays + 1;
  final DateTime previousWeekStart = currentWeekStart.subtract(
    const Duration(days: 7),
  );
  final int currentWeekAyahs = _ayahsForRange(
    activityByDate,
    currentWeekStart,
    daysElapsed,
  );
  final int previousWeekAyahs = _ayahsForRange(
    activityByDate,
    previousWeekStart,
    daysElapsed,
  );
  if (previousWeekAyahs <= 0 || currentWeekAyahs == previousWeekAyahs) {
    return null;
  }
  final bool up = currentWeekAyahs > previousWeekAyahs;
  final int percent = math.max(
    1,
    (((currentWeekAyahs - previousWeekAyahs).abs() / previousWeekAyahs) * 100)
        .round(),
  );
  return InsightData(
    icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
    label: up
        ? localizations.readingUpFromLastWeek(percent)
        : localizations.readingDownFromLastWeek(percent),
  );
}

int _ayahsForRange(
  Map<String, QuranActivityDay> activityByDate,
  DateTime start,
  int dayCount,
) {
  int total = 0;
  for (int offset = 0; offset < dayCount; offset++) {
    total += _dayAyahCount(
      activityByDate[_dateKey(start.add(Duration(days: offset)))],
    );
  }
  return total;
}

InsightData? _favouriteSurahInsight(
  Map<int, int> surahVisitCounts,
  AppLocalizations localizations,
) {
  if (surahVisitCounts.isEmpty) return null;
  final MapEntry<int, int> favourite = surahVisitCounts.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );
  return InsightData(
    icon: Icons.favorite_rounded,
    label: localizations.youVisitSurahMostOften(
      localizedSurahName(localizations, favourite.key),
    ),
  );
}

DateTime _activityDayDate(QuranActivityDay day) {
  final DateTime? parsed = DateTime.tryParse(day.dateKey);
  if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
  return DateTime(day.updatedAt.year, day.updatedAt.month, day.updatedAt.day);
}

DateTime _weekStart(DateTime date) {
  final DateTime day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

DateTime _monthStart(DateTime date) {
  return DateTime(date.year, date.month);
}

bool _isCurrentMonth(DateTime date) {
  final DateTime current = _monthStart(DateTime.now());
  final DateTime month = _monthStart(date);
  return current.year == month.year && current.month == month.month;
}

bool _isFutureMonth(DateTime date) {
  return _monthStart(date).isAfter(_monthStart(DateTime.now()));
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _monthCacheKey(int year, int month) {
  final DateTime date = DateTime(year, month);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}

DateTime _getShiftedNow() {
  final DateTime now = DateTime.now();
  final PrayerSettingsStore store = PrayerSettingsStore();
  final prayer_models.PrayerLocation? location = store.getLocation();
  final prayer_models.PrayerTimeSettings settings = store.getSettings();
  if (location == null) return now;
  return const PrayerTimesService().calendarDateForInstant(
    instant: now,
    location: location,
    settings: settings,
  );
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _averageLabel(double value) {
  if (value == 0) return '0';
  return value.toStringAsFixed(value >= 10 ? 0 : 1);
}

String _monthLabel(DateTime date, AppLocalizations localizations) {
  return '${_shortMonthLabel(date, localizations)} ${date.year}';
}

String _monthYearLabel(DateTime date, AppLocalizations localizations) {
  return '${_fullMonthLabel(date.month, localizations)} ${date.year}';
}

String _monthDayLabel(DateTime date, AppLocalizations localizations) {
  return '${_shortMonthLabel(date, localizations)} ${date.day}';
}

String _dateRangeLabel(
  DateTime start,
  DateTime end,
  AppLocalizations localizations,
) {
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return _monthDayLabel(start, localizations);
  }
  return '${_monthDayLabel(start, localizations)} - ${_monthDayLabel(end, localizations)}';
}

String _dateChipLabel(DateTime date, AppLocalizations localizations) {
  return '${_shortMonthLabel(date, localizations)} ${date.day}, ${date.year}';
}

String _monthlySummaryLabel(
  MonthlyActivityData data,
  AppLocalizations localizations,
) {
  final MonthlyActivityDay? bestDay = data.bestDay;
  return localizations.monthlyActivitySummary(
    localizations.activeDaysCount(data.activeDays),
    bestDay == null
        ? localizations.noDayYet
        : _weekdayName(bestDay.date.weekday, localizations),
    data.totalActions,
  );
}

List<MonthlyActivityDay?> _monthlyCalendarCells(MonthlyActivityData data) {
  final int daysInMonth = DateTime(
    data.month.year,
    data.month.month + 1,
    0,
  ).day;
  final int leadingEmptyCells = data.month.weekday - 1;
  final int rowCount = math.max(
    5,
    ((leadingEmptyCells + daysInMonth) / 7).ceil(),
  );
  return <MonthlyActivityDay?>[
    for (int index = 0; index < rowCount * 7; index++)
      if (index < leadingEmptyCells || index >= leadingEmptyCells + daysInMonth)
        null
      else
        data.days[index - leadingEmptyCells + 1],
  ];
}

String _shortWeekdayLabel(int weekday, AppLocalizations localizations) {
  final List<String> weekdays = <String>[
    localizations.mondayShort,
    localizations.tuesdayShort,
    localizations.wednesdayShort,
    localizations.thursdayShort,
    localizations.fridayShort,
    localizations.saturdayShort,
    localizations.sundayShort,
  ];
  return weekdays[(weekday - 1).clamp(0, weekdays.length - 1)];
}

String _weekdayName(int weekday, AppLocalizations localizations) {
  final List<String> weekdays = <String>[
    localizations.monday,
    localizations.tuesday,
    localizations.wednesday,
    localizations.thursday,
    localizations.friday,
    localizations.saturday,
    localizations.sunday,
  ];
  return weekdays[(weekday - 1).clamp(0, weekdays.length - 1)];
}

String _weekdayPlural(int weekday, AppLocalizations localizations) {
  final List<String> weekdays = <String>[
    localizations.mondays,
    localizations.tuesdays,
    localizations.wednesdays,
    localizations.thursdays,
    localizations.fridays,
    localizations.saturdays,
    localizations.sundays,
  ];
  return weekdays[(weekday - 1).clamp(0, weekdays.length - 1)];
}

List<String> _weekdayInitials(AppLocalizations localizations) {
  return <String>[
    localizations.mondayInitial,
    localizations.tuesdayInitial,
    localizations.wednesdayInitial,
    localizations.thursdayInitial,
    localizations.fridayInitial,
    localizations.saturdayInitial,
    localizations.sundayInitial,
  ];
}

String _shortMonthLabel(DateTime date, AppLocalizations localizations) {
  final List<String> months = <String>[
    localizations.januaryShort,
    localizations.februaryShort,
    localizations.marchShort,
    localizations.aprilShort,
    localizations.mayShort,
    localizations.juneShort,
    localizations.julyShort,
    localizations.augustShort,
    localizations.septemberShort,
    localizations.octoberShort,
    localizations.novemberShort,
    localizations.decemberShort,
  ];
  return months[date.month - 1];
}

String _fullMonthLabel(int month, AppLocalizations localizations) {
  final List<String> months = <String>[
    localizations.january,
    localizations.february,
    localizations.march,
    localizations.april,
    localizations.may,
    localizations.june,
    localizations.july,
    localizations.august,
    localizations.september,
    localizations.october,
    localizations.november,
    localizations.december,
  ];
  return months[(month - 1).clamp(0, months.length - 1)];
}

String _localizedDhikrStatsLabel(String label, AppLocalizations localizations) {
  if (!isArabicLocalizations(localizations)) return label;
  return switch (label) {
    'Post-prayer dhikr' => localizations.postPrayerDhikr,
    'SubhanAllah' => 'سبحان الله',
    'Alhamdulillah' => 'الحمد لله',
    'Allahu Akbar' => 'الله أكبر',
    'Astaghfirullah' => 'أستغفر الله',
    'Custom' => 'ذكر مخصص',
    _ => label,
  };
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num || value is bool) return value.toString();
  return null;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) =>
      HairlineCard(child: SizedBox(height: height));
}

class HeroCornerOrnamentsPainter extends CustomPainter {
  const HeroCornerOrnamentsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    const double inset = 10;
    const double length = 16;

    final Path path = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(size.width - inset - length, inset)
      ..lineTo(size.width - inset, inset)
      ..lineTo(size.width - inset, inset + length)
      ..moveTo(inset, size.height - inset - length)
      ..lineTo(inset, size.height - inset)
      ..lineTo(inset + length, size.height - inset)
      ..moveTo(size.width - inset - length, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(size.width - inset, size.height - inset - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeroCornerOrnamentsPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({required this.color, this.opacity = 0.06});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const double tileSize = 80;
    for (double x = 0; x < size.width + tileSize; x += tileSize) {
      for (double y = 0; y < size.height + tileSize; y += tileSize) {
        _drawStar(
          canvas,
          paint,
          Offset(x + tileSize / 2, y + tileSize / 2),
          36,
        );
        _drawStar(
          canvas,
          paint,
          Offset(x + tileSize / 2, y + tileSize / 2),
          22,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final Path path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = (i * 45 - 90) * (math.pi / 180);
      final double innerAngle = angle + (22.5 * math.pi / 180);
      final Offset outerPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final Offset innerPoint = Offset(
        center.dx + (radius * 0.5) * math.cos(innerAngle),
        center.dy + (radius * 0.5) * math.sin(innerAngle),
      );
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return color != oldDelegate.color || opacity != oldDelegate.opacity;
  }
}
