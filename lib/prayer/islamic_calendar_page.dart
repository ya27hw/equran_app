import 'package:equran/backend/settings_db.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/theme/inter_optical_size.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:equran/widgets/redesign/segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// The Islamic calendar tab. The selected day is always shown at the top, so a
/// tap on the month changes what the page says straight away. Swiping the
/// month changes the month, and the key dates ahead jump the grid to them.
class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key, this.now});

  /// The clock for today and the selected day; tests pass a fixed one.
  final DateTime Function()? now;

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage> {
  late DateTime _focusedDate;
  late DateTime _selectedDate;
  int _sightingOffset = 0;
  bool _fastingRemindersEnabled = false;
  List<_UpcomingDay> _upcoming = const <_UpcomingDay>[];

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
    _upcoming = _findUpcomingKeyDays(_now());
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  Future<void> _updateSightingOffset(int newOffset) async {
    if (newOffset == _sightingOffset) return;
    await SettingsDB().put('hijri_offset', newOffset);
    setState(() {
      _sightingOffset = newOffset;
      _upcoming = _findUpcomingKeyDays(_now());
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

  /// Every event that falls on [hijri], in legend order. A day can carry
  /// several: the 15th of Sha'ban is both a blessed night and a white day of
  /// fasting.
  List<_DayEvent> _eventsOn(HijriCalendar hijri) {
    final List<_DayEvent> events = <_DayEvent>[];
    if (hijri.hDay == 1) {
      events.add(
        _DayEvent(_EventKind.monthStart, localizations.newMonthLegend),
      );
    }
    switch (hijri.majorOccasion) {
      case 'Eid al-Fitr':
        events.add(_DayEvent(_EventKind.eid, localizations.occasionEidAlFitr));
      case 'Eid al-Adha':
        events.add(_DayEvent(_EventKind.eid, localizations.occasionEidAlAdha));
      case 'Islamic New Year':
        events.add(
          _DayEvent(_EventKind.newYear, localizations.occasionIslamicNewYear),
        );
      case 'Day of Arafah':
        events.add(
          _DayEvent(_EventKind.fast, localizations.occasionDayOfArafah),
        );
      case 'Day of Ashura':
        events.add(
          _DayEvent(_EventKind.fast, localizations.occasionDayOfAshura),
        );
      case 'Laylat al-Qadr':
        events.add(
          _DayEvent(
            _EventKind.night,
            localizations.occasionLaylatAlQadrBlessed,
          ),
        );
      case 'Shab-e-Barat':
        events.add(
          _DayEvent(_EventKind.night, localizations.occasionShabEBaratBlessed),
        );
      case "Isra' and Mi'raj":
        events.add(
          _DayEvent(_EventKind.night, localizations.occasionIsraAndMiraj),
        );
    }
    if (hijri.hMonth == 1 && hijri.hDay == 9) {
      events.add(_DayEvent(_EventKind.fast, localizations.occasionTasuaFast));
    }
    if (hijri.hMonth != 9 &&
        (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15)) {
      events.add(_DayEvent(_EventKind.fast, localizations.occasionAyyamAlBid));
    }
    return events;
  }

  /// The dot colour for each event. Hues are fixed, with a lighter pair for
  /// dark themes so each stays visible on both.
  Color _eventColor(_EventKind kind) {
    final EquranTokens tokens = context.equranTokens;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return switch (kind) {
      _EventKind.eid => tokens.gold,
      _EventKind.fast => tokens.emText,
      _EventKind.night =>
        dark ? const Color(0xFF9AA8FF) : const Color(0xFF4B5BC9),
      _EventKind.newYear =>
        dark ? const Color(0xFFF08A98) : const Color(0xFFC2475A),
      _EventKind.monthStart => tokens.text2,
    };
  }

  Widget _eventDot(Color color, {double size = 5}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  /// Up to a few dots side by side. The row keeps its height when empty so
  /// the numbers in every cell line up.
  Widget _eventDots(List<Color> dotColors, {required bool onSelected}) {
    return SizedBox(
      height: 5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Color color in dotColors)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: onSelected
                    ? Border.all(color: Colors.white, width: 0.8)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  /// The next occurrence of each [_keyDays] entry from [today], soonest first,
  /// found in one pass over the days ahead so the conversions run once per
  /// change rather than on every rebuild.
  List<_UpcomingDay> _findUpcomingKeyDays(DateTime today) {
    final List<_KeyDay> pending = List<_KeyDay>.of(_keyDays);
    final List<_UpcomingDay> found = <_UpcomingDay>[];
    DateTime day = DateTime(today.year, today.month, today.day);
    for (int i = 0; i < 400 && pending.isNotEmpty; i++) {
      final HijriCalendar hijri = HijriCalendar.fromDate(
        day,
        offset: _sightingOffset,
      );
      final int index = pending.indexWhere(
        (_KeyDay key) => key.month == hijri.hMonth && key.day == hijri.hDay,
      );
      if (index != -1) {
        found.add(_UpcomingDay(pending.removeAt(index).label, day));
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return found.take(_upcomingCount).toList();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime selected = _selectedDate;
    final HijriCalendar selectedHijri = HijriCalendar.fromDate(
      selected,
      offset: _sightingOffset,
    );
    final List<String> recommended = _getRecommendedActions(selectedHijri);

    return RedesignSubpage(
      title: localizations.islamicCalendar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          _buildSelectedDayHero(selected, selectedHijri),
          const SizedBox(height: 16),
          _buildMonthCard(),
          const SizedBox(height: 16),
          _buildRecommendedCard(recommended),
          const SizedBox(height: 28),
          _buildComingUp(),
          const SizedBox(height: 28),
          _buildSettingsCard(),
        ],
      ),
    );
  }

  /// The day the user is looking at, in full. It sits above the grid so a tap
  /// on any day is answered without scrolling. The filled background is the
  /// app's shared hero card.
  Widget _buildSelectedDayHero(DateTime date, HijriCalendar hijri) {
    final EquranColors colors = context.equranColors;
    final String lang = localizations.localeName;
    final String? occasion = _getIslamicOccasion(hijri);
    final Color ink = colors.onPrimary;

    return EquranGradientCard(
      showPattern: true,
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('EEEE, d MMMM yyyy', lang).format(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: IconButton(
                  tooltip: localizations.shareDate,
                  icon: DesignIcon('share', color: ink),
                  onPressed: () => _shareDate(date, hijri, occasion),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hijri.toLocalizedDateString(lang),
            style: redesignDisplayStyle(context, size: 30, color: ink),
          ),
          if (hijri.monthNameArabic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                hijri.toArabicString(),
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 18,
                  height: 1.6,
                  color: ink.withValues(alpha: 0.85),
                ),
              ),
            ),
          const SizedBox(height: 16),
          for (final _DayEvent event in _eventsOn(hijri))
            _heroLine(
              ink: ink,
              text: event.label,
              bold: true,
              leading: _eventDot(_eventColor(event.kind), size: 7),
            ),
          if (hijri.hMonth == 9)
            _heroLine(ink: ink, text: localizations.occasionRamadan),
          _heroLine(
            ink: ink,
            text: _localizeMoonPhase(hijri.estimatedMoonPhase),
            leading: Icon(
              _moonIconForPhase(hijri.estimatedMoonPhase),
              size: 16,
              color: ink.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// One line on the selected-day hero. [leading] is a dot for an event, or
  /// an icon for the moon; lines without one are indented to line up.
  Widget _heroLine({
    required Color ink,
    required String text,
    Widget? leading,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 17,
            child: leading == null ? null : Center(child: leading),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The month header, the grid and the legend, as one unit. The Hijri line
  /// names every Hijri month the Gregorian month touches.
  Widget _buildMonthCard() {
    final EquranTokens tokens = context.equranTokens;
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final String lang = localizations.localeName;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final DateTime today = _now();
    final DateTime firstOfMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      1,
    );
    final DateTime lastOfMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    );
    final bool atToday =
        _isSameMonth(firstOfMonth, today) && _isSameDay(_selectedDate, today);

    return HairlineCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _mirroredInRtl(
                IconButton44(
                  designIcon: 'chevl',
                  tooltip: material.previousMonthTooltip,
                  ghost: true,
                  onPressed: () => _changeMonth(-1),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      DateFormat('MMMM yyyy', lang).format(firstOfMonth),
                      textAlign: TextAlign.center,
                      style: redesignDisplayStyle(context, size: 24),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _hijriRangeLabel(
                        HijriCalendar.fromDate(
                          firstOfMonth,
                          offset: _sightingOffset,
                        ),
                        HijriCalendar.fromDate(
                          lastOfMonth,
                          offset: _sightingOffset,
                        ),
                      ),
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
              _mirroredInRtl(
                IconButton44(
                  designIcon: 'chev',
                  tooltip: material.nextMonthTooltip,
                  ghost: true,
                  onPressed: () => _changeMonth(1),
                ),
              ),
            ],
          ),
          if (!atToday) ...<Widget>[
            const SizedBox(height: 4),
            ChipButton(
              localizations.todayLegend,
              designIcon: 'calendar',
              onPressed: () => _selectDay(today),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _onGridSwipe,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildMonthGrid(
                key: ValueKey<int>(_focusedDate.year * 12 + _focusedDate.month),
                firstOfMonth: firstOfMonth,
                today: today,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildMonthGrid({
    required Key key,
    required DateTime firstOfMonth,
    required DateTime today,
  }) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final String lang = localizations.localeName;
    final bool narrow = MediaQuery.sizeOf(context).width < 360;
    final double gregorianSize = narrow ? 13 : 15;
    final double hijriSize = narrow ? 9 : 10.5;
    // Cells grow with large text so the two lines never clip.
    final double textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final int blankDaysCount = firstOfMonth.weekday - 1; // Mon = 1
    final int daysInMonthCount = DateTime(
      firstOfMonth.year,
      firstOfMonth.month + 1,
      0,
    ).day;
    final List<String> weekdays = List<String>.generate(7, (int index) {
      // 2026-06-08 is a Monday
      return DateFormat.E(lang).format(DateTime(2026, 6, 8 + index));
    });

    return Column(
      key: key,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String weekday in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.muted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 56 * textScale.clamp(1.0, 1.6),
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
              firstOfMonth.year,
              firstOfMonth.month,
              dayNumber,
            );
            final HijriCalendar hijri = HijriCalendar.fromDate(
              date,
              offset: _sightingOffset,
            );
            final bool isToday = _isSameDay(date, today);
            final bool isSelected = _isSameDay(date, _selectedDate);
            final List<_DayEvent> events = _eventsOn(hijri);

            Color background = Colors.transparent;
            Color border = tokens.hair;
            double borderWidth = 1;
            Color dayColor = colors.textPrimary;
            Color hijriColor = tokens.muted;

            if (isSelected) {
              background = tokens.filled;
              border = isToday ? tokens.gold : tokens.filled;
              borderWidth = isToday ? 2 : 1;
              dayColor = Colors.white;
              hijriColor = Colors.white.withValues(alpha: 0.82);
            } else if (isToday) {
              background = tokens.emWash;
              border = tokens.emText;
              borderWidth = 1.6;
              dayColor = tokens.emText;
            } else if (hijri.hMonth == 9) {
              // Ramadan is a period, so it is a wash rather than a dot.
              background = tokens.emWash;
            }

            final String eventNames = events
                .map((_DayEvent event) => event.label)
                .join(', ');
            final String semanticsLabel = <String>[
              DateFormat.yMMMMd(lang).format(date),
              hijri.toLocalizedDateString(lang),
              if (eventNames.isNotEmpty) eventNames,
            ].join(', ');

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
                      color: background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border, width: borderWidth),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: gregorianSize,
                              fontWeight: FontWeight.w600,
                              color: dayColor,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ).withInterOpticalSize(),
                          ),
                          Text(
                            '${hijri.hDay}',
                            style: TextStyle(
                              fontSize: hijriSize,
                              color: hijriColor,
                            ).withInterOpticalSize(),
                          ),
                          const SizedBox(height: 3),
                          _eventDots(<Color>[
                            for (final _DayEvent event in events)
                              _eventColor(event.kind),
                          ], onSelected: isSelected),
                        ],
                      ),
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

  /// The month arrows point along the reading direction, so they turn round
  /// in RTL. `IconButton44` has no mirror flag of its own.
  Widget _mirroredInRtl(Widget child) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return rtl ? Transform.flip(flipX: true, child: child) : child;
  }

  /// Swipe left for the next month in LTR, and right to left in RTL.
  void _onGridSwipe(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final bool towardsNext = rtl ? velocity > 0 : velocity < 0;
    _changeMonth(towardsNext ? 1 : -1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + delta, 1);
    });
  }

  void _selectDay(DateTime date) {
    setState(() {
      _focusedDate = DateTime(date.year, date.month, 1);
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  /// "Ramadan – Shawwal 1447", or with years when the span crosses one.
  String _hijriRangeLabel(HijriCalendar first, HijriCalendar last) {
    final String lang = localizations.localeName;
    final String startName = first.getLocalizedMonthName(lang);
    if (first.hMonth == last.hMonth && first.hYear == last.hYear) {
      return '$startName ${first.hYear}';
    }
    final String endName = last.getLocalizedMonthName(lang);
    if (first.hYear == last.hYear) {
      return '$startName – $endName ${first.hYear}';
    }
    return '$startName ${first.hYear} – $endName ${last.hYear}';
  }

  /// The legend draws each swatch the way the grid draws the day.
  Widget _buildLegend() {
    final EquranTokens tokens = context.equranTokens;
    Widget swatch({Color? fill, Color? border, double borderWidth = 1}) =>
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: fill ?? Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: border ?? tokens.hair,
              width: borderWidth,
            ),
          ),
        );
    Widget dotMark(_EventKind kind) => SizedBox(
      width: 18,
      height: 18,
      child: Center(child: _eventDot(_eventColor(kind), size: 8)),
    );
    final List<(String, Widget)> items = <(String, Widget)>[
      (
        localizations.todayLegend,
        swatch(fill: tokens.emWash, border: tokens.emText, borderWidth: 1.6),
      ),
      (localizations.ramadanLegend, swatch(fill: tokens.emWash)),
      (localizations.eidLegend, dotMark(_EventKind.eid)),
      (localizations.fastLegend, dotMark(_EventKind.fast)),
      (localizations.blessedNightLegend, dotMark(_EventKind.night)),
      (localizations.occasionIslamicNewYear, dotMark(_EventKind.newYear)),
      (localizations.newMonthLegend, dotMark(_EventKind.monthStart)),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 10,
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

  Widget _buildRecommendedCard(List<String> actions) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return HairlineCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RedesignEyebrow(localizations.recommendedForThisDay),
          const SizedBox(height: 12),
          for (final String action in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
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
                        fontVariations: const [FontVariation('opsz', 14.5)],
                        height: 1.45,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The next key dates. Each row jumps the grid to that day.
  Widget _buildComingUp() {
    if (_upcoming.isEmpty) return const SizedBox.shrink();
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final String lang = localizations.localeName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 12),
          child: Text(
            localizations.comingUp,
            style: redesignDisplayStyle(context, size: 24),
          ),
        ),
        // Material, not a Container, so the row ripples show.
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EquranRadii.xl),
            side: BorderSide(color: tokens.hair),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < _upcoming.length; i++) ...<Widget>[
                if (i > 0) const Divider(height: 1),
                InkWell(
                  onTap: () => _selectDay(_upcoming[i].date),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _localizeOccasion(_upcoming[i].label),
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat(
                                  'EEE, d MMM yyyy',
                                  lang,
                                ).format(_upcoming[i].date),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: tokens.text2,
                                ),
                              ),
                              Text(
                                HijriCalendar.fromDate(
                                  _upcoming[i].date,
                                  offset: _sightingOffset,
                                ).toLocalizedDateString(lang),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: tokens.goldText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DesignIcon(
                          'chev',
                          size: 16,
                          color: tokens.muted,
                          mirrorInRtl: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Moon sighting and fasting reminders. The offset applies at once, so the
  /// grid above shows the effect without a trip to a sheet.
  Widget _buildSettingsCard() {
    final EquranTokens tokens = context.equranTokens;
    const List<int> offsets = <int>[-1, 0, 1];

    return HairlineCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RedesignEyebrow(localizations.moonSighting),
          const SizedBox(height: 12),
          RedesignSegmentedControl(
            labels: <String>[for (final int o in offsets) _offsetLabel(o)],
            selectedIndex: offsets.indexOf(_sightingOffset).clamp(0, 2),
            onChanged: (int index) => _updateSightingOffset(offsets[index]),
          ),
          const SizedBox(height: 10),
          Text(
            localizations.moonSightingHint,
            style: TextStyle(fontSize: 13, height: 1.4, color: tokens.text2),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      localizations.fastingReminder,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.equranColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.fastingRemindersSubtitle,
                      style: TextStyle(fontSize: 13, color: tokens.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _fastingRemindersEnabled,
                onChanged: (bool value) => _toggleFastingReminders(value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.hijriDateDisclaimer,
            style: TextStyle(fontSize: 12, height: 1.4, color: tokens.muted),
          ),
        ],
      ),
    );
  }

  String _offsetLabel(int offset) {
    if (offset == 0) return localizations.standard;
    final String amount = offset.abs() == 1
        ? localizations.daySingular(1)
        : localizations.daysPlural(offset.abs());
    return offset > 0 ? '+$amount' : '-$amount';
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
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

/// How many upcoming key dates the page lists.
const int _upcomingCount = 5;

class _KeyDay {
  const _KeyDay(this.label, this.month, this.day);
  final String label;
  final int month;
  final int day;
}

/// Hijri days the page looks ahead for. The labels are the keys
/// [_IslamicCalendarPageState._localizeOccasion] already maps.
const List<_KeyDay> _keyDays = <_KeyDay>[
  _KeyDay('Ramadan begins', 9, 1),
  _KeyDay('Eid al-Fitr', 10, 1),
  _KeyDay('Day of Arafah', 12, 9),
  _KeyDay('Eid al-Adha', 12, 10),
  _KeyDay('Islamic New Year', 1, 1),
  _KeyDay('Day of Ashura', 1, 10),
  _KeyDay('Isra\' and Mi\'raj', 7, 27),
  _KeyDay('Shab-e-Barat', 8, 15),
];

class _UpcomingDay {
  const _UpcomingDay(this.label, this.date);
  final String label;
  final DateTime date;
}

/// The kinds of event the grid marks. Each has its own dot colour.
enum _EventKind { eid, fast, night, newYear, monthStart }

class _DayEvent {
  const _DayEvent(this.kind, this.label);
  final _EventKind kind;
  final String label;
}
