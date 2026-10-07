import 'package:equran/backend/settings_db.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:equran/widgets/redesign/segmented_control.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key, this.now});

  /// The clock for today and the selected day; tests pass a fixed one.
  final DateTime Function()? now;

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage> {
  late DateTime _focusedDate;
  DateTime? _selectedDate;
  int _sightingOffset = 0;
  bool _fastingRemindersEnabled = false;

  AppLocalizations get localizations => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _sightingOffset = SettingsDB().get('hijri_offset', defaultValue: 0);
    _fastingRemindersEnabled = SettingsDB().get(
      'fasting_reminders_enabled',
      defaultValue: false,
    );
    _focusedDate = _now();
    _selectedDate = _focusedDate;
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  Future<void> _updateSightingOffset(int newOffset) async {
    await SettingsDB().put('hijri_offset', newOffset);
    setState(() {
      _sightingOffset = newOffset;
    });
    if (_fastingRemindersEnabled) {
      await _scheduleFastingReminders();
    }
  }

  Future<void> _toggleFastingReminders(bool value) async {
    await SettingsDB().put('fasting_reminders_enabled', value);
    setState(() {
      _fastingRemindersEnabled = value;
    });

    if (value) {
      final status = await FlutterPrayerLocalNotificationPlatform.instance
          .checkPermission();
      if (status != PrayerNotificationPermissionStatus.granted) {
        await FlutterPrayerLocalNotificationPlatform.instance
            .requestPermission();
      }
      await _scheduleFastingReminders();
    } else {
      await _cancelFastingReminders();
    }
  }

  Future<void> _scheduleFastingReminders() async {
    await _cancelFastingReminders();
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    final DateTime now = DateTime.now();
    final int offset = _sightingOffset;

    int scheduledCount = 0;

    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final DateTime date = DateTime(now.year, now.month, now.day + dayOffset);
      final HijriCalendar hijri = HijriCalendar.fromDate(date, offset: offset);
      final String? fastingReason = _getFastingReason(hijri);

      if (fastingReason != null) {
        // Fasting alert goes out at 8:00 PM the night before
        final DateTime reminderTime = DateTime(
          date.year,
          date.month,
          date.day - 1,
          20,
          0,
        );

        if (reminderTime.isAfter(now)) {
          final int notificationId = 82000 + dayOffset;
          await FlutterPrayerLocalNotificationPlatform.instance.schedule(
            id: notificationId,
            title: localizations.fastingReminder,
            body: localizations.fastingNotificationBody(
              hijri.toLocalizedDateString(localizations.localeName),
              _localizeOccasion(fastingReason),
            ),
            scheduledAt: reminderTime,
            payload: 'fasting:reminder:${hijri.toString()}',
          );
          scheduledCount++;
        }
      }
    }

    if (mounted && scheduledCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.fastingAlertsActive),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelFastingReminders() async {
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      await FlutterPrayerLocalNotificationPlatform.instance.cancel(
        82000 + dayOffset,
      );
    }
  }

  String? _getFastingReason(HijriCalendar hijri) {
    if (hijri.hMonth == 9) return 'Ramadan Fasting Day';
    if (hijri.hMonth == 12 && hijri.hDay == 9) return 'Day of Arafah';
    if (hijri.hMonth == 1 && hijri.hDay == 9) return 'Tasua Fast';
    if (hijri.hMonth == 1 && hijri.hDay == 10) return 'Day of Ashura';
    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) {
      return 'Ayyam al-Bid (White Day)';
    }
    return null;
  }

  String? _getIslamicOccasion(HijriCalendar hijri) {
    // Prefer the richer data now provided by the enhanced helper
    final String? major = hijri.majorOccasion;
    if (major != null) {
      // Add slight extra context for a couple of cases to match previous tone
      if (major == 'Laylat al-Qadr') return 'Laylat al-Qadr (Blessed Night)';
      if (major == 'Shab-e-Barat') return 'Shab-e-Barat (Blessed Night)';
      if (major == 'Isra\' and Mi\'raj') {
        return 'Isra\' and Mi\'raj (Blessed Night)';
      }
      if (major == 'Day of Arafah') return 'Day of Arafah (Fasting)';
      if (major == 'Day of Ashura') return 'Day of Ashura (Fasting)';
      return major;
    }

    // Fallbacks for fasting-only days
    if (hijri.hMonth == 9) return 'Ramadan Fasting Day';
    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) {
      return 'Ayyam al-Bid (White Day - Fasting)';
    }
    if (hijri.isRecommendedFastingDay) return 'Recommended Fasting Day';
    return null;
  }

  String _localizeOccasion(String label) {
    switch (label) {
      case 'Ramadan':
        return localizations.occasionRamadan;
      case 'Eid al-Fitr':
      case 'Eid al-Fiṭr':
        return localizations.occasionEidAlFitr;
      case 'Day of Arafah':
      case 'Day of ʿArafah':
        return localizations.occasionDayOfArafah;
      case 'Day of Arafah (Fasting)':
        return localizations.occasionDayOfArafahFasting;
      case 'Eid al-Adha':
      case 'Eid al-Aḍḥā':
        return localizations.occasionEidAlAdha;
      case 'Day of Ashura':
      case 'ʿĀshūrā':
      case 'Ashura':
        return localizations.occasionDayOfAshura;
      case 'Day of Ashura (Fasting)':
        return localizations.occasionDayOfAshuraFasting;
      case 'Isra\' and Mi\'raj':
      case 'Isra\' & Mi\'raj':
      case 'Isra\' and Mi\'raj (Blessed Night)':
      case 'Isrāʾ & Miʿrāj':
        return localizations.occasionIsraAndMiraj;
      case 'Ramadan begins':
      case 'First Day of Ramadan':
      case '1 Ramaḍān':
        return localizations.occasionRamadanBegins;
      case 'Ramadan Fasting Day':
        return localizations.occasionRamadanFastingDay;
      case 'Laylat al-Qadr':
      case 'Laylat al-Qadr (Blessed Night)':
        return localizations.occasionLaylatAlQadrBlessed;
      case 'Islamic New Year':
        return localizations.occasionIslamicNewYear;
      case 'Shab-e-Barat':
      case 'Shab-e-Barat (Blessed Night)':
        return localizations.occasionShabEBaratBlessed;
      case 'Tasua Fast':
        return localizations.occasionTasuaFast;
      case 'Ayyam al-Bid (White Day)':
        return localizations.occasionAyyamAlBid;
      case 'Ayyam al-Bid (White Day - Fasting)':
        return localizations.occasionAyyamAlBidFasting;
      case 'Recommended Fasting Day':
        return localizations.occasionRecommendedFastingDay;
      case 'Fast':
        return localizations.occasionFast;
      default:
        return label;
    }
  }

  String _localizeMoonPhase(int phase) {
    switch (phase) {
      case 0:
        return localizations.moonPhaseNew;
      case 1:
        return localizations.moonPhaseWaxingCrescent;
      case 2:
        return localizations.moonPhaseFull;
      case 3:
        return localizations.moonPhaseWaningCrescent;
      default:
        return localizations.moonPhaseCrescent;
    }
  }

  String _localizeAction(String action) {
    switch (action) {
      case 'Increase recitation of the Qur\'an':
        return localizations.recActionQuran;
      case 'Give charity and help those in need':
        return localizations.recActionCharity;
      case 'Seek Laylat al-Qadr in the odd nights':
        return localizations.recActionLaylatAlQadr;
      case 'Perform Eid prayer + Zakat al-Fitr':
        return localizations.recActionEidFitr;
      case 'Visit family and share food':
        return localizations.recActionEidFitrSocial;
      case 'Fast the Day of Arafah':
        return localizations.recActionFastArafah;
      case 'Make abundant du\'a':
        return localizations.recActionDua;
      case 'Perform Eid al-Adha prayer':
        return localizations.recActionEidAdha;
      case 'Sacrifice an animal if able (Qurbani)':
        return localizations.recActionQurbani;
      case 'Fast Ashura (before/after)':
        return localizations.recActionFastAshura;
      case 'Observe voluntary fast if able':
        return localizations.recActionVoluntaryFast;
      case 'Fast one of the Ayyam al-Bid (White Days)':
        return localizations.recActionFastAyyamAlBid;
      case 'Engage in dhikr, prayer, and good deeds':
        return localizations.recActionGeneralWorship;
      default:
        return action;
    }
  }

  /// The calendar treatment a day gets. The conditions are the page's own
  /// (Eid, Ramadan, fasting days, blessed nights); only how they are drawn
  /// changed.
  _DayKind _dayKind(HijriCalendar hijri) {
    final bool isMajorEid =
        (hijri.hMonth == 10 && hijri.hDay == 1) ||
        (hijri.hMonth == 12 && hijri.hDay == 10);
    if (isMajorEid) return _DayKind.eid;
    if (hijri.hMonth == 9) return _DayKind.ramadan;

    final String? occasion = hijri.majorOccasion;
    if (occasion == 'Day of Arafah' || occasion == 'Day of Ashura') {
      return _DayKind.fast;
    }
    if (occasion == 'Laylat al-Qadr' ||
        occasion == 'Shab-e-Barat' ||
        occasion == 'Isra\' and Mi\'raj') {
      return _DayKind.blessedNight;
    }
    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) {
      return _DayKind.fast;
    }
    return _DayKind.none;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime focused = _focusedDate;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Days in current focused month
    final DateTime firstOfMonth = DateTime(focused.year, focused.month, 1);
    final int blankDaysCount = firstOfMonth.weekday - 1; // Mon = 1
    final DateTime lastOfMonth = DateTime(focused.year, focused.month + 1, 0);
    final int daysInMonthCount = lastOfMonth.day;

    final List<String> weekdays = List<String>.generate(7, (index) {
      // 2026-06-08 is a Monday
      return DateFormat.E(
        localizations.localeName,
      ).format(DateTime(2026, 6, 8 + index));
    });

    return RedesignSubpage(
      title: localizations.islamicCalendar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          _buildCalendarHeader(),
          const SizedBox(height: 12),
          HairlineCard(
            padding: const EdgeInsets.all(12),
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildPremiumMonthGrid(
                key: ValueKey<int>(focused.month * 10000 + focused.year),
                firstOfMonth: firstOfMonth,
                blankDaysCount: blankDaysCount,
                daysInMonthCount: daysInMonthCount,
                weekdays: weekdays,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildEventLegend(),
          const SizedBox(height: 16),
          _buildTopMoonCombinedSection(),
          const SizedBox(height: 20),
          _buildQuickJumps(),
          const SizedBox(height: 22),
          _buildYearKeyDates(),
          if (_selectedDate != null) ...<Widget>[
            const SizedBox(height: 22),
            _buildDateDetailsCard(),
          ],
        ],
      ),
    );
  }

  // Moon sighting controls and the moon phase, side by side.
  Widget _buildTopMoonCombinedSection() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: _buildCompactMoonSightingCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildMoonPhaseCard()),
        ],
      ),
    );
  }

  /// A hairline card that can be tapped; the ripple needs the surface to be a
  /// [Material], so this does not wrap a plain container.
  Widget _tapCard({required Widget child, VoidCallback? onTap}) {
    final EquranTokens tokens = context.equranTokens;
    return Material(
      color: context.equranColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EquranRadii.xl),
        side: BorderSide(color: tokens.hair),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }

  Widget _infoCardBody({
    required Widget icon,
    required String label,
    required String value,
    required String caption,
    int captionLines = 2,
  }) {
    final EquranTokens tokens = context.equranTokens;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReaderIconWell(icon: icon),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tokens.emText,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: redesignDisplayStyle(context, size: 22)),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: captionLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, height: 1.35, color: tokens.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMoonSightingCard() {
    final String offsetLabel = _sightingOffset == 0
        ? localizations.standard
        : '${_sightingOffset > 0 ? '+' : ''}${_sightingOffset.abs() == 1 ? localizations.daySingular(_sightingOffset.abs()) : localizations.daysPlural(_sightingOffset.abs())}';

    return _tapCard(
      onTap: _showCalendarSettingsSheet,
      child: _infoCardBody(
        icon: const DesignIcon('sliders'),
        label: localizations.moonSighting,
        value: offsetLabel,
        caption: localizations.tapToAdjust,
      ),
    );
  }

  Widget _buildMoonPhaseCard() {
    final DateTime referenceDate = _selectedDate ?? _now();
    final HijriCalendar hijri = HijriCalendar.fromDate(
      referenceDate,
      offset: _sightingOffset,
    );
    final int phase = hijri.estimatedMoonPhase;
    final String phaseName = _localizeMoonPhase(phase);

    // Short contextual line, so the phase name is not repeated.
    final String contextLine = switch (phase) {
      0 => localizations.moonPhaseContextNew,
      1 => localizations.moonPhaseContextWaxing,
      2 => localizations.moonPhaseContextFull,
      _ => localizations.moonPhaseContextWaning,
    };

    return _tapCard(
      child: _infoCardBody(
        icon: Icon(_moonIconForPhase(phase)),
        label: localizations.moonPhase,
        value: phaseName,
        caption: contextLine,
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final EquranTokens tokens = context.equranTokens;
    final String gregorianLabel = DateFormat(
      'MMM yyyy',
      localizations.localeName,
    ).format(_focusedDate);

    // Approximate Hijri month for the middle of the focused Gregorian month.
    final DateTime midMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      15,
    );
    final HijriCalendar midHijri = HijriCalendar.fromDate(
      midMonth,
      offset: _sightingOffset,
    );
    final MaterialLocalizations material = MaterialLocalizations.of(context);

    return HairlineCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: <Widget>[
          IconButton44(
            designIcon: 'chevl',
            tooltip: material.previousMonthTooltip,
            ghost: true,
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month - 1,
                );
              });
            },
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  gregorianLabel,
                  textAlign: TextAlign.center,
                  style: redesignDisplayStyle(context, size: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  '${midHijri.getLocalizedMonthName(localizations.localeName)} ${midHijri.hYear}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.goldText,
                  ),
                ),
              ],
            ),
          ),
          IconButton44(
            designIcon: 'chev',
            tooltip: material.nextMonthTooltip,
            ghost: true,
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMonthGrid({
    Key? key,
    required DateTime firstOfMonth,
    required int blankDaysCount,
    required int daysInMonthCount,
    required List<String> weekdays,
  }) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double cellAspect = screenWidth < 360 ? 0.95 : 1.05;
    final DateTime today = _now();
    final double gregorianSize = screenWidth < 360 ? 11.0 : 13.0;
    final double hijriSize = screenWidth < 360 ? 8.0 : 9.5;

    return Column(
      key: key,
      children: <Widget>[
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.6,
          ),
          itemCount: 7,
          itemBuilder: (BuildContext context, int index) {
            return Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.muted,
                  letterSpacing: 0.4,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: cellAspect,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: blankDaysCount + daysInMonthCount,
          itemBuilder: (BuildContext context, int index) {
            if (index < blankDaysCount) {
              return const SizedBox.shrink();
            }

            final int dayNumber = index - blankDaysCount + 1;
            final DateTime date = DateTime(
              _focusedDate.year,
              _focusedDate.month,
              dayNumber,
            );
            final HijriCalendar hijri = HijriCalendar.fromDate(
              date,
              offset: _sightingOffset,
            );

            final bool isToday = _isSameDay(date, today);
            final bool isSelected =
                _selectedDate != null && _isSameDay(date, _selectedDate!);
            final _DayKind kind = _dayKind(hijri);
            final bool hasEvent = hijri.shortEventLabel != null;

            // Visual hierarchy, strongest first:
            // 1. Selected: the solid emerald fill.
            // 2. Today: an emerald wash with a full-strength ring.
            // 3. Events: washes and dots that are always lighter than both
            //    (Eid gets a gold wash and a hairline, never a ring).
            Color bgColor = Colors.transparent;
            Color borderColor = tokens.hair;
            double borderWidth = 1;
            Color dayColor = colors.textPrimary;
            Color hijriColor = tokens.muted;

            if (isSelected) {
              bgColor = tokens.filled;
              borderColor = isToday ? tokens.gold : tokens.filled;
              borderWidth = isToday ? 2 : 1;
              dayColor = Colors.white;
              hijriColor = Colors.white.withValues(alpha: 0.78);
            } else if (isToday) {
              bgColor = tokens.emWash;
              borderColor = tokens.emText;
              borderWidth = 1.6;
              dayColor = tokens.emText;
            } else {
              switch (kind) {
                case _DayKind.eid:
                  bgColor = tokens.goldWash;
                  borderColor = tokens.gold.withValues(alpha: 0.5);
                case _DayKind.ramadan:
                  bgColor = tokens.emWash;
                case _DayKind.fast:
                case _DayKind.blessedNight:
                case _DayKind.none:
                  break;
              }
            }

            final Color dotColor = kind == _DayKind.fast
                ? tokens.emText
                : tokens.gold;
            final String semanticsLabel =
                '${DateFormat.yMMMMd(localizations.localeName).format(date)}, ${hijri.toLocalizedDateString(localizations.localeName)}';

            return Semantics(
              button: true,
              selected: isSelected,
              label: semanticsLabel,
              child: ExcludeSemantics(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        PositionedDirectional(
                          top: 5,
                          start: 7,
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: gregorianSize,
                              fontWeight: FontWeight.w600,
                              color: dayColor,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          bottom: 5,
                          end: 7,
                          child: Text(
                            '${hijri.hDay}',
                            style: TextStyle(
                              fontSize: hijriSize,
                              color: hijriColor,
                            ),
                          ),
                        ),
                        if (hasEvent && !isToday && !isSelected)
                          PositionedDirectional(
                            top: 7,
                            end: 7,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  IconData _moonIconForPhase(int phase) {
    switch (phase) {
      case 0:
        return Icons.brightness_1; // New moon
      case 1:
        return Icons.nightlight_round; // Crescent / waxing
      case 2:
        return Icons.brightness_7; // Full
      case 3:
        return Icons.nightlight; // Waning
      default:
        return Icons.nightlight_round;
    }
  }

  /// The legend draws each swatch the way the grid draws the day.
  Widget _buildEventLegend() {
    final EquranTokens tokens = context.equranTokens;
    Widget swatch({
      Color? fill,
      Color? border,
      double borderWidth = 1,
      Color? dot,
    }) => Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: fill ?? Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border ?? tokens.hair, width: borderWidth),
      ),
      alignment: dot == null ? null : AlignmentDirectional.topEnd,
      padding: dot == null ? null : const EdgeInsets.all(2),
      child: dot == null
          ? null
          : Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
    );
    final List<(String, Widget)> items = <(String, Widget)>[
      (
        localizations.todayLegend,
        swatch(fill: tokens.emWash, border: tokens.emText, borderWidth: 1.6),
      ),
      (
        localizations.eidLegend,
        swatch(
          fill: tokens.goldWash,
          border: tokens.gold.withValues(alpha: 0.5),
        ),
      ),
      (localizations.ramadanLegend, swatch(fill: tokens.emWash)),
      (localizations.blessedNightLegend, swatch(dot: tokens.gold)),
      (localizations.fastLegend, swatch(dot: tokens.emText)),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: <Widget>[
        for (final (String label, Widget mark) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              mark,
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: tokens.text2)),
            ],
          ),
      ],
    );
  }

  Widget _buildQuickJumps() {
    final List<_QuickJump> jumps = <_QuickJump>[
      _QuickJump('1 Ramaḍān', 9, 1),
      _QuickJump('Eid al-Fiṭr', 10, 1),
      _QuickJump('Day of ʿArafah', 12, 9),
      _QuickJump('Eid al-Aḍḥā', 12, 10),
      _QuickJump('ʿĀshūrā', 1, 10),
      _QuickJump('Isrāʾ & Miʿrāj', 7, 27),
    ];

    final Color background = context.equranColors.background;
    return SizedBox(
      height: 36,
      child: Stack(
        children: <Widget>[
          ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: jumps.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final _QuickJump jump = jumps[index];
              return ChipButton(
                _localizeOccasion(jump.label),
                onPressed: () => _jumpToDate(jump.month, jump.day),
              );
            },
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            width: 40,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: <Color>[
                      background.withValues(alpha: 0.0),
                      background.withValues(alpha: 0.9),
                    ],
                    stops: const <double>[0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearKeyDates() {
    final int year = _now().year;
    final List<MapEntry<String, DateTime>> keyDates =
        <MapEntry<String, DateTime>>[];

    // Approximate major dates for the current Gregorian year
    final List<_QuickJump> candidates = <_QuickJump>[
      _QuickJump('Ramadan begins', 9, 1),
      _QuickJump('Eid al-Fitr', 10, 1),
      _QuickJump('Eid al-Adha', 12, 10),
      _QuickJump('Ashura', 1, 10),
    ];

    for (final _QuickJump j in candidates) {
      for (int d = 0; d < 400; d++) {
        final DateTime test = DateTime(year, 1, 1).add(Duration(days: d));
        if (test.year > year) break;
        final HijriCalendar h = HijriCalendar.fromDate(
          test,
          offset: _sightingOffset,
        );
        if (h.hMonth == j.month && h.hDay == j.day) {
          keyDates.add(MapEntry(j.label, test));
          break;
        }
      }
    }

    if (keyDates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 12),
          child: Text(
            localizations.keyDatesInYear(year),
            style: redesignDisplayStyle(context, size: 24),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keyDates.map((entry) {
            final String label =
                '${_localizeOccasion(entry.key)} • ${DateFormat('d MMM', localizations.localeName).format(entry.value)}';
            return ChipButton(
              label,
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(
                    entry.value.year,
                    entry.value.month,
                    1,
                  );
                  _selectedDate = entry.value;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _jumpToDate(int hijriMonth, int hijriDay) {
    // Find a reasonable Gregorian date in the current or next year that matches the target Hijri day
    final DateTime now = _now();
    DateTime candidate = DateTime(now.year, now.month, now.day);

    // Search forward up to 400 days
    for (int i = 0; i < 400; i++) {
      final HijriCalendar h = HijriCalendar.fromDate(
        candidate,
        offset: _sightingOffset,
      );
      if (h.hMonth == hijriMonth && h.hDay == hijriDay) {
        setState(() {
          _focusedDate = DateTime(candidate.year, candidate.month, 1);
          _selectedDate = candidate;
        });
        return;
      }
      candidate = candidate.add(const Duration(days: 1));
    }

    // Fallback: just go to current month
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localizations.dateNotFound)));
  }

  Future<void> _showCalendarSettingsSheet() async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    String offsetLabel(int offset) => offset == 0
        ? l.standard
        : offset > 0
        ? '+${offset.abs() == 1 ? l.daySingular(offset.abs()) : l.daysPlural(offset.abs())}'
        : '-${offset.abs() == 1 ? l.daySingular(offset.abs()) : l.daysPlural(offset.abs())}';
    const List<int> offsets = <int>[-1, 0, 1];

    await showReaderSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return ReaderSheetFrame(
          title: l.calendarSettings,
          subtitle: l.calendarSettingsSubtitle,
          children: <Widget>[
            ReaderFieldLabel(l.sightingOffsetLabel),
            RedesignSegmentedControl(
              labels: <String>[for (final int o in offsets) offsetLabel(o)],
              selectedIndex: offsets.indexOf(_sightingOffset).clamp(0, 2),
              onChanged: (int index) {
                Navigator.pop(sheetContext);
                _updateSightingOffset(offsets[index]);
              },
            ),
            const SizedBox(height: 22),
            ReaderSheetGroup(
              bottomPadding: 14,
              children: <Widget>[
                ReaderSwitchRow(
                  leading: const DesignIcon('bell'),
                  title: l.fastingReminder,
                  subtitle: l.fastingRemindersSubtitle,
                  value: _fastingRemindersEnabled,
                  onChanged: (bool value) async {
                    Navigator.pop(sheetContext);
                    await _toggleFastingReminders(value);
                  },
                ),
              ],
            ),
            ReaderNotice(
              icon: const DesignIcon('info'),
              text: l.hijriDateDisclaimer,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateDetailsCard() {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final DateTime selDate = _selectedDate!;
    final HijriCalendar hijri = HijriCalendar.fromDate(
      selDate,
      offset: _sightingOffset,
    );
    final String? occasion = _getIslamicOccasion(hijri);
    final List<String> recommended = _getRecommendedActions(hijri);

    return HairlineCard(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 8, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          localizations.localeName,
                        ).format(selDate),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.text2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hijri.toLocalizedDateString(localizations.localeName),
                      style: redesignDisplayStyle(context, size: 28),
                    ),
                    if (hijri.monthNameArabic.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          hijri.toArabicString(),
                          textDirection: ui.TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 17,
                            height: 1.6,
                            color: tokens.goldText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton44(
                designIcon: 'share',
                tooltip: localizations.shareDate,
                ghost: true,
                onPressed: () => _shareDate(selDate, hijri, occasion),
              ),
            ],
          ),

          if (occasion != null) ...<Widget>[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: tokens.goldWash,
                  borderRadius: BorderRadius.circular(EquranRadii.large),
                ),
                child: Row(
                  children: <Widget>[
                    DesignIcon('sparkle', size: 18, color: tokens.goldText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _localizeOccasion(occasion),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              DesignIcon('moon', size: 16, color: tokens.muted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _localizeMoonPhase(hijri.estimatedMoonPhase),
                  style: TextStyle(fontSize: 14, color: tokens.text2),
                ),
              ),
            ],
          ),

          if (recommended.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            RedesignEyebrow(localizations.recommendedForThisDay),
            const SizedBox(height: 10),
            for (final String action in recommended)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: tokens.emText,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localizeAction(action),
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.45,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<String> _getRecommendedActions(HijriCalendar hijri) {
    final List<String> actions = <String>[];

    if (hijri.hMonth == 9) {
      actions.add('Increase recitation of the Qur\'an');
      actions.add('Give charity and help those in need');
      if (hijri.hDay >= 21 && hijri.hDay <= 29) {
        actions.add('Seek Laylat al-Qadr in the odd nights');
      }
    }
    if (hijri.hMonth == 10 && hijri.hDay == 1) {
      actions.add('Perform Eid prayer + Zakat al-Fitr');
      actions.add('Visit family and share food');
    }
    if (hijri.hMonth == 12 && hijri.hDay == 9) {
      actions.add('Fast the Day of Arafah');
      actions.add('Make abundant du\'a');
    }
    if (hijri.hMonth == 12 && hijri.hDay == 10) {
      actions.add('Perform Eid al-Adha prayer');
      actions.add('Sacrifice an animal if able (Qurbani)');
    }
    if (hijri.hMonth == 1 && hijri.hDay == 10) {
      actions.add('Fast Ashura (before/after)');
    }
    if (hijri.isRecommendedFastingDay && hijri.hMonth != 9) {
      actions.add('Observe voluntary fast if able');
    }
    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) {
      actions.add('Fast one of the Ayyam al-Bid (White Days)');
    }

    if (actions.isEmpty) {
      actions.add('Engage in dhikr, prayer, and good deeds');
    }

    return actions;
  }

  Future<void> _shareDate(
    DateTime date,
    HijriCalendar hijri,
    String? occasion,
  ) async {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      localizations.shareIslamicDate(
        hijri.toLocalizedDateString(localizations.localeName),
      ),
    );
    buffer.writeln(
      localizations.shareGregorianDate(
        DateFormat('EEEE, d MMMM yyyy', localizations.localeName).format(date),
      ),
    );
    if (occasion != null) {
      buffer.writeln(localizations.shareOccasion(_localizeOccasion(occasion)));
    }
    buffer.writeln(
      localizations.shareMoonPhase(
        _localizeMoonPhase(hijri.estimatedMoonPhase),
      ),
    );
    if (hijri.isRecommendedFastingDay) {
      buffer.writeln(localizations.shareRecommendedFasting);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.dateCopiedClipboard),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _QuickJump {
  const _QuickJump(this.label, this.month, this.day);
  final String label;
  final int month;
  final int day;
}

enum _DayKind { eid, ramadan, fast, blessedNight, none }
