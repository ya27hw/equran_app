import 'package:emushaf/backend/surah_model.dart';
import 'package:emushaf/home/read.dart';
import 'package:flutter/material.dart';

class QuranCard extends StatelessWidget {
  final Surah surah;
  const QuranCard({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 270));
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ReadPage(
                    chapter: surah.id,
                  )));
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                surah.transliteration,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                surah.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),

          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                surah.englishName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                "${surah.verses} Verses",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          //
        ),
      ),
    );
  }
}
