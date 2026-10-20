import 'package:hive/hive.dart';

part 'hifz_models.g.dart';

const String hifzStatusNew = 'new';
const String hifzStatusMastered = 'mastered';

const String hifzTrackSabaq = 'sabaq';

const String hifzRatingGood = 'good';
const String hifzRatingEasy = 'easy';

@HiveType(typeId: 20)
class HifzEntry {
  HifzEntry({
    required this.surah,
    required this.ayah,
    this.status = hifzStatusNew,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    required this.dueDate,
    this.lastReviewed,
    this.lapses = 0,
    this.track = hifzTrackSabaq,
  });

  @HiveField(0)
  int surah;

  @HiveField(1)
  int ayah;

  @HiveField(2)
  String status;

  @HiveField(3)
  int interval;

  @HiveField(4)
  double easeFactor;

  @HiveField(5)
  int repetitions;

  @HiveField(6)
  DateTime dueDate;

  @HiveField(7)
  DateTime? lastReviewed;

  @HiveField(8)
  int lapses;

  @HiveField(9)
  String track;

  String get key => '$surah:$ayah';

  HifzEntry copyWith({
    int? surah,
    int? ayah,
    String? status,
    int? interval,
    double? easeFactor,
    int? repetitions,
    DateTime? dueDate,
    DateTime? lastReviewed,
    bool clearLastReviewed = false,
    int? lapses,
    String? track,
  }) {
    return HifzEntry(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      status: status ?? this.status,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      lastReviewed: clearLastReviewed
          ? null
          : (lastReviewed ?? this.lastReviewed),
      lapses: lapses ?? this.lapses,
      track: track ?? this.track,
    );
  }
}

@HiveType(typeId: 21)
class HifzReviewLog {
  const HifzReviewLog({
    required this.surah,
    required this.ayah,
    required this.rating,
    required this.reviewedAt,
    required this.previousInterval,
    required this.newInterval,
  });

  @HiveField(0)
  final int surah;

  @HiveField(1)
  final int ayah;

  @HiveField(2)
  final String rating;

  @HiveField(3)
  final DateTime reviewedAt;

  @HiveField(4)
  final int previousInterval;

  @HiveField(5)
  final int newInterval;
}
