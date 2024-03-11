import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class ReadQuranCard extends StatelessWidget {
  final int currentChapter;
  final int currentVerse;
  final int totalVerses;
  final double fontSize;
  const ReadQuranCard({
    super.key,
    required this.currentChapter,
    required this.currentVerse,
    required this.totalVerses,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Get the size of the screen
    Size screenSize = MediaQuery.of(context).size;

    // Define margin values for different screen sizes
    double marginValue;
    if (screenSize.width > 1200) {
      marginValue = 90.0; // Large screen
    } else if (screenSize.width > 700) {
      marginValue = 40.0; // Medium screen
    } else {
      marginValue = 8.0; // Small screen
    }
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: marginValue, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Juz ${quran.getJuzNumber(currentChapter, currentVerse)} • $currentVerse/$totalVerses",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            currentChapter != 1 && currentVerse == 1 && currentChapter != 9
                ? Text(quran.basmala,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 2.3,
                        fontFamily: 'Hafs',
                        fontSize: fontSize))
                : const SizedBox(),
            Text(
              quran.getVerse(
                currentChapter,
                currentVerse,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Hafs',
                height: 2,
                fontSize: fontSize,
              ),
            ),
            Text(
              quran.getVerseTranslation(
                currentChapter,
                currentVerse,
                translation: quran.Translation.enSaheeh,
              ),
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
