import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_sky_scene.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:flutter_test/flutter_test.dart';

const PrayerLocation skyTestLocation = PrayerLocation(
  latitude: 23.588,
  longitude: 58.3829,
  label: 'Muscat',
  mode: PrayerLocationMode.manual,
  countryCode: 'OM',
  timezoneId: 'Asia/Muscat',
);
const PrayerTimeSettings skyTestSettings = PrayerTimeSettings();
const PrayerTimesService skyTestService = PrayerTimesService();

PrayerDay skyTestDay(int day, {PrayerLocation location = skyTestLocation}) =>
    skyTestService.calculateDay(
      date: DateTime(2026, 10, day),
      location: location,
      settings: skyTestSettings,
    );

void main() {
  final PrayerDay day = skyTestDay(4);
  final PrayerDay following = skyTestDay(5);
  PrayerSkyScene at(DateTime now) =>
      PrayerSkyScene.forInstant(day: day, followingDay: following, now: now);

  test('uses the following prayer day for the daylight sunset', () {
    expect(
      day
          .entryFor(PrayerTimeKind.maghrib)
          .time
          .isBefore(day.entryFor(PrayerTimeKind.sunrise).time),
      isTrue,
    );
    expect(at(day.entryFor(PrayerTimeKind.sunrise).time).sunProgress, 0);
    expect(at(day.entryFor(PrayerTimeKind.dhuhr).time).sunProgress, 0.5);
    expect(at(following.entryFor(PrayerTimeKind.maghrib).time).sunProgress, 1);
    expect(at(day.entryFor(PrayerTimeKind.dhuhr).time).sunVisibility, 1);
  });

  test('sunset stays continuous when the prayer date rolls over', () {
    final DateTime sunset = following.entryFor(PrayerTimeKind.maghrib).time;
    final PrayerSkyScene before = at(sunset);
    final PrayerSkyScene after = PrayerSkyScene.forInstant(
      day: following,
      followingDay: skyTestDay(6),
      now: sunset,
    );
    expect(before, after);
  });

  test('night continues across midnight and gives way to dawn and sunrise', () {
    final DateTime midnight = day.date;
    final PrayerSkyScene before = at(
      midnight.subtract(const Duration(seconds: 1)),
    );
    final PrayerSkyScene after = at(midnight.add(const Duration(seconds: 1)));
    expect(before.top, after.top);
    expect(before.sunVisibility, 0);
    expect(after.sunVisibility, 0);
    expect(after.stars, greaterThan(0.9));
    final PrayerSkyScene dawn = at(day.entryFor(PrayerTimeKind.fajr).time);
    final PrayerSkyScene sunrise = at(
      day.entryFor(PrayerTimeKind.sunrise).time,
    );
    expect(dawn.sunVisibility, 0);
    expect(dawn.top, isNot(after.top));
    expect(sunrise.sunVisibility, 1);
    expect(sunrise.stars, 0);
  });

  test('UTC and location-zone representations of the same instant agree', () {
    final DateTime noon = day.entryFor(PrayerTimeKind.dhuhr).time;
    expect(at(noon), at(noon.toUtc()));
  });

  test('out-of-order adjusted times use a safe static scene', () {
    final PrayerDay invalid = PrayerDay(
      date: day.date,
      location: day.location,
      settings: day.settings,
      effectiveMethod: day.effectiveMethod,
      timezoneId: day.timezoneId,
      usesLocationTimezone: day.usesLocationTimezone,
      entries: day.entries
          .map(
            (entry) => entry.kind == PrayerTimeKind.dhuhr
                ? PrayerTimeEntry(
                    kind: entry.kind,
                    time: day.entryFor(PrayerTimeKind.sunrise).time,
                    offsetMinutes: 0,
                  )
                : entry,
          )
          .toList(),
    );
    expect(
      PrayerSkyScene.forInstant(
        day: invalid,
        followingDay: following,
        now: day.date,
      ),
      PrayerSkyScene.night,
    );
  });

  test(
    'a daylight-saving change uses calculated instants without 24h shifts',
    () {
      const PrayerLocation newYork = PrayerLocation(
        latitude: 40.7128,
        longitude: -74.006,
        label: 'New York',
        mode: PrayerLocationMode.manual,
        countryCode: 'US',
        timezoneId: 'America/New_York',
      );
      final PrayerDay dstDay = skyTestService.calculateDay(
        date: DateTime(2026, 11, 1),
        location: newYork,
        settings: skyTestSettings,
      );
      final PrayerDay next = skyTestService.calculateDay(
        date: DateTime(2026, 11, 2),
        location: newYork,
        settings: skyTestSettings,
      );
      expect(
        PrayerSkyScene.forInstant(
          day: dstDay,
          followingDay: next,
          now: dstDay.entryFor(PrayerTimeKind.dhuhr).time,
        ).sunProgress,
        0.5,
      );
      expect(
        PrayerSkyScene.forInstant(
          day: dstDay,
          followingDay: next,
          now: next.entryFor(PrayerTimeKind.maghrib).time,
        ).sunProgress,
        1,
      );
    },
  );
}
