import 'package:emushaf/backend/favourites_db.dart';
import 'package:emushaf/widgets/library.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';

class ReadQuranCard extends StatelessWidget {
  final int currentChapter;
  final int currentVerse;
  final int totalVerses;
  final int juzNumber;

  final String translation;
  final String verse;
  final String url;
  final String? basmala;

  final double fontSize;

  const ReadQuranCard({
    super.key,
    required this.currentChapter,
    required this.currentVerse,
    required this.totalVerses,
    required this.fontSize,
    required this.juzNumber,
    required this.translation,
    this.basmala,
    required this.verse,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    // Get the size of the screen
    Size screenSize = MediaQuery.of(context).size;

    // Define margin values for different screen sizes
    double marginValue;
    if (screenSize.width > 1500) {
      marginValue = 150;
    }
    if (screenSize.width > 1200) {
      marginValue = 120.0; // Large screen
    } else if (screenSize.width > 700) {
      marginValue = 40.0; // Medium screen
    } else {
      marginValue = 8.0; // Small screen
    }
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: marginValue, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PlayButton(
                  url: url,
                ),
                Text(
                  "Juz' $juzNumber • $currentVerse/$totalVerses",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                LikeButton(
                  isLiked: FavouritesDB().contains(
                      "$currentChapter-${currentVerse.toString().padLeft(3, "0")}"),
                  onTap: (bool isLiked) async {
                    if (!isLiked) {
                      FavouritesDB().put(
                          "$currentChapter-${currentVerse.toString().padLeft(3, "0")}",
                          true);
                    } else {
                      FavouritesDB().delete(
                          "$currentChapter-${currentVerse.toString().padLeft(3, "0")}");
                    }
                    return !isLiked;
                  },
                )
              ],
            ),
            basmala != null
                ? Text(basmala!,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 2,
                        fontFamily: 'Hafs',
                        fontSize: fontSize))
                : const SizedBox(),
            Text(
              verse,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Hafs',
                height: 1.65,
                fontSize: fontSize,
              ),
            ),
            Text(
              translation,
              textAlign: TextAlign.justify,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: fontSize / 2.55),
            )
          ],
        ),
      ),
    );
  }
}
