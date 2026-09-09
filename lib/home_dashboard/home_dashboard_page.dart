import 'dart:async';
import 'dart:math' as math;

import 'package:equran/backend/library.dart';
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/home/read.dart';
import 'package:equran/prayer/prayer_hero_card.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_time_thumb_card.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:equran/reading_plans/routine_progress.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:equran/widgets/holographic_card.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/widgets/last_read_cards.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quran/quran.dart' as quran;
import 'package:equran/duas/daily_dua_repository.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/duas/duas_category_page.dart';
import 'package:equran/backend/daily_tools_config.dart';
import 'package:equran/home/hijri_calendar_page.dart' hide HijriCalendar;
import 'package:equran/home/zakah_calculator_page.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/duas/asma_ul_husna_page.dart';

const String _appAssetBase = 'assets/media/images/app';
const String _quranAsset = '$_appAssetBase/quran.webp';
const String _lastReadAsset = '$_appAssetBase/last_read.webp';
const String _duaAsset = '$_appAssetBase/dua.webp';
const String _designAsset = '$_appAssetBase/design.webp';
const String _routineAsset = '$_appAssetBase/routine.webp';
const String _settingsAsset = '$_appAssetBase/settings.webp';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({
    super.key,
    required this.onOpenMore,
    required this.onOpenQuran,
    required this.onOpenZakat,
    required this.onOpenPrayerTimes,
    required this.onOpenQibla,
    required this.onOpenDuas,
    required this.onOpenTasbih,
    required this.onOpenReadingPlans,
    required this.onOpenDownloads,
    required this.onOpenSearch,
    required this.onOpenStats,
  });

  final VoidCallback onOpenMore;
  final VoidCallback onOpenQuran;
  final VoidCallback onOpenZakat;
  final VoidCallback onOpenPrayerTimes;
  final VoidCallback onOpenQibla;
  final VoidCallback onOpenDuas;
  final VoidCallback onOpenTasbih;
  final VoidCallback onOpenReadingPlans;
  final VoidCallback onOpenDownloads;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenStats;

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final PrayerSettingsStore _prayerStore = PrayerSettingsStore();
  final PrayerTimesService _prayerService = const PrayerTimesService();
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  PrayerExactAlarmPermissionStatus? _exactAlarmPermission;

  @override
  void initState() {
    super.initState();
    _scheduleMinuteClock();
    unawaited(_loadExactAlarmStatus());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return Material(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _now = DateTime.now();
            });
            await _loadExactAlarmStatus();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(child: _buildHeader(theme)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  EquranSpacing.pagePadding,
                  8,
                  EquranSpacing.pagePadding,
                  112,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: _DashboardReactiveShell(
                        now: _now,
                        exactAlarmPermission: _exactAlarmPermission,
                        prayerStore: _prayerStore,
                        prayerService: _prayerService,
                        actions: widget,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final PrayerLocation? location = _prayerStore.getLocation();
    final String locationLabel =
        location?.displayLabel ?? localizations.setPrayerLocation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EquranSpacing.pagePadding,
        10,
        EquranSpacing.pagePadding,
        8,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.nights_stay_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          localizations.currentLocation,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Container(
              //   width: 42,
              //   height: 42,
              //   decoration: BoxDecoration(
              //     color: colors.surface,
              //     shape: BoxShape.circle,
              //     border: Border.all(color: colors.border),
              //   ),
              //   child: IconButton(
              //     tooltip: 'Search Quran text',
              //     onPressed: widget.onOpenSearch,
              //     color: colors.primary,
              //     iconSize: 22,
              //     padding: EdgeInsets.zero,
              //     icon: const Icon(Icons.search_rounded),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _formatDashboardDate(_now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Integrated Hijri date (beautiful small gold text)
                    Builder(
                      builder: (BuildContext context) {
                        final int offset =
                            SettingsDB().get('hijri_offset', defaultValue: 0)
                                as int;
                        final HijriCalendar hijri = HijriCalendar.fromDate(
                          _now,
                          offset: offset,
                        );
                        return Text(
                          hijri.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // TextButton(
              //   onPressed: widget.onOpenPrayerTimes,
              //   style: TextButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(horizontal: 4),
              //     minimumSize: const Size(0, 32),
              //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //   ),
              //   child: const Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: <Widget>[
              //       Text('Prayer Times'),
              //       SizedBox(width: 2),
              //       Icon(Icons.chevron_right_rounded, size: 18),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  void _scheduleMinuteClock() {
    _clockTimer?.cancel();
    final DateTime now = DateTime.now();
    final Duration untilNextMinute = Duration(
      minutes: 1,
      seconds: -now.second,
      milliseconds: -now.millisecond,
      microseconds: -now.microsecond,
    );
    _clockTimer = Timer(untilNextMinute, () {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
      _scheduleMinuteClock();
    });
  }

  Future<void> _loadExactAlarmStatus() async {
    final PrayerTimeSettings settings = _prayerStore.getSettings();
    if (!settings.reminderSettings.remindersEnabled) return;
    final PrayerExactAlarmPermissionStatus status =
        await PrayerNotificationService().checkExactAlarmPermission();
    if (!mounted) return;
    setState(() {
      _exactAlarmPermission = status;
    });
  }
}

class _DashboardReactiveShell extends StatelessWidget {
  const _DashboardReactiveShell({
    required this.now,
    required this.exactAlarmPermission,
    required this.prayerStore,
    required this.prayerService,
    required this.actions,
  });

  final DateTime now;
  final PrayerExactAlarmPermissionStatus? exactAlarmPermission;
  final PrayerSettingsStore prayerStore;
  final PrayerTimesService prayerService;
  final HomeDashboardPage actions;

  @override
  Widget build(BuildContext context) {
    // One merged listener instead of 7 nested ValueListenableBuilders:
    // identical rebuild semantics (any box change rebuilds the content)
    // with a single subscription set and no nesting overhead.
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        SettingsDB().listener,
        ResumeStateDB().listener,
        QuranBookmarksDB().listener,
        FavouritesDB().listener,
        ReadingPlansDB().listener,
        QuranActivityDB().listener,
        QuranStatsDB().listener,
      ]),
      builder: (context, child) {
        return _DashboardContent(
          now: now,
          exactAlarmPermission: exactAlarmPermission,
          prayerStore: prayerStore,
          prayerService: prayerService,
          actions: actions,
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.now,
    required this.exactAlarmPermission,
    required this.prayerStore,
    required this.prayerService,
    required this.actions,
  });

  final DateTime now;
  final PrayerExactAlarmPermissionStatus? exactAlarmPermission;
  final PrayerSettingsStore prayerStore;
  final PrayerTimesService prayerService;
  final HomeDashboardPage actions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final _DashboardSummary summary = _DashboardSummary.load(
      now: now,
      prayerStore: prayerStore,
      prayerService: prayerService,
      localizations: localizations,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PrayerHeroCard(
              day: summary.prayerSummary.day,
              nextPrayer: summary.prayerSummary.nextPrayer,
              currentPrayer: summary.prayerSummary.currentPrayer,
              titleOverride: summary.prayerSummary.heroTitleOverride,
              subtitleOverride: summary.prayerSummary.heroSubtitleOverride,
              exactAlarmPermission: exactAlarmPermission,
              onTap: actions.onOpenPrayerTimes,
            ),
            if (summary.prayerSummary.day != null) ...<Widget>[
              const SizedBox(height: 12),
              _PrayerThumbCarousel(
                prayerSummary: summary.prayerSummary,
                onOpenPrayerTimes: actions.onOpenPrayerTimes,
              ),
            ],
            const SizedBox(height: 14),
            _JourneyPreviewCard(
              stats: summary.stats,
              activity: summary.todayActivity,
              latestReadingActivityDate: summary.latestReadingActivityDate,
              onOpenStats: actions.onOpenStats,
            ),
            if (summary.activePlan != null) ...<Widget>[
              const SizedBox(height: 14),
              _RoutinePlanCta(plan: summary.activePlan!),
            ] else ...<Widget>[
              const SizedBox(height: 12),
              _RoutinePlanCta(
                plan: null,
                onOpenReadingPlans: actions.onOpenReadingPlans,
              ),
            ],
            const SizedBox(height: 22),
            _DailyQuranCompanionSection(
              wide: wide,
              latestReading: summary.latestReading,
              latestListening: summary.latestListening,
              actions: actions,
            ),
            const SizedBox(height: 22),
            _DailyAyahPreview(
              ayah: summary.dailyAyah,
              onOpenQuran: actions.onOpenQuran,
            ),
            const SizedBox(height: 22),
            _DailyDuaPreview(
              date: summary.todayDate,
              onOpenDuas: actions.onOpenDuas,
            ),
            // const SizedBox(height: 22),
            // _PersonalLibraryPreview(
            //   bookmarks: summary.bookmarks,
            //   onOpenQuran: actions.onOpenQuran,
            // ),
          ],
        );
      },
    );
  }
}

