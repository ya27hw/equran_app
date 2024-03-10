import 'package:flutter/material.dart';

import '../home/read.dart';
import '../utils/surah.dart';

class QuranCard extends StatelessWidget {
  final Surah surah;
  const QuranCard({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 120));
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ReadPage(chapter: surah.id)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                      child: Text("${surah.id}",
                          style: Theme.of(context).textTheme.titleMedium))),
            ),
            title: Text(
              "${surah.transliteration}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Text(
              "سوﺭة ${surah.name}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              "${surah.verses} Ayahs",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // Add leading/trailing icons, subtitle, etc. for further customization
          ),
        ),
      ),
    );
  }
}
