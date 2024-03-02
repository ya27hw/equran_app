import 'package:emushaf/home/home.dart';
import 'package:emushaf/theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  await Hive.initFlutter("assets");
  await Hive.openBox("bookmarks");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: MyTheme.lightThemeData(context),
        darkTheme: MyTheme.darkThemeData(context),
        home: HomePage());
  }
}
