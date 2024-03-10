import 'package:emushaf/utils/debouncer.dart';
import 'package:emushaf/widgets/quran_card.dart';
import 'package:emushaf/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../utils/surah.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _searchQuery = '';
  final debouncer = Debouncer(milliseconds: 200);

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
              pinned: true,
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
                        "eQuran",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
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
              // Container(
              //   margin: const EdgeInsets.only(left: 20),
              //   child: Align(
              //     alignment: Alignment.centerLeft,
              //     child: Text(
              //       "Continue Reading :",
              //       textAlign: TextAlign.left,
              //       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              //           fontWeight: FontWeight.bold,
              //           color:
              //               Theme.of(context).colorScheme.onSecondaryContainer),
              //     ),
              //   ),
              // ),
              // const SizedBox(
              //   height: 10,
              // ),
              // SizedBox(
              //   height: 70,
              //   child: ListView(
              //     clipBehavior: Clip.none,
              //     shrinkWrap: true,
              //     scrollDirection: Axis.horizontal,
              //     children: const [
              //       LastReadCard(),
              //       LastReadCard(),
              //       LastReadCard(),
              //       LastReadCard(),
              //       LastReadCard(),
              //     ],
              //   ),
              // ),
              // const SizedBox(
              //   height: 20,
              // ),
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
              FutureBuilder(
                future: _fetchSurahs(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Surah>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 50),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    List<Surah> data = snapshot.data!;
                    return ListView.builder(
                      itemCount: data.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        Surah surah = data[index];
                        final isMatching = _searchQuery.isEmpty ||
                            surah.transliteration
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            surah.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            surah.id.toString() == _searchQuery;
                        return isMatching
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: QuranCard(
                                  surah: data[index],
                                ),
                              )
                            : Container();
                      },
                    );
                  }
                },
              )
            ]))
          ],
        ),
      ),
    );
  }

  void _changeSearchQuery(String value) {
    debouncer.call(() {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  Future<List<Surah>> _fetchSurahs() async {
    final surahs = <Surah>[];
    for (int i = 1; i <= 114; i++) {
      final transliteration = quran.getSurahName(i);
      final name = quran.getSurahNameArabic(i);
      final verses = quran.getVerseCount(i);
      surahs.add(Surah(
          id: i, transliteration: transliteration, name: name, verses: verses));
      await Future.delayed(
          const Duration(milliseconds: 5)); // Adjust delay as needed
    }
    return surahs;
  }
}
