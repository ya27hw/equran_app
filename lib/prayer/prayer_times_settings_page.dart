import 'dart:async';

import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_location_service.dart';
import 'package:equran/prayer/prayer_map_location_page.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/widgets/app_selection_dialog.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrayerTimesSettingsPage extends StatefulWidget {
  const PrayerTimesSettingsPage({super.key});

  @override
  State<PrayerTimesSettingsPage> createState() =>
      _PrayerTimesSettingsPageState();
}

class _PrayerTimesSettingsPageState extends State<PrayerTimesSettingsPage>
    with WidgetsBindingObserver {
  final PrayerSettingsStore _store = PrayerSettingsStore();
  final PrayerLocationService _locationService = const PrayerLocationService();
  final PrayerNotificationService _notificationService =
      PrayerNotificationService();
  final PrayerTimesService _service = const PrayerTimesService();
  late PrayerTimeSettings _settings;
  PrayerLocation? _location;
  bool _isUpdatingReminders = false;
  bool _isCheckingNotificationPermission = false;
  bool _isCheckingExactAlarmPermission = false;
  bool _notificationPermissionRequestAttempted = false;
  bool _notificationPermissionHasError = false;
  bool _exactAlarmPermissionHasError = false;
  PrayerNotificationPermissionStatus? _notificationPermission;
  PrayerExactAlarmPermissionStatus? _exactAlarmPermission;
  String? _notificationMessage;
  String? _exactAlarmMessage;

  AppLocalizations get localizations => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = _store.getSettings();
    _location = _store.getLocation();
    _refreshNotificationPermission();
    _refreshExactAlarmPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationPermission(rescheduleIfGranted: true);
      _refreshExactAlarmPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.prayerTimesSettings),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colors.textSecondary),
        actionsIconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: <Widget>[
          _buildSettingsGroup(
            context: context,
            title: localizations.location,
            subtitle: _locationSubtitle,
            icon: Icons.location_on_outlined,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(localizations.chooseOnMap),
                subtitle: Text(localizations.moveMapUnderPin),
                onTap: () => _chooseOnMap(_location),
              ),
              if (_location != null)
                ListTile(
                  leading: const Icon(Icons.location_disabled_outlined),
                  title: Text(localizations.clearSavedLocation),
                  subtitle: Text(localizations.clearSavedLocationSubtitle),
                  onTap: _clearLocation,
                ),
            ],
          ),
          _buildPrayerRemindersSection(context),
          _buildSettingsGroup(
            context: context,
            title: localizations.calculation,
            subtitle: _calculationSubtitle,
            icon: Icons.calculate_outlined,
            children: <Widget>[
              ListTile(
                title: Text(localizations.calculationMethod),
                subtitle: Text(_methodSubtitle),
                onTap: _selectCalculationMethod,
              ),
              ListTile(
                title: Text(localizations.asrMethod),
                subtitle: Text(_settings.asrMethod.label),
                onTap: _selectAsrMethod,
              ),
              ListTile(
                title: Text(localizations.highLatitudeAdjustment),
                subtitle: Text(
                  '${_settings.highLatitudeRule.label}\n${localizations.highLatitudeAdjustmentSubtitle}',
                ),
                isThreeLine: true,
                onTap: _selectHighLatitudeRule,
              ),
              ListTile(
                title: Text(localizations.timeFormat),
                subtitle: Text(
                  _settings.use24HourFormat ? '24-hour' : '12-hour',
                ),
                onTap: _selectTimeFormat,
              ),
              SwitchListTile(
                title: Text(localizations.useLocationTimezone),
                subtitle: Text(_timezoneSettingSubtitle),
                value: _settings.useLocationTimezone,
                onChanged: (bool enabled) => _saveSettings(
                  _settings.copyWith(useLocationTimezone: enabled),
                ),
              ),
              if (_settings.method == PrayerCalculationMethod.custom)
                _buildCustomMethodCard(theme),
            ],
          ),
          _buildProhibitedTimesSection(context),
          _buildSettingsGroup(
            context: context,
            title: localizations.manualOffsets,
            subtitle: localizations.manualOffsetsSubtitle,
            icon: Icons.tune_rounded,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Text(
                  localizations.offsetsAreAppliedAfterBaseCalculation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
              for (final PrayerTimeKind prayer in PrayerTimeKind.displayOrder)
                ListTile(
                  title: Text(prayer.label),
                  subtitle: Text(
                    _offsetLabel(_settings.offsets.forPrayer(prayer)),
                  ),
                  onTap: () => _editOffset(prayer),
                ),
            ],
          ),
          _buildDisclaimer(context),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: ExpansionTile(
            initiallyExpanded: true,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildProhibitedTimesSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return _buildSettingsGroup(
      context: context,
      title: localizations.prohibitedTimes,
      subtitle: localizations.prohibitedTimesSubtitle,
      icon: Icons.block_outlined,
      children: <Widget>[
        ListTile(
          title: Text(localizations.sunriseProhibitedTime),
          subtitle: Text(
            localizations.sunriseProhibitedTimeMinutes(
              _settings.sunriseProhibitedDurationMinutes,
            ),
          ),
          onTap: () => _editProhibitedDuration(
            title: localizations.sunriseProhibitedTime,
            currentValue: _settings.sunriseProhibitedDurationMinutes,
            min: minSunriseProhibitedDurationMinutes,
            max: maxSunriseProhibitedDurationMinutes,
            onChanged: (int value) => _saveSettings(
              _settings.copyWith(sunriseProhibitedDurationMinutes: value),
            ),
          ),
        ),
        ListTile(
          title: Text(localizations.zawalProhibitedTime),
          subtitle: Text(
            localizations.zawalProhibitedTimeMinutes(
              _settings.dhuhrProhibitedDurationMinutes,
            ),
          ),
          onTap: () => _editProhibitedDuration(
            title: localizations.zawalProhibitedTime,
            currentValue: _settings.dhuhrProhibitedDurationMinutes,
            min: minDhuhrProhibitedDurationMinutes,
            max: maxDhuhrProhibitedDurationMinutes,
            onChanged: (int value) => _saveSettings(
              _settings.copyWith(dhuhrProhibitedDurationMinutes: value),
            ),
          ),
        ),
        ListTile(
          title: Text(localizations.sunsetProhibitedTime),
          subtitle: Text(
            localizations.sunsetProhibitedTimeMinutes(
              _settings.sunsetProhibitedDurationMinutes,
            ),
          ),
          onTap: () => _editProhibitedDuration(
            title: localizations.sunsetProhibitedTime,
            currentValue: _settings.sunsetProhibitedDurationMinutes,
            min: minSunsetProhibitedDurationMinutes,
            max: maxSunsetProhibitedDurationMinutes,
            onChanged: (int value) => _saveSettings(
              _settings.copyWith(sunsetProhibitedDurationMinutes: value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerRemindersSection(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final PrayerReminderSettings reminders = _settings.reminderSettings;
    final bool remindersOn = reminders.remindersEnabled;
    final PrayerNotificationPermissionStatus? permission =
        _notificationPermission;
    final bool permissionOff =
        permission == PrayerNotificationPermissionStatus.denied ||
        permission == PrayerNotificationPermissionStatus.unsupported;
    final PrayerExactAlarmPermissionStatus? exactAlarmPermission =
        _exactAlarmPermission;
    final bool exactAlarmOff =
        exactAlarmPermission == PrayerExactAlarmPermissionStatus.denied;

    return _buildSettingsGroup(
      context: context,
      title: localizations.prayerReminders,
      subtitle: _reminderSubtitle,
      icon: Icons.notifications_active_outlined,
      children: <Widget>[
        SwitchListTile(
          secondary: _isUpdatingReminders
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications_none_rounded),
          title: Text(localizations.prayerRemindersEnabled),
          subtitle: Text(_notificationPermissionSubtitle),
          value: remindersOn,
          onChanged: _isUpdatingReminders ? null : _toggleGlobalReminders,
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none_rounded),
          title: Text(localizations.notificationsPermission),
          subtitle: Text(_notificationPermissionSubtitle),
          trailing: permission == PrayerNotificationPermissionStatus.denied
              ? TextButton(
                  onPressed: _isUpdatingReminders
                      ? null
                      : _requestNotificationPermission,
                  child: Text(localizations.enable),
                )
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.alarm_on_outlined),
          title: Text(localizations.exactAlarmPermission),
          subtitle: Text(_exactAlarmPermissionSubtitle),
          trailing: exactAlarmOff
              ? TextButton(
                  onPressed: _isUpdatingReminders
                      ? null
                      : _openExactAlarmSettings,
                  child: Text(localizations.open),
                )
              : null,
        ),
        if (permissionOff || _notificationMessage != null)
          _buildNotificationPermissionBanner(theme),
        if (exactAlarmOff || _exactAlarmMessage != null)
          _buildExactAlarmPermissionBanner(theme),
        if (remindersOn && _location == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              localizations.chooseLocationBeforeReminders,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: <Widget>[
              for (final PrayerTimeKind prayer in PrayerTimeKind.reminderOrder)
                SwitchListTile(
                  title: Text(prayer.label),
                  subtitle: Text(localizations.notifyAtSavedPrayerTime),
                  value: reminders.prayerToggleFor(prayer),
                  onChanged: _isUpdatingReminders
                      ? null
                      : (bool enabled) =>
                            _togglePrayerReminder(prayer, enabled),
                ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: Text(localizations.reminderTime),
                subtitle: Text(
                  _reminderOffsetLabel(reminders.reminderOffsetMinutes),
                ),
                enabled: !_isUpdatingReminders,
                onTap: _isUpdatingReminders ? null : _selectReminderOffset,
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(localizations.schedule1MinuteExactTest),
                  subtitle: Text(
                    localizations.schedule1MinuteExactTestSubtitle,
                  ),
                  enabled: !_isUpdatingReminders,
                  onTap: _isUpdatingReminders
                      ? null
                      : _scheduleDebugPrayerNotification,
                ),
            ],
          ),
          crossFadeState: remindersOn
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }

  Widget _buildNotificationPermissionBanner(ThemeData theme) {
    final ColorScheme colors = theme.colorScheme;
    final PrayerNotificationPermissionStatus? permission =
        _notificationPermission;
    final bool unsupported =
        permission == PrayerNotificationPermissionStatus.unsupported;
    final bool error = _notificationPermissionHasError;
    final bool openSettings =
        permission == PrayerNotificationPermissionStatus.denied &&
        _notificationPermissionRequestAttempted;
    final VoidCallback action = error
        ? () => _refreshNotificationPermission()
        : openSettings
        ? _openNotificationSettings
        : _requestNotificationPermission;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: colors.error.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.notifications_off_outlined,
                    color: colors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _notificationMessage ??
                          localizations.notificationPermissionOffEnable,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!unsupported)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _isUpdatingReminders ? null : action,
                    icon: Icon(
                      error
                          ? Icons.refresh_rounded
                          : openSettings
                          ? Icons.settings_outlined
                          : Icons.notifications_active_outlined,
                    ),
                    label: Text(
                      error
                          ? localizations.retry
                          : openSettings
                          ? localizations.openAppSettings
                          : localizations.requestPermission,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExactAlarmPermissionBanner(ThemeData theme) {
    final ColorScheme colors = theme.colorScheme;
    final bool error = _exactAlarmPermissionHasError;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: colors.error.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.alarm_off_outlined, color: colors.error, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _exactAlarmMessage ??
                          localizations.exactAlarmPermissionDisabled,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _isUpdatingReminders
                      ? null
                      : error
                      ? _refreshExactAlarmPermission
                      : _openExactAlarmSettings,
                  icon: Icon(
                    error ? Icons.refresh_rounded : Icons.settings_outlined,
                  ),
                  label: Text(
                    error
                        ? localizations.retry
                        : localizations.openAlarmPermissionSettings,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomMethodCard(ThemeData theme) {
    final ColorScheme colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: <Widget>[
                  Icon(Icons.construction_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      localizations.customMethod,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(localizations.fajrAngle),
              subtitle: Text(
                '${_settings.customFajrAngle.toStringAsFixed(1)}°',
              ),
              onTap: () => _editDoubleSetting(
                title: localizations.fajrAngle,
                currentValue: _settings.customFajrAngle,
                min: 0,
                max: 30,
                suffix: 'degrees',
                onChanged: (double value) =>
                    _saveSettings(_settings.copyWith(customFajrAngle: value)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(localizations.highLatitudeMosqueNotice),
              ),
            ),
            ListTile(
              title: Text(localizations.ishaMode),
              subtitle: Text(_localizedIshaModeLabel(_settings.customIshaMode)),
              onTap: _selectCustomIshaMode,
            ),
            ..._buildCustomIshaFields(),
            ListTile(
              title: Text(localizations.maghribAngle),
              subtitle: Text(
                _settings.customMaghribAngle == null
                    ? localizations.useSunset
                    : '${_settings.customMaghribAngle!.toStringAsFixed(1)}°',
              ),
              onTap: () => _editOptionalDoubleSetting(
                title: localizations.maghribAngle,
                currentValue: _settings.customMaghribAngle,
                min: 0,
                max: 30,
                emptyLabel: localizations.leaveBlankToUseSunset,
                onChanged: (double? value) =>
                    _saveSettings(_settings.withCustomMaghribAngle(value)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizedIshaModeLabel(PrayerCustomIshaMode mode) {
    return switch (mode) {
      PrayerCustomIshaMode.angle => localizations.ishaModeAngle,
      PrayerCustomIshaMode.interval => localizations.ishaModeInterval,
      PrayerCustomIshaMode.fixedTime => localizations.ishaModeFixedTime,
      PrayerCustomIshaMode.latestCap => localizations.ishaModeLatestCap,
    };
  }

  List<Widget> _buildCustomIshaFields() {
    return switch (_settings.customIshaMode) {
      PrayerCustomIshaMode.angle => <Widget>[_buildCustomIshaAngleTile()],
      PrayerCustomIshaMode.interval => <Widget>[
        _buildCustomIshaIntervalTile(requiredValue: true),
      ],
      PrayerCustomIshaMode.fixedTime => <Widget>[
        ListTile(
          title: Text(localizations.fixedIshaTime),
          subtitle: Text(
            _clockLabel(
              _settings.customIshaFixedTimeHour,
              _settings.customIshaFixedTimeMinute,
            ),
          ),
          onTap: () => _editCustomIshaClockTime(
            title: localizations.fixedIshaTime,
            initialHour: _settings.customIshaFixedTimeHour,
            initialMinute: _settings.customIshaFixedTimeMinute,
            onChanged: (TimeOfDay value) => _saveSettings(
              _settings.copyWith(
                customIshaFixedTimeHour: value.hour,
                customIshaFixedTimeMinute: value.minute,
              ),
            ),
          ),
        ),
      ],
      PrayerCustomIshaMode.latestCap => <Widget>[
        _buildCustomIshaAngleTile(title: localizations.baseIshaAngle),
        _buildCustomIshaIntervalTile(requiredValue: false),
        ListTile(
          title: Text(localizations.latestIshaTime),
          subtitle: Text(
            localizations.latestIshaTimeHelp(
              _clockLabel(
                _settings.customIshaLatestCapHour,
                _settings.customIshaLatestCapMinute,
              ),
            ),
          ),
          onTap: () => _editCustomIshaClockTime(
            title: localizations.latestIshaTime,
            initialHour: _settings.customIshaLatestCapHour,
            initialMinute: _settings.customIshaLatestCapMinute,
            onChanged: (TimeOfDay value) => _saveSettings(
              _settings.copyWith(
                customIshaLatestCapHour: value.hour,
                customIshaLatestCapMinute: value.minute,
              ),
            ),
          ),
        ),
      ],
    };
  }

  Widget _buildCustomIshaAngleTile({String? title}) {
    final String resolvedTitle = title ?? localizations.ishaAngle;
    return ListTile(
      title: Text(resolvedTitle),
      subtitle: Text('${_settings.customIshaAngle.toStringAsFixed(1)}°'),
      onTap: () => _editDoubleSetting(
        title: resolvedTitle,
        currentValue: _settings.customIshaAngle,
        min: 0,
        max: 30,
        suffix: localizations.degrees,
        onChanged: (double value) =>
            _saveSettings(_settings.copyWith(customIshaAngle: value)),
      ),
    );
  }

  Widget _buildCustomIshaIntervalTile({required bool requiredValue}) {
    return ListTile(
      title: Text(
        requiredValue
            ? localizations.ishaInterval
            : localizations.baseIshaInterval,
      ),
      subtitle: Text(
        _settings.customIshaInterval == null
            ? localizations.useIshaAngle
            : localizations.minutesAfterMaghrib(_settings.customIshaInterval!),
      ),
      onTap: () => requiredValue
          ? _editIntSetting(
              title: localizations.ishaInterval,
              currentValue: _settings.customIshaInterval ?? 90,
              min: 0,
              max: 240,
              suffix: localizations.minutes,
              onChanged: (int value) =>
                  _saveSettings(_settings.withCustomIshaInterval(value)),
            )
          : _editOptionalIntSetting(
              title: localizations.baseIshaInterval,
              currentValue: _settings.customIshaInterval,
              min: 0,
              max: 240,
              emptyLabel: localizations.leaveBlankToUseBaseIshaAngle,
              onChanged: (int? value) =>
                  _saveSettings(_settings.withCustomIshaInterval(value)),
            ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.info_outline_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  localizations.prayerTimesExperimental,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCalculationMethod() async {
    final PrayerCalculationMethod? selected =
        await _showSelectionDialog<PrayerCalculationMethod>(
          title: localizations.calculationMethod,
          icon: Icons.calculate_outlined,
          selectedValue: _settings.method,
          options: PrayerCalculationMethod.values
              .map(
                (PrayerCalculationMethod method) =>
                    AppSelectionOption<PrayerCalculationMethod>(
                      value: method,
                      title: method.label,
                      subtitle: method == PrayerCalculationMethod.auto
                          ? localizations.bestMethodSubtitle
                          : null,
                    ),
              )
              .toList(),
        );
    if (selected == null) return;
    await _saveSettings(_settings.copyWith(method: selected));
  }

  Future<void> _selectAsrMethod() async {
    final PrayerAsrMethod? selected =
        await _showSelectionDialog<PrayerAsrMethod>(
          title: localizations.asrMethod,
          icon: Icons.wb_sunny_outlined,
          selectedValue: _settings.asrMethod,
          options: PrayerAsrMethod.values
              .map(
                (PrayerAsrMethod method) => AppSelectionOption<PrayerAsrMethod>(
                  value: method,
                  title: method.label,
                ),
              )
              .toList(),
        );
    if (selected == null) return;
    await _saveSettings(_settings.copyWith(asrMethod: selected));
  }

  Future<void> _selectHighLatitudeRule() async {
    final PrayerHighLatitudeRule? selected =
        await _showSelectionDialog<PrayerHighLatitudeRule>(
          title: localizations.highLatitudeAdjustment,
          icon: Icons.public_rounded,
          selectedValue: _settings.highLatitudeRule,
          options: PrayerHighLatitudeRule.values
              .map(
                (
                  PrayerHighLatitudeRule rule,
                ) => AppSelectionOption<PrayerHighLatitudeRule>(
                  value: rule,
                  title: rule.label,
                  subtitle: switch (rule) {
                    PrayerHighLatitudeRule.auto =>
                      localizations.highLatitudeRuleAutoSubtitle,
                    PrayerHighLatitudeRule.none =>
                      localizations.highLatitudeRuleNoneSubtitle,
                    PrayerHighLatitudeRule.middleOfTheNight =>
                      localizations.highLatitudeRuleMiddleOfTheNightSubtitle,
                    PrayerHighLatitudeRule.oneSeventh =>
                      localizations.highLatitudeRuleOneSeventhSubtitle,
                    PrayerHighLatitudeRule.angleBased =>
                      localizations.highLatitudeRuleAngleBasedSubtitle,
                  },
                ),
              )
              .toList(),
        );
    if (selected == null) return;
    await _saveSettings(_settings.copyWith(highLatitudeRule: selected));
  }

  Future<void> _selectCustomIshaMode() async {
    final PrayerCustomIshaMode? selected =
        await _showSelectionDialog<PrayerCustomIshaMode>(
          title: localizations.ishaMode,
          icon: Icons.dark_mode_outlined,
          selectedValue: _settings.customIshaMode,
          options: PrayerCustomIshaMode.values
              .map(
                (PrayerCustomIshaMode mode) =>
                    AppSelectionOption<PrayerCustomIshaMode>(
                      value: mode,
                      title: _localizedIshaModeLabel(mode),
                      subtitle: switch (mode) {
                        PrayerCustomIshaMode.angle =>
                          localizations.ishaModeAngleSubtitle,
                        PrayerCustomIshaMode.interval =>
                          localizations.ishaModeIntervalSubtitle,
                        PrayerCustomIshaMode.fixedTime =>
                          localizations.ishaModeFixedTimeSubtitle,
                        PrayerCustomIshaMode.latestCap =>
                          localizations.ishaModeLatestCapSubtitle,
                      },
                    ),
              )
              .toList(),
        );
    if (selected == null) return;
    PrayerTimeSettings settings = _settings.copyWith(customIshaMode: selected);
    if (selected == PrayerCustomIshaMode.interval &&
        settings.customIshaInterval == null) {
      settings = settings.copyWith(customIshaInterval: 90);
    }
    await _saveSettings(settings);
  }

  Future<void> _selectTimeFormat() async {
    final bool? use24HourFormat = await _showSelectionDialog<bool>(
      title: localizations.timeFormat,
      icon: Icons.schedule_rounded,
      selectedValue: _settings.use24HourFormat,
      options: <AppSelectionOption<bool>>[
        AppSelectionOption<bool>(value: false, title: localizations.twelveHour),
        AppSelectionOption<bool>(
          value: true,
          title: localizations.twentyFourHour,
        ),
      ],
    );
    if (use24HourFormat == null) return;
    await _saveSettings(_settings.copyWith(use24HourFormat: use24HourFormat));
  }

  Future<void> _toggleGlobalReminders(bool enabled) async {
    final PrayerReminderSettings reminders = _settings.reminderSettings;
    if (!enabled) {
      await _saveReminderSettings(reminders.copyWith(remindersEnabled: false));
      return;
    }

    setState(() {
      _isUpdatingReminders = true;
      _notificationMessage = null;
      _exactAlarmMessage = null;
      _notificationPermissionHasError = false;
      _exactAlarmPermissionHasError = false;
    });
    try {
      final PrayerNotificationPermissionStatus permission =
          await _notificationService.requestPermission();
      if (!mounted) return;
      setState(() {
        _notificationPermission = permission;
        _notificationPermissionRequestAttempted = true;
        _notificationPermissionHasError = false;
      });

      if (permission != PrayerNotificationPermissionStatus.granted) {
        await _notificationService.cancelPrayerNotifications();
        if (!mounted) return;
        setState(() {
          _notificationMessage = _notificationMessageForPermission(permission);
        });
        _showMessage(
          permission == PrayerNotificationPermissionStatus.unsupported
              ? localizations.prayerRemindersUnsupported
              : localizations.notificationPermissionOffRemindersNotEnabled,
        );
        return;
      }

      await _saveReminderSettings(reminders.copyWith(remindersEnabled: true));
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage =
            localizations.notificationPermissionTimeoutMessage;
      });
      _showMessage(localizations.notificationPermissionTimeout);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage = localizations.notificationPermissionErrorMessage;
      });
      _showMessage(localizations.notificationPermissionError);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReminders = false;
        });
      }
    }
  }

  Future<void> _togglePrayerReminder(
    PrayerTimeKind prayer,
    bool enabled,
  ) async {
    setState(() {
      _isUpdatingReminders = true;
    });
    try {
      await _saveReminderSettings(
        _settings.reminderSettings.copyWithPrayer(prayer, enabled),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReminders = false;
        });
      }
    }
  }

  Future<void> _selectReminderOffset() async {
    final int? selected = await _showSelectionDialog<int>(
      title: localizations.reminderTime,
      icon: Icons.schedule_rounded,
      selectedValue: _settings.reminderSettings.reminderOffsetMinutes,
      options: <AppSelectionOption<int>>[
        AppSelectionOption<int>(value: 0, title: localizations.atPrayerTime),
        AppSelectionOption<int>(
          value: 5,
          title: localizations.minutesBeforePrayer(5),
        ),
        AppSelectionOption<int>(
          value: 10,
          title: localizations.minutesBeforePrayer(10),
        ),
        AppSelectionOption<int>(
          value: 15,
          title: localizations.minutesBeforePrayer(15),
        ),
        AppSelectionOption<int>(
          value: 30,
          title: localizations.minutesBeforePrayer(30),
        ),
      ],
    );
    if (selected == null) return;
    setState(() {
      _isUpdatingReminders = true;
    });
    try {
      await _saveReminderSettings(
        _settings.reminderSettings.copyWith(reminderOffsetMinutes: selected),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReminders = false;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isUpdatingReminders = true;
      _notificationMessage = null;
      _notificationPermissionHasError = false;
    });
    try {
      final PrayerNotificationPermissionStatus permission =
          await _notificationService.requestPermission();
      if (!mounted) return;
      setState(() {
        _notificationPermission = permission;
        _notificationPermissionRequestAttempted = true;
        _notificationPermissionHasError = false;
        _notificationMessage = _notificationMessageForPermission(permission);
      });
      if (permission == PrayerNotificationPermissionStatus.granted &&
          _settings.reminderSettings.remindersEnabled) {
        await _saveSettings(_settings);
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage =
            localizations.notificationPermissionTimeoutMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage = localizations.notificationPermissionErrorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReminders = false;
        });
      }
    }
  }

  Future<void> _openNotificationSettings() async {
    setState(() {
      _notificationPermissionRequestAttempted = true;
      _notificationPermissionHasError = false;
    });
    try {
      await _notificationService.openSettings();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage = localizations.openNotificationSettingsTimeout;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage = localizations.openNotificationSettingsError;
      });
    }
  }

  Future<void> _openExactAlarmSettings() async {
    setState(() {
      _exactAlarmPermissionHasError = false;
      _exactAlarmMessage = null;
    });
    try {
      await _notificationService.openExactAlarmSettings();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _exactAlarmPermissionHasError = true;
        _exactAlarmMessage = localizations.openExactAlarmSettingsTimeout;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exactAlarmPermissionHasError = true;
        _exactAlarmMessage = localizations.openExactAlarmSettingsError;
      });
    }
  }

  Future<void> _scheduleDebugPrayerNotification() async {
    setState(() {
      _isUpdatingReminders = true;
      _notificationMessage = null;
      _exactAlarmMessage = null;
      _notificationPermissionHasError = false;
      _exactAlarmPermissionHasError = false;
    });
    try {
      final PrayerNotificationScheduleResult result = await _notificationService
          .scheduleDebugExactNotificationOneMinuteFromNow();
      if (!mounted) return;
      _applyPermissionStateFromScheduleResult(result);
      switch (result.status) {
        case PrayerNotificationScheduleStatus.scheduled:
          final DateTime scheduledAt =
              result.scheduledNotifications.single.scheduledAt;
          _showMessage(
            localizations.debugReminderScheduled(_formatClockTime(scheduledAt)),
          );
          break;
        case PrayerNotificationScheduleStatus.permissionDenied:
          _showMessage(localizations.notificationPermissionOff);
          break;
        case PrayerNotificationScheduleStatus.exactAlarmDenied:
          _showMessage(localizations.exactAlarmPermissionDisabled);
          break;
        case PrayerNotificationScheduleStatus.unsupported:
        case PrayerNotificationScheduleStatus.failed:
        case PrayerNotificationScheduleStatus.disabled:
        case PrayerNotificationScheduleStatus.missingLocation:
          _showMessage(
            result.message ?? localizations.debugReminderCouldNotBeScheduled,
          );
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReminders = false;
        });
      }
    }
  }

  Future<void> _saveReminderSettings(
    PrayerReminderSettings reminderSettings,
  ) async {
    final PrayerTimeSettings settings = _settings.copyWith(
      reminderSettings: reminderSettings,
    );
    await _saveSettings(settings);
  }

  Future<T?> _showSelectionDialog<T>({
    required String title,
    required IconData icon,
    required T selectedValue,
    required List<AppSelectionOption<T>> options,
  }) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) => AppSelectionDialog<T>(
        title: title,
        icon: icon,
        selectedValue: selectedValue,
        options: options,
      ),
    );
  }

  Future<void> _editOffset(PrayerTimeKind prayer) async {
    final int? value = await _showSteppedIntDialog(
      title: localizations.prayerOffsetTitle(
        localizedPrayerName(localizations, prayer),
      ),
      currentValue: _settings.offsets.forPrayer(prayer),
      min: -120,
      max: 120,
      helperText: localizations.steppedIntOffsetHelper,
    );
    if (value == null) return;
    await _saveSettings(
      _settings.copyWith(
        offsets: _settings.offsets.copyWithPrayer(prayer, value),
      ),
    );
  }

  Future<void> _editDoubleSetting({
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) async {
    final double? value = await _showNumberDialog<double>(
      title: title,
      currentValue: currentValue,
      helperText: localizations.enterValueBetweenMinMaxSuffix(
        min.toStringAsFixed(0),
        max.toStringAsFixed(0),
        suffix,
      ),
      parser: double.tryParse,
      validator: (double value) => value >= min && value <= max,
      formatter: (double value) => value.toStringAsFixed(1),
    );
    if (value == null) return;
    onChanged(value);
  }

  Future<void> _editIntSetting({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) async {
    final int? value = await _showSteppedIntDialog(
      title: title,
      currentValue: currentValue,
      min: min,
      max: max,
      helperText: localizations.steppedIntSuffixHelper(suffix),
    );
    if (value == null) return;
    onChanged(value);
  }

  Future<void> _editProhibitedDuration({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return _editIntSetting(
      title: title,
      currentValue: currentValue,
      min: min,
      max: max,
      suffix: localizations.minutes,
      onChanged: onChanged,
    );
  }

  Future<void> _editCustomIshaClockTime({
    required String title,
    required int initialHour,
    required int initialMinute,
    required ValueChanged<TimeOfDay> onChanged,
  }) async {
    final TimeOfDay? value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: title,
    );
    if (value == null) return;
    onChanged(value);
  }

  Future<void> _editOptionalIntSetting({
    required String title,
    required int? currentValue,
    required int min,
    required int max,
    required String emptyLabel,
    required ValueChanged<int?> onChanged,
  }) async {
    final _OptionalNumberResult<int>? result =
        await _showOptionalSteppedIntDialog(
          title: title,
          currentValue: currentValue,
          min: min,
          max: max,
          helperText: localizations.optionalSteppedIntHelper(emptyLabel),
        );
    if (result == null) return;
    onChanged(result.value);
  }

  Future<void> _editOptionalDoubleSetting({
    required String title,
    required double? currentValue,
    required double min,
    required double max,
    required String emptyLabel,
    required ValueChanged<double?> onChanged,
  }) async {
    final _OptionalNumberResult<double>? result =
        await _showOptionalNumberDialog<double>(
          title: title,
          currentValue: currentValue,
          helperText: emptyLabel,
          parser: double.tryParse,
          validator: (double value) => value >= min && value <= max,
          formatter: (double value) => value.toStringAsFixed(1),
        );
    if (result == null) return;
    onChanged(result.value);
  }

  Future<T?> _showNumberDialog<T extends num>({
    required String title,
    required T currentValue,
    required String helperText,
    required T? Function(String value) parser,
    required bool Function(T value) validator,
    required String Function(T value) formatter,
  }) {
    return _showNumberDialogInternal<T>(
      title: title,
      currentValue: currentValue,
      helperText: helperText,
      parser: parser,
      validator: validator,
      formatter: formatter,
      allowEmpty: false,
    );
  }

  Future<_OptionalNumberResult<T>?> _showOptionalNumberDialog<T extends num>({
    required String title,
    required T? currentValue,
    required String helperText,
    required T? Function(String value) parser,
    required bool Function(T value) validator,
    required String Function(T value) formatter,
  }) {
    return _showOptionalNumberDialogInternal<T>(
      title: title,
      currentValue: currentValue,
      helperText: helperText,
      parser: parser,
      validator: validator,
      formatter: formatter,
      allowEmpty: true,
    );
  }

  Future<int?> _showSteppedIntDialog({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required String helperText,
  }) {
    return _showSteppedIntDialogInternal(
      title: title,
      currentValue: currentValue,
      min: min,
      max: max,
      helperText: helperText,
      allowNullValue: false,
    ).then((value) => value?.value);
  }

  Future<_OptionalNumberResult<int>?> _showOptionalSteppedIntDialog({
    required String title,
    required int? currentValue,
    required int min,
    required int max,
    required String helperText,
  }) {
    return _showSteppedIntDialogInternal(
      title: title,
      currentValue: currentValue,
      min: min,
      max: max,
      helperText: helperText,
      allowNullValue: true,
    );
  }

  Future<_OptionalNumberResult<int>?> _showSteppedIntDialogInternal({
    required String title,
    required int? currentValue,
    required int min,
    required int max,
    required String helperText,
    required bool allowNullValue,
  }) {
    int signedValue = (currentValue ?? 0).clamp(min, max).toInt();
    bool isNegative = signedValue < 0;
    final TextEditingController controller = TextEditingController(
      text: currentValue == null ? '' : signedValue.abs().toString(),
    );

    int signedValueFromText() {
      final String raw = controller.text.trim();
      final int magnitude = raw.isEmpty ? 0 : int.tryParse(raw) ?? -1;
      if (magnitude < 0) return min - 1;
      if (isNegative && magnitude != 0 && min < 0) return -magnitude;
      return magnitude;
    }

    return showDialog<_OptionalNumberResult<int>?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            void toggleSign() {
              if (min >= 0) return;
              setDialogState(() {
                isNegative = !isNegative;
                final int fromText = signedValueFromText();
                if (fromText >= min && fromText <= max) {
                  signedValue = fromText;
                }
              });
            }

            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  prefixIcon: min < 0
                      ? IconButton(
                          tooltip: isNegative ? 'Set positive' : 'Set negative',
                          onPressed: toggleSign,
                          icon: Text(
                            isNegative ? '−' : '+',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        )
                      : null,
                  helperText: helperText,
                ),
                onChanged: (_) {
                  setDialogState(() {
                    final int fromText = signedValueFromText();
                    if (fromText >= min && fromText <= max) {
                      signedValue = fromText;
                    }
                  });
                },
              ),
              actions: <Widget>[
                if (allowNullValue)
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _OptionalNumberResult<Never>(null)),
                    child: Text(localizations.clear),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final int value = signedValueFromText();
                    if (value < min || value > max) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.enterValueFromMinToMax(
                              min.toString(),
                              max.toString(),
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(
                      context,
                    ).pop(_OptionalNumberResult<int>(value));
                  },
                  child: Text(localizations.save),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<T?> _showNumberDialogInternal<T extends num>({
    required String title,
    required T? currentValue,
    required String helperText,
    required T? Function(String value) parser,
    required bool Function(T value) validator,
    required String Function(T value) formatter,
    required bool allowEmpty,
  }) {
    final TextEditingController controller = TextEditingController(
      text: currentValue == null ? '' : formatter(currentValue),
    );
    return showDialog<T?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: InputDecoration(helperText: helperText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () {
                final String raw = controller.text.trim();
                if (allowEmpty && raw.isEmpty) {
                  Navigator.of(context).pop(null);
                  return;
                }
                final T? value = parser(raw);
                if (value == null || !validator(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.enterValidValue)),
                  );
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: Text(localizations.save),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<_OptionalNumberResult<T>?>
  _showOptionalNumberDialogInternal<T extends num>({
    required String title,
    required T? currentValue,
    required String helperText,
    required T? Function(String value) parser,
    required bool Function(T value) validator,
    required String Function(T value) formatter,
    required bool allowEmpty,
  }) {
    final TextEditingController controller = TextEditingController(
      text: currentValue == null ? '' : formatter(currentValue),
    );
    return showDialog<_OptionalNumberResult<T>?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: InputDecoration(helperText: helperText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () {
                final String raw = controller.text.trim();
                if (allowEmpty && raw.isEmpty) {
                  Navigator.of(
                    context,
                  ).pop(const _OptionalNumberResult<Never>(null));
                  return;
                }
                final T? value = parser(raw);
                if (value == null || !validator(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.enterValidValue)),
                  );
                  return;
                }
                Navigator.of(context).pop(_OptionalNumberResult<T>(value));
              },
              child: Text(localizations.save),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _chooseOnMap(PrayerLocation? initialLocation) async {
    final PrayerLocation? location = await showPrayerMapLocationPicker(
      context,
      initialLocation,
    );
    if (location == null) return;
    final PrayerLocation resolvedLocation = await _saveResolvedLocation(
      location,
    );
    if (!mounted) return;
    setState(() {
      _location = resolvedLocation;
    });
    _showMessage(localizations.locationSaved);
  }

  Future<PrayerLocation> _saveResolvedLocation(PrayerLocation location) async {
    final EquranColors colors = context.equranColors;
    final PrayerLocation resolvedLocation = await _locationService
        .resolveLocationForSave(location, previousLocation: _location);
    await _store.saveLocation(resolvedLocation);
    await _rescheduleReminders(location: resolvedLocation);
    unawaited(PrayerWidgetService.refreshWidget(colors: colors));
    return resolvedLocation;
  }

  Future<void> _clearLocation() async {
    final EquranColors colors = context.equranColors;
    await _store.clearLocation();
    await _rescheduleReminders(locationCleared: true);
    unawaited(PrayerWidgetService.refreshWidget(colors: colors));
    if (!mounted) return;
    setState(() {
      _location = null;
    });
    _showMessage(localizations.locationCleared);
  }

  Future<void> _saveSettings(PrayerTimeSettings settings) async {
    final EquranColors colors = context.equranColors;
    await _store.saveSettings(settings);
    unawaited(PrayerWidgetService.refreshWidget(colors: colors));
    final PrayerNotificationScheduleResult reminderResult =
        await _rescheduleReminders(settings: settings);
    if (mounted) {
      _applyPermissionStateFromScheduleResult(reminderResult);
    }
    PrayerTimeSettings savedSettings = settings;
    final bool permissionBlocked =
        settings.reminderSettings.remindersEnabled &&
        (reminderResult.status ==
                PrayerNotificationScheduleStatus.permissionDenied ||
            reminderResult.status ==
                PrayerNotificationScheduleStatus.unsupported);
    if (permissionBlocked) {
      savedSettings = settings.copyWith(
        reminderSettings: settings.reminderSettings.copyWith(
          remindersEnabled: false,
        ),
      );
      await _store.saveSettings(savedSettings);
      if (mounted) {
        setState(() {
          _notificationPermission =
              reminderResult.status ==
                  PrayerNotificationScheduleStatus.unsupported
              ? PrayerNotificationPermissionStatus.unsupported
              : PrayerNotificationPermissionStatus.denied;
          _notificationMessage = _notificationMessageForPermission(
            _notificationPermission!,
          );
        });
        _showMessage(
          reminderResult.status == PrayerNotificationScheduleStatus.unsupported
              ? localizations.prayerRemindersUnsupported
              : localizations.notificationPermissionOffWarning,
        );
      }
    } else if (reminderResult.status ==
        PrayerNotificationScheduleStatus.failed) {
      if (mounted) {
        setState(() {
          _notificationMessage =
              reminderResult.message ??
              localizations.prayerRemindersCouldNotBeScheduled;
        });
        _showMessage(_notificationMessage!);
      }
    } else if (reminderResult.status ==
        PrayerNotificationScheduleStatus.exactAlarmDenied) {
      if (mounted) {
        setState(() {
          _exactAlarmPermission = PrayerExactAlarmPermissionStatus.denied;
          _exactAlarmMessage =
              reminderResult.message ??
              localizations.exactAlarmPermissionOffWarning;
        });
        _showMessage(_exactAlarmMessage!);
      }
    } else if (reminderResult.status ==
        PrayerNotificationScheduleStatus.scheduled) {
      if (mounted) {
        setState(() {
          _notificationPermission = PrayerNotificationPermissionStatus.granted;
          _exactAlarmPermission =
              reminderResult.exactAlarmPermission ?? _exactAlarmPermission;
          _notificationMessage = null;
          _exactAlarmMessage = null;
        });
      }
    }
    if (!mounted) return;
    setState(() {
      _settings = savedSettings;
    });
  }

  Future<PrayerNotificationScheduleResult> _rescheduleReminders({
    PrayerTimeSettings? settings,
    PrayerLocation? location,
    bool locationCleared = false,
  }) async {
    return _notificationService.reschedule(
      settings: settings ?? _settings,
      location: locationCleared ? null : location ?? _location,
    );
  }

  void _applyPermissionStateFromScheduleResult(
    PrayerNotificationScheduleResult result,
  ) {
    if (!mounted) return;
    setState(() {
      if (result.notificationPermission != null) {
        _notificationPermission = result.notificationPermission;
        _notificationPermissionHasError = false;
        _notificationMessage = _notificationMessageForPermission(
          result.notificationPermission!,
        );
      }
      if (result.exactAlarmPermission != null) {
        _exactAlarmPermission = result.exactAlarmPermission;
        _exactAlarmPermissionHasError = false;
        _exactAlarmMessage = _exactAlarmMessageForPermission(
          result.exactAlarmPermission!,
        );
      }
      if (result.status == PrayerNotificationScheduleStatus.scheduled) {
        _notificationMessage = null;
        _exactAlarmMessage = null;
      }
      if (result.status == PrayerNotificationScheduleStatus.exactAlarmDenied) {
        _exactAlarmMessage =
            result.message ??
            'Exact alarm permission is disabled. Prayer reminders may be delayed.';
      }
    });
  }

  Future<void> _refreshNotificationPermission({
    bool rescheduleIfGranted = false,
  }) async {
    setState(() {
      _isCheckingNotificationPermission = true;
    });
    try {
      final PrayerNotificationPermissionStatus permission =
          await _notificationService.checkPermission();
      if (!mounted) return;
      final bool showDeniedMessage =
          permission == PrayerNotificationPermissionStatus.denied &&
          _settings.reminderSettings.remindersEnabled;
      setState(() {
        _notificationPermission = permission;
        _notificationPermissionHasError = false;
        if (permission == PrayerNotificationPermissionStatus.granted) {
          _notificationPermissionRequestAttempted = false;
        }
        _notificationMessage =
            showDeniedMessage ||
                permission == PrayerNotificationPermissionStatus.unsupported
            ? _notificationMessageForPermission(permission)
            : null;
      });
      if (permission == PrayerNotificationPermissionStatus.granted &&
          rescheduleIfGranted &&
          _settings.reminderSettings.remindersEnabled) {
        final PrayerNotificationScheduleResult result =
            await _rescheduleReminders();
        if (mounted) {
          _applyPermissionStateFromScheduleResult(result);
        }
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage =
            'Notification permission check timed out. Try reopening the app or enabling notifications in system settings.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notificationPermissionHasError = true;
        _notificationMessage =
            'Could not check notification permission. Try again or enable notifications in system settings.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingNotificationPermission = false;
        });
      }
    }
  }

  Future<void> _refreshExactAlarmPermission() async {
    setState(() {
      _isCheckingExactAlarmPermission = true;
    });
    try {
      final PrayerExactAlarmPermissionStatus permission =
          await _notificationService.checkExactAlarmPermission();
      if (!mounted) return;
      final bool showDeniedMessage =
          permission == PrayerExactAlarmPermissionStatus.denied &&
          _settings.reminderSettings.remindersEnabled;
      setState(() {
        _exactAlarmPermission = permission;
        _exactAlarmPermissionHasError = false;
        _exactAlarmMessage = showDeniedMessage
            ? _exactAlarmMessageForPermission(permission)
            : null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _exactAlarmPermissionHasError = true;
        _exactAlarmMessage =
            'Exact alarm permission check timed out. Try reopening the app or enabling alarms & reminders in system settings.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exactAlarmPermissionHasError = true;
        _exactAlarmMessage =
            'Could not check exact alarm permission. Try again or enable alarms & reminders in system settings.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingExactAlarmPermission = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _locationSubtitle {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final PrayerLocation? location = _location;
    if (location == null) return localizations.chooseLocationBeforeCalculating;
    return location.displayLabel;
  }

  String get _calculationSubtitle {
    return _methodSubtitle;
  }

  String get _timezoneSettingSubtitle {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (!_settings.useLocationTimezone) {
      return localizations.usingDeviceTimezone;
    }
    final String? timezoneId = _location?.timezoneId;
    if (timezoneId == null || timezoneId.isEmpty) {
      return localizations.usingDeviceTimezoneUntilLocationAvailable;
    }
    return localizations.displayPrayerTimesUsingTimezone(timezoneId);
  }

  String get _reminderSubtitle {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final PrayerReminderSettings reminders = _settings.reminderSettings;
    if (!reminders.remindersEnabled || reminders.enabledPrayerCount == 0) {
      return localizations.remindersOff;
    }
    if (_location == null) return localizations.remindersOnWaitingLocation;
    final int enabledCount = reminders.enabledPrayerCount;
    if (enabledCount == PrayerTimeKind.reminderOrder.length) {
      return localizations.allPrayerRemindersOn;
    }
    return localizations.remindersEnabledCount(enabledCount);
  }

  String get _notificationPermissionSubtitle {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (_isCheckingNotificationPermission) {
      return localizations.checkingNotificationPermission;
    }
    if (_notificationPermissionHasError) {
      return localizations.permissionStatusNeedsRetry;
    }
    final PrayerNotificationPermissionStatus? permission =
        _notificationPermission;
    return switch (permission) {
      PrayerNotificationPermissionStatus.granted =>
        _settings.reminderSettings.remindersEnabled
            ? localizations.localNotificationsScheduled
            : localizations.notificationPermissionGranted,
      PrayerNotificationPermissionStatus.denied =>
        localizations.notificationPermissionOff,
      PrayerNotificationPermissionStatus.unsupported =>
        localizations.prayerRemindersUnsupported,
      null => localizations.checkingNotificationPermission,
    };
  }

  String get _exactAlarmPermissionSubtitle {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (_isCheckingExactAlarmPermission) {
      return localizations.checkingExactAlarmPermission;
    }
    if (_exactAlarmPermissionHasError) {
      return localizations.exactAlarmStatusNeedsRetry;
    }
    final PrayerExactAlarmPermissionStatus? permission = _exactAlarmPermission;
    return switch (permission) {
      PrayerExactAlarmPermissionStatus.granted =>
        localizations.alarmPermissionGranted,
      PrayerExactAlarmPermissionStatus.denied =>
        localizations.exactAlarmPermissionDisabled,
      PrayerExactAlarmPermissionStatus.unsupported =>
        localizations.exactAlarmPermissionNotRequired,
      null => localizations.checkingExactAlarmPermission,
    };
  }

  String? _notificationMessageForPermission(
    PrayerNotificationPermissionStatus permission,
  ) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return switch (permission) {
      PrayerNotificationPermissionStatus.granted => null,
      PrayerNotificationPermissionStatus.denied =>
        localizations.notificationPermissionOffEnable,
      PrayerNotificationPermissionStatus.unsupported =>
        localizations.prayerRemindersUnsupported,
    };
  }

  String? _exactAlarmMessageForPermission(
    PrayerExactAlarmPermissionStatus permission,
  ) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return switch (permission) {
      PrayerExactAlarmPermissionStatus.granted => null,
      PrayerExactAlarmPermissionStatus.denied =>
        localizations.exactAlarmPermissionDisabled,
      PrayerExactAlarmPermissionStatus.unsupported => null,
    };
  }

  String get _methodSubtitle {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final PrayerLocation? location = _location;
    if (_settings.method == PrayerCalculationMethod.auto && location == null) {
      return localizations.bestMethodAfterLocationSaved;
    }
    final PrayerCalculationMethod effectiveMethod =
        _settings.method == PrayerCalculationMethod.auto && location != null
        ? _service.effectiveMethodFor(location: location, settings: _settings)
        : _settings.method;
    return prayerMethodDisplayLabel(
      settings: _settings,
      effectiveMethod: effectiveMethod,
    );
  }

  String _offsetLabel(int offset) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (offset == 0) return localizations.noManualAdjustment;
    final String label = localizations.positiveOrNegativeMinutes(offset);
    return offset > 0 ? '+$label' : label;
  }

  String _reminderOffsetLabel(int offset) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (offset == 0) return localizations.atPrayerTime;
    return localizations.minutesBeforePrayer(offset);
  }

  String _clockLabel(int hour, int minute) {
    final TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  String _formatClockTime(DateTime time) {
    return TimeOfDay(hour: time.hour, minute: time.minute).format(context);
  }
}

class _OptionalNumberResult<T extends num> {
  const _OptionalNumberResult(this.value);

  final T? value;
}

extension PrayerOffsetsUpdate on PrayerOffsets {
  PrayerOffsets copyWithPrayer(PrayerTimeKind prayer, int value) {
    return PrayerOffsets(
      fajr: prayer == PrayerTimeKind.fajr ? value : fajr,
      sunrise: prayer == PrayerTimeKind.sunrise ? value : sunrise,
      dhuhr: prayer == PrayerTimeKind.dhuhr ? value : dhuhr,
      asr: prayer == PrayerTimeKind.asr ? value : asr,
      maghrib: prayer == PrayerTimeKind.maghrib ? value : maghrib,
      isha: prayer == PrayerTimeKind.isha ? value : isha,
    );
  }
}

extension PrayerCustomSettingsUpdate on PrayerTimeSettings {
  PrayerTimeSettings withCustomIshaInterval(int? value) {
    return PrayerTimeSettings(
      method: method,
      customFajrAngle: customFajrAngle,
      customIshaAngle: customIshaAngle,
      customIshaMode: customIshaMode,
      customIshaInterval: value,
      customIshaFixedTimeHour: customIshaFixedTimeHour,
      customIshaFixedTimeMinute: customIshaFixedTimeMinute,
      customIshaLatestCapHour: customIshaLatestCapHour,
      customIshaLatestCapMinute: customIshaLatestCapMinute,
      customMaghribAngle: customMaghribAngle,
      asrMethod: asrMethod,
      highLatitudeRule: highLatitudeRule,
      offsets: offsets,
      use24HourFormat: use24HourFormat,
      useLocationTimezone: useLocationTimezone,
      sunriseProhibitedDurationMinutes: sunriseProhibitedDurationMinutes,
      dhuhrProhibitedDurationMinutes: dhuhrProhibitedDurationMinutes,
      sunsetProhibitedDurationMinutes: sunsetProhibitedDurationMinutes,
      reminderSettings: reminderSettings,
    );
  }

  PrayerTimeSettings withCustomMaghribAngle(double? value) {
    return PrayerTimeSettings(
      method: method,
      customFajrAngle: customFajrAngle,
      customIshaAngle: customIshaAngle,
      customIshaMode: customIshaMode,
      customIshaInterval: customIshaInterval,
      customIshaFixedTimeHour: customIshaFixedTimeHour,
      customIshaFixedTimeMinute: customIshaFixedTimeMinute,
      customIshaLatestCapHour: customIshaLatestCapHour,
      customIshaLatestCapMinute: customIshaLatestCapMinute,
      customMaghribAngle: value,
      asrMethod: asrMethod,
      highLatitudeRule: highLatitudeRule,
      offsets: offsets,
      use24HourFormat: use24HourFormat,
      useLocationTimezone: useLocationTimezone,
      sunriseProhibitedDurationMinutes: sunriseProhibitedDurationMinutes,
      dhuhrProhibitedDurationMinutes: dhuhrProhibitedDurationMinutes,
      sunsetProhibitedDurationMinutes: sunsetProhibitedDurationMinutes,
      reminderSettings: reminderSettings,
    );
  }
}
