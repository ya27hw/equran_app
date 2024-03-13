import 'package:emushaf/backend/favourites_db.dart';
import 'package:emushaf/home/read.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

var allKeys = FavouritesDB().getKeys().toList();

class FavouritesList extends StatefulWidget {
  FavouritesList({super.key});

  @override
  State<FavouritesList> createState() => _FavouritesListState();
}

class _FavouritesListState extends State<FavouritesList> {
  Future<void> _onRefresh() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 400));
    // if failed,use refreshFailed()
    setState(() {
      allKeys = FavouritesDB().getKeys().toList();
      allKeys.sort();
    });
    print(allKeys);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: allKeys.length,
        itemBuilder: (BuildContext context, int index) {
          final String key = allKeys[index];

          final List<String> surahAndVerse = key.split("-");
          final surah = int.parse(surahAndVerse.first);
          final verse = int.parse(surahAndVerse.last);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ReadPage(
                          chapter: surah,
                          startVerse: verse,
                        )));
              },
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ListTile(
                    title: Text(quran.getSurahName(surah)),
                    subtitle: Text("Verse $verse"),
                    trailing: Text(
                      quran.getSurahNameArabic(surah),
                      style: Theme.of(context).textTheme.bodyLarge,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }
}
