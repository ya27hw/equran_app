import 'dart:async';

import 'package:equran/backend/settings_db.dart';
import 'package:equran/prayer/manual_prayer_location_page.dart';
import 'package:equran/prayer/prayer_map_location_page.dart';
import 'package:equran/prayer/prayer_location_service.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/prayer/prayer_hero_card.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_time_thumb_card.dart';
import 'package:equran/prayer/prayer_times_settings_page.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({
    super.key,
    this.enableLiveCountdown = true,
    this.initialNow,
    this.mapLocationPicker,
    this.locationService,
    this.notificationService,
  });

  final bool enableLiveCountdown;
  final DateTime? initialNow;
  final PrayerLocationPicker? mapLocationPicker;
  final PrayerLocationService? locationService;
  final PrayerNotificationService? notificationService;

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  static const Duration _prayerSnackBarDuration = Duration(seconds: 3);

  final PrayerTimesService _service = const PrayerTimesService();
  final PrayerSettingsStore _store = PrayerSettingsStore();
  late final PrayerLocationService _locationService;
  late final PrayerNotificationService _notificationService;
  Timer? _timer;
  late DateTime _now;
  DateTime? _selectedDate;
  bool _isLocating = false;
  String? _activePrayerSnackBarMessage;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? const PrayerLocationService();
    _notificationService =
        widget.notificationService ?? PrayerNotificationService();
    _now = widget.initialNow ?? DateTime.now();
    unawaited(_refreshCurrentDeviceLocationOnEntry());
    if (widget.enableLiveCountdown) {
      _scheduleNextRefresh();
    }
    if (_store.getLocation() == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chooseOnMap(null);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ValueListenableBuilder(
        valueListenable: SettingsDB().listener,
        builder: (BuildContext context, Object? value, Widget? child) {
          final PrayerLocation? location = _store.getLocation();
          final PrayerTimeSettings settings = _store.getSettings();
          final AppLocalizations localizations = AppLocalizations.of(context)!;
          if (location == null) {
            return _buildSetupState(context);
          }

          final DateTime todayDate = _service.calendarDateForInstant(
            instant: _now,
            location: location,
            settings: settings,
          );
          final PrayerDay today = _service.calculateDay(
            date: todayDate,
            location: location,
            settings: settings,
          );
          final DateTime selectedDate = _selectedDate ?? todayDate;
          final bool isViewingToday = _isSameCalendarDate(
            selectedDate,
            todayDate,
          );
          final PrayerDay selectedDay = isViewingToday
              ? today
              : _service.calculateDay(
                  date: selectedDate,
                  location: location,
                  settings: settings,
                );

          final _PrayerHeroTiming heroTiming;
          final PrayerTimeKind? highlightedPrayer;
          PrayerTimeEntry? heroCurrentPrayer;
          String? heroTitleOverride;
          String? heroSubtitleOverride;
          if (isViewingToday) {
            final PrayerDay yesterday = _service.calculateDay(
              date: DateTime(
                todayDate.year,
                todayDate.month,
                todayDate.day - 1,
              ),
              location: location,
              settings: settings,
            );
            final PrayerDay tomorrow = _service.calculateDay(
              date: DateTime(
                todayDate.year,
                todayDate.month,
                todayDate.day + 1,
              ),
              location: location,
              settings: settings,
            );
            final NextPrayer nextPrayer = _service.nextPrayer(
              day: today,
              tomorrow: tomorrow,
              now: _now,
            );
            heroTiming = _heroTimingFor(nextPrayer);
            final PrayerCurrentPeriod currentPeriod = _service
                .currentPrayerPeriod(
                  today: today,
                  yesterday: yesterday,
                  now: _now,
                );
            highlightedPrayer = currentPeriod.highlightedKind;
            heroCurrentPrayer = currentPeriod.currentPrayer;
            heroTitleOverride = _heroTitleOverrideFor(
              currentPeriod,
              localizations,
            );
            heroSubtitleOverride = _heroSubtitleOverrideFor(
              currentPeriod: currentPeriod,
              nextPrayer: nextPrayer,
              now: _now,
              localizations: localizations,
            );
          } else {
            heroTiming = _selectedDateHeroTiming(selectedDay);
            highlightedPrayer = null;
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              EquranSpacing.pagePadding,
              14,
              EquranSpacing.pagePadding,
              28,
            ),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      PrayerHeroCard(
                        day: selectedDay,
                        nextPrayer: NextPrayer(
                          entry: heroTiming.entry,
                          countdown: heroTiming.countdown,
                        ),
                        currentPrayer: heroCurrentPrayer,
                        titleOverride: heroTitleOverride,
                        subtitleOverride:
                            heroSubtitleOverride ??
                            (isViewingToday
                                ? null
                                : _formatDate(selectedDate, localizations)),
                        onTap: _openPrayerSettings,
                      ),
                      const SizedBox(height: 14),
                      _buildPrayerInfoCard(
                        context,
                        selectedDay,
                        isViewingToday,
                      ),
                      const SizedBox(height: 12),
                      _buildNightTimesCard(context, selectedDay, settings),
                      const SizedBox(height: 14),
                      _buildPrayerGrid(
                        context,
                        selectedDay,
                        highlightedPrayer,
                        settings,
                      ),
                      const SizedBox(height: 14),
                      _buildDisclaimer(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSetupState(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;
    final TextStyle? buttonTextStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colors.mint,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Icon(
                            Icons.add_location_alt_outlined,
                            color: colors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.prayerTimesNeedLocation,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.prayerTimesLocationSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        localizations.locationUseNotice,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.textMuted,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _chooseOnMap(null),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            textStyle: buttonTextStyle,
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: Text(localizations.setUpLocation),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        localizations.timesCalculatedLocally,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerInfoCard(
    BuildContext context,
    PrayerDay day,
    bool isViewingToday,
  ) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;
    final String dateLabel = isViewingToday
        ? localizations.today
        : _formatDate(day.date, localizations);
    final BorderRadius dateButtonRadius = BorderRadius.circular(
      AppRadii.medium,
    );

    return EquranSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      backgroundColor: colors.surface,
      borderColor: colors.border,
      child: Row(
        children: <Widget>[
          _PrayerDateArrowButton(
            icon: Icons.chevron_left_rounded,
            tooltip: localizations.previousDay,
            onPressed: () => _movePrayerDate(day.date, -1),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: dateButtonRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: dateButtonRadius,
                onTap: () => _selectPrayerDate(day.date),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          dateLabel,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      // Integrated current Hijri date (small elegant gold text)
                      Builder(
                        builder: (BuildContext context) {
                          final int offset =
                              SettingsDB().get('hijri_offset', defaultValue: 0)
                                  as int;
                          final HijriCalendar hijri = HijriCalendar.fromDate(
                            day.date,
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
              ),
            ),
          ),
          _PrayerDateArrowButton(
            icon: Icons.chevron_right_rounded,
            tooltip: localizations.nextDay,
            onPressed: () => _movePrayerDate(day.date, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNightTimesCard(
    BuildContext context,
    PrayerDay day,
    PrayerTimeSettings settings,
  ) {
    final EquranColors colors = context.equranColors;
    final _NightTimes nightTimes = _nightTimesFor(day);
    final localizations = AppLocalizations.of(context)!;

    return EquranSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      backgroundColor: colors.paleGreen,
      borderColor: colors.border,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _NightTimeValue(
              icon: Icons.nights_stay_outlined,
              label: localizations.middleOfNight,
              value: _formatTime(
                nightTimes.middle,
                settings.use24HourFormat,
                localizations,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NightTimeValue(
              icon: Icons.dark_mode_outlined,
              label: localizations.lastThirdStarts,
              value: _formatTime(
                nightTimes.lastThirdStart,
                settings.use24HourFormat,
                localizations,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerGrid(
    BuildContext context,
    PrayerDay day,
    PrayerTimeKind? highlightedKind,
    PrayerTimeSettings settings,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 700 ? 3 : 2;
        return GridView.builder(
          itemCount: day.entries.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: columns == 3 ? 146 : 142,
          ),
          itemBuilder: (BuildContext context, int index) {
            final PrayerTimeEntry entry = day.entries[index];
            return PrayerTimeThumbCard(
              entry: entry,
              isActive:
                  highlightedKind != null && entry.kind == highlightedKind,
              use24HourFormat: settings.use24HourFormat,
            );
          },
        );
      },
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(110),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: colors.border.withAlpha(140)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline_rounded, color: colors.textMuted, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localizations.prayerTimesDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshCurrentDeviceLocationOnEntry() async {
    final PrayerLocation? savedLocation = _store.getLocation();
    if (savedLocation?.mode != PrayerLocationMode.currentDevice) return;

    setState(() {
      _isLocating = true;
    });
    final PrayerLocationResult result = await _locationService
        .currentDeviceLocation();
    if (!mounted) return;
    setState(() {
      _isLocating = false;
    });

    final PrayerLocation? location = result.location;
    if (location == null) {
      _showLocationError(result);
      return;
    }

    await _store.saveLocation(location);
    await _rescheduleReminders(location);
  }

  Future<void> _chooseOnMap(PrayerLocation? initialLocation) async {
    final PrayerLocationPicker picker =
        widget.mapLocationPicker ?? showPrayerMapLocationPicker;
    final PrayerLocation? location = await picker(context, initialLocation);
    if (location == null) return;
    await _saveResolvedLocation(location);
    if (!mounted) return;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    _showMessage(localizations.locationSaved);
  }

  // ignore: unused_element
  Future<void> _showLocationDetails(PrayerLocation location) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return _LocationDetailsSheet(
          location: location,
          isLocating: _isLocating,
          onUpdateCurrentLocation: () {
            Navigator.of(sheetContext).pop();
          },
          onChooseMap: () {
            Navigator.of(sheetContext).pop();
            _chooseOnMap(location);
          },
          onSave: (_LocationDetailsSave detailsSave) async {
            await _saveResolvedLocation(
              detailsSave.location,
              previousLocation: location,
              preserveCustomLabel: detailsSave.preserveCustomLabel,
            );
            if (!mounted || !sheetContext.mounted) return;
            Navigator.of(sheetContext).pop();
            final AppLocalizations localizations = AppLocalizations.of(
              context,
            )!;
            _showMessage(localizations.locationSaved);
          },
        );
      },
    );
  }

  Future<void> _saveResolvedLocation(
    PrayerLocation location, {
    PrayerLocation? previousLocation,
    bool preserveCustomLabel = false,
  }) async {
    final EquranColors colors = context.equranColors;
    final PrayerLocation resolvedLocation = await _locationService
        .resolveLocationForSave(
          location,
          previousLocation: previousLocation ?? _store.getLocation(),
          preserveCustomLabel: preserveCustomLabel,
        );
    await _store.saveLocation(resolvedLocation);
    await _rescheduleReminders(resolvedLocation);
    unawaited(PrayerWidgetService.refreshWidget(colors: colors));
  }

  Future<void> _rescheduleReminders(PrayerLocation location) async {
    final PrayerTimeSettings settings = _store.getSettings();
    final PrayerNotificationScheduleResult result = await _notificationService
        .reschedule(settings: settings, location: location);
    if (result.status == PrayerNotificationScheduleStatus.permissionDenied &&
        settings.reminderSettings.remindersEnabled) {
      await _store.saveSettings(
        settings.copyWith(
          reminderSettings: settings.reminderSettings.copyWith(
            remindersEnabled: false,
          ),
        ),
      );
      if (!mounted) return;
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      _showMessage(localizations.notificationPermissionOffWarning);
    } else if (result.status ==
            PrayerNotificationScheduleStatus.exactAlarmDenied &&
        settings.reminderSettings.remindersEnabled) {
      if (!mounted) return;
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      _showMessage(localizations.exactAlarmPermissionOffWarning);
    }
  }

  void _openPrayerSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const PrayerTimesSettingsPage(),
      ),
    );
  }

  Future<void> _selectPrayerDate(DateTime currentDate) async {
    final DateTime initialDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: AppLocalizations.of(context)!.selectPrayerDate,
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  void _movePrayerDate(DateTime currentDate, int dayDelta) {
    setState(() {
      _selectedDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day + dayDelta,
      );
    });
  }

  void _showMessage(String message) {
    _showPrayerSnackBar(message);
  }

  void _showLocationError(PrayerLocationResult result) {
    final localizations = AppLocalizations.of(context)!;
    final String message = result.message ?? localizations.unableGetLocation;
    final PrayerLocationFailureReason? reason = result.failureReason;
    final SnackBarAction? action = switch (reason) {
      PrayerLocationFailureReason.servicesDisabled => SnackBarAction(
        label: localizations.settings,
        onPressed: () {
          _locationService.openLocationSettings();
        },
      ),
      PrayerLocationFailureReason.permissionDeniedForever => SnackBarAction(
        label: localizations.appSettings,
        onPressed: () {
          _locationService.openAppSettings();
        },
      ),
      _ => null,
    };
    _showPrayerSnackBar(message, action: action);
  }

  void _showPrayerSnackBar(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    if (_activePrayerSnackBarMessage == message) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    _activePrayerSnackBarMessage = message;

    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller =
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            action: action,
            duration: _prayerSnackBarDuration,
            // Action snackbars persist by default; keep prayer prompts timed.
            persist: false,
          ),
        );
    unawaited(
      controller.closed.then((_) {
        if (_activePrayerSnackBarMessage == message) {
          _activePrayerSnackBarMessage = null;
        }
      }),
    );
  }

  void _scheduleNextRefresh() {
    _timer?.cancel();
    final DateTime now = DateTime.now();
    final Duration elapsedThisMinute = Duration(
      seconds: now.second,
      milliseconds: now.millisecond,
      microseconds: now.microsecond,
    );
    final Duration delay = elapsedThisMinute == Duration.zero
        ? const Duration(minutes: 1)
        : const Duration(minutes: 1) - elapsedThisMinute;

    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
      unawaited(PrayerWidgetService.refreshWidget(context: context));
      _scheduleNextRefresh();
    });
  }
}

class _PrayerHeroTiming {
  const _PrayerHeroTiming({
    required this.entry,
    required this.countdown,
    required this.isNow,
  });

  final PrayerTimeEntry entry;
  final Duration countdown;
  final bool isNow;
}

_PrayerHeroTiming _heroTimingFor(NextPrayer nextPrayer) {
  return _PrayerHeroTiming(
    entry: nextPrayer.entry,
    countdown: nextPrayer.countdown,
    isNow: false,
  );
}

_PrayerHeroTiming _selectedDateHeroTiming(PrayerDay day) {
  return _PrayerHeroTiming(
    entry: day.entryFor(PrayerTimeKind.fajr),
    countdown: Duration.zero,
    isNow: false,
  );
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

class _NightTimes {
  const _NightTimes({required this.middle, required this.lastThirdStart});

  final DateTime middle;
  final DateTime lastThirdStart;
}

_NightTimes _nightTimesFor(PrayerDay day) {
  final DateTime maghrib = day.entryFor(PrayerTimeKind.maghrib).time;
  DateTime fajr = day.entryFor(PrayerTimeKind.fajr).time;
  if (!fajr.isAfter(maghrib)) {
    fajr = fajr.add(const Duration(days: 1));
  }
  final Duration night = fajr.difference(maghrib);
  return _NightTimes(
    middle: maghrib.add(Duration(microseconds: night.inMicroseconds ~/ 2)),
    lastThirdStart: maghrib.add(
      Duration(microseconds: (night.inMicroseconds * 2) ~/ 3),
    ),
  );
}

bool _isSameCalendarDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _LocationDetailsSheet extends StatefulWidget {
  const _LocationDetailsSheet({
    required this.location,
    required this.isLocating,
    required this.onUpdateCurrentLocation,
    required this.onChooseMap,
    required this.onSave,
  });

  final PrayerLocation location;
  final bool isLocating;
  final VoidCallback onUpdateCurrentLocation;
  final VoidCallback onChooseMap;
  final Future<void> Function(_LocationDetailsSave location) onSave;

  @override
  State<_LocationDetailsSheet> createState() => _LocationDetailsSheetState();
}

class _LocationDetailsSheetState extends State<_LocationDetailsSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final String _initialLabel;
  late final String _initialLatitudeText;
  late final String _initialLongitudeText;
  bool _advancedExpanded = false;
  bool _hasFieldChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialLabel = widget.location.displayLabel;
    _initialLatitudeText = widget.location.latitude.toStringAsFixed(6);
    _initialLongitudeText = widget.location.longitude.toStringAsFixed(6);
    _labelController = TextEditingController(text: _initialLabel);
    _latitudeController = TextEditingController(text: _initialLatitudeText);
    _longitudeController = TextEditingController(text: _initialLongitudeText);
    _labelController.addListener(_updateFieldChanges);
    _latitudeController.addListener(_updateFieldChanges);
    _longitudeController.addListener(_updateFieldChanges);
  }

  @override
  void dispose() {
    _labelController.removeListener(_updateFieldChanges);
    _latitudeController.removeListener(_updateFieldChanges);
    _longitudeController.removeListener(_updateFieldChanges);
    _labelController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(AppRadii.medium),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.locationDetails,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SavedLocationPanel(location: widget.location),
              const SizedBox(height: 14),
              _LocationActionRow(
                icon: Icons.my_location_rounded,
                title: localizations.updateCurrentLocation,
                subtitle: localizations.useThisDeviceLocation,
                onTap: widget.isLocating || _isSaving
                    ? null
                    : widget.onUpdateCurrentLocation,
              ),
              const SizedBox(height: 8),
              _LocationActionRow(
                icon: Icons.map_outlined,
                title: localizations.chooseOnMap,
                subtitle: localizations.moveMapPinDescription,
                onTap: _isSaving ? null : widget.onChooseMap,
              ),
              const SizedBox(height: 14),
              _buildAdvancedCoordinates(context),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _advancedExpanded
                    ? Padding(
                        key: const ValueKey<String>('save-location-changes'),
                        padding: const EdgeInsets.only(top: 14),
                        child: FilledButton.icon(
                          onPressed: _isSaving || !_hasFieldChanges
                              ? null
                              : _save,
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(localizations.saveChanges),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedCoordinates(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          initiallyExpanded: _advancedExpanded,
          maintainState: true,
          onExpansionChanged: (bool expanded) {
            setState(() {
              _advancedExpanded = expanded;
            });
          },
          leading: Icon(Icons.tune_rounded, color: colors.primary),
          title: Text(
            localizations.advancedCoordinates,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: _advancedExpanded
              ? null
              : Text(
                  localizations.advancedCoordinatesEditSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
          children: <Widget>[
            TextFormField(
              controller: _labelController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: localizations.locationLabel,
                hintText: localizations.locationLabelHint,
                prefixIcon: const Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: localizations.latitude,
                helperText: localizations.latitudeHelperText,
                prefixIcon: const Icon(Icons.explore_outlined),
              ),
              validator: _advancedExpanded
                  ? (String? value) => validatePrayerCoordinate(
                      value,
                      min: -90,
                      max: 90,
                      label: localizations.latitude,
                      localizations: localizations,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: localizations.longitude,
                helperText: localizations.longitudeHelperText,
                prefixIcon: const Icon(Icons.public_rounded),
              ),
              validator: _advancedExpanded
                  ? (String? value) => validatePrayerCoordinate(
                      value,
                      min: -180,
                      max: 180,
                      label: localizations.longitude,
                      localizations: localizations,
                    )
                  : null,
              onFieldSubmitted: (_) {
                if (_hasFieldChanges) _save();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (!_advancedExpanded && !_hasFieldChanges) return;
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isSaving = true;
    });

    final double latitude = double.parse(_latitudeController.text.trim());
    final double longitude = double.parse(_longitudeController.text.trim());
    final String label = _labelController.text.trim().isEmpty
        ? widget.location.mode.label
        : _labelController.text.trim();
    final bool coordinatesChanged =
        latitude != widget.location.latitude ||
        longitude != widget.location.longitude;
    final bool labelChanged = label != _initialLabel;

    await widget.onSave(
      _LocationDetailsSave(
        location: PrayerLocation(
          latitude: latitude,
          longitude: longitude,
          label: coordinatesChanged && !labelChanged
              ? localizations.savedLocationFallback
              : label,
          mode: coordinatesChanged
              ? PrayerLocationMode.manual
              : widget.location.mode,
          countryCode: coordinatesChanged ? null : widget.location.countryCode,
          timezoneId: coordinatesChanged ? null : widget.location.timezoneId,
        ),
        preserveCustomLabel: labelChanged,
      ),
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
  }

  void _updateFieldChanges() {
    final bool hasChanges =
        _labelController.text.trim() != _initialLabel ||
        _latitudeController.text.trim() != _initialLatitudeText ||
        _longitudeController.text.trim() != _initialLongitudeText;
    if (hasChanges == _hasFieldChanges) return;
    setState(() {
      _hasFieldChanges = hasChanges;
    });
  }
}

class _LocationDetailsSave {
  const _LocationDetailsSave({
    required this.location,
    required this.preserveCustomLabel,
  });

  final PrayerLocation location;
  final bool preserveCustomLabel;
}

class _SavedLocationPanel extends StatelessWidget {
  const _SavedLocationPanel({required this.location});

  final PrayerLocation location;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.place_outlined, color: colors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    location.displayLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _locationPrivacyText(location, localizations),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
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

String _locationPrivacyText(
  PrayerLocation location,
  AppLocalizations localizations,
) {
  final String? timezoneId = location.timezoneId;
  final String timezoneText = timezoneId == null || timezoneId.isEmpty
      ? ''
      : ' Timezone: $timezoneId.';
  return localizations.coordinatesPrivacyDescription(timezoneText);
}

class _LocationActionRow extends StatelessWidget {
  const _LocationActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool enabled = onTap != null;
    final BorderRadius radius = BorderRadius.circular(AppRadii.medium);

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(
                    alpha: enabled ? 0.58 : 0.28,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: enabled ? null : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LocationSummaryRow extends StatelessWidget {
  const _LocationSummaryRow({
    required this.location,
    required this.onTap,
    // ignore: unused_element_parameter
    this.onHero = false,
  });

  final PrayerLocation location;
  final VoidCallback onTap;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final EquranColors equranColors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(AppRadii.medium);

    return Material(
      color: onHero
          ? equranColors.onPrimary.withAlpha(24)
          : colors.surface.withValues(alpha: 0.54),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('prayer_location_summary'),
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.location_on_outlined,
                color: onHero
                    ? equranColors.onPrimaryMuted
                    : colors.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      location.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onHero ? equranColors.onPrimaryMuted : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.manage_search_rounded,
                color: onHero
                    ? equranColors.onPrimaryMuted
                    : colors.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerDateArrowButton extends StatelessWidget {
  const _PrayerDateArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(AppRadii.medium);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.mint.withAlpha(150),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, color: colors.primary, size: 24),
          ),
        ),
      ),
    );
  }
}

class _NightTimeValue extends StatelessWidget {
  const _NightTimeValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return Row(
      children: <Widget>[
        Icon(icon, color: colors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatTime(
  DateTime time,
  bool use24HourFormat,
  AppLocalizations localizations,
) {
  final int hour = time.hour;
  final int minute = time.minute;
  if (use24HourFormat) {
    return '${_two(hour)}:${_two(minute)}';
  }

  final bool arabic = isArabicLocalizations(localizations);
  final String period = arabic
      ? (hour >= 12 ? 'م' : 'ص')
      : (hour >= 12 ? 'PM' : 'AM');
  final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${_two(minute)} $period';
}

String formatPrayerCountdownLabel(
  Duration duration,
  AppLocalizations localizations, {
  bool isNow = false,
}) {
  if (isNow || duration == Duration.zero || duration.isNegative) {
    return localizations.countdownNow;
  }
  if (duration < const Duration(minutes: 5)) {
    return localizations.countdownVerySoon;
  }

  final int totalMinutes = (duration.inSeconds / 60).ceil();
  final int hours = totalMinutes ~/ 60;
  if (hours > 0) {
    final int minutes = totalMinutes.remainder(60);
    return minutes == 0
        ? localizations.countdownInHours(hours)
        : localizations.countdownInHoursMinutes(hours, minutes);
  }
  return localizations.countdownInMinutes(totalMinutes);
}

String _formatDate(DateTime date, AppLocalizations localizations) {
  return DateFormat.yMMMMEEEEd(localizations.localeName).format(date);
}

String _two(int value) => value.toString().padLeft(2, '0');
