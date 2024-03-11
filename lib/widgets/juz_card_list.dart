import 'package:emushaf/backend/surah_model.dart';
import 'package:emushaf/widgets/quran_card.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class JuzCardList extends StatefulWidget {
  @override
  _JuzCardListState createState() => _JuzCardListState();
}

class _JuzCardListState extends State<JuzCardList> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: 30,
      itemBuilder: (BuildContext context, int index) {
        final juz = quran.getSurahAndVersesFromJuz(index + 1);

        final juzCards = juz.entries.map((entry) {
          final surahName = quran.getSurahName(entry.key);
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: QuranCard(
              endVerse: entry.value[1],
              surah: Surah(
                id: entry.key,
                transliteration: surahName,
                name: "",
                verses: entry.value[0],
              ),
            ),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10,),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: Text("Juz ${index + 1}"),
            ),
            Divider(),
            ...juzCards,
          ],
        );
      },
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
