import 'package:emushaf/backend/bookmark_db.dart';
import 'package:emushaf/utils/debouncer.dart';
import 'package:emushaf/widgets/library.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
    return SafeArea(
      child: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) =>
            <Widget>[
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
                    height: 10,
                  ),
                  Text(
                    "eQuran",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 20,
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
          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: BookmarkDB().listener,
              builder: (BuildContext context, Box<dynamic> box, child) {
                if (box.length == 0) {
                  return SizedBox.shrink();
                }
                return LastReadCard(box: box);
              },
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
