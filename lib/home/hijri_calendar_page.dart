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

class HijriCalendar {
  final int year;
  final int month;
  final int day;

  HijriCalendar(this.year, this.month, this.day);

  static const List<String> monthNamesEn = <String>[
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qa\'dah',
    'Dhu al-Hijjah',
  ];

  static const List<String> monthNamesAr = <String>[
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> monthNamesTr = <String>[
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce',
  ];

  static const List<String> monthNamesId = <String>[
    'Muharram',
    'Safar',
    'Rabiul Awal',
    'Rabiul Akhir',
    'Jumadil Awal',
    'Jumadil Akhir',
    'Rajab',
    'Sya\'ban',
    'Ramadhan',
    'Syawal',
    'Zulkaidah',
    'Zulhijah',
  ];

  static const List<String> monthNamesBn = <String>[
    'মহররম',
    'সফর',
    'রবিউল আউয়াল',
    'রবিউস সানি',
    'জমাদিউল আউয়াল',
    'জমাদিউস সানি',
    'রজব',
    'শাবান',
    'রমজান',
    'শাওয়াল',
    'জিলকদ',
    'জিলহজ',
  ];

  static const List<String> monthNamesDe = <String>[
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' ath-Thani',
    'Dschumada al-Ula',
    'Dschumada ath-Thaniya',
    'Radschab',
    'Scha\'ban',
    'Ramadan',
    'Schawwal',
    'Dhu l-qa\'da',
    'Dhu l-hidschdscha',
  ];

  static bool isLeapYear(int hYear) {
    final int remainder = hYear % 30;
    return const <int>[
      2,
      5,
      7,
      10,
      13,
      16,
      18,
      21,
      24,
      26,
      29,
    ].contains(remainder);
  }

  static int daysInMonth(int hYear, int hMonth) {
    if (hMonth < 1 || hMonth > 12) return 30;
    if (hMonth == 12) {
      return isLeapYear(hYear) ? 30 : 29;
    }
    return hMonth % 2 == 1 ? 30 : 29;
  }

  static HijriCalendar fromGregorian(DateTime date) {
    int gYear = date.year;
    int gMonth = date.month;
    int gDay = date.day;

    if (gMonth < 3) {
      gYear -= 1;
      gMonth += 12;
    }

    final double a = (gYear / 100).floorToDouble();
    final double b = (a / 4).floorToDouble();
    final double c = 2.0 - a + b;
    final double e = (365.25 * (gYear + 4716)).floorToDouble();
    final double f = (30.6001 * (gMonth + 1)).floorToDouble();
    final double jd = c + gDay + e + f - 1524.5;

    final double l = jd - 1948440.0 + 10632.0;
    final double n = ((l - 1.0) / 10631.0).floorToDouble();
    double rem = l - 10631.0 * n;

    final double j =
        ((10985.0 - rem) / 5316.0).floorToDouble() *
            ((50.0 - rem) / 36.0).floorToDouble() +
        ((rem - 2.0) / 30.0).floorToDouble() *
            ((rem - 2800.0) / 29.0).floorToDouble() *
            ((rem - 2828.0) / 30.0).floorToDouble();
    rem =
        rem +
        j -
        ((10985.0 - j) / 5316.0).floorToDouble() *
            ((50.0 - j) / 36.0).floorToDouble();

    final double y = (30.0 * n + (rem - 15.0) / 10631.0).floorToDouble();
    rem = rem - (10631.0 * (y - 30.0 * n) / 30.0).floorToDouble() + 354.0;

    double m = ((rem - 1.0) / 29.5).floorToDouble();
    if (m > 12) m = 12;
    if (m < 1) m = 1;
    final double d = rem - (29.5 * m).floorToDouble() - 17.0;

    return HijriCalendar(y.toInt(), m.toInt(), d.toInt() + 1);
  }

  String getMonthName(String locale) {
    final List<String> list = switch (locale) {
      'ar' || 'fa' || 'ur' => monthNamesAr,
      'tr' => monthNamesTr,
      'id' => monthNamesId,
      'bn' => monthNamesBn,
      'de' => monthNamesDe,
      _ => monthNamesEn,
    };
    if (month < 1 || month > 12) return '';
    return list[month - 1];
  }
}

class HijriCalendarPage extends StatefulWidget {
  const HijriCalendarPage({super.key, this.now});

  /// The clock for today; tests pass a fixed one.
  final DateTime Function()? now;

  @override
  State<HijriCalendarPage> createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  late DateTime _today;
  late HijriCalendar _todayHijri;
  late int _viewingYear;
  late int _viewingMonth;

  @override
  void initState() {
    super.initState();
    _today = widget.now?.call() ?? DateTime.now();
    _todayHijri = HijriCalendar.fromGregorian(_today);
    _viewingYear = _todayHijri.year;
    _viewingMonth = _todayHijri.month;
  }

  DateTime _getFirstDayOfHijriMonth(int hYear, int hMonth) {
    final double daysSinceEpoch =
        (hYear - 1) * 354.367 + (hMonth - 1) * 29.53 + 1;
    DateTime approxDate = DateTime(
      622,
      7,
      16,
    ).add(Duration(days: daysSinceEpoch.round()));

    HijriCalendar cal = HijriCalendar.fromGregorian(approxDate);
    int difference = cal.day - 1;
    DateTime firstDay = approxDate.subtract(Duration(days: difference));

    cal = HijriCalendar.fromGregorian(firstDay);
    int iterations = 0;
    while ((cal.month != hMonth || cal.year != hYear || cal.day != 1) &&
        iterations < 30) {
      if (cal.year < hYear || (cal.year == hYear && cal.month < hMonth)) {
        firstDay = firstDay.add(const Duration(days: 1));
      } else {
        firstDay = firstDay.subtract(const Duration(days: 1));
      }
      cal = HijriCalendar.fromGregorian(firstDay);
      iterations++;
    }
    return firstDay;
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
    final String monthName = HijriCalendar(
      _viewingYear,
      _viewingMonth,
      1,
    ).getMonthName(lang);
    final int daysCount = HijriCalendar.daysInMonth(
      _viewingYear,
      _viewingMonth,
    );

    // First Day Gregorian to find start weekday
    final DateTime firstDayGregorian = _getFirstDayOfHijriMonth(
      _viewingYear,
      _viewingMonth,
    );
    final int startWeekdayOffset = firstDayGregorian.weekday % 7; // Sunday is 0

    // Gregorian range of the Hijri month
    final DateTime lastDayGregorian = firstDayGregorian.add(
      Duration(days: daysCount - 1),
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
              _viewingYear = _todayHijri.year;
              _viewingMonth = _todayHijri.month;
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
                          final DateTime cellGregorian = firstDayGregorian.add(
                            Duration(days: dayNumber - 1),
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
        '${_todayHijri.day} ${_todayHijri.getMonthName(lang)} ${_todayHijri.year}';
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
