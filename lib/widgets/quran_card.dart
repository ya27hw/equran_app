import 'package:emushaf/backend/surah_model.dart';
import 'package:flutter/material.dart';

import '../home/read.dart';

class QuranCard extends StatelessWidget {
  final Surah surah;
  final int? endVerse;
  const QuranCard({super.key, required this.surah, this.endVerse});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () async {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ReadPage(
                  chapter: surah.id,
                  startVerse: endVerse != null ? surah.verses : 1)));
        },
        child: ListTile(
          leading: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                  child: Text(surah.id.toString(),
                      style: Theme.of(context).textTheme.titleSmall))),
          title: Text(
            surah.transliteration,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: Text(
            surah.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: endVerse != null
              ? Text(
                  "Ayahs: ${surah.verses} - $endVerse",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Text(
                  "${surah.verses} Ayahs",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          // Add leading/trailing icons, subtitle, etc. for further customization
        ),
      ),
    );
  }
}
