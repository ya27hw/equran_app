import 'package:emushaf/widgets/last_read_cards.dart';
import 'package:emushaf/widgets/quran_card.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../widgets/search.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  int _selectedIndex = 0;
  List<Widget> pages = <Widget>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("eMushaf"),
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.menu),
        ),
      ),
      body: ListView(
        // scrollDirection: Axis.vertical,
        physics: BouncingScrollPhysics(),
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(left: 30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recently Read",
                textAlign: TextAlign.left,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
              children: [
                LastReadCard(),
                LastReadCard(),
                LastReadCard(),
                // LastReadCard(),
                // LastReadCard(),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Container(
            margin: const EdgeInsets.only(left: 30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Find Surah",
                textAlign: TextAlign.left,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          MySearchBar(
            onChanged: (value) {
              _changeSearchQuery(value);
            },
          ),
          const SizedBox(
            height: 30,
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: QuranCard(
                  index: id,
                  transliteration: transliteration,
                  name: name,
                  verses: verses,
                ),
              );
            },
          )
        ],
      ),
    );
  }

  void _changeSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
