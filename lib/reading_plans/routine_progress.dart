import 'dart:math' as math;

import 'package:equran/backend/companion_storage.dart';
import 'package:equran/backend/companion_storage_models.dart';

class RoutineProgressSummary {
  const RoutineProgressSummary({
    required this.totalAyahs,
    required this.completedAyahs,
    required this.remainingAyahs,
    required this.daysRemainingIncludingToday,
    required this.todayPortionAyahs,
    required this.todayCompletedAyahs,
    required this.todayRemainingAyahs,
    required this.catchUpAyahs,
    required this.completedGlobalAyahs,
    required this.todayRequiredGlobalAyahs,
    required this.nextUnreadGlobalAyah,
    required this.contiguousCompletedGlobalAyah,
  });

  final int totalAyahs;
  final int completedAyahs;
  final int remainingAyahs;
  final int daysRemainingIncludingToday;
  final int todayPortionAyahs;
  final int todayCompletedAyahs;
  final int todayRemainingAyahs;
  final int catchUpAyahs;
  final Set<int> completedGlobalAyahs;
  final List<int> todayRequiredGlobalAyahs;
  final int nextUnreadGlobalAyah;
  final int contiguousCompletedGlobalAyah;

  bool get isRoutineDone => remainingAyahs <= 0;
  bool get isTodayDone => todayRemainingAyahs <= 0;

  double get todayFraction {
    if (todayPortionAyahs <= 0) return isRoutineDone ? 1 : 0;
    return (todayCompletedAyahs / todayPortionAyahs).clamp(0.0, 1.0).toDouble();
  }

  int get todayStartGlobalAyah => todayRequiredGlobalAyahs.isEmpty
      ? nextUnreadGlobalAyah
      : todayRequiredGlobalAyahs.first;

  int get todayEndGlobalAyah => todayRequiredGlobalAyahs.isEmpty
      ? nextUnreadGlobalAyah
      : todayRequiredGlobalAyahs.last;
}

RoutineProgressSummary routineProgressSummary(
  ReadingPlanEntry plan, {
  DateTime? now,
}) {
  final DateTime effectiveNow = now ?? DateTime.now();
  final DateTime today = _dateOnly(effectiveNow);
  final String todayKey = routineDateKey(today);
  final DateTime start = _dateOnly(plan.startedAt);
  final DateTime finish = _dateOnly(plan.finishBy);
  final DateTime scheduleDay = today.isBefore(start) ? start : today;
  final int totalAyahs = math.max(
    1,
    plan.targetGlobalAyah - plan.startGlobalAyah + 1,
  );
  final List<RoutineDayProgressEntry> entries = RoutineDayProgressDB()
      .progressEntriesForRoutine(plan.id);
  final bool hasStoredProgress = entries.any(
    (RoutineDayProgressEntry entry) => entry.completedGlobalAyahs.isNotEmpty,
  );
  final Set<int> completedGlobalAyahs = _completedFromEntries(plan, entries);
  final Set<int> completedBeforeTodayGlobalAyahs = _completedFromEntries(
    plan,
    entries.where((entry) => entry.dateKey.compareTo(todayKey) < 0),
  );

  if (!hasStoredProgress) {
    final Iterable<int> legacyCompleted = _legacyCompletedAyahs(plan);
    completedGlobalAyahs.addAll(legacyCompleted);
    completedBeforeTodayGlobalAyahs.addAll(legacyCompleted);
  }

  final int completedAyahs = completedGlobalAyahs.length.clamp(0, totalAyahs);
  final int remainingAyahs = math.max(0, totalAyahs - completedAyahs);
  final int totalDays = math.max(1, finish.difference(start).inDays + 1);
  final int elapsedDays = scheduleDay
      .difference(start)
      .inDays
      .clamp(0, totalDays)
      .toInt();
  final int daysRemaining = math.max(
    1,
    finish.difference(scheduleDay).inDays + 1,
  );
  final int remainingAtStartOfDay = math.max(
    0,
    totalAyahs - completedBeforeTodayGlobalAyahs.length,
  );
  final int todayPortionAyahs = remainingAtStartOfDay <= 0
      ? 0
      : math.min(
          remainingAtStartOfDay,
          (remainingAtStartOfDay / daysRemaining).ceil(),
        );
  final int perScheduledDay = (totalAyahs / totalDays).ceil();
  final int expectedCompletedBeforeToday = math.min(
    totalAyahs,
    elapsedDays * perScheduledDay,
  );
  final int missedBeforeToday = math.max(
    0,
    expectedCompletedBeforeToday - completedBeforeTodayGlobalAyahs.length,
  );
  final int catchUpAyahs = math.min(todayPortionAyahs, missedBeforeToday);
  final List<int> todayRequiredGlobalAyahs = _firstIncompleteAyahs(
    plan,
    completedBeforeTodayGlobalAyahs,
    todayPortionAyahs,
  );
  final int todayCompletedAyahs = todayRequiredGlobalAyahs
      .where(completedGlobalAyahs.contains)
      .length
      .clamp(0, todayPortionAyahs)
      .toInt();
  final int todayRemainingAyahs = math.max(
    0,
    todayPortionAyahs - todayCompletedAyahs,
  );
  final int nextUnreadGlobalAyah = _nextUnreadGlobalAyah(
    plan,
    completedGlobalAyahs,
  );
  final int contiguousCompletedGlobalAyah = _contiguousCompletedGlobalAyah(
    plan,
    completedGlobalAyahs,
  );

  return RoutineProgressSummary(
    totalAyahs: totalAyahs,
    completedAyahs: completedAyahs,
    remainingAyahs: remainingAyahs,
    daysRemainingIncludingToday: daysRemaining,
    todayPortionAyahs: todayPortionAyahs,
    todayCompletedAyahs: todayCompletedAyahs,
    todayRemainingAyahs: todayRemainingAyahs,
    catchUpAyahs: catchUpAyahs,
    completedGlobalAyahs: completedGlobalAyahs,
    todayRequiredGlobalAyahs: todayRequiredGlobalAyahs,
    nextUnreadGlobalAyah: nextUnreadGlobalAyah,
    contiguousCompletedGlobalAyah: contiguousCompletedGlobalAyah,
  );
}

String routineDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int routineContiguousCompletedGlobalAyah(
  ReadingPlanEntry plan,
  Set<int> completedGlobalAyahs,
) {
  return _contiguousCompletedGlobalAyah(plan, completedGlobalAyahs);
}

Set<int> _completedFromEntries(
  ReadingPlanEntry plan,
  Iterable<RoutineDayProgressEntry> entries,
) {
  return entries
      .expand((RoutineDayProgressEntry entry) => entry.completedGlobalAyahs)
      .where((int ayah) => _isInPlan(plan, ayah))
      .toSet();
}

Iterable<int> _legacyCompletedAyahs(ReadingPlanEntry plan) sync* {
  final int end = plan.lastCompletedGlobalAyah.clamp(
    plan.startGlobalAyah - 1,
    plan.targetGlobalAyah,
  );
  for (int ayah = plan.startGlobalAyah; ayah <= end; ayah++) {
    yield ayah;
  }
}

List<int> _firstIncompleteAyahs(
  ReadingPlanEntry plan,
  Set<int> completedGlobalAyahs,
  int limit,
) {
  if (limit <= 0) return const <int>[];
  final List<int> ayahs = <int>[];
  for (
    int ayah = plan.startGlobalAyah;
    ayah <= plan.targetGlobalAyah && ayahs.length < limit;
    ayah++
  ) {
    if (!completedGlobalAyahs.contains(ayah)) {
      ayahs.add(ayah);
    }
  }
  return ayahs;
}

int _nextUnreadGlobalAyah(
  ReadingPlanEntry plan,
  Set<int> completedGlobalAyahs,
) {
  for (int ayah = plan.startGlobalAyah; ayah <= plan.targetGlobalAyah; ayah++) {
    if (!completedGlobalAyahs.contains(ayah)) return ayah;
  }
  return plan.targetGlobalAyah;
}

int _contiguousCompletedGlobalAyah(
  ReadingPlanEntry plan,
  Set<int> completedGlobalAyahs,
) {
  int completed = plan.startGlobalAyah - 1;
  for (int ayah = plan.startGlobalAyah; ayah <= plan.targetGlobalAyah; ayah++) {
    if (!completedGlobalAyahs.contains(ayah)) break;
    completed = ayah;
  }
  return completed.clamp(0, plan.targetGlobalAyah).toInt();
}

bool _isInPlan(ReadingPlanEntry plan, int ayah) {
  return ayah >= plan.startGlobalAyah && ayah <= plan.targetGlobalAyah;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
