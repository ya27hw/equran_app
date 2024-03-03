import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;


class ReadQuranCard extends StatelessWidget {
  final int currentChapter;
  final int currentVerse;
  final int totalVerses;
  ReadQuranCard({super.key, required this.currentChapter, required this.currentVerse, required this.totalVerses});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(
          horizontal: 15, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Juz ${quran.getJuzNumber(currentChapter, currentVerse)}",                             style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "$currentVerse/$totalVerses",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(
              height: 10,
            ),
            currentChapter != 1 &&
                currentVerse == 1 &&
                currentChapter != 9
                ? const Text(quran.basmala,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 2.3,
                    fontFamily: 'Hafs',
                    fontSize: 40))
                : const SizedBox(),
            Text(
              quran.getVerse(
                currentChapter,
                currentVerse,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                  fontFamily: 'Hafs',
                  height: 2.2,
                  fontSize: 38,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              quran.getVerseTranslation(
                currentChapter,
                currentVerse,
                translation: quran.Translation.enSaheeh,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          ],
        ),
      ),
    );
  }
}

