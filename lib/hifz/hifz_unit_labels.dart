import 'package:equran/hifz/models/hifz_unit.dart';
import 'package:equran/l10n/app_localizations.dart';

/// Screen label for a Hifz unit. Surahs keep the transliterated name from
/// `HifzSurahData`; a juz uses the localized "Juz {number}" (the model's own
/// [HifzUnit.displayName] is English only and is kept for logs and tests).
String hifzUnitLabel(HifzUnit unit, AppLocalizations l10n) {
  return unit.type == HifzUnitType.juz
      ? l10n.juzNumber(unit.unitNumber)
      : unit.displayName;
}
