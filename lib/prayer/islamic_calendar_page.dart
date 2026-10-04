import 'package:equran/backend/settings_db.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key});

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage> {
  DateTime _focusedDate = DateTime.now();
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
    _selectedDate = DateTime.now();
  }

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

  Color? _getDayHighlightColor(HijriCalendar hijri, EquranColors colors) {
    // Use gold/accent for major blessed events (never stronger than today/selection)
    final bool isMajorEid =
        (hijri.hMonth == 10 && hijri.hDay == 1) ||
        (hijri.hMonth == 12 && hijri.hDay == 10);

    if (isMajorEid) {
      return colors.accentGold; // Gold for Eids — special but not overpowering
    }

    if (hijri.hMonth == 9) {
      return colors.primary.withAlpha(18); // Very soft Ramadan wash
    }

    final String? occasion = hijri.majorOccasion;
    if (occasion == 'Day of Arafah' || occasion == 'Day of Ashura') {
      return colors.mint.withAlpha(45);
    }
    if (occasion == 'Laylat al-Qadr' ||
        occasion == 'Shab-e-Barat' ||
        occasion == 'Isra\' and Mi\'raj') {
      return colors.goldSoft.withAlpha(35);
    }

    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) {
      return colors.mint.withAlpha(22); // Ayyam al-Bid — very subtle
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);

    // Days in current focused month
    final DateTime firstOfMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      1,
    );
    final int blankDaysCount = firstOfMonth.weekday - 1; // Mon = 1
    final DateTime lastOfMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    );
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
          // ==================== DATE WIDGET (Header) at the very top ====================
          _buildCalendarHeader(theme, colors),

          const SizedBox(height: 10),

          // ==================== CALENDAR GRID — wrapped in a beautiful card ====================
          EquranSurfaceCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                // Uses responsive, elegant cells with correct visual hierarchy.
                // Subtle animation on month change.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildPremiumMonthGrid(
                    key: ValueKey<int>(
                      _focusedDate.month * 10000 + _focusedDate.year,
                    ),
                    theme,
                    colors,
                    firstOfMonth: firstOfMonth,
                    blankDaysCount: blankDaysCount,
                    daysInMonthCount: daysInMonthCount,
                    weekdays: weekdays,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: colors.divider, height: 24),

          // ==================== TWO MOON WIDGETS — placed beneath the calendar ====================
          _buildTopMoonCombinedSection(theme, colors),

          const SizedBox(height: 8),

          // Elegant Event Legend (small but beautiful)
          _buildEventLegend(theme, colors),

          const SizedBox(height: 10),

          // Quick Jump to Major Dates
          _buildQuickJumps(theme, colors),

          const SizedBox(height: 14),

          // This Year's Key Islamic Dates (compact summary)
          _buildYearKeyDates(theme, colors),

          Divider(color: colors.divider, height: 24),

          // Date Details Box
          if (_selectedDate != null) ...<Widget>[
            _buildDateDetailsCard(theme, colors),
          ],
        ],
      ),
    );
  }

  // ==================== TOP COMBINED SQUARE-ISH SECTION ====================
  // Moon Sighting controls (left) + Beautiful Moon Phase visual (right)
  // Designed to feel balanced and square when placed side-by-side on phones.
  Widget _buildTopMoonCombinedSection(ThemeData theme, EquranColors colors) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Left: Moon Sighting / Offset controls (compact & clean)
          Expanded(child: _buildCompactMoonSightingCard(theme, colors)),
          const SizedBox(width: 12),
          // Right: Beautiful Moon Phase visual (tight, elegant, no overflow)
          Expanded(child: _buildMoonPhaseCard(theme, colors)),
        ],
      ),
    );
  }

  Widget _buildCompactMoonSightingCard(ThemeData theme, EquranColors colors) {
    final String offsetLabel = _sightingOffset == 0
        ? localizations.standard
        : '${_sightingOffset > 0 ? '+' : ''}${_sightingOffset.abs() == 1 ? localizations.daySingular(_sightingOffset.abs()) : localizations.daysPlural(_sightingOffset.abs())}';

    return InkWell(
      onTap: () => _showCalendarSettingsSheet(theme, colors),
      borderRadius: BorderRadius.circular(AppRadii.large),
      child: EquranSurfaceCard(
        padding: const EdgeInsets.all(14),
        backgroundColor: colors.surface,
        borderColor: colors.border,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.visibility_outlined,
                  color: colors.primary,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.moonSighting,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              offsetLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localizations.tapToAdjust,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SEPARATE BEAUTIFUL MOON PHASE CARD ====================
  Widget _buildMoonPhaseCard(ThemeData theme, EquranColors colors) {
    final DateTime referenceDate = _selectedDate ?? DateTime.now();
    final HijriCalendar hijri = HijriCalendar.fromDate(
      referenceDate,
      offset: _sightingOffset,
    );
    final int phase = hijri.estimatedMoonPhase;
    final IconData moonIcon = _moonIconForPhase(phase);
    final String phaseName = _localizeMoonPhase(phase);

    // Short contextual line — avoid repeating the phase name
    final String contextLine = switch (phase) {
      0 => localizations.moonPhaseContextNew,
      1 => localizations.moonPhaseContextWaxing,
      2 => localizations.moonPhaseContextFull,
      _ => localizations.moonPhaseContextWaning,
    };

    return EquranSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: colors.surface,
      borderColor: colors.border,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(moonIcon, size: 32, color: colors.primary),
          const SizedBox(height: 6),
          Text(
            localizations.moonPhase,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            phaseName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            contextLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== NEW PREMIUM HEADER ====================
  Widget _buildCalendarHeader(ThemeData theme, EquranColors colors) {
    // Use MMM YYYY format as requested for the main calendar card label
    final String gregorianLabel = DateFormat('MMM yyyy').format(_focusedDate);

    // Try to show approximate Hijri month for the middle of the focused Gregorian month
    final DateTime midMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      15,
    );
    final HijriCalendar midHijri = HijriCalendar.fromDate(
      midMonth,
      offset: _sightingOffset,
    );

    return EquranSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 26),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month - 1,
                );
              });
            },
            color: colors.textSecondary,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  gregorianLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${midHijri.getLocalizedMonthName(localizations.localeName)} ${midHijri.hYear}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 26),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month + 1,
                );
              });
            },
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }

  // ==================== THE BEAUTIFUL NEW MONTH GRID ====================
  Widget _buildPremiumMonthGrid(
    ThemeData theme,
    EquranColors colors, {
    Key? key,
    required DateTime firstOfMonth,
    required int blankDaysCount,
    required int daysInMonthCount,
    required List<String> weekdays,
  }) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    // Responsive cell sizing for small phones
    final double cellAspect = screenWidth < 360 ? 0.95 : 1.05;
    final double headerAspect = 1.6;

    return Column(
      key: key,
      children: <Widget>[
        // Elegant Weekday Header
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: headerAspect,
          ),
          itemCount: 7,
          itemBuilder: (BuildContext context, int index) {
            return Center(
              child: Text(
                weekdays[index],
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),

        // The actual days – premium cells with correct hierarchy
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: cellAspect,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
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

            final bool isToday = _isSameDay(date, DateTime.now());
            final bool isSelected =
                _selectedDate != null && _isSameDay(date, _selectedDate!);

            final Color? eventColor = _getDayHighlightColor(hijri, colors);
            final String? eventLabel = hijri.shortEventLabel;

            // === Visual Hierarchy (critical fix) ===
            // 1. Today or Selected = strongest treatment (primary ring + tint)
            // 2. Major events = elegant gold accents (never stronger than today)
            // 3. Other blessed days = very soft mint/gold wash
            Color bgColor = colors.surface;
            Color borderColor = colors.border;
            double borderWidth = 1.0;
            Color dayNumberColor = colors.textPrimary;

            if (isSelected) {
              bgColor = colors.primary.withAlpha(38);
              borderColor = colors.primary;
              borderWidth = 1.8;
              dayNumberColor = colors.primary;
            } else if (isToday) {
              bgColor = colors.primary.withAlpha(18);
              borderColor = colors.accentGold;
              borderWidth = 1.0;
              dayNumberColor = colors.primary;
            } else if (eventColor != null) {
              // Events get gold or soft tint, but lighter treatment
              bgColor = eventColor.withAlpha(
                eventColor == colors.accentGold ? 22 : 30,
              );
              borderColor = eventColor.withAlpha(140);
              borderWidth = 1.2;
              if (eventColor == colors.accentGold) {
                dayNumberColor = colors.textPrimary;
              }
            }

            final double gregorianSize = screenWidth < 360 ? 11.0 : 13.0;
            final double hijriSize = screenWidth < 360 ? 8.0 : 9.5;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  border: Border.all(color: borderColor, width: borderWidth),
                  boxShadow: isToday || isSelected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: colors.primary.withAlpha(25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: <Widget>[
                    // Gregorian day (prominent)
                    Positioned(
                      top: 5,
                      left: 6,
                      child: Text(
                        dayNumber.toString(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: dayNumberColor,
                          fontWeight: FontWeight.w600,
                          fontSize: gregorianSize,
                        ),
                      ),
                    ),

                    // Hijri day (elegant, smaller, gold-tinted on events)
                    Positioned(
                      bottom: 5,
                      right: 6,
                      child: Text(
                        hijri.hDay.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: hijriSize,
                        ),
                      ),
                    ),

                    // Subtle event indicator (gold dot or small label for major days)
                    if (eventLabel != null && !isToday && !isSelected)
                      Positioned(
                        top: 5,
                        right: 6,
                        child: Container(
                          width: 4.5,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: eventColor ?? colors.accentGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
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

  Widget _buildEventLegend(ThemeData theme, EquranColors colors) {
    final localizations = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: <Widget>[
        _legendChip(theme, colors, localizations.todayLegend, colors.primary),
        _legendChip(theme, colors, localizations.eidLegend, colors.accentGold),
        _legendChip(
          theme,
          colors,
          localizations.ramadanLegend,
          colors.primary.withAlpha(140),
        ),
        _legendChip(
          theme,
          colors,
          localizations.blessedNightLegend,
          colors.goldSoft,
        ),
        _legendChip(theme, colors, localizations.fastLegend, colors.mint),
      ],
    );
  }

  Widget _legendChip(
    ThemeData theme,
    EquranColors colors,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ELEGANT SETTINGS BAR + SHEET ====================
  Widget _buildQuickJumps(ThemeData theme, EquranColors colors) {
    final List<_QuickJump> jumps = <_QuickJump>[
      _QuickJump('1 Ramaḍān', 9, 1),
      _QuickJump('Eid al-Fiṭr', 10, 1),
      _QuickJump('Day of ʿArafah', 12, 9),
      _QuickJump('Eid al-Aḍḥā', 12, 10),
      _QuickJump('ʿĀshūrā', 1, 10),
      _QuickJump('Isrāʾ & Miʿrāj', 7, 27),
    ];

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
              return InkWell(
                onTap: () => _jumpToDate(jump.month, jump.day),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: colors.border),
                  ),
                  child: Center(
                    child: Text(
                      _localizeOccasion(jump.label),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 40,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      colors.background.withValues(alpha: 0.0),
                      colors.background.withValues(alpha: 0.9),
                    ],
                    stops: <double>[0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearKeyDates(ThemeData theme, EquranColors colors) {
    final int year = DateTime.now().year;
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          localizations.keyDatesInYear(year),
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keyDates.map((entry) {
            final String label =
                '${_localizeOccasion(entry.key)} • ${DateFormat('d MMM', localizations.localeName).format(entry.value)}';
            return InkWell(
              onTap: () {
                setState(() {
                  _focusedDate = DateTime(
                    entry.value.year,
                    entry.value.month,
                    1,
                  );
                  _selectedDate = entry.value;
                });
              },
              borderRadius: BorderRadius.circular(AppRadii.small),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _jumpToDate(int hijriMonth, int hijriDay) {
    // Find a reasonable Gregorian date in the current or next year that matches the target Hijri day
    final DateTime now = DateTime.now();
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

  Future<void> _showCalendarSettingsSheet(
    ThemeData theme,
    EquranColors colors,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.calendarSettings,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                localizations.calendarSettingsSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Sighting Offset
              Text(
                localizations.sightingOffsetLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [-1, 0, 1].map<Widget>((int offset) {
                  final bool selected = _sightingOffset == offset;
                  final String label = offset == 0
                      ? localizations.standard
                      : offset > 0
                      ? '+${offset.abs() == 1 ? localizations.daySingular(offset.abs()) : localizations.daysPlural(offset.abs())}'
                      : '-${offset.abs() == 1 ? localizations.daySingular(offset.abs()) : localizations.daysPlural(offset.abs())}';
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _updateSightingOffset(offset);
                        },
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.primary.withAlpha(15)
                                : colors.surfaceAlt,
                            borderRadius: BorderRadius.circular(
                              AppRadii.medium,
                            ),
                            border: Border.all(
                              color: selected ? colors.primary : colors.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected
                                    ? colors.primary
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Fasting Reminders
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          localizations.fastingReminder,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localizations.fastingRemindersSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _fastingRemindersEnabled,
                    activeThumbColor: colors.primary,
                    onChanged: (bool value) async {
                      Navigator.pop(sheetContext);
                      await _toggleFastingReminders(value);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                localizations.hijriDateDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== EXISTING DETAILS CARD (will be enhanced next) ====================
  Widget _buildDateDetailsCard(ThemeData theme, EquranColors colors) {
    final localizations = AppLocalizations.of(context)!;
    final DateTime selDate = _selectedDate!;
    final HijriCalendar hijri = HijriCalendar.fromDate(
      selDate,
      offset: _sightingOffset,
    );
    final String? occasion = _getIslamicOccasion(hijri);
    final List<String> recommended = _getRecommendedActions(hijri);

    final BorderRadius borderRadius = BorderRadius.circular(AppRadii.large);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          border: Border.all(color: colors.border, width: 1),
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.shadow.withAlpha(
                Theme.of(context).brightness == Brightness.light ? 13 : 32,
              ),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 3, color: colors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  DateFormat(
                                    'EEEE, d MMMM yyyy',
                                    localizations.localeName,
                                  ).format(selDate),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hijri.toLocalizedDateString(
                                    localizations.localeName,
                                  ),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                if (hijri.monthNameArabic.isNotEmpty)
                                  Text(
                                    hijri.toArabicString(),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colors.accentGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textDirection: ui.TextDirection.rtl,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded),
                            onPressed: () =>
                                _shareDate(selDate, hijri, occasion),
                            color: colors.textSecondary,
                            tooltip: localizations.shareDate,
                          ),
                        ],
                      ),

                      if (occasion != null) ...<Widget>[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(12),
                            borderRadius: BorderRadius.circular(
                              AppRadii.medium,
                            ),
                            border: Border.all(
                              color: colors.primary.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.star_rounded,
                                color: colors.accentGold,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _localizeOccasion(occasion),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Moon row (fasting pill removed to prevent overflow)
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.nightlight_round,
                            color: colors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _localizeMoonPhase(hijri.estimatedMoonPhase),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (recommended.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          localizations.recommendedForThisDay.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...recommended.map(
                          (action) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  '• ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Expanded(
                                  child: Text(
                                    _localizeAction(action),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
