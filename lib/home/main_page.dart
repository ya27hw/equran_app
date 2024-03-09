import 'package:emushaf/widgets/last_read_cards.dart';
import 'package:emushaf/widgets/quran_card.dart';
import 'package:emushaf/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _searchQuery = '';
  // bool _isReversed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverAppBar(
              iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              elevation: 2,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30))),
              pinned: false,
              floating: false,
              expandedHeight: 200,
              centerTitle: true,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "eMushaf",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 50,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      MySearchBar(
                        onChanged: (value) {
                          _changeSearchQuery(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
                delegate: SliverChildListDelegate(<Widget>[
              const SizedBox(
                height: 25,
              ),
              Container(
                margin: const EdgeInsets.only(left: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Continue Reading :",
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 70,
                child: ListView(
                  clipBehavior: Clip.none,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: const [
                    LastReadCard(),
                    LastReadCard(),
                    LastReadCard(),
                    LastReadCard(),
                    LastReadCard(),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                margin: const EdgeInsets.only(left: 30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Surahs",
                    textAlign: TextAlign.left,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                // Number of Surahs
                itemCount: 114,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  int index = i + 1;
                  final transliteration = quran.getSurahName(index);
                  final name = quran.getSurahNameArabic(index);
                  final verses = quran.getVerseCount(index);
                  final id = index;

                  if (_searchQuery.isNotEmpty &&
                      !transliteration.toLowerCase().contains(_searchQuery) &&
                      !name.toLowerCase().contains(_searchQuery)) {
                    return const SizedBox
                        .shrink(); // Hide the item if it doesn't match the search query
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: QuranCard(
                      index: id,
                      transliteration: transliteration,
                      name: name,
                      verses: verses,
                    ),
                  );
                },
              )
            ]))
          ],
        ),
      ),
    );
  }

  void _changeSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
    });
  }
}
