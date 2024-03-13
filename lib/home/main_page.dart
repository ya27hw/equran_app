import 'package:card_swiper/card_swiper.dart';
import 'package:emushaf/utils/debouncer.dart';
import 'package:emushaf/widgets/favourites_list.dart';
import 'package:emushaf/widgets/library.dart'
    show JuzCardList, QuranCardList, MySearchBar;
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: NestedScrollView(
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
              pinned: false,
              floating: false,
              expandedHeight: 150,
              centerTitle: true,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
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
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 20,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Swiper(
                  loop: false,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        elevation: 0,
                        child: const Text("Hey"));
                  },
                  itemCount: 9,
                  control: SwiperControl(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 10)),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 20,
              ),
            ),
            SliverPersistentHeader(
              pinned: false,
              delegate: _SliverAppBarDelegate(
                TabBar(
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
              FavouritesList(),
            ],
          ),
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
