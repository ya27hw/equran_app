import 'dart:ui' show Color, lerpDouble;

import 'package:equran/prayer/prayer_models.dart';
import 'package:flutter/foundation.dart';

/// Decorative sky, anchored to actual instants rather than device clock hours.
/// PrayerDay starts at the previous Maghrib; followingDay supplies this day's
/// sunset. Never approximate either boundary by adding 24 hours (DST/seasons).
@immutable
class PrayerSkyScene {
  const PrayerSkyScene({
    required this.top,
    required this.middle,
    required this.horizon,
    required this.sunProgress,
    required this.sunVisibility,
    required this.stars,
  });

  final Color top;
  final Color middle;
  final Color horizon;
  final double sunProgress;
  final double sunVisibility;
  final double stars;

  static const Color foreground = Color(0xfffff8e8);
  static const Color sun = Color(0xffffedb6);
  static const Color sunGlow = Color(0xffffdfa1);
  static const Color scrim = Color(0xff102b39);
  static const Color farLand = Color(0xfff0d8a6);
  static const Color middleLand = Color(0xff305b63);
  static const Color nearLand = Color(0xff1d414d);

  static const PrayerSkyScene night = PrayerSkyScene(
    top: Color(0xff102639),
    middle: Color(0xff1b3c4d),
    horizon: Color(0xff35515d),
    sunProgress: 0,
    sunVisibility: 0,
    stars: 1,
  );
  static const PrayerSkyScene _dawn = PrayerSkyScene(
    top: Color(0xff1b344e),
    middle: Color(0xff4c596d),
    horizon: Color(0xffbe886a),
    sunProgress: 0,
    sunVisibility: 0,
    stars: 0.45,
  );
  static const PrayerSkyScene _sunrise = PrayerSkyScene(
    top: Color(0xff436176),
    middle: Color(0xffc49983),
    horizon: Color(0xffedc18d),
    sunProgress: 0,
    sunVisibility: 1,
    stars: 0,
  );
  static const PrayerSkyScene _morning = PrayerSkyScene(
    top: Color(0xff236c8e),
    middle: Color(0xff67adbb),
    horizon: Color(0xffe3cf9a),
    sunProgress: 0,
    sunVisibility: 1,
    stars: 0,
  );
  static const PrayerSkyScene _noon = PrayerSkyScene(
    top: Color(0xff174f78),
    middle: Color(0xff4399b0),
    horizon: Color(0xffd9d5ae),
    sunProgress: 0.5,
    sunVisibility: 1,
    stars: 0,
  );
  static const PrayerSkyScene _afternoon = PrayerSkyScene(
    top: Color(0xff2d647b),
    middle: Color(0xff85a5a4),
    horizon: Color(0xffe8bf7b),
    sunProgress: 0,
    sunVisibility: 1,
    stars: 0,
  );
  static const PrayerSkyScene _sunset = PrayerSkyScene(
    top: Color(0xff593d58),
    middle: Color(0xffc47a61),
    horizon: Color(0xfff0b767),
    sunProgress: 1,
    sunVisibility: 1,
    stars: 0,
  );
  static const PrayerSkyScene _twilight = PrayerSkyScene(
    top: Color(0xff172d45),
    middle: Color(0xff3b4b61),
    horizon: Color(0xff866d72),
    sunProgress: 1,
    sunVisibility: 0,
    stars: 0.7,
  );

