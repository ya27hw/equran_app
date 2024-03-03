import 'package:emushaf/home/main_page.dart';
import 'package:emushaf/test.dart';
import 'package:flutter/material.dart';

class ExampleDestination {
  const ExampleDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<ExampleDestination> _pageDestinations = <ExampleDestination>[
    ExampleDestination("Quran", Icon(Icons.book_outlined), Icon(Icons.book)),
    ExampleDestination("Test", Icon(Icons.info_outline), Icon(Icons.info))
  ];
  final List<Widget> _pages = [MainPage(), TestPage()];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawer(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Header',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ..._pageDestinations.map(
            (ExampleDestination destination) {
              return NavigationDrawerDestination(
                label: Text(destination.label),
                icon: destination.icon,
                selectedIcon: destination.selectedIcon,
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
            child: Divider(),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
    );
  }

  void _onItemTapped(int index) {
    print("Chaning Screen to $index");
    setState(() {
      _selectedIndex = index;
    });
  }

  void _scrollUp() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }
}
