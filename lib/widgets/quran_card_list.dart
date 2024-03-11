import 'package:emushaf/backend/surah_model.dart';
import 'package:emushaf/utils/surah_db.dart';
import 'package:emushaf/widgets/quran_card.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class QuranCardList extends StatelessWidget {
  final String searchQuery;
  const QuranCardList({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchSurahs(),
      builder: (BuildContext context, AsyncSnapshot<List<Surah>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 50),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          final data = snapshot.data!;
          return ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: data.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              Surah surah = data[index];

              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: QuranCard(
                  surah: data[index],
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<List<Surah>> _fetchSurahs() async {
    if (SurahDB().contains("surahsList")) {
      var cachedData = SurahDB().get("surahsList");
      if (cachedData is List) {
        return cachedData.cast<Surah>();
      } else {
        throw Exception("Cached data is not valid");
      }
    }

    final surahs = <Surah>[];
    for (int i = 1; i <= 114; i++) {
      final transliteration = quran.getSurahName(i);
      final name = quran.getSurahNameArabic(i);
      final verses = quran.getVerseCount(i);
      final isMatching = searchQuery.isEmpty ||
          transliteration.toLowerCase().contains(searchQuery.toLowerCase()) ||
          name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          i.toString() == searchQuery;
      if (isMatching) {
        surahs.add(Surah(
            id: i,
            transliteration: transliteration,
            verses: verses,
            name: name));
      }
    }
    await SurahDB().set("surahsList", surahs);
    return surahs;
  }
}
