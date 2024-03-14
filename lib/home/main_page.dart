import 'package:emushaf/backend/library.dart';
import 'package:emushaf/utils/debouncer.dart';
import 'package:emushaf/widgets/library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' show getSurahName;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final debouncer = Debouncer(milliseconds: 700);
  final List<Tab> _tabs = const [
    Tab(text: 'SURAH'),
    Tab(text: 'JUZ\''),
    Tab(
      icon: Icon(Icons.favorite_border_rounded),
    )
  ];
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkDB>(
      builder: (BuildContext context, BookmarkDB value, Widget? child) {
        return SafeArea(
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) => <Widget>[
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
                expandedHeight: 150,
                centerTitle: true,
                title: innerBoxIsScrolled
                    ? GestureDetector(
                        onTap: () {
                          _scrollController.animateTo(
                              _scrollController.position.minScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut);
                        },
                        child: const Text("eQuran"))
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(
                        height: 5,
                      ),
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
                        height: 30,
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
              value.lastRead == "0-0"
                  ? const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    )
                  : SliverToBoxAdapter(
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        elevation: 1,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          children: <Widget>[
                            // Left Section with Text and Button
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Last Read',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(
                                      getSurahName(
                                          int.parse(value.lastRead[0])),
                                      // Replace with actual Surah name
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      'Ayah No : 2',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Right Section with SVG
                            Padding(
                              padding: const EdgeInsets.only(right: 20, top: 5),
                              child: Container(
                                child: SvgPicture.asset(
                                    'assets/images/quran.svg',
                                    colorFilter: ColorFilter.mode(
                                        Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        BlendMode.srcIn)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              SliverPersistentHeader(
                pinned: false,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    splashBorderRadius: BorderRadius.circular(30),
                    dividerHeight: 2,
                    controller: _tabController,
                    tabs: _tabs,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                QuranCardList(searchQuery: _searchQuery),
                JuzCardList(),
                const FavouritesList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changeSearchQuery(String value) {
    debouncer.call(() {
      setState(() {
        _searchQuery = value;
      });
    });
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
