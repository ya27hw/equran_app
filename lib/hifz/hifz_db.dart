import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/hifz_entry.dart';
import 'models/hifz_review_log.dart';
import 'models/hifz_unit.dart';
import 'package:quran/quran.dart' as quran;
import 'hifz_surah_data.dart';

class HifzDB {
  static const String entriesBoxName = 'hifzEntries';
  static const String logsBoxName = 'hifzLogs';
  static const String unitsBoxName = 'hifzUnits';

  static Future<void> init() async {
    try {
      await Hive.openBox<HifzEntry>(entriesBoxName);
      await Hive.openBox<HifzReviewLog>(logsBoxName);
      await Hive.openBox<HifzUnit>(unitsBoxName);
    } catch (error, stackTrace) {
      // Never delete a user's memorization data as a recovery shortcut. The
      // caller can surface a categorized storage error and offer an export or
      // repair flow while the original Hive files remain intact.
      debugPrint('Hifz storage initialization failed: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'equran hifz storage',
          context: ErrorDescription('while opening Hifz boxes'),
        ),
      );
      rethrow;
    }
  }

  static Box<HifzEntry> get _entries => Hive.box<HifzEntry>(entriesBoxName);

  static Box<HifzReviewLog> get _logs => Hive.box<HifzReviewLog>(logsBoxName);

  // Save or update a single entry
  static Future<void> saveEntry(HifzEntry entry) async {
    await _entries.put(entry.key, entry);
  }

  // Get a single entry, null if not exists
  static HifzEntry? getEntry(int surah, int ayah) {
    return _entries.get('$surah:$ayah');
  }

  // Get all entries
  static List<HifzEntry> getAllEntries() {
    return _entries.values.toList();
  }

  // Get all due entries sorted by dueDate ascending
  static List<HifzEntry> getDueEntries() {
    final now = DateTime.now().add(const Duration(hours: 1));
    return _entries.values.where((e) => e.dueDate.isBefore(now)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // Get entries with status 'new' not yet due
  static List<HifzEntry> getNewEntries() {
    return _entries.values.where((e) => e.status == 'new').toList()
      ..sort((a, b) {
        if (a.surah != b.surah) return a.surah.compareTo(b.surah);
        return a.ayah.compareTo(b.ayah);
      });
  }

  // ── UNIT METHODS ─────────────────────

  static Box<HifzUnit> get _units => Hive.box<HifzUnit>(unitsBoxName);

  static ValueListenable<Box<HifzUnit>> get unitsListenable =>
      _units.listenable();

  static Future<void> saveUnit(HifzUnit unit) async {
    await _units.put(unit.id, unit);
  }

  static HifzUnit? getUnit(String id) => _units.get(id);

  static List<HifzUnit> getAllUnits() =>
      _units.values.toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  static List<HifzUnit> getActiveUnits() =>
      _units.values.where((u) => !u.isComplete).toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  // Create a new unit and populate HifzEntry
  // records for all ayahs in the unit
  // All start as status: 'unseen'
  static Future<HifzUnit> createUnit({
    required HifzUnitType type,
    required int unitNumber,
  }) async {
    final id = type == HifzUnitType.surah
        ? 'surah_$unitNumber'
        : 'juz_$unitNumber';

    // Do not duplicate if already exists
    if (_units.containsKey(id)) {
      return _units.get(id)!;
    }

    // Build ordered ayah list
    final List<(int, int)> ayahs;
    if (type == HifzUnitType.surah) {
      ayahs = List.generate(
        HifzSurahData.ayahCount(unitNumber),
        (i) => (unitNumber, i + 1),
      );
    } else {
      final juzData = quran.getSurahAndVersesFromJuz(unitNumber);
      ayahs = [];
      for (final entry in juzData.entries) {
        final surah = entry.key;
        final range = entry.value;
        for (int a = range[0]; a <= range[1]; a++) {
          ayahs.add((surah, a));
        }
      }
    }

    final firstAyah = ayahs.first;

    final unit = HifzUnit()
      ..id = id
      ..unitType = type == HifzUnitType.surah ? 'surah' : 'juz'
      ..unitNumber = unitNumber
      ..frontierSurah = firstAyah.$1
      ..frontierAyah = firstAyah.$2
      ..startedAt = DateTime.now()
      ..completedAt = null
      ..isComplete = false;

    await _units.put(id, unit);

    // Create HifzEntry for every ayah in unit
    // with status 'unseen'
    for (int i = 0; i < ayahs.length; i++) {
      final (s, a) = ayahs[i];
      final key = '$s:$a';
      if (_entries.containsKey(key)) continue;

      final entry = HifzEntry()
        ..surah = s
        ..ayah = a
        ..status = 'unseen'
        ..interval = 0
        ..easeFactor = 2.5
        ..repetitions = 0
        ..dueDate = DateTime.now()
        ..lastReviewed = null
        ..lapses = 0
        ..track = 'sabaq'
        ..unitId = id
        ..sequenceIndex = i
        ..introducedRepetitions = 0
        ..firstLearnedAt = null;

      await _entries.put(key, entry);
    }

    return unit;
  }

  // Advance the frontier by n ayahs
  // Returns the newly unlocked entries
  // in sequential order
  static Future<List<HifzEntry>> advanceFrontier(
    HifzUnit unit,
    int count,
  ) async {
    final List<(int, int)> allAyahs;
    if (unit.type == HifzUnitType.surah) {
      allAyahs = List.generate(
        HifzSurahData.ayahCount(unit.unitNumber),
        (i) => (unit.unitNumber, i + 1),
      );
    } else {
      final juzData = quran.getSurahAndVersesFromJuz(unit.unitNumber);
      allAyahs = [];
      for (final entry in juzData.entries) {
        final surah = entry.key;
        final range = entry.value;
        for (int a = range[0]; a <= range[1]; a++) {
          allAyahs.add((surah, a));
        }
      }
    }

    // Find current frontier index
    final frontierIdx = allAyahs.indexWhere(
      (e) => e.$1 == unit.frontierSurah && e.$2 == unit.frontierAyah,
    );

    if (frontierIdx < 0) return [];

    final newlyUnlocked = <HifzEntry>[];

    for (
      int i = frontierIdx;
      i < frontierIdx + count && i < allAyahs.length;
      i++
    ) {
      final (s, a) = allAyahs[i];
      final entry = getEntry(s, a);
      if (entry == null) continue;
      if (entry.status != 'unseen') continue;

      entry.status = 'learning';
      entry.firstLearnedAt = DateTime.now();
      entry.dueDate = DateTime.now();
      await saveEntry(entry);
      newlyUnlocked.add(entry);
    }

    // Update frontier to next unseen
    final nextIdx = frontierIdx + count;
    if (nextIdx >= allAyahs.length) {
      unit.isComplete = true;
      unit.completedAt = DateTime.now();
      unit.frontierSurah = allAyahs.last.$1;
      unit.frontierAyah = allAyahs.last.$2;
    } else {
      unit.frontierSurah = allAyahs[nextIdx].$1;
      unit.frontierAyah = allAyahs[nextIdx].$2;
    }
    await saveUnit(unit);

    return newlyUnlocked;
  }

  // ── SEQUENTIAL SESSION QUERIES ────────

  // Get today's new ayahs for a unit
  // Returns up to maxNew entries with
  // status == 'learning' (any rep count)
  // in sequenceIndex ascending order
  static List<HifzEntry> getNewAyahsForUnit(String unitId, int maxNew) {
    final filtered =
        _entries.values
            .where((e) => e.unitId == unitId && e.status == 'learning')
            .toList()
          ..sort(
            (a, b) => (a.sequenceIndex ?? 0).compareTo(b.sequenceIndex ?? 0),
          );
    return filtered.take(maxNew).toList();
  }

  // Get sabqi ayahs — graduated to review in last 7 days
  // and due for revision today.
  // Excludes 'learning' entries (still doing learn reps).
  // Returns in sequenceIndex ascending order.
  static List<HifzEntry> getSabqiAyahs(String unitId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final now = DateTime.now().add(const Duration(hours: 1));
    return _entries.values
        .where(
          (e) =>
              e.unitId == unitId &&
              e.status == 'review' &&
              e.firstLearnedAt != null &&
              e.firstLearnedAt!.isAfter(cutoff) &&
              e.dueDate.isBefore(now),
        )
        .toList()
      ..sort((a, b) => (a.sequenceIndex ?? 0).compareTo(b.sequenceIndex ?? 0));
  }

  // Get manzil ayahs — older than 7 days
  // due for SM-2 review today
  // Returns in sequenceIndex ascending order
  static List<HifzEntry> getManzilAyahs(String unitId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final now = DateTime.now().add(const Duration(hours: 1));
    return _entries.values
        .where(
          (e) =>
              e.unitId == unitId &&
              (e.status == 'review' || e.status == 'mastered') &&
              (e.firstLearnedAt == null ||
                  e.firstLearnedAt!.isBefore(cutoff)) &&
              e.dueDate.isBefore(now),
        )
        .toList()
      ..sort((a, b) => (a.sequenceIndex ?? 0).compareTo(b.sequenceIndex ?? 0));
  }

  // Get all entries for a unit in order
  static List<HifzEntry> getUnitEntries(String unitId) {
    return _entries.values.where((e) => e.unitId == unitId).toList()
      ..sort((a, b) => (a.sequenceIndex ?? 0).compareTo(b.sequenceIndex ?? 0));
  }

  // Update getStatusCounts to include 'unseen'
  static Map<String, int> getStatusCounts() {
    final counts = <String, int>{
      'unseen': 0,
      'learning': 0,
      'review': 0,
      'mastered': 0,
    };
    for (final e in _entries.values) {
      counts[e.status] = (counts[e.status] ?? 0) + 1;
    }
    return counts;
  }

  // Count mastered ayahs per surah
  // Returns Map<surahNumber, masteredCount>
  static Map<int, int> getMasteredPerSurah() {
    final result = <int, int>{};
    for (final e in _entries.values.where((e) => e.status == 'mastered')) {
      result[e.surah] = (result[e.surah] ?? 0) + 1;
    }
    return result;
  }

  // Get all entries for a specific surah
  static List<HifzEntry> getEntriesForSurah(int surah) {
    return _entries.values.where((e) => e.surah == surah).toList()
      ..sort((a, b) => a.ayah.compareTo(b.ayah));
  }

  // Save review log
  static Future<void> saveLog(HifzReviewLog log) async {
    await _logs.add(log);
  }

  // Get logs for a date range
  static List<HifzReviewLog> getLogsForRange(DateTime from, DateTime to) {
    return _logs.values
        .where((l) => l.reviewedAt.isAfter(from) && l.reviewedAt.isBefore(to))
        .toList();
  }

  // Get retention rate (0.0 to 1.0)
  // = (good + easy) / total ratings, all time
  static double getRetentionRate() {
    final logs = _logs.values.toList();
    if (logs.isEmpty) return 0.0;
    final positive = logs
        .where(
          (l) =>
              l.rating == 'good' ||
              l.rating == 'easy' ||
              l.rating == 'pass' ||
              l.rating == 'gotIt',
        )
        .length;
    return positive / logs.length;
  }

  // Get total review count for today
  static int getTodayReviewCount() {
    final today = DateTime.now();
    return _logs.values.where((l) {
      return l.reviewedAt.year == today.year &&
          l.reviewedAt.month == today.month &&
          l.reviewedAt.day == today.day;
    }).length;
  }

  // Check if any hifz activity on a given date
  // Used for Statistics heatmap integration
  static bool hasActivityOnDate(DateTime date) {
    return _logs.values.any(
      (l) =>
          l.reviewedAt.year == date.year &&
          l.reviewedAt.month == date.month &&
          l.reviewedAt.day == date.day,
    );
  }

  // Compatibility shim: maps old UI calls to the new unit-based sequential system
  static Future<void> addAyahRange({
    required int surah,
    required int startAyah,
    required int endAyah,
  }) async {
    await createUnit(type: HifzUnitType.surah, unitNumber: surah);
  }

  // Delete a single entry
  static Future<void> deleteEntry(int surah, int ayah) async {
    await _entries.delete('$surah:$ayah');
  }

  // Listenable for ValueListenableBuilder
  static ValueListenable<Box<HifzEntry>> get entriesListenable =>
      _entries.listenable();
}