class _DashboardSummary {
  const _DashboardSummary({
    required this.todayDate,
    required this.latestReading,
    required this.latestListening,
    required this.prayerSummary,
    required this.todayActivity,
    required this.activePlan,
    required this.dailyAyah,
    required this.stats,
    required this.latestReadingActivityDate,
    required this.bookmarks,
  });

  final DateTime todayDate;
  final ResumeStateEntry? latestReading;
  final ResumeStateEntry? latestListening;
  final _PrayerSummary prayerSummary;
  final QuranActivityDay? todayActivity;
  final ReadingPlanEntry? activePlan;
  final _DailyAyah dailyAyah;
  final QuranStatsSnapshot? stats;
  final DateTime? latestReadingActivityDate;
  final List<QuranBookmarkEntry> bookmarks;

  static _DashboardSummary load({
    required DateTime now,
    required PrayerSettingsStore prayerStore,
    required PrayerTimesService prayerService,
    required AppLocalizations localizations,
  }) {
    final List<ResumeStateEntry> resumeEntries = ResumeStateDB().box.values
        .whereType<ResumeStateEntry>()
        .toList(growable: false);
    final ResumeStateEntry? latestReading =
        _latestResume(resumeEntries, 'reading') ?? _legacyReadingResume();
    final ResumeStateEntry? latestListening = _latestResume(
      resumeEntries,
      'listening',
    );
    // Newest active plan via a single pass: sorting the whole box on
    // every rebuild is O(n log n) for one row.
    ReadingPlanEntry? activePlan;
    for (final ReadingPlanEntry plan in ReadingPlansDB().box.values
        .whereType<ReadingPlanEntry>()) {
      if (!plan.active) continue;
      final ReadingPlanEntry? current = activePlan;
      if (current == null || plan.startedAt.isAfter(current.startedAt)) {
        activePlan = plan;
      }
    }
    final PrayerLocation? location = prayerStore.getLocation();
    final PrayerTimeSettings settings = prayerStore.getSettings();
    final DateTime todayDate = location == null
        ? DateTime(now.year, now.month, now.day)
        : prayerService.calendarDateForInstant(
            instant: now,
            location: location,
            settings: settings,
          );
    final String todayKey = _dateKey(todayDate);
    final dynamic activityValue = QuranActivityDB().get(todayKey);
    final dynamic statsValue = QuranStatsDB().get('summary');
    final DateTime? latestReadingActivityDate = latestQuranReadingActivityDate(
      QuranActivityDB().box.values.whereType<QuranActivityDay>(),
    );

    return _DashboardSummary(
      todayDate: todayDate,
      latestReading: latestReading,
      latestListening: latestListening,
      prayerSummary: _PrayerSummary.load(
        now: now,
        store: prayerStore,
        service: prayerService,
        localizations: localizations,
      ),
      todayActivity: activityValue is QuranActivityDay ? activityValue : null,
      activePlan: activePlan,
      dailyAyah: _DailyAyah.forDate(todayDate),
      stats: statsValue is QuranStatsSnapshot ? statsValue : null,
      latestReadingActivityDate: latestReadingActivityDate,
      bookmarks: const QuranBookmarkService()
          .bookmarkEntriesWithLegacyFallback()
          .take(3)
          .toList(growable: false),
    );
  }

  static ResumeStateEntry? _latestResume(
    List<ResumeStateEntry> entries,
    String kind,
  ) {
    ResumeStateEntry? latest;
    for (final ResumeStateEntry entry in entries) {
      if (entry.kind != kind) continue;
      final ResumeStateEntry? current = latest;
      if (current == null || entry.updatedAt.isAfter(current.updatedAt)) {
        latest = entry;
      }
    }
    return latest;
  }

  static ResumeStateEntry? _legacyReadingResume() {
    ReadingEntry? latest;
    for (final ReadingEntry entry
        in BookmarkDB().box.values.whereType<ReadingEntry>()) {
      final ReadingEntry? current = latest;
      if (current == null || entry.timestamp.isAfter(current.timestamp)) {
        latest = entry;
      }
    }
    if (latest == null) return null;
    final ReadingEntry entry = latest;
    return ResumeStateEntry(
      id: 'legacy-reading:${entry.surah}',
      kind: 'reading',
      surah: entry.surah,
      ayah: entry.verse,
      title: quran.getSurahName(entry.surah),
      subtitle: 'Ayah ${entry.verse}',
      updatedAt: entry.timestamp,
    );
  }
}

class _PrayerSummary {
  const _PrayerSummary({
    required this.location,
    required this.day,
    required this.currentPeriod,
    required this.nextPrayer,
    required this.heroTitleOverride,
    required this.heroSubtitleOverride,
  });

  final PrayerLocation? location;
  final PrayerDay? day;
  final PrayerCurrentPeriod? currentPeriod;
  final NextPrayer? nextPrayer;
  final String? heroTitleOverride;
  final String? heroSubtitleOverride;

  PrayerTimeEntry? get currentPrayer => currentPeriod?.currentPrayer;

  // Single-entry memo for the expensive adhan day calculations. The three
  // days depend only on (date, location, settings); the current/next period
  // derivation from `now` stays live on every build. The key embeds the
  // full settings JSON so no calculation-relevant field can go stale.
  // Single entry by design: bounded memory, repeat builds hit it.
  static String? _daysCacheKey;
  static _CachedPrayerDays? _daysCache;

