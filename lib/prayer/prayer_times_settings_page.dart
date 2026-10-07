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
import 'package:equran/prayer/prayer_settings_dialogs.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/app_selection_dialog.dart'
    show AppSelectionOption;
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:flutter/foundation.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:equran/widgets/redesign/settings_group_card.dart';
import 'package:flutter/material.dart';

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

    return RedesignSubpage(
      title: localizations.prayerTimesSettings,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: <Widget>[
          _buildSettingsGroup(
            context: context,
            title: localizations.location,
            subtitle: _locationSubtitle,
            icon: Icons.location_on_outlined,
            children: <Widget>[
              ReaderOptionRow(
                leading: const DesignIcon('pin'),
                title: localizations.chooseOnMap,
                subtitle: localizations.moveMapUnderPin,
                onTap: () => _chooseOnMap(_location),
              ),
              if (_location != null)
                ReaderOptionRow(
                  leading: const Icon(Icons.location_disabled_outlined),
                  title: localizations.clearSavedLocation,
                  subtitle: localizations.clearSavedLocationSubtitle,
                  showChevron: false,
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
              ReaderOptionRow(
                leading: const Icon(Icons.calculate_outlined),
                title: localizations.calculationMethod,
                subtitle: _methodSubtitle,
                subtitleMaxLines: 3,
                onTap: _selectCalculationMethod,
              ),
              ReaderOptionRow(
                leading: const DesignIcon('sun'),
                title: localizations.asrMethod,
                subtitle: _settings.asrMethod.label,
                onTap: _selectAsrMethod,
              ),
              ReaderOptionRow(
                leading: const Icon(Icons.public_rounded),
                title: localizations.highLatitudeAdjustment,
                subtitle:
                    '${_settings.highLatitudeRule.label}\n${localizations.highLatitudeAdjustmentSubtitle}',
                subtitleMaxLines: 4,
                onTap: _selectHighLatitudeRule,
              ),
              ReaderOptionRow(
                leading: const DesignIcon('clock'),
                title: localizations.timeFormat,
                subtitle: _settings.use24HourFormat ? '24-hour' : '12-hour',
                onTap: _selectTimeFormat,
              ),
              ReaderSwitchRow(
                leading: const Icon(Icons.language_rounded),
                title: localizations.useLocationTimezone,
                subtitle: _timezoneSettingSubtitle,
                value: _settings.useLocationTimezone,
                onChanged: (bool enabled) => _saveSettings(
                  _settings.copyWith(useLocationTimezone: enabled),
                ),
              ),
              if (_settings.method == PrayerCalculationMethod.custom)
                _buildCustomMethodCard(),
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
                padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 12),
                child: Text(
                  localizations.offsetsAreAppliedAfterBaseCalculation,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: context.equranTokens.muted,
                  ),
                ),
              ),
              for (final PrayerTimeKind prayer in PrayerTimeKind.displayOrder)
                ReaderOptionRow(
                  leading: const DesignIcon('clock'),
                  title: prayer.label,
                  subtitle: _offsetLabel(_settings.offsets.forPrayer(prayer)),
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
  }) => SettingsGroupCard(
    title: title,
    subtitle: subtitle,
    icon: icon,
    initiallyExpanded: true,
    children: children,
  );

  Widget _buildProhibitedTimesSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return _buildSettingsGroup(
      context: context,
      title: localizations.prohibitedTimes,
      subtitle: localizations.prohibitedTimesSubtitle,
      icon: Icons.block_outlined,
      children: <Widget>[
        ReaderOptionRow(
          leading: const Icon(Icons.block_outlined),
          title: localizations.sunriseProhibitedTime,
          subtitle: localizations.sunriseProhibitedTimeMinutes(
            _settings.sunriseProhibitedDurationMinutes,
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
        ReaderOptionRow(
          leading: const Icon(Icons.block_outlined),
          title: localizations.zawalProhibitedTime,
          subtitle: localizations.zawalProhibitedTimeMinutes(
            _settings.dhuhrProhibitedDurationMinutes,
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
        ReaderOptionRow(
          leading: const Icon(Icons.block_outlined),
          title: localizations.sunsetProhibitedTime,
          subtitle: localizations.sunsetProhibitedTimeMinutes(
            _settings.sunsetProhibitedDurationMinutes,
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
    final EquranTokens tokens = context.equranTokens;
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
        ReaderSwitchRow(
          leading: _isUpdatingReminders
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const DesignIcon('bell'),
          title: localizations.prayerRemindersEnabled,
          subtitle: _notificationPermissionSubtitle,
          value: remindersOn,
          onChanged: _isUpdatingReminders ? null : _toggleGlobalReminders,
        ),
        ReaderOptionRow(
          leading: const DesignIcon('bell'),
          title: localizations.notificationsPermission,
          subtitle: _notificationPermissionSubtitle,
          showChevron: false,
          onTap: null,
          trailing: permission == PrayerNotificationPermissionStatus.denied
              ? TextButton(
                  style: readerNoticeButtonStyle(context),
                  onPressed: _isUpdatingReminders
                      ? null
                      : _requestNotificationPermission,
                  child: Text(localizations.enable),
                )
              : null,
        ),
        ReaderOptionRow(
          leading: const Icon(Icons.alarm_on_outlined),
          title: localizations.exactAlarmPermission,
          subtitle: _exactAlarmPermissionSubtitle,
          showChevron: false,
          onTap: null,
          trailing: exactAlarmOff
              ? TextButton(
                  style: readerNoticeButtonStyle(context),
                  onPressed: _isUpdatingReminders
                      ? null
                      : _openExactAlarmSettings,
                  child: Text(localizations.open),
                )
              : null,
        ),
        if (permissionOff || _notificationMessage != null)
          _buildNotificationPermissionBanner(),
        if (exactAlarmOff || _exactAlarmMessage != null)
          _buildExactAlarmPermissionBanner(),
        if (remindersOn && _location == null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
            child: Text(
              localizations.chooseLocationBeforeReminders,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: tokens.muted,
              ),
            ),
          ),
        if (remindersOn) ...<Widget>[
          for (final PrayerTimeKind prayer in PrayerTimeKind.reminderOrder)
            ReaderSwitchRow(
              leading: const DesignIcon('bell'),
              title: prayer.label,
              subtitle: localizations.notifyAtSavedPrayerTime,
              value: reminders.prayerToggleFor(prayer),
              onChanged: _isUpdatingReminders
                  ? null
                  : (bool enabled) => _togglePrayerReminder(prayer, enabled),
            ),
          ReaderOptionRow(
            leading: const DesignIcon('clock'),
            title: localizations.reminderTime,
            subtitle: _reminderOffsetLabel(reminders.reminderOffsetMinutes),
            onTap: _isUpdatingReminders ? null : _selectReminderOffset,
          ),
          if (kDebugMode)
            ReaderOptionRow(
              leading: const Icon(Icons.bug_report_outlined),
              title: localizations.schedule1MinuteExactTest,
              subtitle: localizations.schedule1MinuteExactTestSubtitle,
              showChevron: false,
              onTap: _isUpdatingReminders
                  ? null
                  : _scheduleDebugPrayerNotification,
            ),
        ],
      ],
    );
  }

  Widget _buildNotificationPermissionBanner() {
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
    return ReaderNotice(
      margin: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      danger: true,
      icon: const Icon(Icons.notifications_off_outlined),
      text:
          _notificationMessage ?? localizations.notificationPermissionOffEnable,
      action: unsupported
          ? null
          : TextButton.icon(
              style: readerNoticeButtonStyle(context),
              onPressed: _isUpdatingReminders ? null : action,
              icon: Icon(
                error
                    ? Icons.refresh_rounded
                    : openSettings
                    ? Icons.settings_outlined
                    : Icons.notifications_active_outlined,
                size: 18,
              ),
              label: Text(
                error
                    ? localizations.retry
                    : openSettings
                    ? localizations.openAppSettings
                    : localizations.requestPermission,
              ),
            ),
    );
  }

  Widget _buildExactAlarmPermissionBanner() {
    final bool error = _exactAlarmPermissionHasError;
    return ReaderNotice(
      margin: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      danger: true,
      icon: const Icon(Icons.alarm_off_outlined),
      text: _exactAlarmMessage ?? localizations.exactAlarmPermissionDisabled,
      action: TextButton.icon(
        style: readerNoticeButtonStyle(context),
        onPressed: _isUpdatingReminders
            ? null
            : error
            ? _refreshExactAlarmPermission
            : _openExactAlarmSettings,
        icon: Icon(
          error ? Icons.refresh_rounded : Icons.settings_outlined,
          size: 18,
        ),
        label: Text(
          error
              ? localizations.retry
              : localizations.openAlarmPermissionSettings,
        ),
      ),
    );
  }

  Widget _buildCustomMethodCard() {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final List<Widget> rows = <Widget>[
      ReaderOptionRow(
        leading: const DesignIcon('sliders'),
        title: localizations.fajrAngle,
        subtitle: '${_settings.customFajrAngle.toStringAsFixed(1)}°',
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
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
        child: Text(
          localizations.highLatitudeMosqueNotice,
          style: TextStyle(fontSize: 12.5, height: 1.4, color: tokens.muted),
        ),
      ),
      ReaderOptionRow(
        leading: const DesignIcon('moon'),
        title: localizations.ishaMode,
        subtitle: _localizedIshaModeLabel(_settings.customIshaMode),
        onTap: _selectCustomIshaMode,
      ),
      ..._buildCustomIshaFields(),
      ReaderOptionRow(
        leading: const DesignIcon('sliders'),
        title: localizations.maghribAngle,
        subtitle: _settings.customMaghribAngle == null
            ? localizations.useSunset
            : '${_settings.customMaghribAngle!.toStringAsFixed(1)}°',
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
    ];
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EquranRadii.large - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 12),
              child: Row(
                children: <Widget>[
                  const ReaderIconWell(icon: Icon(Icons.construction_rounded)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      localizations.customMethod,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final Widget row in rows) ...<Widget>[
              Divider(height: 1, thickness: 1, color: tokens.hair),
              row,
            ],
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
        ReaderOptionRow(
          leading: const DesignIcon('clock'),
          title: localizations.fixedIshaTime,
          subtitle: _clockLabel(
            _settings.customIshaFixedTimeHour,
            _settings.customIshaFixedTimeMinute,
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
        ReaderOptionRow(
          leading: const DesignIcon('clock'),
          title: localizations.latestIshaTime,
          subtitle: localizations.latestIshaTimeHelp(
            _clockLabel(
              _settings.customIshaLatestCapHour,
              _settings.customIshaLatestCapMinute,
            ),
          ),
          subtitleMaxLines: 3,
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
    return ReaderOptionRow(
      leading: const DesignIcon('sliders'),
      title: resolvedTitle,
      subtitle: '${_settings.customIshaAngle.toStringAsFixed(1)}°',
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
    return ReaderOptionRow(
      leading: const DesignIcon('clock'),
      title: requiredValue
          ? localizations.ishaInterval
          : localizations.baseIshaInterval,
      subtitle: _settings.customIshaInterval == null
          ? localizations.useIshaAngle
          : localizations.minutesAfterMaghrib(_settings.customIshaInterval!),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ReaderNotice(
        icon: const DesignIcon('info'),
        text: localizations.prayerTimesExperimental,
      ),
    );
  }

  Future<void> _selectCalculationMethod() async {
    final PrayerCalculationMethod? selected =
        await _showSelectionDialog<PrayerCalculationMethod>(
          title: localizations.calculationMethod,
          icon: const Icon(Icons.calculate_outlined),
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
          icon: const DesignIcon('sun'),
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
          icon: const Icon(Icons.public_rounded),
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
          icon: const DesignIcon('moon'),
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
      icon: const DesignIcon('clock'),
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
      icon: const DesignIcon('clock'),
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
    required Widget icon,
    required T selectedValue,
    required List<AppSelectionOption<T>> options,
  }) {
    return showReaderDialog<T>(
      context: context,
      builder: (BuildContext context) => ReaderChoiceDialog<T>(
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
    final OptionalNumberResult<int>? result =
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
    final OptionalNumberResult<double>? result =
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
    ).then((OptionalNumberResult<T>? result) => result?.value);
  }

  Future<OptionalNumberResult<T>?> _showOptionalNumberDialog<T extends num>({
    required String title,
    required T? currentValue,
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

  Future<OptionalNumberResult<int>?> _showOptionalSteppedIntDialog({
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

  Future<OptionalNumberResult<int>?> _showSteppedIntDialogInternal({
    required String title,
    required int? currentValue,
    required int min,
    required int max,
    required String helperText,
    required bool allowNullValue,
  }) {
    return showReaderDialog<OptionalNumberResult<int>?>(
      context: context,
      builder: (BuildContext context) => PrayerSteppedIntDialog(
        title: title,
        currentValue: currentValue,
        min: min,
        max: max,
        helperText: helperText,
        allowNullValue: allowNullValue,
      ),
    );
  }

  Future<OptionalNumberResult<T>?> _showNumberDialogInternal<T extends num>({
    required String title,
    required T? currentValue,
    required String helperText,
    required T? Function(String value) parser,
    required bool Function(T value) validator,
    required String Function(T value) formatter,
    required bool allowEmpty,
  }) {
    return showReaderDialog<OptionalNumberResult<T>?>(
      context: context,
      builder: (BuildContext context) => PrayerNumberDialog<T>(
        title: title,
        currentValue: currentValue,
        helperText: helperText,
        parser: parser,
        validator: validator,
        formatter: formatter,
        allowEmpty: allowEmpty,
      ),
    );
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
