import 'package:emushaf/backend/surah_model.dart';
import 'package:emushaf/utils/surah_db.dart';
import 'package:emushaf/widgets/quran_card.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class QuranCardList extends StatefulWidget {
  final String searchQuery;

  const QuranCardList({super.key, required this.searchQuery});

  @override
  _QuranCardListState createState() => _QuranCardListState();
}

class _QuranCardListState extends State<QuranCardList>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            physics: const BouncingScrollPhysics(),
            itemCount: data.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              Surah surah = data[index];

              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: QuranCard(
                  surah: surah,
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
      final isMatching = widget.searchQuery.isEmpty ||
          transliteration
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase()) ||
          name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          i.toString() == widget.searchQuery;
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

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
