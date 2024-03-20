import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:emushaf/backend/surah_db.dart';
import 'package:emushaf/backend/surah_model.dart';
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
    dynamic width = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (width > 650) {
      crossAxisCount = 2;
    }
    if (width > 1300) {
      crossAxisCount = 3;
    }

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
          return DynamicHeightGridView(
            physics: const BouncingScrollPhysics(),
            itemCount: data.length,
            shrinkWrap: true,
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            builder: (BuildContext context, int index) {
              Surah surah = data[index];

              return QuranCard(
                surah: surah,
              );
            },
          );
        }
      },
    );
  }

  Future<List<Surah>> _fetchSurahs() async {
    List<Surah> surahs = <Surah>[];
    if (SurahDB().contains("surahsList")) {
      var cachedData = SurahDB().get("surahsList");
      if (cachedData is List) {
        surahs = cachedData.cast<Surah>();
      } else {
        throw Exception("Cached data is not valid");
      }
    } else {
      for (int i = 1; i <= 114; i++) {
        final transliteration = quran.getSurahName(i);
        final name = quran.getSurahNameArabic(i);
        final verses = quran.getVerseCount(i);
        final englishName = quran.getSurahNameEnglish(i);

        surahs.add(Surah(
            id: i,
            transliteration: transliteration,
            verses: verses,
            name: name,
            englishName: englishName));
      }
      await SurahDB().put("surahsList", surahs);
    }
    if (widget.searchQuery.isEmpty) {
      return surahs;
    } else {
      return surahs
          .where((surah) =>
              surah.name
                  .toLowerCase()
                  .contains(widget.searchQuery.toLowerCase()) ||
              surah.transliteration
                  .toLowerCase()
                  .contains(widget.searchQuery.toLowerCase()) ||
              surah.id.toString() == widget.searchQuery)
          .toList();
    }
  }

  @override
  bool get wantKeepAlive => true;
}