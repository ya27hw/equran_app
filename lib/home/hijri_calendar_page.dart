import 'package:equran/backend/settings_db.dart';
import 'package:equran/prayer/hijri_calendar.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/hero_panel.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;

class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key, this.now, this.hijriOffset});

  /// The clock for today; tests pass a fixed one.
  final DateTime Function()? now;

  /// Moon-sighting offset in days. Defaults to the `hijri_offset` setting, the
  /// same one the prayer times and the Islamic calendar use.
  final int? hijriOffset;

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late DateTime _today;
  late HijriCalendar _todayHijri;
  late int _offset;
  late int _viewingYear;
  late int _viewingMonth;

  @override
  void initState() {
    super.initState();
    _today = widget.now?.call() ?? DateTime.now();
    _offset =
        widget.hijriOffset ??
        (SettingsDB().get('hijri_offset', defaultValue: 0) as int);
    _todayHijri = HijriCalendar.fromDate(_today, offset: _offset);
    _viewingYear = _todayHijri.hYear;
    _viewingMonth = _todayHijri.hMonth;
  }

  void _nextMonth() {
    setState(() {
      if (_viewingMonth == 12) {
        _viewingMonth = 1;
        _viewingYear++;
      } else {
        _viewingMonth++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (_viewingMonth == 1) {
        _viewingMonth = 12;
        _viewingYear--;
      } else {
        _viewingMonth--;
      }
    });
  }

  String _translateTitle(String lang) {
    return switch (lang) {
      'ar' => 'التقويم الهجري',
      'fa' => 'تقویم هجری',
      'de' => 'Hijri-Kalender',
      'bn' => 'হিজরি ক্যালেন্ডার',
      'id' => 'Kalender Hijriah',
      'tr' => 'Hicri Takvim',
      'ur' => 'ہجری کیلنڈر',
      _ => 'Hijri Calendar',
    };
  }

  String _translateToday(String lang) {
    return switch (lang) {
      'ar' => 'اليوم',
      'fa' => 'امروز',
      'de' => 'Heute',
      'bn' => 'আজ',
      'id' => 'Hari Ini',
      'tr' => 'Bugün',
      'ur' => 'آج',
      _ => 'Today',
    };
  }

  List<String> _getWeekdayHeaders(String lang) {
    if (lang == 'ar') {
      return <String>['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
    }
    if (lang == 'fa') {
      return <String>['ی', 'د', 'س', 'چ', 'پ', 'ج', 'ش'];
    }
    if (lang == 'ur') {
      return <String>['ا', 'پ', 'م', 'ب', 'ج', 'ج', 'ہ'];
    }
    if (lang == 'de') {
      return <String>['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'];
    }
    if (lang == 'tr') {
      return <String>['Pz', 'Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct'];
    }
    if (lang == 'bn') {
      return <String>['র', 'সো', 'ম', 'বু', 'বৃ', 'শু', 'শ'];
    }
    if (lang == 'id') {
      return <String>['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    }
    return <String>['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String lang = localizations.localeName.split('_').first.toLowerCase();
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final MaterialLocalizations material = MaterialLocalizations.of(context);

    // Current Hijri Month Info
    final String monthName = HijriCalendar.monthNameFor(_viewingMonth, lang);
    final int daysCount = HijriCalendar.daysInMonth(
      _viewingYear,
      _viewingMonth,
      offset: _offset,
    );

    // First Day Gregorian to find start weekday
    final DateTime firstDayGregorian = HijriCalendar.firstGregorianDayOf(
      _viewingYear,
      _viewingMonth,
      offset: _offset,
    );
    final int startWeekdayOffset = firstDayGregorian.weekday % 7; // Sunday is 0

    // Gregorian range of the Hijri month
    final DateTime lastDayGregorian = DateTime(
      firstDayGregorian.year,
      firstDayGregorian.month,
      firstDayGregorian.day + daysCount - 1,
    );
    final DateFormat rangeFormat = DateFormat(
      'MMM d, yyyy',
      localizations.localeName,
    );
    final String gregRange =
        '${rangeFormat.format(firstDayGregorian)} - ${rangeFormat.format(lastDayGregorian)}';
    final List<String> weekdayHeaders = _getWeekdayHeaders(lang);

    return RedesignSubpage(
      title: _translateTitle(lang),
      actions: <Widget>[
        IconButton44(
          designIcon: 'calendar',
          tooltip: _translateToday(lang),
          onPressed: () {
            setState(() {
              _viewingYear = _todayHijri.hYear;
              _viewingMonth = _todayHijri.hMonth;
            });
          },
        ),
      ],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTodayCard(lang),
                const SizedBox(height: 16),
                HairlineCard(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconButton44(
                            designIcon: 'chevl',
                            tooltip: material.previousMonthTooltip,
                            ghost: true,
                            onPressed: _prevMonth,
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Text(
                                  '$monthName $_viewingYear',
                                  textAlign: TextAlign.center,
                                  style: redesignDisplayStyle(
                                    context,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  gregRange,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: tokens.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton44(
                            designIcon: 'chev',
                            tooltip: material.nextMonthTooltip,
                            ghost: true,
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Weekday Headers
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 7,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisExtent: 32,
                            ),
                        itemBuilder: (context, index) {
                          return Center(
                            child: Text(
                              weekdayHeaders[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.muted,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),

                      // Month Days Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: startWeekdayOffset + daysCount,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                            ),
                        itemBuilder: (context, index) {
                          if (index < startWeekdayOffset) {
                            return const SizedBox.shrink();
                          }

                          final int dayNumber = index - startWeekdayOffset + 1;
                          final DateTime cellGregorian = DateTime(
                            firstDayGregorian.year,
                            firstDayGregorian.month,
                            firstDayGregorian.day + dayNumber - 1,
                          );
                          final bool isCurrentToday =
                              cellGregorian.year == _today.year &&
                              cellGregorian.month == _today.month &&
                              cellGregorian.day == _today.day;

                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: isCurrentToday
                                  ? tokens.filled
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrentToday
                                    ? tokens.filled
                                    : tokens.hair,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontVariations: const [
                                      FontVariation('opsz', 15),
                                    ],
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrentToday
                                        ? Colors.white
                                        : colors.textPrimary,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${cellGregorian.day}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    height: 1.2,
                                    color: isCurrentToday
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : tokens.muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(String lang) {
    final EquranTokens tokens = context.equranTokens;
    final Color gold = heroGoldOf(context);
    final String todayHijriStr =
        '${_todayHijri.hDay} ${_todayHijri.getLocalizedMonthName(lang)} ${_todayHijri.hYear}';
    final DateFormat formatter = DateFormat('EEEE, MMMM d, yyyy', lang);
    final String todayGregorianStr = formatter.format(_today);

    return HeroPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DesignIcon('moon', size: 16, color: gold),
              const SizedBox(width: 8),
              Expanded(
                child: RedesignEyebrow(_translateToday(lang), color: gold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            todayHijriStr,
            style: redesignDisplayStyle(
              context,
              size: 32,
              color: EquranColors.dark.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            todayGregorianStr,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: tokens.featText2,
            ),
          ),
        ],
      ),
    );
  }
}