  static _PrayerSummary load({
    required DateTime now,
    required PrayerSettingsStore store,
    required PrayerTimesService service,
    required AppLocalizations localizations,
  }) {
    final PrayerLocation? location = store.getLocation();
    if (location == null) {
      return const _PrayerSummary(
        location: null,
        day: null,
        currentPeriod: null,
        nextPrayer: null,
        heroTitleOverride: null,
        heroSubtitleOverride: null,
      );
    }

    final PrayerTimeSettings settings = store.getSettings();
    final DateTime todayDate = service.calendarDateForInstant(
      instant: now,
      location: location,
      settings: settings,
    );
    final String cacheKey =
        '${_dateKey(todayDate)}|${location.coordinateLabel}|'
        '${location.timezoneId}|${location.mode.id}|${settings.toJson()}';
    _CachedPrayerDays? days = _daysCacheKey == cacheKey ? _daysCache : null;
    if (days == null) {
      days = _CachedPrayerDays(
        today: service.calculateDay(
          date: todayDate,
          location: location,
          settings: settings,
        ),
        yesterday: service.calculateDay(
          date: DateTime(todayDate.year, todayDate.month, todayDate.day - 1),
          location: location,
          settings: settings,
        ),
        tomorrow: service.calculateDay(
          date: DateTime(todayDate.year, todayDate.month, todayDate.day + 1),
          location: location,
          settings: settings,
        ),
      );
      _daysCacheKey = cacheKey;
      _daysCache = days;
    }
    final PrayerDay today = days.today;
    final PrayerDay yesterday = days.yesterday;
    final PrayerDay tomorrow = days.tomorrow;
    final PrayerCurrentPeriod currentPeriod = service.currentPrayerPeriod(
      today: today,
      yesterday: yesterday,
      now: now,
    );
    final NextPrayer nextPrayer = service.nextPrayer(
      day: today,
      tomorrow: tomorrow,
      now: now,
    );
    return _PrayerSummary(
      location: location,
      day: today,
      currentPeriod: currentPeriod,
      nextPrayer: nextPrayer,
      heroTitleOverride: _heroTitleOverrideFor(currentPeriod, localizations),
      heroSubtitleOverride: _heroSubtitleOverrideFor(
        currentPeriod: currentPeriod,
        nextPrayer: nextPrayer,
        now: now,
        localizations: localizations,
      ),
    );
  }
}

class _CachedPrayerDays {
  const _CachedPrayerDays({
    required this.today,
    required this.yesterday,
    required this.tomorrow,
  });

  final PrayerDay today;
  final PrayerDay yesterday;
  final PrayerDay tomorrow;
}

class _DailyAyah {
  const _DailyAyah({
    required this.surah,
    required this.verse,
    required this.arabic,
    required this.translation,
  });

  final int surah;
  final int verse;
  final String arabic;
  final String translation;

  static _DailyAyah forDate(DateTime date) {
    final String todayKey = _dateKey(date);
    final SettingsDB settings = SettingsDB();
    final dynamic savedDate = settings.get('dailyAyahDate');
    final dynamic savedGlobalAyah = settings.get('dailyAyahGlobalAyah');
    int globalAyah;
    if (savedDate == todayKey &&
        savedGlobalAyah is int &&
        savedGlobalAyah >= 1 &&
        savedGlobalAyah <= quran.totalVerseCount) {
      globalAyah = savedGlobalAyah;
    } else if (savedDate == todayKey) {
      // Same day but a corrupt saved value: keep the original synchronous
      // write so the persisted state converges exactly as before.
      globalAyah = math.Random().nextInt(quran.totalVerseCount) + 1;
      unawaited(settings.put('dailyAyahDate', todayKey));
      unawaited(settings.put('dailyAyahGlobalAyah', globalAyah));
    } else {
      // Day rollover: writing to the settings box during build would
      // synchronously notify its listeners mid-build and cascade into a
      // second full dashboard rebuild. Defer persistence one frame; the
      // ayah returned (and displayed) this frame is unchanged.
      globalAyah = math.Random().nextInt(quran.totalVerseCount) + 1;
      final String pendingKey = todayKey;
      final int pendingAyah = globalAyah;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (settings.get('dailyAyahDate') == pendingKey) return;
        unawaited(settings.put('dailyAyahDate', pendingKey));
        unawaited(settings.put('dailyAyahGlobalAyah', pendingAyah));
      });
    }
    final _AyahRef ref = _ayahRefFromGlobalIndex(globalAyah);
    final int translationIndex = _translationIndex();
    return _DailyAyah(
      surah: ref.surah,
      verse: ref.verse,
      arabic: quranVerseText(ref.surah, ref.verse),
      translation: quran.cleanTranslationText(
        quran.getVerseTranslation(
          ref.surah,
          ref.verse,
          translation: quran.Translation.values[translationIndex],
        ),
      ),
    );
  }
}

class _PrayerThumbCarousel extends StatelessWidget {
  const _PrayerThumbCarousel({
    required this.prayerSummary,
    required this.onOpenPrayerTimes,
  });

  final _PrayerSummary prayerSummary;
  final VoidCallback onOpenPrayerTimes;

  @override
  Widget build(BuildContext context) {
    final PrayerDay? day = prayerSummary.day;
    if (day == null) return const SizedBox.shrink();

    final PrayerTimeKind? activeKind =
        prayerSummary.currentPeriod?.highlightedKind;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 380;
        return SizedBox(
          height: compact ? 138 : 144,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: day.entries.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final PrayerTimeEntry entry = day.entries[index];
              return PrayerTimeThumbCard(
                entry: entry,
                use24HourFormat: day.settings.use24HourFormat,
                isActive: entry.kind == activeKind,
                width: compact ? 132 : 142,
                onTap: onOpenPrayerTimes,
              );
            },
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _PrayerMetaChip extends StatelessWidget {
  const _PrayerMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.onPrimary.withAlpha(24),
        borderRadius: BorderRadius.circular(EquranRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: colors.onPrimaryMuted),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PrayerTimesChipRow extends StatelessWidget {
  const _PrayerTimesChipRow({
    required this.day,
    required this.use24HourFormat,
    required this.activeKind,
  });

  final PrayerDay day;
  final bool use24HourFormat;
  final PrayerTimeKind activeKind;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final List<PrayerTimeEntry> entries = day.entries
        .where((PrayerTimeEntry entry) => entry.kind != PrayerTimeKind.sunrise)
        .toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < entries.length; i++) ...<Widget>[
            _PrayerTimeChip(
              entry: entries[i],
              use24HourFormat: use24HourFormat,
              isActive: entries[i].kind == activeKind,
            ),
            if (i != entries.length - 1)
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                color: colors.onPrimary.withAlpha(32),
              ),
          ],
        ],
      ),
    );
  }
}

class _PrayerTimeChip extends StatelessWidget {
  const _PrayerTimeChip({
    required this.entry,
    required this.use24HourFormat,
    required this.isActive,
  });

