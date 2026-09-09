import 'package:equran/backend/base_db.dart';
import 'package:equran/backend/hifz_models.dart';
import 'package:equran/backend/settings_db.dart';

class HifzEntryDB extends BaseDB {
  HifzEntryDB._() : super('hifzEntries');

  static final HifzEntryDB _instance = HifzEntryDB._();

  factory HifzEntryDB() => _instance;

  Future<void> save(HifzEntry entry) => put(entry.key, entry);

  HifzEntry? getEntry(int surah, int ayah) {
    final dynamic value = get('$surah:$ayah');
    return value is HifzEntry ? value : null;
  }

  List<HifzEntry> entries() {
    return box.values.whereType<HifzEntry>().toList(growable: false);
  }

  List<HifzEntry> dueEntries({DateTime? now}) {
    final DateTime today = _startOfDay(now ?? DateTime.now());
    final List<HifzEntry> values =
        entries()
            .where(
              (HifzEntry entry) => !_startOfDay(entry.dueDate).isAfter(today),
            )
            .toList(growable: false)
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return values;
  }

  int countDueToday({DateTime? now}) => dueEntries(now: now).length;

  int countMastered() {
    return entries()
        .where((HifzEntry entry) => entry.status == hifzStatusMastered)
        .length;
  }

  int countReviewed() {
    return entries()
        .where((HifzEntry entry) => entry.lastReviewed != null)
        .length;
  }

  Map<int, List<HifzEntry>> entriesBySurah() {
    final Map<int, List<HifzEntry>> grouped = <int, List<HifzEntry>>{};
    for (final HifzEntry entry in entries()) {
      grouped.putIfAbsent(entry.surah, () => <HifzEntry>[]).add(entry);
    }
    return grouped;
  }
}

class HifzLogDB extends BaseDB {
  HifzLogDB._() : super('hifzLogs');

  static final HifzLogDB _instance = HifzLogDB._();

  factory HifzLogDB() => _instance;

  Future<void> add(HifzReviewLog log) async {
    final List<HifzReviewLog> updated = logs().toList(growable: true)..add(log);
    await put('logs', updated);
  }

  List<HifzReviewLog> logs() {
    final dynamic value = get('logs', defaultValue: const <HifzReviewLog>[]);
    if (value is List) {
      return value.whereType<HifzReviewLog>().toList(growable: false);
    }
    return const <HifzReviewLog>[];
  }
}

class HifzPrefs {
  HifzPrefs._();

  static const int defaultMaxNewPerDay = 10;
  static const int defaultMaxReviewPerDay = 50;

  static int maxNewPerDay() {
    final dynamic val = SettingsDB().get(
      'hifzMaxNewPerDay',
      defaultValue: defaultMaxNewPerDay,
    );
    if (val is int) return val;
    if (val is num) return val.toInt();
    return defaultMaxNewPerDay;
  }

  static int maxReviewPerDay() {
    final dynamic val = SettingsDB().get(
      'hifzMaxReviewPerDay',
      defaultValue: defaultMaxReviewPerDay,
    );
    if (val is int) return val;
    if (val is num) return val.toInt();
    return defaultMaxReviewPerDay;
  }

  static bool showTransliterationByDefault() {
    final dynamic val = SettingsDB().get(
      'hifzShowTransliteration',
      defaultValue: false,
    );
    return val is bool ? val : false;
  }

  static bool showTranslationByDefault() {
    final dynamic val = SettingsDB().get(
      'hifzShowTranslation',
      defaultValue: false,
    );
    return val is bool ? val : false;
  }

  static bool autoPlayAudioOnLearn() {
    final dynamic val = SettingsDB().get(
      'hifzAutoPlayAudio',
      defaultValue: false,
    );
    return val is bool ? val : false;
  }

  static String blankingLevel() {
    final dynamic val = SettingsDB().get(
      'hifzBlankingLevel',
      defaultValue: 'auto',
    );
    return val is String ? val : 'auto';
  }

  static Future<void> setMaxNewPerDay(int value) =>
      SettingsDB().put('hifzMaxNewPerDay', value);

  static Future<void> setMaxReviewPerDay(int value) =>
      SettingsDB().put('hifzMaxReviewPerDay', value);

  static Future<void> setShowTransliterationByDefault(bool value) =>
      SettingsDB().put('hifzShowTransliteration', value);

