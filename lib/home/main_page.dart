import 'package:emushaf/utils/debouncer.dart';
import 'package:emushaf/widgets/quran_card_list.dart';
import 'package:emushaf/widgets/search.dart';
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
  List<Tab> _tabs = const [
    Tab(text: 'Surah'),
    Tab(text: 'Juz'),
    Tab(
      icon: Icon(Icons.star),
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
        child: Column(
      children: <Widget>[
        SizedBox(
          height: 10,
        ),
        MySearchBar(
          onChanged: _changeSearchQuery,
        ),
        SizedBox(
          height: 10,
        ),
        TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
        SizedBox(
          height: 10,
        ),
        Expanded(
            child: TabBarView(
          controller: _tabController,
          children: [
            QuranCardList(searchQuery: _searchQuery),
            Text("Juz"),
            Text("Favourites")
          ],
        ))
      ],
    ));
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Material(
  //     child: SafeArea(
  //       child: CustomScrollView(
  //         physics: BouncingScrollPhysics(),
  //         slivers: <Widget>[
  //           SliverAppBar(
  //             iconTheme: IconThemeData(
  //                 color: Theme.of(context).colorScheme.onPrimaryContainer),
  //             elevation: 2,
  //             shape: const RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.only(
  //                     bottomLeft: Radius.circular(30),
  //                     bottomRight: Radius.circular(30))),
  //             pinned: false,
  //             floating: false,
  //             expandedHeight: 150,
  //             centerTitle: true,
  //             backgroundColor: Theme.of(context).colorScheme.primaryContainer,
  //             flexibleSpace: FlexibleSpaceBar(
  //               background: Container(
  //                 // padding: const EdgeInsets.all(10.0),
  //                 child: Column(
  //                   //crossAxisAlignment: CrossAxisAlignment.center,
  //                   children: <Widget>[
  //                     Text(
  //                       "eQuran",
  //                       style: Theme.of(context)
  //                           .textTheme
  //                           .headlineLarge
  //                           ?.copyWith(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .onPrimaryContainer,
  //                               fontWeight: FontWeight.bold),
  //                     ),
  //                     const SizedBox(
  //                       height: 30,
  //                     ),
  //                     MySearchBar(
  //                       onChanged: (value) {
  //                         _changeSearchQuery(value);
  //                       },
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //           SliverPersistentHeader(
  //             pinned: false,
  //             delegate: _SliverAppBarDelegate(
  //               TabBar(
  //                 controller: _tabController,
  //                 tabs: _tabs,
  //               ),
  //             ),
  //           ),
  //           SliverFillRemaining(
  //             child: TabBarView(
  //               controller: _tabController,
  //               children: [
  //                 SizedBox(
  //                     height: 10,
  //                     child: QuranCardList(searchQuery: _searchQuery)),
  //                 Text("Juz"),
  //                 Text("Favourites")
  //               ],
  //             ),
  //           )
  //         ],
  //
  //         // body: SizedBox(),
  //       ),
  //     ),
  //   );
  // }

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
