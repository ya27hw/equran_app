import 'dart:math' as math;
import 'hifz_db.dart';
import 'hifz_limits.dart';
import 'models/hifz_unit.dart';

class HifzFrontierService {
  // Call at the END of every session.
  // Advances the frontier for the unit
  // by the number of ayahs graduated today.
  // This ensures tomorrow's session has
  // fresh content ready without the user
  // needing to do anything.
  static Future<void> advanceAfterSession({
    required HifzUnit unit,
    required int graduatedToday,
  }) async {
    try {
      if (unit.isComplete) return;
      if (graduatedToday <= 0) return;

      // Advance frontier by graduated count
      // capped at remainingNewToday
      final advanceBy = math.min(graduatedToday, HifzLimits.remainingNewToday);

      // If nothing to advance, still check
      // if frontier needs seeding
      if (advanceBy > 0) {
        await HifzDB.advanceFrontier(unit, advanceBy);
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Call on app startup and on session complete.
  // For each active unit, ensure the frontier
  // is far enough ahead that the user always
  // has at least 1 new ayah ready to learn.
  // If new ayahs have been exhausted (all
  // learning entries have been graduated),
  // advance the frontier to unlock more.
  static Future<void> ensureFrontierReady(HifzUnit unit) async {
    try {
      if (unit.isComplete) return;

      final available = HifzDB.getNewAyahsForUnit(
        unit.id,
        HifzLimits.maxNewPerDay,
      );

      if (available.isEmpty) {
        // No new ayahs waiting — advance
        // frontier to unlock next batch
        await HifzDB.advanceFrontier(unit, HifzLimits.maxNewPerDay);
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Call once per day (on app open).
  // Runs ensureFrontierReady for all
  // active units.
  static Future<void> dailyFrontierCheck() async {
    try {
      final units = HifzDB.getActiveUnits();
      for (final unit in units) {
        await ensureFrontierReady(unit);
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Returns total due count across all
  // active units. Used by home page
  // reminder card and statistics.
  static int totalDueCount() {
    try {
      int total = 0;
      for (final unit in HifzDB.getActiveUnits()) {
        total += HifzDB.getSabqiAyahs(unit.id).length;
        total += HifzDB.getManzilAyahs(unit.id).length;
        total += math.min(
          HifzDB.getNewAyahsForUnit(unit.id, 999).length,
          HifzLimits.remainingNewToday,
        );
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // Returns per-unit due summary.
  // Used by Statistics page.
}

class HifzUnitDueSummary {
  final int newCount;
  final int sabqiCount;
  final int manzilCount;
  final HifzUnit unit;
  int get total => newCount + sabqiCount + manzilCount;

  const HifzUnitDueSummary({
    required this.newCount,
    required this.sabqiCount,
    required this.manzilCount,
    required this.unit,
  });
}
