import 'package:equran/backend/companion_storage.dart';
import 'package:equran/backend/companion_storage_models.dart';
import 'package:equran/backend/favourites_db.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:quran/quran.dart' as quran;

class QuranBookmarkService {
  const QuranBookmarkService();

  static const String defaultFolder = 'Default';

  bool isFavourite(int surah, int verse) {
    final String key = favouriteAyahKey(surah, verse);
    final dynamic entry = QuranBookmarksDB().get(key);
    if (entry is QuranBookmarkEntry && entry.isFavourite) return true;
    return FavouritesDB().contains(key);
  }

  Future<void> saveFavourite(int surah, int verse, {String note = ''}) async {
    final String key = favouriteAyahKey(surah, verse);
    final String trimmedNote = note.trim();
    final String legacyNote = FavouritesDB()
        .get(key, defaultValue: '')
        .toString()
        .trim();
    final String noteToStore = trimmedNote.isEmpty ? legacyNote : trimmedNote;
    final DateTime now = DateTime.now();

    await FavouritesDB().put(key, noteToStore);

    final dynamic existing = QuranBookmarksDB().get(key);
    if (existing is QuranBookmarkEntry) {
      final String existingNote = existing.note.trim();
      await QuranBookmarksDB().put(
        key,
        existing.copyWith(
          isFavourite: true,
          note: noteToStore.isEmpty && existingNote.isNotEmpty
              ? existingNote
              : noteToStore,
          legacyKey: key,
          updatedAt: now,
        ),
      );
      return;
    }

    await QuranBookmarksDB().put(
      key,
      QuranBookmarkEntry(
        id: key,
        surah: surah,
        verse: verse,
        note: noteToStore,
        legacyKey: key,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> removeFavourite(int surah, int verse) async {
    final String key = favouriteAyahKey(surah, verse);
    await FavouritesDB().delete(key);

    final dynamic existing = QuranBookmarksDB().get(key);
    if (existing is! QuranBookmarkEntry) return;
    if (existing.note.trim().isEmpty &&
        existing.tags.isEmpty &&
        existing.folder == 'Default') {
      await QuranBookmarksDB().delete(key);
      return;
    }

    await QuranBookmarksDB().put(
      key,
      existing.copyWith(isFavourite: false, updatedAt: DateTime.now()),
    );
  }

  Future<void> saveBookmarkDetails(
    int surah,
    int verse, {
    bool? isFavourite,
    String? note,
    String? folder,
    List<String>? tags,
  }) async {
    final String key = favouriteAyahKey(surah, verse);
    final DateTime now = DateTime.now();
    final dynamic existing = QuranBookmarksDB().get(key);
    final QuranBookmarkEntry base = existing is QuranBookmarkEntry
        ? existing
        : QuranBookmarkEntry(
            id: key,
            surah: surah,
            verse: verse,
            createdAt: now,
            updatedAt: now,
            legacyKey: key,
            isFavourite: FavouritesDB().contains(key),
            note: FavouritesDB().get(key, defaultValue: '').toString(),
          );
    final String nextNote = note?.trim() ?? base.note;
    final String nextFolder = _cleanFolder(folder ?? base.folder);
    final List<String> nextTags = _cleanTags(tags ?? base.tags);
    final bool nextFavourite = isFavourite ?? base.isFavourite;
    final bool hasLibraryData =
        nextFavourite ||
        nextNote.isNotEmpty ||
        nextFolder != 'Default' ||
        nextTags.isNotEmpty;

    if (!hasLibraryData) {
      await FavouritesDB().delete(key);
      await QuranBookmarksDB().delete(key);
      return;
    }

    if (nextFavourite) {
      await FavouritesDB().put(key, nextNote);
    } else {
      await FavouritesDB().delete(key);
    }

    await QuranBookmarksDB().put(
      key,
      QuranBookmarkEntry(
        id: key,
        surah: surah,
        verse: verse,
        isFavourite: nextFavourite,
        note: nextNote,
        folder: nextFolder,
        tags: nextTags,
        legacyKey: key,
        createdAt: base.createdAt,
        updatedAt: now,
        schemaVersion: base.schemaVersion,
      ),
    );
  }

  Future<void> deleteBookmark(int surah, int verse) async {
    final String key = favouriteAyahKey(surah, verse);
    await FavouritesDB().delete(key);
    await QuranBookmarksDB().delete(key);
  }

  List<QuranBookmarkEntry> bookmarkEntriesWithLegacyFallback() {
    final Map<String, QuranBookmarkEntry> entries =
        <String, QuranBookmarkEntry>{};
    for (final QuranBookmarkEntry entry
        in QuranBookmarksDB().box.values.whereType<QuranBookmarkEntry>()) {
      entries[entry.id] = entry;
    }

    final DateTime fallbackTime = DateTime.fromMillisecondsSinceEpoch(0);
    for (final dynamic rawKey in FavouritesDB().getKeys()) {
      final _ParsedAyahKey? parsed = _ParsedAyahKey.parse(rawKey);
      if (parsed == null) continue;
      final String key = favouriteAyahKey(parsed.surah, parsed.verse);
      entries.putIfAbsent(
        key,
        () => QuranBookmarkEntry(
          id: key,
          surah: parsed.surah,
          verse: parsed.verse,
          note: FavouritesDB().get(rawKey, defaultValue: '').toString(),
          legacyKey: rawKey.toString(),
          createdAt: fallbackTime,
          updatedAt: fallbackTime,
        ),
      );
    }

    final List<QuranBookmarkEntry> sorted = entries.values.toList();
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  List<String> folders() {
    final Set<String> folders = <String>{defaultFolder};
    for (final dynamic key in QuranBookmarkFoldersDB().getKeys()) {
      final String folder = _cleanFolder(key.toString());
      folders.add(folder);
    }
    for (final QuranBookmarkEntry entry
        in bookmarkEntriesWithLegacyFallback()) {
      folders.add(_cleanFolder(entry.folder));
    }
    return folders.toList(growable: false)..sort((a, b) {
      if (a == defaultFolder) return -1;
      if (b == defaultFolder) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  }

  Future<String> createFolder(String name) async {
    final String folder = _cleanFolder(name);
    if (folder == defaultFolder) return defaultFolder;
    await QuranBookmarkFoldersDB().put(
      folder,
      DateTime.now().toIso8601String(),
    );
    return folder;
  }

  Future<void> renameFolder(String oldName, String newName) async {
    final String oldFolder = _cleanFolder(oldName);
    final String newFolder = _cleanFolder(newName);
    if (oldFolder == defaultFolder || newFolder == oldFolder) return;
    await createFolder(newFolder);
    await QuranBookmarkFoldersDB().delete(oldFolder);
    final DateTime now = DateTime.now();
    for (final QuranBookmarkEntry entry
        in bookmarkEntriesWithLegacyFallback()) {
      if (_cleanFolder(entry.folder) != oldFolder) continue;
      await QuranBookmarksDB().put(
        entry.id,
        entry.copyWith(folder: newFolder, updatedAt: now),
      );
    }
  }

  Future<void> deleteFolder(String folderName) async {
    final String folder = _cleanFolder(folderName);
    if (folder == defaultFolder) return;
    await QuranBookmarkFoldersDB().delete(folder);
    final DateTime now = DateTime.now();
    for (final QuranBookmarkEntry entry
        in bookmarkEntriesWithLegacyFallback()) {
      if (_cleanFolder(entry.folder) != folder) continue;
      await QuranBookmarksDB().put(
        entry.id,
        entry.copyWith(folder: defaultFolder, updatedAt: now),
      );
    }
  }

  List<String> tags() {
    final Set<String> tags = <String>{};
    for (final QuranBookmarkEntry entry
        in bookmarkEntriesWithLegacyFallback()) {
      tags.addAll(_cleanTags(entry.tags));
    }
    return tags.toList(growable: false)..sort();
  }
}

String _cleanFolder(String value) {
  final String folder = value.trim();
  if (folder.isEmpty || folder.toLowerCase() == 'unsorted') {
    return QuranBookmarkService.defaultFolder;
  }
  return folder;
}

List<String> _cleanTags(List<String> tags) {
  final Set<String> cleanTags = <String>{};
  for (final String tag in tags) {
    final String cleanTag = tag.trim();
    if (cleanTag.isNotEmpty) cleanTags.add(cleanTag);
  }
  return cleanTags.toList(growable: false)..sort();
}

class _ParsedAyahKey {
  const _ParsedAyahKey({required this.surah, required this.verse});

  final int surah;
  final int verse;

  static _ParsedAyahKey? parse(dynamic rawKey) {
    final List<String> parts = rawKey.toString().split('-');
    if (parts.length != 2) return null;
    final int? surah = int.tryParse(parts[0]);
    final int? verse = int.tryParse(parts[1]);
    if (surah == null || verse == null) return null;
    if (surah < 1 || surah > 114 || verse < 1) return null;
    if (verse > quran.getVerseCount(surah)) return null;
    return _ParsedAyahKey(surah: surah, verse: verse);
  }
}
