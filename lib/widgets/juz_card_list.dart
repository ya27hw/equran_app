import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import 'juz_card.dart';

class JuzCardList extends StatefulWidget {
  @override
  _JuzCardListState createState() => _JuzCardListState();
}

class _JuzCardListState extends State<JuzCardList>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: 30,
      itemBuilder: (BuildContext context, int index) {
        final juz = quran.getSurahAndVersesFromJuz(index + 1);
        int totalVerses = 0;

        final juzCards = juz.entries.map((entry) {
          totalVerses += (entry.value.last - entry.value.first + 1);
          final transliteration = quran.getSurahName(entry.key);
          final name = quran.getSurahNameArabic(entry.key);
          return QuranJuzTile(
            id: entry.key,
            transliteration: transliteration,
            name: name,
            startVerse: entry.value[0],
            endVerse: entry.value[1],
          );
        }).toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 10,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Juz' ${index + 1}",
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                ),
                const Divider(),
                ...juzCards,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
