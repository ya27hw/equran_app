import 'package:eQuran/home/read.dart';
import 'package:flutter/material.dart';

class QuranJuzTile extends StatelessWidget {
  final String transliteration;
  final String name;
  final int id;
  final int startVerse;
  final int endVerse;
  const QuranJuzTile(
      {super.key,
      required this.transliteration,
      required this.startVerse,
      required this.endVerse,
      required this.id,
      required this.name});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Future.delayed(
            const Duration(milliseconds: 270)); // Adjust as needed
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                ReadPage(chapter: id, startVerse: startVerse, juzMode: true)));
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
                  child: Text(id.toString(),
                      style: Theme.of(context).textTheme.titleSmall))),
          title: Text(
            transliteration,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Verses:",
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                "$startVerse-$endVerse",
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          )

          // Add leading/trailing icons, subtitle, etc. for further customization
          ),
    );
  }
}
