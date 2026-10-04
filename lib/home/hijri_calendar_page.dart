import 'package:equran/widgets/redesign/redesign_widgets.dart'
    show IconButton44, RedesignSubpage;
import 'package:flutter/material.dart';
import 'package:equran/theme/equran_colors.dart';
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
  const HijriCalendarPage({super.key});

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
    _today = DateTime.now();
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
    final ThemeData theme = Theme.of(context);

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

    return RedesignSubpage(
      title: _translateTitle(lang),
      actions: [
        IconButton44(
          icon: Icons.today_rounded,
          tooltip: _translateToday(lang),
          onPressed: () {
            setState(() {
              _viewingYear = _todayHijri.year;
              _viewingMonth = _todayHijri.month;
            });
          },
        ),
      ],
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Beautiful Today Card
                  _buildTodayCard(colors, theme, lang),
                  const SizedBox(height: 20),

                  // Month Navigation & Grid Card
                  Card(
                    color: colors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colors.border.withAlpha(120)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Month Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? Icons.chevron_right_rounded
                                      : Icons.chevron_left_rounded,
                                  color: colors.primary,
                                ),
                                onPressed: _prevMonth,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '$monthName $_viewingYear',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      gregRange,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? Icons.chevron_left_rounded
                                      : Icons.chevron_right_rounded,
                                  color: colors.primary,
                                ),
                                onPressed: _nextMonth,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

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
                                  _getWeekdayHeaders(lang)[index],
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          // Month Days Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: startWeekdayOffset + daysCount,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              if (index < startWeekdayOffset) {
                                return const SizedBox.shrink();
                              }

                              final int dayNumber =
                                  index - startWeekdayOffset + 1;
                              final DateTime cellGregorian = firstDayGregorian
                                  .add(Duration(days: dayNumber - 1));
                              final bool isCurrentToday =
                                  cellGregorian.year == _today.year &&
                                  cellGregorian.month == _today.month &&
                                  cellGregorian.day == _today.day;

                              return Material(
                                color: isCurrentToday
                                    ? colors.primary
                                    : colors.surfaceSoft,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    // Could show details or events for this Hijri day
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrentToday
                                            ? colors.primary
                                            : colors.border.withAlpha(80),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$dayNumber',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: isCurrentToday
                                                    ? colors.onPrimary
                                                    : colors.textPrimary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${cellGregorian.day}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isCurrentToday
                                                    ? colors.onPrimary
                                                          .withAlpha(200)
                                                    : colors.textSecondary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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

  Widget _buildTodayCard(EquranColors colors, ThemeData theme, String lang) {
    final String todayHijriStr =
        '${_todayHijri.day} ${_todayHijri.getMonthName(lang)} ${_todayHijri.year}';
    final DateFormat formatter = DateFormat('EEEE, MMMM d, yyyy', lang);
    final String todayGregorianStr = formatter.format(_today);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryStrong],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.dark_mode_outlined,
              size: 130,
              color: colors.onPrimary.withAlpha(25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withAlpha(35),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _translateToday(lang).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  todayHijriStr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  todayGregorianStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withAlpha(210),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
