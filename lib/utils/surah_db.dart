import 'package:hive/hive.dart';

class SurahDB {
  // Private constructor
  SurahDB._privateConstructor();

  // Singleton instance
  static final SurahDB _instance = SurahDB._privateConstructor();

  // Factory constructor to return the singleton instance
  factory SurahDB() {
    return _instance;
  }

  // Hive box instance
  final Box _box = Hive.box('surahs');

  // Getter method
  dynamic get(String key) {
    return _box.get(key);
  }

  // Setter method
  Future<void> set(String key, dynamic value) async {
    await _box.put(key, value);
  }

  bool contains(String key) {
    return _box.containsKey(key);
  }
}
