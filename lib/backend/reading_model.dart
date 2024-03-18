import 'package:hive/hive.dart';

part 'reading_model.g.dart';

@HiveType(typeId: 0)
class ReadingEntry {
  @HiveField(0)
  int surah;
  @HiveField(1)
  int verse;
  @HiveField(2)
  DateTime timestamp;

  ReadingEntry(
      {required this.surah, required this.verse, required this.timestamp});
}
