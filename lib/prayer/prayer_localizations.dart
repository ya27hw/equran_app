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

/// Localized name of a calculation method for lists and dialogs.
///
/// `PrayerCalculationMethod.label` stays English for logs and tests.
String localizedCalculationMethod(
  AppLocalizations l10n,
  PrayerCalculationMethod method,
) {
  return switch (method) {
    PrayerCalculationMethod.auto => l10n.prayerMethodAuto,
    PrayerCalculationMethod.muslimWorldLeague =>
      l10n.prayerMethodMuslimWorldLeague,
    PrayerCalculationMethod.egyptian => l10n.prayerMethodEgyptian,
    PrayerCalculationMethod.ummAlQura => l10n.prayerMethodUmmAlQura,
    PrayerCalculationMethod.dubai => l10n.prayerMethodDubai,
    PrayerCalculationMethod.kuwait => l10n.prayerMethodKuwait,
    PrayerCalculationMethod.qatar => l10n.prayerMethodQatar,
    PrayerCalculationMethod.karachi => l10n.prayerMethodKarachi,
    // Acronyms, the same in every language.
    PrayerCalculationMethod.northAmerica => method.label,
    PrayerCalculationMethod.moonsightingCommittee =>
      l10n.prayerMethodMoonsighting,
    PrayerCalculationMethod.morocco => l10n.prayerMethodMorocco,
    PrayerCalculationMethod.singapore => l10n.prayerMethodSingapore,
    PrayerCalculationMethod.tehran => l10n.prayerMethodTehran,
    PrayerCalculationMethod.turkiye => l10n.prayerMethodTurkey,
    PrayerCalculationMethod.uk18 => method.label,
    PrayerCalculationMethod.custom => l10n.custom,
  };
}

/// Short form of [localizedCalculationMethod] for one-line summaries.
String localizedCalculationMethodShort(
  AppLocalizations l10n,
  PrayerCalculationMethod method,
) {
  return switch (method) {
    PrayerCalculationMethod.auto => l10n.prayerMethodShortAuto,
    PrayerCalculationMethod.muslimWorldLeague => l10n.prayerMethodShortMwl,
    PrayerCalculationMethod.dubai => l10n.prayerMethodShortDubai,
    PrayerCalculationMethod.moonsightingCommittee =>
      l10n.prayerMethodShortMoonsighting,
    PrayerCalculationMethod.turkiye => l10n.prayerMethodShortTurkey,
    _ => localizedCalculationMethod(l10n, method),
  };
}

/// Localized version of `prayerMethodDisplayLabel`.
String localizedPrayerMethodDisplayLabel(
  AppLocalizations l10n, {
  required PrayerTimeSettings settings,
  required PrayerCalculationMethod effectiveMethod,
}) {
  return switch (settings.method) {
    PrayerCalculationMethod.custom => l10n.custom,
    _ => localizedCalculationMethodShort(l10n, effectiveMethod),
  };
}

String localizedAsrMethod(AppLocalizations l10n, PrayerAsrMethod method) {
  return switch (method) {
    PrayerAsrMethod.standard => l10n.standard,
    PrayerAsrMethod.hanafi => l10n.asrMethodHanafi,
  };
}

String localizedHighLatitudeRule(
  AppLocalizations l10n,
  PrayerHighLatitudeRule rule,
) {
  return switch (rule) {
    PrayerHighLatitudeRule.auto => l10n.highLatitudeRuleAutoTitle,
    PrayerHighLatitudeRule.none => l10n.highLatitudeRuleNoneTitle,
    PrayerHighLatitudeRule.middleOfTheNight =>
      l10n.highLatitudeRuleMiddleOfTheNightTitle,
    PrayerHighLatitudeRule.oneSeventh => l10n.highLatitudeRuleOneSeventhTitle,
    PrayerHighLatitudeRule.angleBased => l10n.highLatitudeRuleAngleBasedTitle,
  };
}

/// [PrayerLocation.displayLabel] with the generic "Saved location" fallback in
/// the app language. Only for display: the stored label is never changed.
String localizedLocationLabel(AppLocalizations l10n, PrayerLocation location) {
  final String label = location.displayLabel;
  return label == 'Saved location' ? l10n.savedLocationFallback : label;
}

/// [PrayerLocation.cityLabel] with the same localized fallback.
String localizedCityLabel(AppLocalizations l10n, PrayerLocation location) {
  final String label = localizedLocationLabel(l10n, location);
  final String first = label.split(RegExp('[,،]')).first.trim();
  return first.isEmpty ? label : first;
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
