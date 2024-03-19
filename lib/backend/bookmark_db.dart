import 'package:collection/collection.dart' show minBy;
import 'package:emushaf/backend/reading_model.dart';

import 'base_db.dart';

class BookmarkDB extends BaseDB {
  BookmarkDB._privateConstructor() : super("bookmarks");

  static final BookmarkDB _instance = BookmarkDB._privateConstructor();

  factory BookmarkDB() {
    return _instance;
  }

  Future<void> addReadingEntry(int surah, int verse) async {
    // siuuuuuuuu
    if (length > 7) {
      removeOldestEntry();
    }

    await put(surah,
        ReadingEntry(surah: surah, verse: verse, timestamp: DateTime.now()));
  }

  void removeOldestEntry() {
    var oldestEntry = minBy(box.toMap().entries, (p0) => p0.value.timestamp);
    if (oldestEntry != null) {
      delete(oldestEntry.key);
    }
  }
}
