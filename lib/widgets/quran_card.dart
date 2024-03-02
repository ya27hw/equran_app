import 'package:flutter/material.dart';

import '../home/read.dart';

class QuranCard extends StatelessWidget {
  final int index;
  final String transliteration;
  final String name;
  final int verses;
  const QuranCard({
    super.key,
    required this.index,
    required this.transliteration,
    required this.name,
    required this.verses,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 120));
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ReadPage(chapter: index)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
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
                      child: Text("$index",
                          style: Theme.of(context).textTheme.titleMedium))),
            ),
            title: Text(
              "Surah $transliteration",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Text(
              "سوﺭة $name",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              "$verses Ayahs",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // Add leading/trailing icons, subtitle, etc. for further customization
          ),
        ),
      ),
    );
    ;
  }
}