  static Future<void> setShowTranslationByDefault(bool value) =>
      SettingsDB().put('hifzShowTranslation', value);

  static Future<void> setAutoPlayAudioOnLearn(bool value) =>
      SettingsDB().put('hifzAutoPlayAudio', value);

  static Future<void> setBlankingLevel(String value) =>
      SettingsDB().put('hifzBlankingLevel', value);

  static int newCountForDate(DateTime date) {
    final String key = 'hifzNewCount_${dateKey(date)}';
    final dynamic val = SettingsDB().get(key, defaultValue: 0);
    if (val is int) return val;
    if (val is num) return val.toInt();
    return 0;
  }

  static int reviewCountForDate(DateTime date) {
    final String key = 'hifzReviewCount_${dateKey(date)}';
    final dynamic val = SettingsDB().get(key, defaultValue: 0);
    if (val is int) return val;
    if (val is num) return val.toInt();
    return 0;
  }

  static Future<void> incrementNewCount({DateTime? now}) async {
    final DateTime value = now ?? DateTime.now();
    final String key = 'hifzNewCount_${dateKey(value)}';
    await SettingsDB().put(key, newCountForDate(value) + 1);
  }

  static Future<void> incrementReviewCount({DateTime? now}) async {
    final DateTime value = now ?? DateTime.now();
    final String key = 'hifzReviewCount_${dateKey(value)}';
    await SettingsDB().put(key, reviewCountForDate(value) + 1);
  }

  static String dateKey(DateTime date) {
    final DateTime day = _startOfDay(date);
    final String year = day.year.toString().padLeft(4, '0');
    final String month = day.month.toString().padLeft(2, '0');
    final String dayValue = day.day.toString().padLeft(2, '0');
    return '$year-$month-$dayValue';
  }
}

class HifzSummary {
  const HifzSummary({
    required this.memorized,
    required this.dueToday,
    required this.totalReviewed,
    required this.totalEntries,
  });

  final int memorized;
  final int dueToday;
  final int totalReviewed;
  final int totalEntries;
}

class HifzStatsSnapshot {
  const HifzStatsSnapshot({
    required this.totalMemorizedAyahs,
    required this.currentDailyStreak,
    required this.retentionRate,
    required this.totalReviewsDone,
    required this.nextDueEntry,
    required this.entriesBySurah,
  });

  final int totalMemorizedAyahs;
  final int currentDailyStreak;
  final double retentionRate;
  final int totalReviewsDone;
  final HifzEntry? nextDueEntry;
  final Map<int, List<HifzEntry>> entriesBySurah;
}

class HifzRepository {
  HifzRepository({HifzEntryDB? entryDb, HifzLogDB? logDb})
    : _entryDb = entryDb ?? HifzEntryDB(),
      _logDb = logDb ?? HifzLogDB();

  final HifzEntryDB _entryDb;
  final HifzLogDB _logDb;

  HifzSummary summary({DateTime? now}) {
    return HifzSummary(
      memorized: _entryDb.countMastered(),
      dueToday: _entryDb.countDueToday(now: now),
      totalReviewed: _entryDb.countReviewed(),
      totalEntries: _entryDb.entries().length,
    );
  }

  HifzStatsSnapshot stats({DateTime? now}) {
    final List<HifzReviewLog> logs = _logDb.logs().toList(growable: false)
      ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
    final int positiveRatings = logs
        .where(
          (HifzReviewLog log) =>
              log.rating == hifzRatingGood || log.rating == hifzRatingEasy,
        )
        .length;
    return HifzStatsSnapshot(
      totalMemorizedAyahs: _entryDb.countMastered(),
      currentDailyStreak: _currentDailyStreak(logs),
      retentionRate: logs.isEmpty ? 0 : (positiveRatings / logs.length) * 100,
      totalReviewsDone: logs.length,
      nextDueEntry: _entryDb.dueEntries(now: now).isEmpty
          ? null
          : _entryDb.dueEntries(now: now).first,
      entriesBySurah: _entryDb.entriesBySurah(),
    );
  }

  int _currentDailyStreak(List<HifzReviewLog> logs) {
    if (logs.isEmpty) return 0;
    final Set<String> activeDays = logs
        .map((HifzReviewLog log) => HifzPrefs.dateKey(log.reviewedAt))
        .toSet();
    int streak = 0;
    DateTime cursor = _startOfDay(DateTime.now());
    while (activeDays.contains(HifzPrefs.dateKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
