import 'package:equran/prayer/hijri_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one Hijri conversion the app uses (prayer times, Islamic calendar,
/// Home header and the Hijri calendar page). The dates below are the
/// algorithm's output and agree with the Umm al-Qura calendar for these
/// month starts; the algorithm is approximate by up to a day elsewhere (see
/// the class comment), which is what the moon-sighting offset is for.
void main() {
  (int, int, int) hijri(DateTime d, {int offset = 0}) {
    final HijriCalendar h = HijriCalendar.fromDate(d, offset: offset);
    return (h.hYear, h.hMonth, h.hDay);
  }

  group('fromDate', () {
    test('known conversions', () {
      expect(hijri(DateTime(2026, 10, 7)), (1448, 4, 24));
      expect(hijri(DateTime(2026, 6, 17)), (1448, 1, 1));
      expect(hijri(DateTime(2026, 6, 16)), (1447, 12, 30));
      expect(hijri(DateTime(2026, 2, 18)), (1447, 9, 1));
      expect(hijri(DateTime(2026, 3, 20)), (1447, 10, 1));
      expect(hijri(DateTime(2025, 3, 1)), (1446, 9, 1));
      expect(hijri(DateTime(2024, 3, 11)), (1445, 9, 1));
      expect(hijri(DateTime(2000, 1, 1)), (1420, 9, 24));
    });

    test('the sighting offset shifts the date by whole days', () {
      expect(hijri(DateTime(2026, 2, 18), offset: 1), (1447, 9, 2));
      expect(hijri(DateTime(2026, 2, 18), offset: -1), (1447, 8, 29));
      expect(hijri(DateTime(2026, 2, 18, 23, 59), offset: 1), (1447, 9, 2));
    });

    test('the offset is a calendar day even across a DST change', () {
      // 1 Nov 2026 is 25 hours long in New York and 29 Mar 2026 is 23 hours
      // long in Berlin; adding a 24 h Duration would land on the wrong day.
      for (final DateTime d in <DateTime>[
        DateTime(2026, 10, 31),
        DateTime(2026, 3, 28),
        DateTime(2026, 11, 1),
        DateTime(2026, 3, 29),
      ]) {
        expect(
          hijri(d, offset: 1),
          hijri(DateTime(d.year, d.month, d.day + 1)),
          reason: '$d',
        );
        expect(
          hijri(d, offset: -1),
          hijri(DateTime(d.year, d.month, d.day - 1)),
          reason: '$d',
        );
      }
    });

    test('every day of a Gregorian year is a valid Hijri date', () {
      HijriCalendar? previous;
      for (int i = 0; i < 400; i++) {
        final HijriCalendar h = HijriCalendar.fromDate(
          DateTime(2026, 1, 1 + i),
        );
        expect(h.hMonth, inInclusiveRange(1, 12));
        expect(h.hDay, inInclusiveRange(1, 30));
        expect(h.hYear, inInclusiveRange(1447, 1448));
        if (previous != null) {
          final bool sameMonth =
              previous.hYear == h.hYear && previous.hMonth == h.hMonth;
          if (sameMonth) {
            expect(h.hDay, previous.hDay + 1);
          } else {
            expect(h.hDay, 1);
            expect(previous.hDay, inInclusiveRange(29, 30));
          }
        }
        previous = h;
      }
    });
  });

  group('month grid helpers', () {
    test('first day of a month converts back to day 1', () {
      for (int y = 1445; y <= 1450; y++) {
        for (int m = 1; m <= 12; m++) {
          for (final int offset in <int>[-1, 0, 1]) {
            final DateTime start = HijriCalendar.firstGregorianDayOf(
              y,
              m,
              offset: offset,
            );
            expect(hijri(start, offset: offset), (y, m, 1), reason: '$y/$m');
            final DateTime before = DateTime(
              start.year,
              start.month,
              start.day - 1,
            );
            expect(hijri(before, offset: offset).$3, greaterThanOrEqualTo(29));
          }
        }
      }
    });

    test('known month ranges, including a year boundary', () {
      // 24 Rabi al-Thani 1448 is 7 Oct 2026: the month spans 14 Sep to 12 Oct.
      expect(HijriCalendar.firstGregorianDayOf(1448, 4), DateTime(2026, 9, 14));
      expect(HijriCalendar.daysInMonth(1448, 4), 29);
      // Dhu al-Hijjah 1447 (30 days) ends the day before 1 Muharram 1448.
      expect(
        HijriCalendar.firstGregorianDayOf(1447, 12),
        DateTime(2026, 5, 18),
      );
      expect(HijriCalendar.daysInMonth(1447, 12), 30);
      expect(HijriCalendar.firstGregorianDayOf(1448, 1), DateTime(2026, 6, 17));
      // The offset moves the whole grid.
      expect(
        HijriCalendar.firstGregorianDayOf(1448, 1, offset: 1),
        DateTime(2026, 6, 16),
      );
    });

    test('months are 29 or 30 days and years 354 or 355', () {
      for (int y = 1440; y <= 1455; y++) {
        int total = 0;
        for (int m = 1; m <= 12; m++) {
          final int days = HijriCalendar.daysInMonth(y, m);
          expect(days, inInclusiveRange(29, 30), reason: '$y/$m');
          total += days;
        }
        expect(total, inInclusiveRange(354, 355), reason: 'year $y');
      }
    });

    test('consecutive months tile the calendar with no gap or overlap', () {
      DateTime expected = HijriCalendar.firstGregorianDayOf(1446, 1);
      int y = 1446;
      int m = 1;
      for (int i = 0; i < 36; i++) {
        expect(HijriCalendar.firstGregorianDayOf(y, m), expected);
        final int days = HijriCalendar.daysInMonth(y, m);
        expected = DateTime(expected.year, expected.month, expected.day + days);
        if (m == 12) {
          m = 1;
          y++;
        } else {
          m++;
        }
      }
    });
  });

  test('localized month names cover all twelve months in every language', () {
    for (final String lang in <String>[
      'en', 'ar', 'bn', 'de', 'fa', 'id', 'tr', 'ur', //
    ]) {
      final Set<String> names = <String>{
        for (int m = 1; m <= 12; m++) HijriCalendar.monthNameFor(m, lang),
      };
      expect(names.length, 12, reason: lang);
    }
    expect(HijriCalendar.monthNameFor(9, 'en'), 'Ramadan');
    expect(HijriCalendar.monthNameFor(9, 'tr_TR'), 'Ramazan');
  });
}
