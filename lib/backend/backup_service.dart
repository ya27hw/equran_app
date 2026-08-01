import 'dart:convert';
import 'dart:typed_data';

import 'package:equran/backend/base_db.dart';
import 'package:equran/backend/bookmark_db.dart';
import 'package:equran/backend/companion_storage.dart';
import 'package:equran/backend/companion_storage_models.dart';
import 'package:equran/backend/favourites_db.dart';
import 'package:equran/hifz/models/hifz_entry.dart';
import 'package:equran/hifz/models/hifz_review_log.dart';
import 'package:equran/hifz/models/hifz_unit.dart';
import 'package:equran/backend/reading_model.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/features/journey_capsules.dart';
import 'package:equran/hifz/memory_twin.dart';
import 'package:equran/hifz/memory_map.dart';
import 'package:equran/utils/reciter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quran/quran.dart' as quran show Translation, getVerseCount;
import 'package:equran/zakat/zakat_db.dart';

class AppBackupException implements Exception {
  AppBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.settingsCount,
    required this.favouritesCount,
    required this.readingHistoryCount,
    this.sectionCounts = const <String, int>{},
  });

  final int settingsCount;
  final int favouritesCount;
  final int readingHistoryCount;
  final Map<String, int> sectionCounts;
}

class BackupService {
  const BackupService._();

  /// Exposes the pure validation boundary to deterministic tests without
  /// opening platform file-picker dialogs.
  static Map<String, dynamic> validateSettingsForTesting(
    Map<String, dynamic> settings,
  ) => _validateSettings(settings);

  static void validateFavouritesForTesting(Map<String, dynamic> favourites) =>
      _validateFavourites(favourites);

  static void validateSectionsForTesting(Object? sections) =>
      _validateSections(sections);

  static String integrityHashForTesting(Map<String, dynamic> payload) =>
      _integrityHashFor(payload);

  static const int _schemaVersion = 2;
  static const int _maxBackupBytes = 25 * 1024 * 1024;
  static const int _themeColorCount = 18;
  static const Set<String> _boolSettings = <String>{
    'vibration',
    'showLastRead',
    'viewMode',
    'enableTranslation',
    'showTransliteration',
    'holographicCardsEnabled',
  };
  static const Set<String> _allowedSettings = <String>{
    ..._boolSettings,
    'translation',
    'reciter',
    'color',
    'locale',
    'themeMode',
    'themeScheme',
    'fontSize',
    'fontSizeTranslation',
    'playbackRate',
    'dailyQuranGoalAyahs',
    'dailyAyahDate',
    'dailyAyahGlobalAyah',
    'ayahDelaySeconds',
    'intervalRepeatCount',
    'repeatAyahCount',
    'playbackInterval',
    'prayerTimeSettings',
    'prayerLocation',
  };

  static Future<String?> exportBackupFile() async {
    final String fileName = _buildFileName();
    final String encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert(_buildBackupPayload());

    final String? outputPath = await FilePicker.saveFile(
      dialogTitle: 'Save eQuran backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const <String>['equranbackup'],
      bytes: Uint8List.fromList(utf8.encode(encoded)),
    );

    if (outputPath == null) {
      throw AppBackupException('Backup cancelled.');
    }

    return outputPath;
  }

