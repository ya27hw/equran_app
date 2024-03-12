import 'package:flutter/material.dart';

class ReadQuranCard extends StatelessWidget {
  final int currentChapter;
  final int currentVerse;
  final int totalVerses;
  final int juzNumber;

  final String translation;
  final String verse;
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
                  "Juz' $juzNumber • $currentVerse/$totalVerses",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            basmala != null
                ? Text(basmala!,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 2.3,
                        fontFamily: 'Hafs',
                        fontSize: fontSize))
                : const SizedBox(),
            Text(
              verse,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Hafs',
                height: 2,
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