  final PrayerTimeEntry entry;
  final bool use24HourFormat;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isActive
            ? colors.onPrimary.withAlpha(34)
            : colors.onPrimary.withAlpha(14),
        borderRadius: BorderRadius.circular(EquranRadii.medium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            entry.kind.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onPrimaryMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatTime(entry.time, use24HourFormat, localizations),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePremiumCard extends StatelessWidget {
  const _HomePremiumCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.baseColor,
    this.accentColor,
    this.assetPath,
    this.assetOpacity = 0.08,
    this.assetWidth = 160,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? baseColor;
  final Color? accentColor;
  final String? assetPath;
  final double assetOpacity;
  final double assetWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final Color base = baseColor ?? colors.surface;
    final Color accent = accentColor ?? colors.primary;
    final BorderRadius radius = BorderRadius.circular(EquranRadii.large);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(
                  accent.withAlpha(
                    Theme.of(context).brightness == Brightness.light ? 42 : 18,
                  ),
                  base,
                ),
                base,
                Color.alphaBlend(
                  colors.primaryStrong.withAlpha(
                    Theme.of(context).brightness == Brightness.light ? 28 : 12,
                  ),
                  base,
                ),
              ],
            ),
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? colors.border.withAlpha(190),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.shadow.withAlpha(
                  Theme.of(context).brightness == Brightness.light ? 14 : 30,
                ),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              if (assetPath != null)
                Positioned(
                  right: -30,
                  top: -18,
                  bottom: -18,
                  width: assetWidth,
                  child: Opacity(
                    opacity: assetOpacity,
                    child: Image.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutinePlanCta extends StatelessWidget {
  const _RoutinePlanCta({required this.plan, this.onOpenReadingPlans});

  final ReadingPlanEntry? plan;
  final VoidCallback? onOpenReadingPlans;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final ReadingPlanEntry? activePlan = plan;
    final localizations = AppLocalizations.of(context)!;
    if (activePlan == null) {
      return _HomePremiumCard(
        onTap: onOpenReadingPlans,
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        baseColor: colors.surface,
        accentColor: colors.primary,
        borderColor: colors.border,
        assetPath: _designAsset,
        assetOpacity: 0.05,
        assetWidth: 112,
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.mint,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Image.asset(
                _routineAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.auto_stories_rounded,
                    color: colors.primary,
                  );
                },
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    localizations.startReadingRoutine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizations.buildDailyQuranHabit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: colors.primary),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  localizations.start,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final _RoutineDayProgress dayProgress = _routineDayProgress(
      activePlan,
      localizations,
    );
    final _AyahRef continueRef = _routineContinueRef(activePlan);

    return _HomePremiumCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ReadPage(
            chapter: continueRef.surah,
            startVerse: continueRef.verse,
            mode: ReadPageMode.routine,
            routineId: activePlan.id,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      baseColor: colors.surface,
      accentColor: colors.primary,
      assetPath: _designAsset,
      assetOpacity: 0.045,
      assetWidth: 185,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.mint,
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  border: Border.all(color: colors.border.withAlpha(110)),
                ),
                child: Transform.scale(
                  scale: 1.25,
                  child: Image.asset(
                    _routineAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.route_outlined, color: colors.primary);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  localizations.readingRoutine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dayProgress.portionLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(EquranRadii.pill),
            child: LinearProgressIndicator(
              value: dayProgress.fraction,
              minHeight: 6,
              color: colors.primary,
              backgroundColor: colors.mint,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  dayProgress.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                localizations.localeName == 'ar' ||
                        localizations.localeName == 'fa' ||
                        localizations.localeName == 'ur'
                    ? '<- ${localizations.continueRoutine}'
                    : '${localizations.continueRoutine} ->',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyQuranCompanionSection extends StatelessWidget {
  const _DailyQuranCompanionSection({
    required this.wide,
    required this.latestReading,
    required this.latestListening,
    required this.actions,
  });

  final bool wide;
  final ResumeStateEntry? latestReading;
  final ResumeStateEntry? latestListening;
  final HomeDashboardPage actions;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _CompanionSectionHeader(
              icon: Icons.auto_stories_outlined,
              title: localizations.dailyQuranCompanion,
              subtitle: localizations.dailyQuranCompanionSubtitle,
            ),
            const SizedBox(height: 12),
            _ContinueExperience(
              wide: wide,
              latestReading: latestReading,
              onOpenQuran: actions.onOpenQuran,
            ),
            const SizedBox(height: 16),
            _CompanionSectionHeader(
              icon: Icons.grid_view_rounded,
              title: localizations.dailyTools,
              subtitle: localizations.dailyToolsSubtitle,
              compact: true,
            ),
            const SizedBox(height: 10),
            _MuslimDailyQuickActions(actions: actions),
          ],
        ),
      ),
    );
  }
}

class _CompanionSectionHeader extends StatelessWidget {
  const _CompanionSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    return Row(
      children: <Widget>[
        Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          decoration: BoxDecoration(
            color: colors.mint.withAlpha(170),
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: Border.all(color: colors.border.withAlpha(170)),
          ),
          child: Icon(icon, color: colors.primary, size: compact ? 17 : 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueExperience extends StatelessWidget {
  const _ContinueExperience({
    required this.wide,
    required this.latestReading,
    required this.onOpenQuran,
  });

  final bool wide;
  final ResumeStateEntry? latestReading;
  final VoidCallback onOpenQuran;

  @override
  Widget build(BuildContext context) {
    return _HomeQuranLastReadCard(
      entry: latestReading,
      onOpenQuran: onOpenQuran,
    );
  }
}

class _MuslimDailyQuickActions extends StatefulWidget {
  const _MuslimDailyQuickActions({required this.actions});

  final HomeDashboardPage actions;

  @override
  State<_MuslimDailyQuickActions> createState() =>
      _MuslimDailyQuickActionsState();
}

class _MuslimDailyQuickActionsState extends State<_MuslimDailyQuickActions> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;

    return ValueListenableBuilder<Box<dynamic>>(
      valueListenable: SettingsDB().listener,
      builder: (context, box, child) {
        final List<DailyToolType> visibleTools = SettingsDB()
            .getVisibleDailyTools();

        final List<_QuickAction> items = visibleTools.map((tool) {
          return _QuickAction(tool.icon, tool.getTitle(localizations), () {
            switch (tool) {
              case DailyToolType.quran:
                widget.actions.onOpenQuran();
                break;
              case DailyToolType.prayer:
                widget.actions.onOpenPrayerTimes();
                break;
              case DailyToolType.qibla:
                widget.actions.onOpenQibla();
                break;
              case DailyToolType.tasbih:
                widget.actions.onOpenTasbih();
                break;
              case DailyToolType.dua:
                widget.actions.onOpenDuas();
                break;
              case DailyToolType.downloads:
                widget.actions.onOpenDownloads();
                break;
              case DailyToolType.search:
                widget.actions.onOpenSearch();
                break;
              case DailyToolType.readingPlans:
                widget.actions.onOpenReadingPlans();
                break;
              case DailyToolType.hifz:
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const HifzHomePage(),
                  ),
                );
                break;
              case DailyToolType.asmaUlHusna:
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AsmaUlHusnaPage(),
                  ),
                );
                break;
              case DailyToolType.statistics:
                widget.actions.onOpenStats();
                break;
              case DailyToolType.calendar:
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const HijriCalendarPage(),
                  ),
                );
                break;
              case DailyToolType.zakah:
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ZakahCalculatorPage(),
                  ),
                );
                break;
            }
          }, assetPath: tool.assetPath);
        }).toList();

        final List<List<_QuickAction>> pages = <List<_QuickAction>>[];
        for (int i = 0; i < items.length; i += 4) {
          pages.add(items.skip(i).take(4).toList(growable: false));
        }

        if (_page >= pages.length && pages.isNotEmpty) {
          _page = pages.length - 1;
        }

        final int maxItemsOnPage = pages.isEmpty
            ? 0
            : pages.map((p) => p.length).reduce((a, b) => a > b ? a : b);
        final double pageViewHeight = maxItemsOnPage <= 2 ? 78.0 : 166.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _HomePremiumCard(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              baseColor: colors.surface,
              accentColor: colors.primary,
              assetPath: _designAsset,
              assetOpacity: 0.035,
              assetWidth: 170,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: pageViewHeight,
                    child: pages.isEmpty
                        ? const SizedBox.shrink()
                        : PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: pages.length,
                            onPageChanged: (int value) {
                              setState(() {
                                _page = value;
                              });
                            },
                            itemBuilder: (context, pageIndex) {
                              final List<_QuickAction> pageItems =
                                  pages[pageIndex];
                              return GridView.builder(
                                itemCount: pageItems.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisExtent: 78,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 8,
                                    ),
                                itemBuilder: (context, index) {
                                  final _QuickAction item = pageItems[index];
                                  return _DashboardActionTile(
                                    icon: item.icon,
                                    label: item.label,
                                    onTap: item.onTap,
                                    assetPath: item.assetPath,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  if (pages.length > 1) ...<Widget>[
                    const SizedBox(height: 6),
                    _QuickActionPageDots(
                      itemCount: pages.length,
                      activeIndex: _page,
                    ),
                  ],
                  const SizedBox(height: 9),
                  _ExploreAllFeaturesRow(onTap: widget.actions.onOpenMore),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.assetPath,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(EquranRadii.medium);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              colors.primary.withAlpha(18),
              colors.surfaceSoft,
            ),
            borderRadius: radius,
            border: Border.all(color: colors.border.withAlpha(130)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.mint.withAlpha(135),
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withAlpha(22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: assetPath == null
                      ? Icon(icon, color: colors.primary, size: 30)
                      : Image.asset(
                          assetPath!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(icon, color: colors.primary, size: 30);
                          },
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
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

class _ExploreAllFeaturesRow extends StatelessWidget {
  const _ExploreAllFeaturesRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(EquranRadii.medium);
    final localizations = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface.withAlpha(120),
            borderRadius: radius,
            border: Border.all(color: colors.border.withAlpha(120)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.mint,
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    border: Border.all(color: colors.border.withAlpha(110)),
                  ),
                  child: Image.asset(
                    _settingsAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.dashboard_customize_outlined,
                        color: colors.primary,
                        size: 21,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localizations.exploreAllFeatures,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  localizations.localeName == 'ar' ||
                          localizations.localeName == 'fa' ||
                          localizations.localeName == 'ur'
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  color: colors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionPageDots extends StatelessWidget {
  const _QuickActionPageDots({
    required this.itemCount,
    required this.activeIndex,
  });

  final int itemCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(itemCount, (index) {
        final bool active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 14 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? colors.primary : colors.border,
            borderRadius: BorderRadius.circular(EquranRadii.pill),
          ),
        );
      }),
    );
  }
}

class _DailyAyahPreview extends StatefulWidget {
  const _DailyAyahPreview({required this.ayah, required this.onOpenQuran});

  final _DailyAyah ayah;
  final VoidCallback onOpenQuran;

  @override
  State<_DailyAyahPreview> createState() => _DailyAyahPreviewState();
}

class _DailyAyahPreviewState extends State<_DailyAyahPreview> {
  @override
  void initState() {
    super.initState();
    _loadFontIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _DailyAyahPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayah.surah != widget.ayah.surah ||
        oldWidget.ayah.verse != widget.ayah.verse) {
      _loadFontIfNeeded();
    }
  }

  Future<void> _loadFontIfNeeded() async {
    final String style = SettingsDB().quranScriptStyle;
    if (style == 'qpc-v4') {
      final int page = EquranTextStyles.getPageNumber(
        widget.ayah.surah,
        widget.ayah.verse,
      );
      final bool loaded = await QpcV4FontService.instance
          .ensureFontLoadedForPage(page);
      if (loaded && mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _DailyAyah ayah = widget.ayah;
    final VoidCallback onOpenQuran = widget.onOpenQuran;
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EquranSectionHeader(
          icon: Icons.local_florist_outlined,
          title: localizations.dailyAyah,
          actionLabel: localizations.seeAll,
          onAction: onOpenQuran,
        ),
        const SizedBox(height: 10),
        _HomePremiumCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) =>
                  ReadPage(chapter: ayah.surah, startVerse: ayah.verse),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
          baseColor: colors.surface,
          accentColor: colors.primary,
          assetPath: _designAsset,
          assetOpacity: 0.055,
          assetWidth: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      localizations.surahLabel(
                        localizedSurahName(localizations, ayah.surah),
                        ayah.verse,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    localizations.localeName == 'ar' ||
                            localizations.localeName == 'fa' ||
                            localizations.localeName == 'ur'
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                quranVerseText(ayah.surah, ayah.verse),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    EquranTextStyles.arabicBody(
                      context,
                      color: colors.textPrimary,
                    ).copyWith(
                      fontFamily: EquranTextStyles.fontFamilyForVerse(
                        ayah.surah,
                        ayah.verse,
                      ),
                      height: 1.7,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                ayah.translation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyDuaPreview extends StatefulWidget {
  const _DailyDuaPreview({required this.date, required this.onOpenDuas});

  final DateTime date;
  final VoidCallback onOpenDuas;

  @override
  State<_DailyDuaPreview> createState() => _DailyDuaPreviewState();
}

class _DailyDuaPreviewState extends State<_DailyDuaPreview> {
  late final DailyDuaRepository _dailyDuaRepository;
  Future<DailyDuaPayload>? _dailyDuaFuture;

  @override
  void initState() {
    super.initState();
    _dailyDuaRepository = DailyDuaRepository();
    _dailyDuaFuture = _dailyDuaRepository.getDailyDua(widget.date);
  }

  @override
  void didUpdateWidget(_DailyDuaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _dailyDuaFuture = _dailyDuaRepository.getDailyDua(widget.date);
    }
  }

  void _retryDailyDua() {
    setState(() {
      _dailyDuaFuture = _dailyDuaRepository.getDailyDua(widget.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DailyDuaPayload>(
      future: _dailyDuaFuture,
      builder: (BuildContext context, AsyncSnapshot<DailyDuaPayload> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: SizedBox.square(
                dimension: 30,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildUnavailableState(context);
        }

        final DailyDuaPayload payload = snapshot.data!;
        final DuaEntry dua = payload.dua;
        final DuaCategoryIndex categoryIndex = payload.categoryIndex;
        final ThemeData theme = Theme.of(context);
        final EquranColors colors = context.equranColors;
        final AppLocalizations localizations = AppLocalizations.of(context)!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            EquranSectionHeader(
              icon: Icons.wb_twilight_rounded,
              title: localizations.dailyDua,
              actionLabel: localizations.seeAll,
              onAction: widget.onOpenDuas,
            ),
            const SizedBox(height: 10),
            _HomePremiumCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => DuasCategoryPage(
                    categoryIndex: categoryIndex,
                    repository: HisnAlMuslimRepository(),
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
              baseColor: colors.surface,
              accentColor: colors.accentGold,
              assetPath: _duaAsset,
              assetOpacity: 0.055,
              assetWidth: 170,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          categoryIndex.localizedTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        localizations.localeName == 'ar' ||
                                localizations.localeName == 'fa' ||
                                localizations.localeName == 'ur'
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        color: colors.accentGold,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    dua.text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: EquranTextStyles.arabicBody(
                      context,
                      color: colors.textPrimary,
                    ).copyWith(height: 1.7),
                  ),
                  if (dua.localizedTranslation(localizations.localeName) !=
                      null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      dua.localizedTranslation(localizations.localeName)!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnavailableState(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EquranSectionHeader(
          icon: Icons.wb_twilight_rounded,
          title: localizations.dailyDua,
          actionLabel: localizations.seeAll,
          onAction: widget.onOpenDuas,
        ),
        const SizedBox(height: 10),
        _HomePremiumCard(
          baseColor: colors.surface,
          accentColor: colors.textSecondary,
          assetPath: _duaAsset,
          assetOpacity: 0.045,
          assetWidth: 150,
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.cloud_off_rounded,
                color: colors.textMuted,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      localizations.duasUnavailable,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.hisnAlMuslimNotLoaded,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: _retryDailyDua,
                child: Text(localizations.retryAction),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _DashboardLastReadSection extends StatelessWidget {
  const _DashboardLastReadSection({
    required this.entry,
    required this.onOpenQuran,
  });

  final ResumeStateEntry? entry;
  final VoidCallback onOpenQuran;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final ResumeStateEntry? current = entry;
    final int? surah = current?.surah;
    final int? ayah = current?.ayah;
    final bool hasResume = surah != null && ayah != null;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String title = hasResume
        ? localizedSurahName(localizations, surah)
        : localizations.beginWithQuran;
    final String subtitle = hasResume
        ? localizations.ayahNumber(ayah)
        : localizations.startReading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          localizations.lastRead,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        EquranGradientCard(
          onTap: hasResume
              ? () => _openReading(context, surah, ayah)
              : onOpenQuran,
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -18,
                top: -6,
                bottom: -10,
                width: 172,
                child: Opacity(
                  opacity: 0.82,
                  child: Image.asset(
                    hasResume ? _quranAsset : _lastReadAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 142),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onPrimaryMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: SizedBox(
                        width: 112,
                        child: Divider(
                          height: 1,
                          color: colors.onPrimary.withAlpha(52),
                        ),
                      ),
                    ),
                    Text(
                      hasResume
                          ? localizations.continueReading
                          : localizations.startReading,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openReading(BuildContext context, int surah, int ayah) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReadPage(chapter: surah, startVerse: ayah),
      ),
    );
  }
}

class _JourneyPreviewCard extends StatelessWidget {
  const _JourneyPreviewCard({
    required this.stats,
    required this.activity,
    required this.latestReadingActivityDate,
    required this.onOpenStats,
  });

  final QuranStatsSnapshot? stats;
  final QuranActivityDay? activity;
  final DateTime? latestReadingActivityDate;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final QuranStatsSnapshot snapshot =
        stats ?? QuranStatsSnapshot(id: 'summary', updatedAt: DateTime.now());
    final int ayahsRead = activity?.ayahsRead ?? 0;
    final int dailyGoal = _dailyQuranGoalAyahs();
    final double progress = (ayahsRead / dailyGoal).clamp(0.0, 1.0).toDouble();
    final int progressPercent = (progress * 100).round();
    final bool showStreak = shouldShowJourneyStreak(
      currentStreak: snapshot.currentStreak,
      lastReadingActivityDate: latestReadingActivityDate,
      now: DateTime.now(),
    );

    return _HomePremiumCard(
      onTap: onOpenStats,
      baseColor: colors.paleGreen,
      accentColor: colors.primary,
      assetPath: _designAsset,
      assetOpacity: 0.055,
      assetWidth: 190,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.quranJourney,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              EquranIconBadge(
                icon: Icons.auto_stories_outlined,
                size: 36,
                backgroundColor: colors.mint,
                foregroundColor: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$ayahsRead / $dailyGoal',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  AppLocalizations.of(context)!.ayahsToday,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: colors.primary,
                    backgroundColor: colors.mint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$progressPercent%',
                textAlign: TextAlign.right,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              if (showStreak) ...<Widget>[
                _JourneyStreakChip(streak: snapshot.currentStreak),
                const SizedBox(width: 8),
              ],
              _JourneyMetricChip(
                label: AppLocalizations.of(
                  context,
                )!.lettersCount(snapshot.estimatedLettersRead),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

int _dailyQuranGoalAyahs() {
  final dynamic saved = SettingsDB().get('dailyQuranGoalAyahs');
  if (saved is int) return saved.clamp(1, 1000).toInt();
  if (saved is String) {
    return (int.tryParse(saved) ?? 20).clamp(1, 1000).toInt();
  }
  return 20;
}

// ignore: unused_element
class _HomeMetricPill extends StatelessWidget {
  const _HomeMetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(EquranRadii.pill),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: colors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyStreakChip extends StatelessWidget {
  const _JourneyStreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    return Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.goldSoft,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: colors.accentGold.withAlpha(102)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.local_fire_department_rounded,
                color: colors.accentGold,
                size: 15,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.dayStreakCount(streak),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w800,
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

class _JourneyMetricChip extends StatelessWidget {
  const _JourneyMetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceAlt.withValues(alpha: isLight ? 0.60 : 0.30),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _PersonalLibraryPreview extends StatelessWidget {
  const _PersonalLibraryPreview({
    required this.bookmarks,
    required this.onOpenQuran,
  });

  final List<QuranBookmarkEntry> bookmarks;
  final VoidCallback onOpenQuran;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;

    return _HomePremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      baseColor: colors.surface,
      accentColor: colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EquranSectionHeader(
            icon: Icons.bookmark_border_rounded,
            title: AppLocalizations.of(context)!.personalLibrary,
            actionLabel: bookmarks.isEmpty
                ? null
                : AppLocalizations.of(context)!.seeAll,
            onAction: onOpenQuran,
          ),
          const SizedBox(height: 6),
          if (bookmarks.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: colors.mint.withAlpha(120),
                borderRadius: BorderRadius.circular(EquranRadii.medium),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.bookmark_add_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.saveAyahsNotesHere,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final QuranBookmarkEntry bookmark in bookmarks.take(2))
              _LibraryPreviewTile(bookmark: bookmark),
        ],
      ),
    );
  }
}

class _LibraryPreviewTile extends StatelessWidget {
  const _LibraryPreviewTile({required this.bookmark});

  final QuranBookmarkEntry bookmark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              ReadPage(chapter: bookmark.surah, startVerse: bookmark.verse),
        ),
      ),
      borderRadius: BorderRadius.circular(EquranRadii.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.mint,
                borderRadius: BorderRadius.circular(EquranRadii.medium),
              ),
              alignment: Alignment.center,
              child: Text(
                bookmark.verse.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)!.surahLabel(
                      localizedSurahName(
                        AppLocalizations.of(context)!,
                        bookmark.surah,
                      ),
                      bookmark.verse,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    bookmark.note.trim().isEmpty
                        ? bookmark.folder
                        : bookmark.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.gradient = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color base = colors.surfaceContainerLow;
    final BorderRadius radius = BorderRadius.circular(AppRadii.large);
    final BoxDecoration decoration = BoxDecoration(
      color: base,
      gradient: gradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(
                  colors.primary.withAlpha(gradient ? 28 : 0),
                  base,
                ),
                Color.alphaBlend(colors.tertiary.withAlpha(18), base),
                base,
              ],
            )
          : null,
      borderRadius: radius,
      border: Border.all(
        color: colors.outlineVariant.withAlpha(isLight ? 150 : 115),
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: colors.shadow.withAlpha(isLight ? 18 : 26),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: decoration,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _PrayerDashboardCard extends StatelessWidget {
  const _PrayerDashboardCard({
    required this.prayerSummary,
    required this.exactAlarmPermission,
    required this.onOpenPrayerTimes,
  });

  final _PrayerSummary prayerSummary;
  final PrayerExactAlarmPermissionStatus? exactAlarmPermission;
  final VoidCallback onOpenPrayerTimes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final PrayerDay? day = prayerSummary.day;
    final NextPrayer? nextPrayer = prayerSummary.nextPrayer;

    if (day == null || nextPrayer == null) {
      return _DashboardCard(
        gradient: true,
        onTap: onOpenPrayerTimes,
        child: _EmptyCardContent(
          icon: Icons.access_time_rounded,
          title: 'Prayer times',
          message: 'Choose a location to show the next prayer here.',
          actionLabel: 'Set up',
        ),
      );
    }

    final PrayerTimeSettings settings = day.settings;
    final String methodLabel = prayerMethodDisplayLabel(
      settings: settings,
      effectiveMethod: day.effectiveMethod,
    );
    final bool exactAlarmDenied =
        exactAlarmPermission == PrayerExactAlarmPermissionStatus.denied;

    return _DashboardCard(
      gradient: true,
      onTap: onOpenPrayerTimes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _IconTile(icon: Icons.access_time_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Next prayer',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      prayerSummary.location?.displayLabel ?? 'Saved location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nextPrayer.entry.kind.label,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(
                icon: Icons.hourglass_bottom_rounded,
                label: _formatCountdown(nextPrayer.countdown),
              ),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: _formatTime(
                  nextPrayer.entry.time,
                  settings.use24HourFormat,
                  localizations,
                ),
              ),
              _InfoPill(icon: Icons.calculate_outlined, label: methodLabel),
            ],
          ),
          const SizedBox(height: 14),
          _CompactPrayerTimes(
            day: day,
            use24HourFormat: settings.use24HourFormat,
          ),
          if (exactAlarmDenied) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Exact alarm permission is off. Prayer reminders may be delayed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.error,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeQuranLastReadCard extends StatelessWidget {
  const _HomeQuranLastReadCard({
    required this.entry,
    required this.onOpenQuran,
  });

  final ResumeStateEntry? entry;
  final VoidCallback onOpenQuran;

  @override
  Widget build(BuildContext context) {
    final ResumeStateEntry? current = entry;
    final int? surah = current?.surah;
    final int? ayah = current?.ayah;
    final localizations = AppLocalizations.of(context)!;
    final Widget card;
    if (surah == null || ayah == null) {
      card = EquranResumeImageCard(
        primary: localizations.beginWithQuran,
        subtitle: localizations.startReadingSubtitle,
        actionText:
            localizations.localeName == 'ar' ||
                localizations.localeName == 'fa' ||
                localizations.localeName == 'ur'
            ? '<- ${localizations.startReading}'
            : '${localizations.startReading} ->',
        trailingAssetPath: _quranAsset,
        onTap: onOpenQuran,
        enforceCompactWidth: false,
      );
    } else {
      card = EquranResumeImageCard(
        primary: localizedSurahName(localizations, surah),
        subtitle: localizations.ayahNumber(ayah),
        actionText:
            localizations.localeName == 'ar' ||
                localizations.localeName == 'fa' ||
                localizations.localeName == 'ur'
            ? '<- ${localizations.continueReading}'
            : '${localizations.continueReading} ->',
        trailingAssetPath: _quranAsset,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => ReadPage(chapter: surah, startVerse: ayah),
          ),
        ),
        enforceCompactWidth: false,
      );
    }

    return HolographicCardWrapper(child: card);
  }
}

// _ContinueListeningCard retired

// ignore: unused_element
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.activity});

  final QuranActivityDay? activity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int ayahsRead = activity?.ayahsRead ?? 0;
    const int dailyGoal = 20;
    final double progress = (ayahsRead / dailyGoal).clamp(0.0, 1.0).toDouble();

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel(
            icon: Icons.local_florist_outlined,
            label: 'Daily goal',
          ),
          const SizedBox(height: 12),
          Text(
            '$ayahsRead / $dailyGoal ayahs',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ayahsRead == 0
                ? 'Reading activity tracking is ready for today.'
                : 'May Allah bless your consistency.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ReadingPlanCard extends StatelessWidget {
  const _ReadingPlanCard({required this.plan});

  final ReadingPlanEntry? plan;

  @override
  Widget build(BuildContext context) {
    final ReadingPlanEntry? activePlan = plan;
    if (activePlan == null) {
      return const _DashboardCard(
        child: _EmptyCardContent(
          icon: Icons.route_outlined,
          title: 'Reading plan',
          message: 'Plans for 7, 30, 60 days and Ramadan are scaffolded.',
        ),
      );
    }

    final RoutineProgressSummary progress = routineProgressSummary(activePlan);
    final int total = progress.totalAyahs;
    final int done = progress.completedAyahs;

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel(
            icon: Icons.route_outlined,
            label: 'Reading plan',
          ),
          const SizedBox(height: 12),
          Text(
            activePlan.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text('$done / $total ayahs completed'),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.actions});

  final HomeDashboardPage actions;

  @override
  Widget build(BuildContext context) {
    final List<_QuickAction> items = <_QuickAction>[
      _QuickAction(Icons.menu_book_outlined, 'Quran', actions.onOpenQuran),
      _QuickAction(
        Icons.access_time_outlined,
        'Prayer',
        actions.onOpenPrayerTimes,
      ),
      _QuickAction(Icons.explore_outlined, 'Qibla', actions.onOpenQibla),
      _QuickAction(Icons.auto_stories_outlined, 'Duas', actions.onOpenDuas),
      _QuickAction(
        Icons.download_outlined,
        'Downloads',
        actions.onOpenDownloads,
      ),
      _QuickAction(Icons.search_rounded, 'Search', actions.onOpenSearch),
    ];

    return _DashboardCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel(icon: Icons.apps_rounded, label: 'Quick actions'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final int columns = constraints.maxWidth >= 720
                  ? 6
                  : constraints.maxWidth >= 460
                  ? 3
                  : 2;
              return GridView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: columns >= 4 ? 1.05 : 1.35,
                ),
                itemBuilder: (context, index) {
                  final _QuickAction item = items[index];
                  return _QuickActionTile(item: item);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _DailyAyahCard extends StatelessWidget {
  const _DailyAyahCard({required this.ayah});

  final _DailyAyah ayah;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return _DashboardCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              ReadPage(chapter: ayah.surah, startVerse: ayah.verse),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionLabel(
            icon: Icons.wb_sunny_outlined,
            label: AppLocalizations.of(context)!.surahLabel(
              localizedSurahName(AppLocalizations.of(context)!, ayah.surah),
              ayah.verse,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            ayah.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: EquranTextStyles.activeFontFamily,
              fontFamilyFallback: const <String>['UthmanicHafs'],
              fontSize: 28,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ayah.translation,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StatsPreviewCard extends StatelessWidget {
  const _StatsPreviewCard({required this.stats, required this.activity});

  final QuranStatsSnapshot? stats;
  final QuranActivityDay? activity;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final QuranStatsSnapshot snapshot =
        stats ?? QuranStatsSnapshot(id: 'summary', updatedAt: DateTime.now());
    final int today = activity?.ayahsRead ?? 0;

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionLabel(
            icon: Icons.insights_outlined,
            label: localizations.statistics,
          ),
          const SizedBox(height: 14),
          _MetricRow(
            label: localizations.today,
            value: localizations.ayahsCount(today),
          ),
          _MetricRow(
            label: localizations.totalRead,
            value: localizations.ayahsCount(snapshot.totalAyahsRead),
          ),
          _MetricRow(
            label: localizations.streaksLabel,
            value: localizations.daysCount(snapshot.currentStreak),
          ),
          _MetricRow(
            label: localizations.estimatedLettersRead,
            value: '${snapshot.estimatedLettersRead}',
          ),
          const SizedBox(height: 8),
          Text(
            localizations.rewardIsWithAllah,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _BookmarksPreviewCard extends StatelessWidget {
  const _BookmarksPreviewCard({required this.bookmarks});

  final List<QuranBookmarkEntry> bookmarks;

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return const _DashboardCard(
        child: _EmptyCardContent(
          icon: Icons.bookmark_border_rounded,
          title: 'Bookmarks and notes',
          message: 'Favourites and private ayah notes will appear here.',
        ),
      );
    }

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel(
            icon: Icons.bookmark_border_rounded,
            label: 'Bookmarks and notes',
          ),
          const SizedBox(height: 10),
          for (final QuranBookmarkEntry bookmark in bookmarks)
            _BookmarkPreviewTile(bookmark: bookmark),
        ],
      ),
    );
  }
}

class _BookmarkPreviewTile extends StatelessWidget {
  const _BookmarkPreviewTile({required this.bookmark});

  final QuranBookmarkEntry bookmark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: colors.primaryContainer,
        child: Text(
          bookmark.verse.toString(),
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.surahLabel(
          localizedSurahName(AppLocalizations.of(context)!, bookmark.surah),
          bookmark.verse,
        ),
      ),
      subtitle: Text(
        bookmark.note.trim().isEmpty ? bookmark.folder : bookmark.note,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              ReadPage(chapter: bookmark.surah, startVerse: bookmark.verse),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ResumeCardContent extends StatelessWidget {
  const _ResumeCardContent({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionLabel(icon: icon, label: label),
        const SizedBox(height: 14),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _IconTile(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (actionLabel != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  actionLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withAlpha(190),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Icon(icon, color: colors.onPrimaryContainer),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: colors.outlineVariant.withAlpha(130)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CompactPrayerTimes extends StatelessWidget {
  const _CompactPrayerTimes({required this.day, required this.use24HourFormat});

  final PrayerDay day;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: day.entries
          .map((PrayerTimeEntry entry) {
            return _InfoPill(
              icon: entry.kind == PrayerTimeKind.sunrise
                  ? Icons.wb_sunny_outlined
                  : Icons.nights_stay_outlined,
              label:
                  '${entry.kind.label} ${_formatTime(entry.time, use24HourFormat, localizations)}',
            );
          })
          .toList(growable: false),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap, {this.assetPath});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? assetPath;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.item});

  final _QuickAction item;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(AppRadii.medium);
    return Material(
      color: colors.surfaceContainer,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant.withAlpha(110)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(item.icon, color: colors.primary),
              const SizedBox(height: 7),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _AyahRef {
  const _AyahRef({required this.surah, required this.verse});

  final int surah;
  final int verse;
}

class _RoutineDayProgress {
  const _RoutineDayProgress({
    required this.portionLabel,
    required this.statusLabel,
    required this.fraction,
  });

  final String portionLabel;
  final String statusLabel;
  final double fraction;
}

_RoutineDayProgress _routineDayProgress(
  ReadingPlanEntry plan,
  AppLocalizations localizations,
) {
  final RoutineProgressSummary progress = routineProgressSummary(plan);
  final String statusLabel = progress.isTodayDone
      ? localizations.todaysPortionComplete
      : progress.catchUpAyahs > 0
      ? localizations.catchUpAyahsIncluded(progress.catchUpAyahs)
      : localizations.ayahsRemainingToday(progress.todayRemainingAyahs);
  return _RoutineDayProgress(
    portionLabel: localizations.todaysPortion(progress.todayPortionAyahs),
    statusLabel: statusLabel,
    fraction: progress.todayFraction,
  );
}

_AyahRef _routineContinueRef(ReadingPlanEntry plan) {
  return _ayahRefFromGlobalIndex(
    routineProgressSummary(plan).nextUnreadGlobalAyah,
  );
}

_AyahRef _ayahRefFromGlobalIndex(int globalAyah) {
  int remaining = globalAyah.clamp(1, quran.totalVerseCount).toInt();
  for (int surah = 1; surah <= 114; surah++) {
    final int verseCount = quran.getVerseCount(surah);
    if (remaining <= verseCount) {
      return _AyahRef(surah: surah, verse: remaining);
    }
    remaining -= verseCount;
  }
  return const _AyahRef(surah: 114, verse: 6);
}

int _translationIndex() {
  final dynamic saved = SettingsDB().get('translation', defaultValue: 0);
  if (saved is int && saved >= 0 && saved < quran.Translation.values.length) {
    return saved;
  }
  return 0;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _formatDashboardDate(DateTime now) {
  const List<String> weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}

String? _heroTitleOverrideFor(
  PrayerCurrentPeriod period,
  AppLocalizations localizations,
) {
  return switch (period.type) {
    PrayerCurrentPeriodType.sunriseProhibited =>
      localizations.prayerNameSunrise,
    PrayerCurrentPeriodType.dhuhrProhibited => localizations.zawal,
    PrayerCurrentPeriodType.sunsetProhibited => localizations.sunset,
    PrayerCurrentPeriodType.beforeDhuhr => localizations.morning,
    PrayerCurrentPeriodType.normalPrayer => null,
  };
}

String? _heroSubtitleOverrideFor({
  required PrayerCurrentPeriod currentPeriod,
  required NextPrayer nextPrayer,
  required DateTime now,
  required AppLocalizations localizations,
}) {
  return switch (currentPeriod.type) {
    PrayerCurrentPeriodType.sunriseProhibited =>
      localizations.prohibitedTimeEndsIn(
        _formatHeroCountdown(
          currentPeriod.endsAt.difference(now),
          localizations,
        ),
      ),
    PrayerCurrentPeriodType.dhuhrProhibited ||
    PrayerCurrentPeriodType
        .sunsetProhibited => localizations.prohibitedTimeEndsIn(
      _formatHeroCountdown(currentPeriod.endsAt.difference(now), localizations),
    ),
    PrayerCurrentPeriodType.beforeDhuhr => localizations.prayerBeginsIn(
      localizedPrayerName(localizations, nextPrayer.entry.kind),
      _formatHeroCountdown(nextPrayer.countdown, localizations),
    ),
    PrayerCurrentPeriodType.normalPrayer => null,
  };
}

String _formatHeroCountdown(Duration duration, AppLocalizations localizations) {
  final Duration normalized = duration.isNegative ? Duration.zero : duration;
  final int hours = normalized.inHours;
  final int minutes = normalized.inMinutes.remainder(60);
  if (hours <= 0) return localizations.minutesShort(minutes);
  return localizations.hoursMinutesShort(hours, minutes);
}

String _formatTime(
  DateTime time,
  bool use24HourFormat, [
  AppLocalizations? localizations,
]) {
  if (use24HourFormat) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final bool arabic =
      localizations != null && isArabicLocalizations(localizations);
  final String suffix = arabic
      ? (time.hour >= 12 ? 'م' : 'ص')
      : (time.hour >= 12 ? 'PM' : 'AM');
  return '$hour:${time.minute.toString().padLeft(2, '0')} $suffix';
}

String _formatCountdown(Duration duration) {
  final Duration normalized = duration.isNegative ? Duration.zero : duration;
  final int hours = normalized.inHours;
  final int minutes = normalized.inMinutes.remainder(60);
  if (hours <= 0) return '$minutes min';
  return '${hours}h ${minutes}m';
}
