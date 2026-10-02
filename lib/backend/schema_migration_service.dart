import 'package:equran/backend/bookmark_db.dart';
import 'package:equran/backend/companion_storage.dart';
import 'package:equran/backend/companion_storage_models.dart';
import 'package:equran/backend/favourites_db.dart';
import 'package:equran/backend/reading_model.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;

class SchemaMigrationService {
  SchemaMigrationService._();

  static final SchemaMigrationService instance = SchemaMigrationService._();

  Future<void> runSafeMigrations() async {
    await _runMigration(
      key: 'quran_bookmarks_from_favourites',
      version: 1,
      migrate: _migrateLegacyFavourites,
    );
    await _runMigration(
      key: 'resume_state_from_reading_history',
      version: 1,
      migrate: _migrateLegacyReadingHistory,
    );
    await _runMigration(
      key: 'quran_stats_initial_snapshot',
      version: 1,
      migrate: _ensureInitialStatsSnapshot,
    );
  }

  Future<void> _runMigration({
    required String key,
    required int version,
    required Future<void> Function() migrate,
  }) async {
    final dynamic existing = SchemaMigrationsDB().get(key);
    if (existing is SchemaMigrationRecord &&
        existing.success &&
        existing.version >= version) {
      return;
    }

    try {
      await migrate();
      await SchemaMigrationsDB().put(
        key,
        SchemaMigrationRecord(
          key: key,
          version: version,
          migratedAt: DateTime.now(),
          success: true,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Schema migration "$key" failed');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'equran schema migration',
          context: ErrorDescription('while running $key'),
        ),
      );
      await SchemaMigrationsDB().put(
        key,
        SchemaMigrationRecord(
          key: key,
          version: version,
          migratedAt: DateTime.now(),
          success: false,
          message: 'migration failed',
        ),
      );
    }
  }

  Future<void> _migrateLegacyFavourites() async {
    final DateTime now = DateTime.now();
    for (final dynamic rawKey in FavouritesDB().getKeys()) {
      final _LegacyAyahKey? legacyKey = _LegacyAyahKey.parse(rawKey);
      if (legacyKey == null) continue;

      final String id = favouriteAyahKey(legacyKey.surah, legacyKey.verse);
      final String note = FavouritesDB()
          .get(rawKey, defaultValue: '')
          .toString()
          .trim();
      final dynamic existing = QuranBookmarksDB().get(id);
      if (existing is QuranBookmarkEntry) {
        final bool shouldPreserveExistingNote = existing.note.trim().isNotEmpty;
        await QuranBookmarksDB().put(
          id,
          existing.copyWith(
            isFavourite: true,
            note: shouldPreserveExistingNote ? existing.note : note,
            legacyKey: rawKey.toString(),
            updatedAt: now,
          ),
        );
        continue;
      }

      await QuranBookmarksDB().put(
        id,
        QuranBookmarkEntry(
          id: id,
          surah: legacyKey.surah,
          verse: legacyKey.verse,
          note: note,
          legacyKey: rawKey.toString(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future<void> _migrateLegacyReadingHistory() async {
    for (final dynamic value in BookmarkDB().box.values) {
      if (value is! ReadingEntry) continue;
      if (!_isValidAyah(value.surah, value.verse)) continue;

      final String id = 'reading:${value.surah}';
      final dynamic existing = ResumeStateDB().get(id);
      if (existing is ResumeStateEntry &&
          existing.updatedAt.isAfter(value.timestamp)) {
        continue;
      }

      await ResumeStateDB().put(
        id,
        ResumeStateEntry(
          id: id,
          kind: 'reading',
          surah: value.surah,
          ayah: value.verse,
          title: quran.getSurahName(value.surah),
          subtitle: 'Ayah ${value.verse}',
          updatedAt: value.timestamp,
        ),
      );
    }
  }

  Future<void> _ensureInitialStatsSnapshot() async {
    if (QuranStatsDB().contains('summary')) return;
    await QuranStatsDB().put(
      'summary',
      QuranStatsSnapshot(id: 'summary', updatedAt: DateTime.now()),
    );
  }

  bool _isValidAyah(int surah, int verse) {
    if (surah < 1 || surah > 114 || verse < 1) return false;
    return verse <= quran.getVerseCount(surah);
  }
}

class _LegacyAyahKey {
  const _LegacyAyahKey({required this.surah, required this.verse});

  final int surah;
  final int verse;

  static _LegacyAyahKey? parse(dynamic rawKey) {
    final String key = rawKey.toString();
    final RegExpMatch? match = RegExp(r'^(\d{1,3})-(\d{1,3})$').firstMatch(key);
    if (match == null) return null;

    final int? surah = int.tryParse(match.group(1)!);
    final int? verse = int.tryParse(match.group(2)!);
    if (surah == null || verse == null) return null;
    if (surah < 1 || surah > 114 || verse < 1) return null;
    if (verse > quran.getVerseCount(surah)) return null;
    return _LegacyAyahKey(surah: surah, verse: verse);
  }
}
