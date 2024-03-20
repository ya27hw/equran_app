import 'dart:math';

import 'package:emushaf/backend/library.dart';
import 'package:emushaf/home/read.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quran/quran.dart';

class LastReadCard extends StatelessWidget {
  const LastReadCard({super.key});

  List displayReadingHistory() {
    return BookmarkDB().getKeys().toList()
      ..sort((a, b) {
        var firstEntry = BookmarkDB().get(a) as ReadingEntry;
        var secondEntry = BookmarkDB().get(b) as ReadingEntry;
        return secondEntry.timestamp.compareTo(firstEntry.timestamp);
      });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double viewportFraction = 1;
    const double threshold = 450.0;

    if (width > threshold) {
      double scaledWidth = (width - threshold) / 900;
      viewportFraction = 1.0 * exp(-scaledWidth);
    } else {
      viewportFraction = 1;
    }

    List keys = displayReadingHistory();
    return ExpandableCarousel.builder(
      itemCount: keys.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
        int keySurah = keys[itemIndex];
        ReadingEntry entry = BookmarkDB().get(keySurah);
        int verse = entry.verse;
        DateTime timeRead = entry.timestamp;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          elevation: 2,
          color: Theme.of(context).colorScheme.secondaryContainer,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ReadPage(
                      chapter: keySurah,
                      startVerse: verse,
                    ))),
            child: Row(
              children: <Widget>[
                // Left Section with Text and Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Last Read',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          getSurahName(keySurah),
                          // Replace with actual Surah name
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Ayah No : $verse',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Section with SVG
                Padding(
                  padding: const EdgeInsets.only(right: 20, top: 5),
                  child: SvgPicture.asset('assets/images/quran.svg',
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSecondaryContainer,
                          BlendMode.srcIn)),
                ),
              ],
            ),
          ),
        );
      },
      options: CarouselOptions(
          showIndicator: true,
          viewportFraction: viewportFraction,
          initialPage: 0),
    );
  }
}