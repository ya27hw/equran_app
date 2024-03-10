import 'package:emushaf/utils/surah.dart';
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
      builder: (BuildContext context,
          AsyncSnapshot<List<Surah>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 50),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          List<Surah> data = snapshot.data!;
          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: data.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              Surah surah = data[index];
              final isMatching = searchQuery.isEmpty ||
                  surah.transliteration
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  surah.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  surah.id.toString() == searchQuery;
              return isMatching
                  ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: QuranCard(
                  surah: data[index],
                ),
              )
                  : Container();
            },
          );
        }
      },
    );
  }

  Future<List<Surah>> _fetchSurahs() async {
    final surahs = <Surah>[];

    for (int i = 1; i <= 114; i++) {
      final transliteration = quran.getSurahName(i);
      final name = quran.getSurahNameArabic(i);
      final verses = quran.getVerseCount(i);
      surahs.add(Surah(
          id: i, transliteration: transliteration, name: name, verses: verses));
      await Future.delayed(const Duration(milliseconds: 1));
    }

    return surahs;
  }
}
