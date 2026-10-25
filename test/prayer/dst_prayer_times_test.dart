import 'package:flutter_test/flutter_test.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Daylight Saving Time transitions (Issue #115)', () {
    const service = PrayerTimesService();

    test('London on 2026-10-25 (clocks put back 1 hour, autumn DST end)', () {
      const london = PrayerLocation(
        latitude: 51.5074,
        longitude: -0.1278,
        label: 'London',
        countryCode: 'GB',
        timezoneId: 'Europe/London',
        mode: PrayerLocationMode.manual,
      );
      const settings = PrayerTimeSettings(useLocationTimezone: true);

      final day = service.calculateDay(
        date: DateTime(2026, 10, 25),
        location: london,
        settings: settings,
      );

      final fajr = day.entryFor(PrayerTimeKind.fajr).time;
      final sunrise = day.entryFor(PrayerTimeKind.sunrise).time;
      final dhuhr = day.entryFor(PrayerTimeKind.dhuhr).time;
      final asr = day.entryFor(PrayerTimeKind.asr).time;

      // Fajr must always precede sunrise.
      expect(fajr.isBefore(sunrise), isTrue);
      // In London on Oct 25, sunrise is ~06:41 GMT, Fajr should be around 04:49 GMT.
      expect(fajr.hour, 4);
      expect(fajr.minute, 49);
      expect(sunrise.hour, 6);
      expect(sunrise.minute, 41);
      expect(dhuhr.hour, 11);
      expect(asr.hour, 14);

      // Verify timezone offset after the 2:00 AM clock change is GMT (UTC+0).
      expect(fajr.timeZoneOffset, Duration.zero);

      // Verify nextPrayer at 1:30 AM GMT points to Fajr of the same morning.
      final londonTz = tz.getLocation('Europe/London');
      final earlyMorning = tz.TZDateTime(londonTz, 2026, 10, 25, 1, 30);
      final next = service.nextPrayer(day: day, now: earlyMorning);
      expect(next.entry.kind, PrayerTimeKind.fajr);
      expect(next.entry.time, fajr);
      expect(next.countdown.isNegative, isFalse);
    });

    test(
      'London on 2026-03-29 (clocks jump forward 1 hour, spring DST start)',
      () {
        const london = PrayerLocation(
          latitude: 51.5074,
          longitude: -0.1278,
          label: 'London',
          countryCode: 'GB',
          timezoneId: 'Europe/London',
          mode: PrayerLocationMode.manual,
        );
        const settings = PrayerTimeSettings(useLocationTimezone: true);

        final day = service.calculateDay(
          date: DateTime(2026, 3, 29),
          location: london,
          settings: settings,
        );

        final fajr = day.entryFor(PrayerTimeKind.fajr).time;
        final sunrise = day.entryFor(PrayerTimeKind.sunrise).time;

        expect(fajr.isBefore(sunrise), isTrue);
        // In London on March 29 (BST UTC+1), Fajr is around 04:55 BST, Sunrise around 06:45 BST.
        expect(fajr.hour, 4);
        expect(sunrise.hour, 6);
        expect(fajr.timeZoneOffset, const Duration(hours: 1));
      },
    );

    test('New York on 2026-11-01 (clocks put back 1 hour, autumn DST end)', () {
      const newYork = PrayerLocation(
        latitude: 40.7128,
        longitude: -74.006,
        label: 'New York',
        countryCode: 'US',
        timezoneId: 'America/New_York',
        mode: PrayerLocationMode.manual,
      );
      const settings = PrayerTimeSettings(useLocationTimezone: true);

      final day = service.calculateDay(
        date: DateTime(2026, 11, 1),
        location: newYork,
        settings: settings,
      );

      final fajr = day.entryFor(PrayerTimeKind.fajr).time;
      final sunrise = day.entryFor(PrayerTimeKind.sunrise).time;

      expect(fajr.isBefore(sunrise), isTrue);
      expect(fajr.hour, 5);
      expect(fajr.minute, 9);
      expect(sunrise.hour, 6);
      expect(sunrise.minute, 26);
      // EST is UTC-5
      expect(fajr.timeZoneOffset, const Duration(hours: -5));
    });

    test('Paris on 2026-10-25 (clocks put back 1 hour, CEST to CET)', () {
      const paris = PrayerLocation(
        latitude: 48.8566,
        longitude: 2.3522,
        label: 'Paris',
        countryCode: 'FR',
        timezoneId: 'Europe/Paris',
        mode: PrayerLocationMode.manual,
      );
      const settings = PrayerTimeSettings(useLocationTimezone: true);

      final day = service.calculateDay(
        date: DateTime(2026, 10, 25),
        location: paris,
        settings: settings,
      );

      final fajr = day.entryFor(PrayerTimeKind.fajr).time;
      final sunrise = day.entryFor(PrayerTimeKind.sunrise).time;

      expect(fajr.isBefore(sunrise), isTrue);
      // CET is UTC+1
      expect(fajr.timeZoneOffset, const Duration(hours: 1));
    });

    test(
      'calendarDateForInstant handles evening after Maghrib on DST change day',
      () {
        const london = PrayerLocation(
          latitude: 51.5074,
          longitude: -0.1278,
          label: 'London',
          countryCode: 'GB',
          timezoneId: 'Europe/London',
          mode: PrayerLocationMode.manual,
        );
        const settings = PrayerTimeSettings(useLocationTimezone: true);
        final londonTz = tz.getLocation('Europe/London');

        // 8:00 PM on Oct 25 (after Maghrib) -> Islamic day advances to Oct 26
        final eveningInstant = tz.TZDateTime(londonTz, 2026, 10, 25, 20, 0);
        final calDate = service.calendarDateForInstant(
          instant: eveningInstant,
          location: london,
          settings: settings,
        );
        expect(calDate.year, 2026);
        expect(calDate.month, 10);
        expect(calDate.day, 26);
      },
    );
  });
}
