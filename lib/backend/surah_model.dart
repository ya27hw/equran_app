import 'package:hive/hive.dart';

part 'surah_model.g.dart';

@HiveType(typeId: 1)
class Surah {
  @HiveField(0)
  int id;
  @HiveField(1)
  String transliteration;
  @HiveField(2)
  String name;
  @HiveField(3)
  int verses;

  Surah(
      {required this.id,
      required this.transliteration,
      required this.name,
      required this.verses});
}
