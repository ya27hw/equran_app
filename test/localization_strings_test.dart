import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keys that replaced hard-coded English strings (the "legacy English-only"
/// list in docs/redesign/CODEX_FOLLOWUP.md). They are machine-drafted in every
/// locale except English and wait for native-speaker review.
const List<String> _localizedLegacyKeys = <String>[
  'hifzRatingFail',
  'hifzRatingPass',
  'shareImageFormat',
  'shareFormatStory',
  'shareFormatSquare',
  'shareFormatClassic',
  'unableToShareAyahImage',
  'reciterGroupDownloaded',
  'reciterShowAlphabetical',
  'audioConnectionInterrupted',
  'offlineDownloadAyahOrReconnect',
  'unableToPlayAyahAudio',
  'repeatOnce',
  'repeatTimes',
  'repeatInfinite',
  'halfSecond',
  'resourceStateUpdateAvailable',
  'resourcePhaseStarting',
  'resourcePhaseVerifying',
  'resourcePhaseExtracting',
  'resourcePhaseInstalling',
  'resourcePhaseFailed',
  'resourceTypeGeneric',
  'translationBundled',
  'translationDownloadUnavailable',
  'navigationSettingsHint',
  'navigationActiveSlots',
  'navigationAvailableItems',
  'navigationSlot',
  'navigationSlotLocked',
  'navigationSwapped',
  'navigationRemoved',
  'navigationPinned',
  'navigationPinnedDisplaced',
  'navSubtitleHome',
  'navSubtitleQuran',
  'navSubtitlePrayer',
  'navSubtitleSettings',
  'dockZakat',
  'dockCalendar',
  'downloadsReciterCount',
  'downloadsItemCount',
  'downloadsDeleteReciterBody',
  'downloadsAllSurahs',
  'downloadsFilterTitle',
  'downloadsFilterSubtitle',
  'downloadsFilterSearchHint',
  'downloadsGroupBy',
  'downloadsSortBy',
  'downloadsCategory',
  'downloadsContentType',
  'downloadsSortReciterAsc',
  'downloadsSortReciterDesc',
  'downloadsSortSizeDesc',
  'downloadsSortSizeAsc',
  'downloadsSortSurahAsc',
  'downloadsSortSurahDesc',
  'offsetSetPositive',
  'offsetSetNegative',
  'notificationPermissionCheckTimedOut',
  'notificationPermissionCheckFailed',
  'exactAlarmPermissionCheckTimedOut',
  'exactAlarmPermissionCheckFailed',
  'asrMethodHanafi',
  'highLatitudeRuleAutoTitle',
  'highLatitudeRuleNoneTitle',
  'highLatitudeRuleMiddleOfTheNightTitle',
  'highLatitudeRuleOneSeventhTitle',
  'highLatitudeRuleAngleBasedTitle',
  'prayerMethodAuto',
  'prayerMethodMuslimWorldLeague',
  'prayerMethodEgyptian',
  'prayerMethodUmmAlQura',
  'prayerMethodDubai',
  'prayerMethodKuwait',
  'prayerMethodQatar',
  'prayerMethodKarachi',
  'prayerMethodMoonsighting',
  'prayerMethodMorocco',
  'prayerMethodSingapore',
  'prayerMethodTehran',
  'prayerMethodTurkey',
  'prayerMethodShortAuto',
  'prayerMethodShortMwl',
  'prayerMethodShortDubai',
  'prayerMethodShortMoonsighting',
  'prayerMethodShortTurkey',
  'dailyToolsKeepOnePinned',
];

/// Locales where the proper name or acronym is correctly the same as English
/// (for example "Kuwait" in German). Everything else must be translated.
const Map<String, Set<String>> _sameAsEnglishOk = <String, Set<String>>{
  'shareFormatStory': <String>{'de', 'id', 'tr'},
  'navigationSlot': <String>{'id'},
  'dockZakat': <String>{'de', 'id'},
  'asrMethodHanafi': <String>{'id'},
  'prayerMethodUmmAlQura': <String>{'de', 'id'},
  'prayerMethodKuwait': <String>{'de', 'id'},
  'prayerMethodQatar': <String>{'id'},
  'prayerMethodKarachi': <String>{'id'},
  'prayerMethodShortMwl': <String>{'bn', 'de', 'fa', 'id', 'tr', 'ur'},
  'prayerMethodShortDubai': <String>{'de', 'id', 'tr'},
};

const List<String> _locales = <String>[
  'ar',
  'bn',
  'de',
  'en',
  'fa',
  'id',
  'tr',
  'ur',
];

Map<String, dynamic> _arb(String locale) {
  final Object? decoded = jsonDecode(
    File('lib/l10n/app_$locale.arb').readAsStringSync(),
  );
  return (decoded as Map<dynamic, dynamic>).cast<String, dynamic>();
}

/// Names of the ICU arguments a message uses, including the `count` of a
/// plural. Nested plural bodies re-use the same names, so a set is enough.
Set<String> _arguments(String message) {
  final Set<String> names = <String>{};
  for (final RegExpMatch match in RegExp(
    r'\{\s*(\w+)\s*[,}]',
  ).allMatches(message)) {
    names.add(match.group(1)!);
  }
  return names;
}

void main() {
  final Map<String, Map<String, dynamic>> arbs = <String, Map<String, dynamic>>{
    for (final String locale in _locales) locale: _arb(locale),
  };
  final Map<String, dynamic> english = arbs['en']!;

  test('every locale defines every template key', () {
    final Set<String> template = english.keys
        .where((String key) => !key.startsWith('@'))
        .toSet();
    for (final String locale in _locales) {
      final Set<String> keys = arbs[locale]!.keys
          .where((String key) => !key.startsWith('@'))
          .toSet();
      expect(
        template.difference(keys),
        isEmpty,
        reason: '$locale is missing keys',
      );
      expect(
        keys.difference(template),
        isEmpty,
        reason: '$locale has keys the template lacks',
      );
    }
  });

  test('placeholders and metadata live only in the English template', () {
    for (final String locale in _locales.where((String l) => l != 'en')) {
      final List<String> metadata = arbs[locale]!.keys
          .where((String key) => key.startsWith('@'))
          .where((String key) => key != '@@locale')
          .where(
            (String key) => _localizedLegacyKeys.contains(key.substring(1)),
          )
          .toList();
      expect(metadata, isEmpty, reason: '$locale must not carry @metadata');
    }
  });

  group('strings that replaced hard-coded English', () {
    for (final String key in _localizedLegacyKeys) {
      test(key, () {
        final Object? template = english[key];
        expect(template, isA<String>(), reason: '$key missing from app_en.arb');
        final String englishText = template! as String;
        expect(englishText.trim(), isNotEmpty);
        final Set<String> englishArguments = _arguments(englishText);
        for (final String locale in _locales.where((String l) => l != 'en')) {
          final Object? value = arbs[locale]![key];
          expect(value, isA<String>(), reason: '$key missing in $locale');
          final String text = value! as String;
          expect(text.trim(), isNotEmpty, reason: '$key is empty in $locale');
          expect(
            _arguments(text),
            englishArguments,
            reason: '$key changes the placeholders in $locale',
          );
          if (!(_sameAsEnglishOk[key]?.contains(locale) ?? false)) {
            expect(
              text,
              isNot(englishText),
              reason: '$key is still the English text in $locale',
            );
          }
        }
      });
    }
  });
}
