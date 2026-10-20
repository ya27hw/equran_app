import 'package:equran/l10n/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

bool isArabicLocalizations(AppLocalizations localizations) {
  final String code = localizations.localeName.split('_').first.toLowerCase();
  return code == 'ar' || code == 'fa';
}

String localizedSurahName(AppLocalizations localizations, int surah) {
  final String code = localizations.localeName.split('_').first.toLowerCase();
  if (code == 'ar' || code == 'fa') {
    return quran.getSurahNameArabic(surah);
  } else if (code == 'tr') {
    return quran.getSurahNameTurkish(surah);
  }
  return quran.getSurahName(surah);
}

String localizedSurahAyahLabel(
  AppLocalizations localizations,
  int surah,
  int ayah,
) {
  return localizations.surahLabel(
    localizedSurahName(localizations, surah),
    ayah,
  );
}

String localizedAyahReference(AppLocalizations localizations, int ayah) {
  return localizations.ayahNumber(ayah);
}

String localizedJuzLabel(AppLocalizations localizations, int juz) {
  return localizations.juzNumber(juz);
}
