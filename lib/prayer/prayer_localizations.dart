import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:flutter/painting.dart';

String localizedPrayerName(
  AppLocalizations localizations,
  PrayerTimeKind kind,
) {
  return switch (kind) {
    PrayerTimeKind.fajr => localizations.prayerNameFajr,
    PrayerTimeKind.sunrise => localizations.prayerNameSunrise,
    PrayerTimeKind.dhuhr => localizations.prayerNameDhuhr,
    PrayerTimeKind.asr => localizations.prayerNameAsr,
    PrayerTimeKind.maghrib => localizations.prayerNameMaghrib,
    PrayerTimeKind.isha => localizations.prayerNameIsha,
  };
}

/// Minutes of a "2h 08m" duration, always two digits.
String twoDigitMinutes(int minutes) => minutes.toString().padLeft(2, '0');

/// "Asr in 2h 08m", with [duration] as a larger numeral. The template decides
/// the word order, so this works for right-to-left languages too.
InlineSpan prayerNextInSpan(
  AppLocalizations l, {
  required String prayer,
  required String duration,
  required TextStyle numeralStyle,
}) {
  const marker = '\u0001';
  final parts = l.prayerNextIn(prayer, marker).split(marker);
  return TextSpan(
    children: [
      TextSpan(text: parts.first),
      TextSpan(text: duration, style: numeralStyle),
      if (parts.length > 1) TextSpan(text: parts.sublist(1).join(marker)),
    ],
  );
}
