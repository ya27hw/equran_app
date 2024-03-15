import 'package:flutter/material.dart';

import 'base_db.dart';

class BookmarkDB extends BaseDB with ChangeNotifier {
  dynamic _lastRead;

  BookmarkDB._privateConstructor() : super("bookmarks") {
    loadLastRead();
  }

  static final BookmarkDB _instance = BookmarkDB._privateConstructor();

  factory BookmarkDB() {
    return _instance;
  }

  String get lastRead => _lastRead;

  void loadLastRead() {
    _lastRead = get("lastRead", defaultValue: "0-0");
    notifyListeners();
  }

  Future<void> updateLastRead(String value) async {
    await put("lastRead", value);
    _lastRead = value;
    notifyListeners();
  }

  Future<void> deleteLastRead() async {
    _lastRead = "0-0";
    notifyListeners();
  }
}