  factory PrayerSkyScene.forInstant({
    required PrayerDay day,
    required PrayerDay followingDay,
    required DateTime now,
  }) {
    final DateTime previousSunset = day.entryFor(PrayerTimeKind.maghrib).time;
    DateTime previousIsha = day.entryFor(PrayerTimeKind.isha).time;
    DateTime fajr = day.entryFor(PrayerTimeKind.fajr).time;
    final DateTime sunrise = day.entryFor(PrayerTimeKind.sunrise).time;
    final DateTime noon = day.entryFor(PrayerTimeKind.dhuhr).time;
    DateTime asr = day.entryFor(PrayerTimeKind.asr).time;
    final DateTime sunset = followingDay.entryFor(PrayerTimeKind.maghrib).time;
    DateTime isha = followingDay.entryFor(PrayerTimeKind.isha).time;
    final List<DateTime> ordered = <DateTime>[
      previousSunset,
      sunrise,
      noon,
      sunset,
    ];
    for (int i = 1; i < ordered.length; i++) {
      if (!ordered[i].isAfter(ordered[i - 1])) return night;
    }
    // Custom offsets and calculator edge cases can put a prayer outside its
    // solar window. Repair only decorative palette anchors, never prayer data.
    if (!previousIsha.isAfter(previousSunset) ||
        !previousIsha.isBefore(sunrise)) {
      previousIsha = _between(previousSunset, sunrise, 0.2);
    }
    if (!fajr.isAfter(previousIsha) || !fajr.isBefore(sunrise)) {
      fajr = _between(previousIsha, sunrise, 0.85);
    }
    if (!asr.isAfter(noon) || !asr.isBefore(sunset)) {
      asr = _between(noon, sunset, 0.6);
    }
    if (!isha.isAfter(sunset)) {
      isha = sunset.add(const Duration(hours: 1));
    }
    final List<(DateTime, PrayerSkyScene)> stops = <(DateTime, PrayerSkyScene)>[
      (previousSunset, _sunset),
      (previousIsha, _twilight),
      (_between(previousIsha, fajr, 0.2), night),
      (_between(previousIsha, fajr, 0.8), night),
      (fajr, _dawn),
      (sunrise, _sunrise),
      (_between(sunrise, noon, 0.2), _morning),
      (noon, _noon),
      (asr, _afternoon),
      (sunset, _sunset),
      (isha, _twilight),
    ];
    PrayerSkyScene palette = now.isBefore(stops.first.$1) ? night : _twilight;
    for (int i = 1; i < stops.length; i++) {
      if (!now.isBefore(stops[i - 1].$1) && !now.isAfter(stops[i].$1)) {
        palette = lerp(
          stops[i - 1].$2,
          stops[i].$2,
          _fraction(now, stops[i - 1].$1, stops[i].$1),
        );
        break;
      }
    }
    final bool previousEvening = now.isBefore(fajr);
    final DateTime settingSun = previousEvening ? previousSunset : sunset;
    final double visibility;
    if (now.isBefore(sunrise) && !previousEvening) {
      visibility = _fraction(
        now,
        sunrise.subtract(const Duration(minutes: 10)),
        sunrise,
      );
    } else if (previousEvening || !now.isBefore(sunset)) {
      visibility =
          1 -
          _fraction(
            now,
            settingSun,
            settingSun.add(const Duration(minutes: 10)),
          );
    } else {
      visibility = 1;
    }
    final double progress = previousEvening
        ? 1
        : now.isBefore(noon)
        ? 0.5 * _fraction(now, sunrise, noon)
        : 0.5 + 0.5 * _fraction(now, noon, sunset);
    return PrayerSkyScene(
      top: palette.top,
      middle: palette.middle,
      horizon: palette.horizon,
      sunProgress: progress,
      sunVisibility: visibility,
      stars: palette.stars,
    );
  }

  static DateTime _between(DateTime start, DateTime end, double fraction) =>
      start.add(
        Duration(
          microseconds: (end.difference(start).inMicroseconds * fraction)
              .round(),
        ),
      );

  static double _fraction(DateTime now, DateTime start, DateTime end) =>
      (now.difference(start).inMicroseconds /
              end.difference(start).inMicroseconds)
          .clamp(0.0, 1.0);

  static PrayerSkyScene lerp(PrayerSkyScene a, PrayerSkyScene b, double t) =>
      PrayerSkyScene(
        top: Color.lerp(a.top, b.top, t)!,
        middle: Color.lerp(a.middle, b.middle, t)!,
        horizon: Color.lerp(a.horizon, b.horizon, t)!,
        sunProgress: lerpDouble(a.sunProgress, b.sunProgress, t)!,
        sunVisibility: lerpDouble(a.sunVisibility, b.sunVisibility, t)!,
        stars: lerpDouble(a.stars, b.stars, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is PrayerSkyScene &&
      top == other.top &&
      middle == other.middle &&
      horizon == other.horizon &&
      sunProgress == other.sunProgress &&
      sunVisibility == other.sunVisibility &&
      stars == other.stars;

  @override
  int get hashCode =>
      Object.hash(top, middle, horizon, sunProgress, sunVisibility, stars);
}
