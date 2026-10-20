import 'package:equran/backend/settings_db.dart';
import 'package:quran/quran.dart' as quran;

const String quranBasmalaText = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';

// Hoisted so per-verse text lookups don't recompile them on every call
// (the reader builds up to 286 segments per frame in QPC mode).
final RegExp quranBasmalaPrefixPattern = RegExp(
  r'^بِسْمِ\s+اللَّهِ\s+الرَّحْمَ[ٰـ]*نِ\s+الرَّحِيمِ\s*',
);

const Map<String, String> arabicDigitGlyphs = <String, String>{
  '0': '٠',
  '1': '١',
  '2': '٢',
  '3': '٣',
  '4': '٤',
  '5': '٥',
  '6': '٦',
  '7': '٧',
  '8': '٨',
  '9': '٩',
};

String favouriteAyahKey(int chapter, int verse) {
  return '$chapter-${verse.toString().padLeft(3, '0')}';
}

String arabicVerseNumber(int verse) {
  return verse
      .toString()
      .split('')
      .map((digit) => arabicDigitGlyphs[digit] ?? digit)
      .join();
}

String quranVerseText(
  int chapter,
  int verse, {
  bool includeVerseNumber = false,
}) {
  String verseText = quran.getVerse(chapter, verse);
  if (verse == 1 && chapter != 1) {
    verseText = verseText.replaceFirst(quranBasmalaPrefixPattern, '');
  }

  if (!includeVerseNumber) return verseText;
  return '$verseText ${arabicVerseNumber(verse)}';
}

String removeArabicDiacritics(String text) {
  return String.fromCharCodes(
    text.runes.where((int rune) {
      return rune != 0x0640 && !_isArabicDiacriticRune(rune);
    }),
  );
}

int countArabicLetters(String text) {
  int count = 0;
  for (final int rune in removeArabicDiacritics(text).runes) {
    if (_isArabicLetterRune(rune)) {
      count++;
    }
  }
  return count;
}

int quranVerseArabicLetterCount(int chapter, int verse) {
  return countArabicLetters(quranVerseText(chapter, verse));
}

bool _isArabicDiacriticRune(int rune) {
  return (rune >= 0x064B && rune <= 0x065F) ||
      rune == 0x0670 ||
      (rune >= 0x06D6 && rune <= 0x06ED) ||
      (rune >= 0x08D3 && rune <= 0x08FF);
}

bool _isArabicLetterRune(int rune) {
  return (rune >= 0x0621 && rune <= 0x063A) ||
      (rune >= 0x0641 && rune <= 0x064A) ||
      (rune >= 0x066E && rune <= 0x066F) ||
      (rune >= 0x0671 && rune <= 0x06D3) ||
      rune == 0x06D5 ||
      (rune >= 0x06EE && rune <= 0x06EF) ||
      (rune >= 0x06FA && rune <= 0x06FC) ||
      rune == 0x06FF ||
      (rune >= 0x0750 && rune <= 0x077F) ||
      (rune >= 0x08A0 && rune <= 0x08C7);
}

String inlineQuranVerseSegment(int chapter, int verse) {
  final bool includeNumber = SettingsDB().quranScriptStyle != 'qpc-v4';
  return '${quranVerseText(chapter, verse, includeVerseNumber: includeNumber)}  ';
}

double shareArabicFontSizeForText(String verseText) {
  final int ayahLength = verseText.runes.length;
  return switch (ayahLength) {
    <= 80 => 86,
    <= 140 => 74,
    <= 220 => 62,
    <= 360 => 52,
    <= 520 => 42,
    <= 760 => 34,
    <= 980 => 30,
    _ => 26,
  };
}

double shareTranslationFontSizeForText(String verseText) {
  final int ayahLength = verseText.runes.length;
  return switch (ayahLength) {
    <= 140 => 26,
    <= 360 => 23,
    <= 760 => 18,
    <= 980 => 16,
    _ => 15,
  };
}