  static Future<BackupRestoreResult> restoreFromPickedFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json', 'equranbackup'],
      withData: true,
    );

    if (result == null) {
      throw AppBackupException('Restore cancelled.');
    }

    final PlatformFile file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw AppBackupException('The selected backup file is empty.');
    }
    if (bytes.length > _maxBackupBytes) {
      throw AppBackupException('The selected backup file is too large.');
    }

    final dynamic decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw AppBackupException('The selected file is not a valid backup.');
    }

    final Map<dynamic, dynamic> payload = decoded;
    final dynamic version = payload['schemaVersion'];
    if (version is! int || (version != 1 && version != _schemaVersion)) {
      throw AppBackupException('Unsupported backup version.');
    }
    _verifyPayloadIntegrity(payload);

    final Map<String, dynamic> settings = _validateSettings(
      _readStringKeyMap(payload['settings']),
    );
    final Map<String, dynamic> favourites = _readStringKeyMap(
      payload['favourites'],
    );
    _validateFavourites(favourites);
    final List<ReadingEntry> readingHistory = _readHistoryEntries(
      payload['readingHistory'],
    );
    _validateSections(payload['sections']);

    final Map<String, Map<dynamic, dynamic>> snapshots = _snapshotStores();
    final Map<String, int> sectionCounts = <String, int>{};
    try {
      await SettingsDB().clear();
      await FavouritesDB().clear();
      await BookmarkDB().clear();

      for (final MapEntry<String, dynamic> entry in settings.entries) {
        await SettingsDB().put(entry.key, entry.value);
      }
      for (final MapEntry<String, dynamic> entry in favourites.entries) {
        await FavouritesDB().put(entry.key, entry.value);
      }
      for (final ReadingEntry entry in readingHistory) {
        await BookmarkDB().put(entry.surah, entry);
      }
      if (version >= 2) {
        await _restoreSections(payload['sections'], sectionCounts);
      }
    } catch (error) {
      await _restoreStores(snapshots);
      throw AppBackupException(
        'The backup could not be restored; the previous data was recovered.',
      );
    }

    return BackupRestoreResult(
      settingsCount: settings.length,
      favouritesCount: favourites.length,
      readingHistoryCount: readingHistory.length,
      sectionCounts: Map<String, int>.unmodifiable(sectionCounts),
    );
  }

  static Map<String, dynamic> _buildBackupPayload() {
    final Map<dynamic, dynamic> rawSettings = SettingsDB().box.toMap();
    final Map<dynamic, dynamic> rawFavourites = FavouritesDB().box.toMap();
    final Map<dynamic, dynamic> rawBookmarks = BookmarkDB().box.toMap();
    final Map<String, dynamic> payload = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': rawSettings.map((dynamic key, dynamic value) {
        final String settingKey = key.toString();
        return MapEntry(settingKey, _settingValueForBackup(settingKey, value));
      }),
      'favourites': rawFavourites.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      ),
      'readingHistory': rawBookmarks.values
          .whereType<ReadingEntry>()
          .map(_readingEntryToJson)
          .toList(),
      'sections': _buildSections(),
    };
    payload['integrity'] = _integrityHashFor(payload);
    return payload;
  }

  static Map<String, Object?> _buildSections() {
    final Map<String, Object?> sections = <String, Object?>{};
    void addBox(String name, BaseDB database) {
      sections[name] = _boxRows(database.box);
    }

    addBox('quranBookmarks', QuranBookmarksDB());
    addBox('bookmarkFolders', QuranBookmarkFoldersDB());
    addBox('quranActivity', QuranActivityDB());
    addBox('readingPlans', ReadingPlansDB());
    addBox('routineDayProgress', RoutineDayProgressDB());
    addBox('resumeState', ResumeStateDB());
    addBox('recentSearches', RecentSearchesDB());
    addBox('dhikrSessions', DhikrSessionsDB());
    addBox('duaInteractions', DuaInteractionsDB());
    addBox('salahLog', SalahLogDB());
    addBox('quranStats', QuranStatsDB());
    addBox('downloadMetadata', DownloadMetadataDB());
    sections['hifzEntries'] = _boxRows(Hive.box<HifzEntry>('hifzEntries'));
    sections['hifzLogs'] = _boxRows(Hive.box<HifzReviewLog>('hifzLogs'));
    sections['hifzUnits'] = _boxRows(Hive.box<HifzUnit>('hifzUnits'));
    sections['zakatHistory'] = _boxRows(ZakatHistoryDB.instance.exportBox());
    sections['memoryTwinPredictions'] = _boxRows(MemoryTwinDB.instance.box);
    // Voice notes are local files and are excluded from the JSON backup
    // unless a future explicit media-export flow opts them in.
    sections['journeyCapsules'] = _boxRowsWithoutVoicePaths(
      JourneyCapsulesDB.instance.box,
    );
    sections['memoryMapState'] = _boxRows(MemoryMapStateDB.instance.box);
    return sections;
  }

  static List<Map<String, Object?>> _boxRows(Box<dynamic> box) {
    return box
        .toMap()
        .entries
        .map(
          (MapEntry<dynamic, dynamic> entry) => <String, Object?>{
            'key': _jsonSafe(entry.key),
            'value': _jsonSafe(entry.value),
          },
        )
        .toList(growable: false);
  }

  static List<Map<String, Object?>> _boxRowsWithoutVoicePaths(
    Box<dynamic> box,
  ) {
    return box
        .toMap()
        .entries
        .map((MapEntry<dynamic, dynamic> entry) {
          final Object? rawValue = entry.value;
          final Object? value = rawValue is Map
              ? <String, Object?>{
                  for (final MapEntry<dynamic, dynamic> field
                      in rawValue.entries)
                    if (field.key.toString() != 'voicePath')
                      field.key.toString(): _jsonSafe(field.value),
                }
              : _jsonSafe(rawValue);
          return <String, Object?>{'key': _jsonSafe(entry.key), 'value': value};
        })
        .toList(growable: false);
  }

  static Object? _jsonSafe(Object? value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Map) {
      return <String, Object?>{
        for (final MapEntry<dynamic, dynamic> entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value),
      };
    }
    if (value is List) return value.map(_jsonSafe).toList(growable: false);
    if (value is QuranBookmarkEntry) {
      return <String, Object?>{
        'id': value.id,
        'surah': value.surah,
        'verse': value.verse,
        'isFavourite': value.isFavourite,
        'note': value.note,
        'folder': value.folder,
        'tags': value.tags,
        'createdAt': value.createdAt.toUtc().toIso8601String(),
        'updatedAt': value.updatedAt.toUtc().toIso8601String(),
        'legacyKey': value.legacyKey,
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is QuranActivityDay) {
      return <String, Object?>{
        'dateKey': value.dateKey,
        'ayahsRead': value.ayahsRead,
        'pagesRead': value.pagesRead,
        'listeningSeconds': value.listeningSeconds,
        'readingSeconds': value.readingSeconds,
        'readAyahKeys': value.readAyahKeys,
        'updatedAt': value.updatedAt.toUtc().toIso8601String(),
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is ReadingPlanEntry) {
      return <String, Object?>{
        'id': value.id,
        'type': value.type,
        'title': value.title,
        'startedAt': value.startedAt.toUtc().toIso8601String(),
        'finishBy': value.finishBy.toUtc().toIso8601String(),
        'startGlobalAyah': value.startGlobalAyah,
        'targetGlobalAyah': value.targetGlobalAyah,
        'lastCompletedGlobalAyah': value.lastCompletedGlobalAyah,
        'active': value.active,
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is RoutineDayProgressEntry) return _jsonSafe(value.toMap());
    if (value is ResumeStateEntry) {
      return <String, Object?>{
        'id': value.id,
        'kind': value.kind,
        'surah': value.surah,
        'ayah': value.ayah,
        'juz': value.juz,
        'positionMillis': value.positionMillis,
        'title': value.title,
        'subtitle': value.subtitle,
        'updatedAt': value.updatedAt.toUtc().toIso8601String(),
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is RecentSearchEntry) {
      return <String, Object?>{
        'id': value.id,
        'query': value.query,
        'mode': value.mode,
        'searchedAt': value.searchedAt.toUtc().toIso8601String(),
        'resultCount': value.resultCount,
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is DhikrSessionEntry) {
      return <String, Object?>{
        'id': value.id,
        'label': value.label,
        'targetCount': value.targetCount,
        'count': value.count,
        'startedAt': value.startedAt.toUtc().toIso8601String(),
        'completedAt': value.completedAt?.toUtc().toIso8601String(),
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is SalahLogEntry) return _jsonSafe(value.toMap());
    if (value is QuranStatsSnapshot) {
      return <String, Object?>{
        'id': value.id,
        'totalAyahsRead': value.totalAyahsRead,
        'estimatedLettersRead': value.estimatedLettersRead,
        'listeningSeconds': value.listeningSeconds,
        'totalReadingSeconds': value.totalReadingSeconds,
        'currentStreak': value.currentStreak,
        'updatedAt': value.updatedAt.toUtc().toIso8601String(),
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is DownloadMetadataEntry) {
      return <String, Object?>{
        'id': value.id,
        'reciterCode': value.reciterCode,
        'type': value.type,
        'surah': value.surah,
        'ayah': value.ayah,
        'path': value.path,
        'sizeBytes': value.sizeBytes,
        'status': value.status,
        'updatedAt': value.updatedAt.toUtc().toIso8601String(),
        'schemaVersion': value.schemaVersion,
      };
    }
    if (value is HifzEntry) {
      return <String, Object?>{
        'surah': value.surah,
        'ayah': value.ayah,
        'status': value.status,
        'interval': value.interval,
        'easeFactor': value.easeFactor,
        'repetitions': value.repetitions,
        'dueDate': value.dueDate.toUtc().toIso8601String(),
        'lastReviewed': value.lastReviewed?.toUtc().toIso8601String(),
        'lapses': value.lapses,
        'track': value.track,
        'unitId': value.unitId,
        'sequenceIndex': value.sequenceIndex,
        'introducedRepetitions': value.introducedRepetitions,
        'firstLearnedAt': value.firstLearnedAt?.toUtc().toIso8601String(),
      };
    }
    if (value is HifzReviewLog) {
      return <String, Object?>{
        'surah': value.surah,
        'ayah': value.ayah,
        'rating': value.rating,
        'reviewedAt': value.reviewedAt.toUtc().toIso8601String(),
        'previousInterval': value.previousInterval,
        'newInterval': value.newInterval,
        'previousEaseFactor': value.previousEaseFactor,
        'newEaseFactor': value.newEaseFactor,
      };
    }
    if (value is HifzUnit) {
      return <String, Object?>{
        'id': value.id,
        'unitType': value.unitType,
        'unitNumber': value.unitNumber,
        'frontierSurah': value.frontierSurah,
        'frontierAyah': value.frontierAyah,
        'startedAt': value.startedAt.toUtc().toIso8601String(),
        'completedAt': value.completedAt?.toUtc().toIso8601String(),
        'isComplete': value.isComplete,
      };
    }
    if (value is ZakatRecord) return value.toMap();
    throw AppBackupException('Unsupported value in backup data.');
  }

  static Map<String, Map<dynamic, dynamic>> _snapshotStores() {
    final Map<String, Map<dynamic, dynamic>> stores =
        <String, Map<dynamic, dynamic>>{};
    void add(String name, Box<dynamic> box) => stores[name] = box.toMap();
    add('settings', SettingsDB().box);
    add('favourites', FavouritesDB().box);
    add('bookmarks', BookmarkDB().box);
    add('quranBookmarks', QuranBookmarksDB().box);
    add('bookmarkFolders', QuranBookmarkFoldersDB().box);
    add('quranActivity', QuranActivityDB().box);
    add('readingPlans', ReadingPlansDB().box);
    add('routineDayProgress', RoutineDayProgressDB().box);
    add('resumeState', ResumeStateDB().box);
    add('recentSearches', RecentSearchesDB().box);
    add('dhikrSessions', DhikrSessionsDB().box);
    add('duaInteractions', DuaInteractionsDB().box);
    add('salahLog', SalahLogDB().box);
    add('quranStats', QuranStatsDB().box);
    add('downloadMetadata', DownloadMetadataDB().box);
    add('hifzEntries', Hive.box<HifzEntry>('hifzEntries'));
    add('hifzLogs', Hive.box<HifzReviewLog>('hifzLogs'));
    add('hifzUnits', Hive.box<HifzUnit>('hifzUnits'));
    add('zakatHistory', ZakatHistoryDB.instance.exportBox());
    add('memoryTwinPredictions', MemoryTwinDB.instance.box);
    add('journeyCapsules', JourneyCapsulesDB.instance.box);
    add('memoryMapState', MemoryMapStateDB.instance.box);
    return stores;
  }

  static Future<void> _restoreStores(
    Map<String, Map<dynamic, dynamic>> stores,
  ) async {
    Future<void> restoreBox(
      Box<dynamic> box,
      Map<dynamic, dynamic> values,
    ) async {
      await box.clear();
      await box.putAll(values);
    }

    await restoreBox(SettingsDB().box, stores['settings']!);
    await restoreBox(FavouritesDB().box, stores['favourites']!);
    await restoreBox(BookmarkDB().box, stores['bookmarks']!);
    await restoreBox(QuranBookmarksDB().box, stores['quranBookmarks']!);
    await restoreBox(QuranBookmarkFoldersDB().box, stores['bookmarkFolders']!);
    await restoreBox(QuranActivityDB().box, stores['quranActivity']!);
    await restoreBox(ReadingPlansDB().box, stores['readingPlans']!);
    await restoreBox(RoutineDayProgressDB().box, stores['routineDayProgress']!);
    await restoreBox(ResumeStateDB().box, stores['resumeState']!);
    await restoreBox(RecentSearchesDB().box, stores['recentSearches']!);
    await restoreBox(DhikrSessionsDB().box, stores['dhikrSessions']!);
    await restoreBox(DuaInteractionsDB().box, stores['duaInteractions']!);
    await restoreBox(SalahLogDB().box, stores['salahLog']!);
    await restoreBox(QuranStatsDB().box, stores['quranStats']!);
    await restoreBox(DownloadMetadataDB().box, stores['downloadMetadata']!);
    await restoreBox(
      Hive.box<HifzEntry>('hifzEntries'),
      stores['hifzEntries']!,
    );
    await restoreBox(Hive.box<HifzReviewLog>('hifzLogs'), stores['hifzLogs']!);
    await restoreBox(Hive.box<HifzUnit>('hifzUnits'), stores['hifzUnits']!);
    await ZakatHistoryDB.instance.replaceBox(stores['zakatHistory']!);
    await restoreBox(
      MemoryTwinDB.instance.box,
      stores['memoryTwinPredictions']!,
    );
    await restoreBox(
      JourneyCapsulesDB.instance.box,
      stores['journeyCapsules']!,
    );
    await restoreBox(MemoryMapStateDB.instance.box, stores['memoryMapState']!);
  }

  static Future<void> _restoreSections(
    Object? raw,
    Map<String, int> counts,
  ) async {
    if (raw == null) return;
    if (raw is! Map) throw AppBackupException('Backup sections are invalid.');
    final Map<String, BaseDB> companionBoxes = <String, BaseDB>{
      'quranBookmarks': QuranBookmarksDB(),
      'bookmarkFolders': QuranBookmarkFoldersDB(),
      'quranActivity': QuranActivityDB(),
      'readingPlans': ReadingPlansDB(),
      'routineDayProgress': RoutineDayProgressDB(),
      'resumeState': ResumeStateDB(),
      'recentSearches': RecentSearchesDB(),
      'dhikrSessions': DhikrSessionsDB(),
      'duaInteractions': DuaInteractionsDB(),
      'salahLog': SalahLogDB(),
      'quranStats': QuranStatsDB(),
      'downloadMetadata': DownloadMetadataDB(),
    };
    for (final MapEntry<dynamic, dynamic> section in raw.entries) {
      final String name = section.key.toString();
      final Object? value = section.value;
      if (name == 'hifzEntries' || name == 'hifzLogs' || name == 'hifzUnits') {
        final Box<dynamic> box = Hive.box<dynamic>(name);
        counts[name] = await _restoreRows(box, value, name);
      } else if (name == 'zakatHistory') {
        counts[name] = await _restoreRows(
          ZakatHistoryDB.instance.exportBox(),
          value,
          name,
        );
      } else if (name == 'memoryTwinPredictions') {
        counts[name] = await _restoreRows(
          MemoryTwinDB.instance.box,
          value,
          name,
        );
      } else if (name == 'journeyCapsules') {
        counts[name] = await _restoreRows(
          JourneyCapsulesDB.instance.box,
          value,
          name,
        );
      } else if (name == 'memoryMapState') {
        counts[name] = await _restoreRows(
          MemoryMapStateDB.instance.box,
          value,
          name,
        );
      } else if (companionBoxes.containsKey(name)) {
        counts[name] = await _restoreRows(
          companionBoxes[name]!.box,
          value,
          name,
        );
      }
    }
  }

  static Future<int> _restoreRows(
    Box<dynamic> box,
    Object? raw,
    String section,
  ) async {
    if (raw is! List || raw.length > 100000) {
      throw AppBackupException('Backup section "$section" is invalid.');
    }
    final List<MapEntry<dynamic, dynamic>> rows =
        <MapEntry<dynamic, dynamic>>[];
    for (final Object? item in raw) {
      if (item is! Map ||
          !item.containsKey('key') ||
          !item.containsKey('value')) {
        throw AppBackupException(
          'Backup section "$section" contains an invalid row.',
        );
      }
      rows.add(MapEntry(item['key'], item['value']));
    }
    await box.clear();
    for (final MapEntry<dynamic, dynamic> row in rows) {
      await box.put(row.key, _decodeStoredValue(section, row.value));
    }
    return rows.length;
  }

  static void _validateSections(Object? raw) {
    if (raw == null) return;
    if (raw is! Map) {
      throw AppBackupException('Backup sections are invalid.');
    }
    for (final MapEntry<dynamic, dynamic> section in raw.entries) {
      final String name = section.key.toString();
      final Object? value = section.value;
      if (value is! List || value.length > 100000) {
        throw AppBackupException('Backup section "$name" is invalid.');
      }
      for (final Object? row in value) {
        if (row is! Map ||
            !row.containsKey('key') ||
            !row.containsKey('value')) {
          throw AppBackupException(
            'Backup section "$name" contains an invalid row.',
          );
        }
        _requireJsonValue('$name row', row['key']);
        _requireJsonValue('$name row', row['value']);
      }
    }
  }

  static Object? _decodeStoredValue(String section, Object? raw) {
    if (raw is! Map) return raw;
    final Map<dynamic, dynamic> map = raw;
    DateTime date(String key) =>
        DateTime.tryParse(map[key]?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    int integer(String key, [int fallback = 0]) =>
        (map[key] as num?)?.toInt() ?? fallback;
    double decimal(String key, [double fallback = 0]) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    switch (section) {
      case 'quranBookmarks':
        return QuranBookmarkEntry(
          id: map['id']?.toString() ?? '',
          surah: integer('surah', 1),
          verse: integer('verse', 1),
          isFavourite: map['isFavourite'] != false,
          note: map['note']?.toString() ?? '',
          folder: map['folder']?.toString() ?? 'Default',
          tags:
              (map['tags'] as List?)?.whereType<String>().toList() ??
              const <String>[],
          createdAt: date('createdAt'),
          updatedAt: date('updatedAt'),
          legacyKey: map['legacyKey']?.toString() ?? '',
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'quranActivity':
        return QuranActivityDay(
          dateKey: map['dateKey']?.toString() ?? '',
          ayahsRead: integer('ayahsRead'),
          pagesRead: integer('pagesRead'),
          listeningSeconds: integer('listeningSeconds'),
          readingSeconds: integer('readingSeconds'),
          readAyahKeys:
              (map['readAyahKeys'] as List?)?.whereType<String>().toList() ??
              const <String>[],
          updatedAt: date('updatedAt'),
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'readingPlans':
        return ReadingPlanEntry(
          id: map['id']?.toString() ?? '',
          type: map['type']?.toString() ?? '',
          title: map['title']?.toString() ?? '',
          startedAt: date('startedAt'),
          finishBy: date('finishBy'),
          startGlobalAyah: integer('startGlobalAyah'),
          targetGlobalAyah: integer('targetGlobalAyah'),
          lastCompletedGlobalAyah: integer('lastCompletedGlobalAyah'),
          active: map['active'] != false,
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'routineDayProgress':
        return RoutineDayProgressEntry.fromStored(map) ?? raw;
      case 'resumeState':
        return ResumeStateEntry(
          id: map['id']?.toString() ?? '',
          kind: map['kind']?.toString() ?? '',
          surah: (map['surah'] as num?)?.toInt(),
          ayah: (map['ayah'] as num?)?.toInt(),
          juz: (map['juz'] as num?)?.toInt(),
          positionMillis: (map['positionMillis'] as num?)?.toInt(),
          title: map['title']?.toString() ?? '',
          subtitle: map['subtitle']?.toString() ?? '',
          updatedAt: date('updatedAt'),
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'recentSearches':
        return RecentSearchEntry(
          id: map['id']?.toString() ?? '',
          query: map['query']?.toString() ?? '',
          mode: map['mode']?.toString() ?? '',
          searchedAt: date('searchedAt'),
          resultCount: integer('resultCount'),
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'dhikrSessions':
        return DhikrSessionEntry(
          id: map['id']?.toString() ?? '',
          label: map['label']?.toString() ?? '',
          targetCount: integer('targetCount'),
          count: integer('count'),
          startedAt: date('startedAt'),
          completedAt: map['completedAt'] == null ? null : date('completedAt'),
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'salahLog':
        return SalahLogEntry.fromStored(map) ?? raw;
      case 'quranStats':
        return QuranStatsSnapshot(
          id: map['id']?.toString() ?? '',
          totalAyahsRead: integer('totalAyahsRead'),
          estimatedLettersRead: integer('estimatedLettersRead'),
          listeningSeconds: integer('listeningSeconds'),
          totalReadingSeconds: integer('totalReadingSeconds'),
          currentStreak: integer('currentStreak'),
          updatedAt: date('updatedAt'),
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'downloadMetadata':
        return DownloadMetadataEntry(
          id: map['id']?.toString() ?? '',
          reciterCode: map['reciterCode']?.toString() ?? '',
          type: map['type']?.toString() ?? '',
          surah: (map['surah'] as num?)?.toInt(),
          ayah: (map['ayah'] as num?)?.toInt(),
          path: map['path']?.toString() ?? '',
          sizeBytes: integer('sizeBytes'),
          status: map['status']?.toString() ?? 'available',
          updatedAt: date('updatedAt'),
          schemaVersion: integer(
            'schemaVersion',
            companionStorageSchemaVersion,
          ),
        );
      case 'hifzEntries':
        final HifzEntry value = HifzEntry()
          ..surah = integer('surah', 1)
          ..ayah = integer('ayah', 1)
          ..status = map['status']?.toString() ?? 'new'
          ..interval = integer('interval')
          ..easeFactor = decimal('easeFactor', 2.5)
          ..repetitions = integer('repetitions')
          ..dueDate = date('dueDate')
          ..lastReviewed = map['lastReviewed'] == null
              ? null
              : date('lastReviewed')
          ..lapses = integer('lapses')
          ..track = map['track']?.toString() ?? 'sabaq'
          ..unitId = map['unitId']?.toString()
          ..sequenceIndex = (map['sequenceIndex'] as num?)?.toInt()
          ..introducedRepetitions = integer('introducedRepetitions')
          ..firstLearnedAt = map['firstLearnedAt'] == null
              ? null
              : date('firstLearnedAt');
        return value;
      case 'hifzLogs':
        return HifzReviewLog()
          ..surah = integer('surah', 1)
          ..ayah = integer('ayah', 1)
          ..rating = map['rating']?.toString() ?? 'again'
          ..reviewedAt = date('reviewedAt')
          ..previousInterval = integer('previousInterval')
          ..newInterval = integer('newInterval')
          ..previousEaseFactor = decimal('previousEaseFactor', 2.5)
          ..newEaseFactor = decimal('newEaseFactor', 2.5);
      case 'hifzUnits':
        return HifzUnit()
          ..id = map['id']?.toString() ?? ''
          ..unitType = map['unitType']?.toString() ?? 'surah'
          ..unitNumber = integer('unitNumber', 1)
          ..frontierSurah = integer('frontierSurah', 1)
          ..frontierAyah = integer('frontierAyah', 1)
          ..startedAt = date('startedAt')
          ..completedAt = map['completedAt'] == null
              ? null
              : date('completedAt')
          ..isComplete = map['isComplete'] == true;
      default:
        return raw;
    }
  }

  static Map<String, dynamic> _readStringKeyMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is! Map) {
      throw AppBackupException('The backup file has an invalid data format.');
    }

    return value.map(
      (dynamic key, dynamic mapValue) => MapEntry(key.toString(), mapValue),
    );
  }

  static List<ReadingEntry> _readHistoryEntries(dynamic value) {
    if (value == null) return <ReadingEntry>[];
    if (value is! List) {
      throw AppBackupException(
        'The backup file has an invalid reading history.',
      );
    }

    return value.map<ReadingEntry>((dynamic item) {
      if (item is! Map) {
        throw AppBackupException(
          'The backup file contains an invalid history entry.',
        );
      }

      final dynamic surah = item['surah'];
      final dynamic verse = item['verse'];
      final dynamic timestamp = item['timestamp'];
      if (surah is! int || verse is! int || timestamp is! String) {
        throw AppBackupException(
          'The backup file contains an invalid history entry.',
        );
      }
      if (surah < 1 ||
          surah > 114 ||
          verse < 1 ||
          verse > quran.getVerseCount(surah)) {
        throw AppBackupException(
          'The backup file contains an out-of-range history entry.',
        );
      }

      try {
        return ReadingEntry(
          surah: surah,
          verse: verse,
          timestamp: DateTime.parse(timestamp),
        );
      } catch (_) {
        throw AppBackupException(
          'The backup file contains an invalid history timestamp.',
        );
      }
    }).toList();
  }

  static Map<String, dynamic> _validateSettings(Map<String, dynamic> settings) {
    final Map<String, dynamic> validated = <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in settings.entries) {
      if (!_allowedSettings.contains(entry.key)) {
        // Unknown settings are optional extensions. Preserve only JSON-safe
        // values so newer versions can round-trip them safely.
        validated[entry.key] = _requireJsonValue(entry.key, entry.value);
        continue;
      }
      validated[entry.key] = switch (entry.key) {
        'vibration' ||
        'showLastRead' ||
        'viewMode' ||
        'enableTranslation' ||
        'showTransliteration' ||
        'holographicCardsEnabled' => _requireBool(entry.key, entry.value),
        'translation' => _requireIntInRange(
          entry.key,
          entry.value,
          min: 0,
          max: quran.Translation.values.length - 1,
        ),
        'color' => _requireIntInRange(
          entry.key,
          entry.value,
          min: 0,
          max: _themeColorCount - 1,
        ),
        'locale' => _requireLocale(entry.value),
        'themeMode' => _requireThemeMode(entry.value),
        'themeScheme' => _requireThemeScheme(entry.value),
        'reciter' => _requireReciterCode(entry.value),
        'fontSize' => _requireDoubleInRange(
          entry.key,
          entry.value,
          min: 25,
          max: 65,
        ),
        'fontSizeTranslation' => _requireDoubleInRange(
          entry.key,
          entry.value,
          min: 10,
          max: 30,
        ),
        'playbackRate' => _requireAllowedDouble(
          entry.key,
          entry.value,
          const <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
        ),
        'dailyQuranGoalAyahs' => _requireIntInRange(
          entry.key,
          entry.value,
          min: 1,
          max: 1000,
        ),
        'dailyAyahDate' => _requireDateKey(entry.key, entry.value),
        'dailyAyahGlobalAyah' => _requireIntInRange(
          entry.key,
          entry.value,
          min: 1,
          max: 6236,
        ),
        'ayahDelaySeconds' => _requireIntInRange(
          entry.key,
          entry.value,
          min: 0,
          max: 10,
        ),
        'intervalRepeatCount' ||
        'repeatAyahCount' => _requireRepeatCount(entry.key, entry.value),
        'playbackInterval' => _sanitizePlaybackIntervalMap(
          _requireJsonMap(entry.key, entry.value),
        ),
        'prayerTimeSettings' => _sanitizePrayerTimeSettingsMap(
          _requireJsonMap(entry.key, entry.value),
        ),
        'prayerLocation' => _requireJsonMap(entry.key, entry.value),
        _ => throw AppBackupException(
          'The backup file contains an unsupported setting: ${entry.key}.',
        ),
      };
    }

    return validated;
  }

  static void _validateFavourites(Map<String, dynamic> favourites) {
    for (final MapEntry<String, dynamic> entry in favourites.entries) {
      final RegExpMatch? match = RegExp(
        r'^(\d{1,3})-(\d{3})$',
      ).firstMatch(entry.key);
      if (match == null) {
        throw AppBackupException(
          'The backup file contains an invalid favourite key.',
        );
      }

      final int surah = int.parse(match.group(1)!);
      final int verse = int.parse(match.group(2)!);
      if (surah < 1 ||
          surah > 114 ||
          verse < 1 ||
          verse > quran.getVerseCount(surah)) {
        throw AppBackupException(
          'The backup file contains an out-of-range favourite entry.',
        );
      }
      if (entry.value is! String) {
        throw AppBackupException('Favourite notes must be stored as text.');
      }
      if ((entry.value as String).length > 80) {
        throw AppBackupException(
          'A favourite note exceeds the supported length.',
        );
      }
    }
  }

  static bool _requireBool(String key, dynamic value) {
    if (value is! bool) {
      throw AppBackupException('Invalid value for "$key".');
    }
    return value;
  }

  static int _requireIntInRange(
    String key,
    dynamic value, {
    required int min,
    required int max,
  }) {
    if (value is! int || value < min || value > max) {
      throw AppBackupException('Invalid value for "$key".');
    }
    return value;
  }

  static String _requireDateKey(String key, dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw AppBackupException('Invalid value for "$key".');
    }
    return value;
  }

  static double _requireDoubleInRange(
    String key,
    dynamic value, {
    required double min,
    required double max,
  }) {
    if (value is! double) {
      throw AppBackupException('Invalid value for "$key".');
    }
    if (!value.isFinite || value < min || value > max) {
      throw AppBackupException('Invalid value for "$key".');
    }
    return value;
  }

  static double _requireAllowedDouble(
    String key,
    dynamic value,
    List<double> allowed,
  ) {
    final double normalized = _requireDoubleInRange(
      key,
      value,
      min: allowed.reduce((a, b) => a < b ? a : b),
      max: allowed.reduce((a, b) => a > b ? a : b),
    );
    if (!allowed.any((double candidate) => candidate == normalized)) {
      throw AppBackupException('Invalid value for "$key".');
    }
    return normalized;
  }

  static String _requireThemeMode(dynamic value) {
    if (value is! String ||
        (value != 'light' && value != 'dark' && value != 'auto')) {
      throw AppBackupException('Invalid value for "themeMode".');
    }
    return value;
  }

  static String _requireLocale(dynamic value) {
    if (value is! String ||
        !const <String>{
          'system',
          'en',
          'ar',
          'fa',
          'ur',
          'bn',
          'tr',
          'id',
          'de',
        }.contains(value)) {
      throw AppBackupException('Invalid value for "locale".');
    }
    return value;
  }

  static String _requireThemeScheme(dynamic value) {
    if (value is! String ||
        (value != 'default' &&
            value != 'fancyBlue' &&
            value != 'fancyPurple' &&
            value != 'sepia' &&
            value != 'black' &&
            value != 'red')) {
      throw AppBackupException('Invalid value for "themeScheme".');
    }
    return value;
  }

  static String _requireReciterCode(dynamic value) {
    if (value is! String) {
      throw AppBackupException('Invalid value for "reciter".');
    }
    final String normalizedCode = AppReciter.normalizeCode(value);
    final bool isValid = AppReciter.values.any(
      (AppReciter reciter) => reciter.code == normalizedCode,
    );
    if (!isValid) {
      throw AppBackupException('Invalid value for "reciter".');
    }
    return normalizedCode;
  }

  static int _requireRepeatCount(String key, dynamic value) {
    if (value is! int || !<int>{0, 1, 3, 5, 11, 19}.contains(value)) {
      throw AppBackupException('Invalid value for "$key".');
    }
    return value;
  }

  static Map<String, dynamic> _sanitizePlaybackIntervalMap(
    Map<String, dynamic> value,
  ) {
    final Map<String, dynamic> start = _requireJsonMap(
      'playbackInterval.start',
      value['start'],
    );
    final Map<String, dynamic> end = _requireJsonMap(
      'playbackInterval.end',
      value['end'],
    );
    final int startSurah = _requireIntInRange(
      'playbackInterval.start.surah',
      start['surah'],
      min: 1,
      max: 114,
    );
    final int startAyah = _requireIntInRange(
      'playbackInterval.start.ayah',
      start['ayah'],
      min: 1,
      max: quran.getVerseCount(startSurah),
    );
    final int endSurah = _requireIntInRange(
      'playbackInterval.end.surah',
      end['surah'],
      min: 1,
      max: 114,
    );
    final int endAyah = _requireIntInRange(
      'playbackInterval.end.ayah',
      end['ayah'],
      min: 1,
      max: quran.getVerseCount(endSurah),
    );
    if (endSurah < startSurah ||
        (endSurah == startSurah && endAyah < startAyah)) {
      throw AppBackupException('Invalid value for "playbackInterval".');
    }
    return <String, dynamic>{
      'start': <String, int>{'surah': startSurah, 'ayah': startAyah},
      'end': <String, int>{'surah': endSurah, 'ayah': endAyah},
    };
  }

  static Map<String, dynamic> _requireJsonMap(String key, dynamic value) {
    if (value is! Map) {
      throw AppBackupException('Invalid value for "$key".');
    }
    return value.map<String, dynamic>((dynamic mapKey, dynamic mapValue) {
      if (mapKey is! String) {
        throw AppBackupException('Invalid value for "$key".');
      }
      return MapEntry<String, dynamic>(
        mapKey,
        _requireJsonValue(key, mapValue),
      );
    });
  }

  static dynamic _settingValueForBackup(String key, dynamic value) {
    if (key == 'prayerTimeSettings' && value is Map) {
      return _sanitizePrayerTimeSettingsMap(
        value.map<String, dynamic>(
          (dynamic mapKey, dynamic mapValue) =>
              MapEntry(mapKey.toString(), mapValue),
        ),
      );
    }
    if (key == 'playbackInterval' && value is Map) {
      return _sanitizePlaybackIntervalMap(
        value.map<String, dynamic>(
          (dynamic mapKey, dynamic mapValue) =>
              MapEntry(mapKey.toString(), mapValue),
        ),
      );
    }
    return value;
  }

  static Map<String, dynamic> _sanitizePrayerTimeSettingsMap(
    Map<String, dynamic> value,
  ) {
    final Map<String, dynamic> sanitized = Map<String, dynamic>.from(value)
      ..remove(_removedExtraPrayerOffsetKey);
    final dynamic offsets = sanitized['offsets'];
    if (offsets is Map) {
      sanitized['offsets'] = Map<String, dynamic>.from(
        offsets.map(
          (dynamic key, dynamic mapValue) => MapEntry(key.toString(), mapValue),
        ),
      )..remove(_removedExtraPrayerKey);
    }
    sanitized.remove('notifications');
    return sanitized;
  }

  static String get _removedExtraPrayerKey {
    return String.fromCharCodes(const <int>[100, 104, 117, 104, 97]);
  }

  static String get _removedExtraPrayerOffsetKey {
    return String.fromCharCodes(const <int>[
      100,
      104,
      117,
      104,
      97,
      77,
      105,
      110,
      117,
      116,
      101,
      115,
      65,
      102,
      116,
      101,
      114,
      83,
      117,
      110,
      114,
      105,
      115,
      101,
    ]);
  }

  static dynamic _requireJsonValue(String key, dynamic value) {
    if (value == null ||
        value is String ||
        value is bool ||
        value is int ||
        value is double) {
      return value;
    }
    if (value is List) {
      return value
          .map<dynamic>((dynamic item) => _requireJsonValue(key, item))
          .toList();
    }
    if (value is Map) {
      return _requireJsonMap(key, value);
    }
    throw AppBackupException('Invalid value for "$key".');
  }

  static void _verifyPayloadIntegrity(Map<dynamic, dynamic> payload) {
    final dynamic integrity = payload['integrity'];
    if (integrity is! String || integrity.isEmpty) {
      throw AppBackupException(
        'The backup file is missing its integrity check.',
      );
    }

    final String expected = _integrityHashFor(
      payload.map(
        (dynamic key, dynamic value) => MapEntry(key.toString(), value),
      ),
    );
    if (integrity != expected) {
      throw AppBackupException('The backup file failed integrity validation.');
    }
  }

  static String _integrityHashFor(Map<String, dynamic> payload) {
    final Map<String, dynamic> sanitized = Map<String, dynamic>.from(payload)
      ..remove('integrity');
    final String canonical = jsonEncode(_canonicalize(sanitized));
    final int crc32 = _computeCrc32(utf8.encode(canonical));
    return crc32.toRadixString(16).padLeft(8, '0');
  }

  static int _computeCrc32(List<int> bytes) {
    int crc = 0xffffffff;
    for (final int byte in bytes) {
      crc ^= byte;
      for (int bit = 0; bit < 8; bit++) {
        final bool hasLowBit = (crc & 1) != 0;
        crc = crc >> 1;
        if (hasLowBit) {
          crc ^= 0xedb88320;
        }
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final List<String> sortedKeys =
          value.keys.map((dynamic key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final String key in sortedKeys) key: _canonicalize(value[key]),
      };
    }
    if (value is List) {
      return value.map<Object?>((dynamic item) => _canonicalize(item)).toList();
    }
    return value;
  }

  static Map<String, dynamic> _readingEntryToJson(ReadingEntry entry) {
    return <String, dynamic>{
      'surah': entry.surah,
      'verse': entry.verse,
      'timestamp': entry.timestamp.toUtc().toIso8601String(),
    };
  }

  static String _buildFileName() {
    final String timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-');
    return 'equran-backup-$timestamp.equranbackup';
  }
}
