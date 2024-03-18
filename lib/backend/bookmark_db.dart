import 'base_db.dart';

class BookmarkDB extends BaseDB {
  BookmarkDB._privateConstructor() : super("bookmarks");

  static final BookmarkDB _instance = BookmarkDB._privateConstructor();

  factory BookmarkDB() {
    return _instance;
  }

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    return get(key, defaultValue: defaultValue);
  }
}
