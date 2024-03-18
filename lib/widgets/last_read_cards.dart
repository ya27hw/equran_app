import 'package:emushaf/home/read.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart';

class LastReadCard extends StatelessWidget {
  final Box box;

  const LastReadCard({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    return ExpandableCarousel.builder(
      itemCount: box.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
        int keySurah = box.keyAt(itemIndex);
        int valueAyah = box.get(keySurah);
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
                      startVerse: box.get(keySurah),
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
                          'Ayah No : $valueAyah',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Section with SVG
                Padding(
                  padding: const EdgeInsets.only(right: 20, top: 5),
                  child: Container(
                    child: SvgPicture.asset('assets/images/quran.svg',
                        colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onSecondaryContainer,
                            BlendMode.srcIn)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      options: CarouselOptions(showIndicator: true, viewportFraction: 1),
    );
  }
}
