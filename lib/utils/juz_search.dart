import 'package:quran/quran.dart' as quran;

class JuzGroup {
  const JuzGroup({
    required this.juzNumber,
    required this.arabicName,
    required this.entries,
  });

  final int juzNumber;
  final String arabicName;
  final List<JuzEntry> entries;
}

const List<String> arabicJuzNamesWithTashkil = <String>[
  'الم',
  'سَيَقُولُ',
  'تِلْكَ الرُّسُلُ',
  'لَنْ تَنَالُوا',
  'وَالْمُحْصَنَاتُ',
  'لَا يُحِبُّ اللَّهُ',
  'وَإِذَا سَمِعُوا',
  'وَلَوْ أَنَّنَا',
  'قَالَ الْمَلَأُ',
  'وَاعْلَمُوا',
  'يَعْتَذِرُونَ',
  'وَمَا مِنْ دَابَّةٍ',
  'وَمَا أُبَرِّئُ',
  'رُبَمَا',
  'سُبْحَانَ الَّذِي',
  'قَالَ أَلَمْ',
  'اقْتَرَبَ',
  'قَدْ أَفْلَحَ',
  'وَقَالَ الَّذِينَ',
  'أَمَّنْ خَلَقَ',
  'اتْلُ مَا أُوحِيَ',
  'وَمَنْ يَقْنُتْ',
  'وَمَا لِيَ',
  'فَمَنْ أَظْلَمُ',
  'إِلَيْهِ يُرَدُّ',
  'حم',
  'قَالَ فَمَا خَطْبُكُمْ',
  'قَدْ سَمِعَ',
  'تَبَارَكَ الَّذِي',
  'عَمَّ',
];

String arabicJuzNameWithTashkil(int juzNumber) {
  return arabicJuzNamesWithTashkil[juzNumber - 1];
}

class JuzEntry {
  const JuzEntry({
    required this.surahId,
    required this.transliteration,
    required this.name,
    required this.startVerse,
    required this.endVerse,
  });

  final int surahId;
  final String transliteration;
  final String name;
  final int startVerse;
  final int endVerse;

  bool matches(String query, int juzNumber) {
    final String normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return juzNumber.toString() == normalized ||
        juzNumber.toString().startsWith(normalized) ||
        transliteration.toLowerCase().contains(normalized) ||
        name.contains(query);
  }
}

List<JuzGroup> buildJuzGroups(String searchQuery) {
  final String query = searchQuery.trim().toLowerCase();
  final List<JuzGroup> groups = <JuzGroup>[];

  for (int juzNumber = 1; juzNumber <= 30; juzNumber++) {
    final String arabicName = arabicJuzNameWithTashkil(juzNumber);
    final bool juzHeaderMatches =
        query.isNotEmpty &&
        (juzNumber.toString() == query ||
            juzNumber.toString().startsWith(query) ||
            arabicName.contains(searchQuery.trim()));
    final Map<int, List<int>> juz = quran.getSurahAndVersesFromJuz(juzNumber);
    final List<JuzEntry> entries = <JuzEntry>[];

    juz.forEach((surahId, verses) {
      final JuzEntry entry = JuzEntry(
        surahId: surahId,
        transliteration: quran.getSurahName(surahId),
        name: quran.getSurahNameArabic(surahId),
        startVerse: verses[0],
        endVerse: verses[1],
      );

      if (query.isEmpty ||
          juzHeaderMatches ||
          entry.matches(query, juzNumber)) {
        entries.add(entry);
      }
    });

    if (entries.isNotEmpty) {
      groups.add(
        JuzGroup(
          juzNumber: juzNumber,
          arabicName: arabicName,
          entries: entries,
        ),
      );
    }
  }

  return groups;
}
