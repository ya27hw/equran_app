import 'package:hive/hive.dart';

class SettingsDB {
  // Private constructor
  SettingsDB._privateConstructor();

  // Singleton instance
  static final SettingsDB _instance = SettingsDB._privateConstructor();

  // Factory constructor to return the singleton instance
  factory SettingsDB() {
    return _instance;
  }

  // Hive box instance
  final Box _box = Hive.box('settings');

  // Getter method
  dynamic get(String key, dynamic defaultValue) {
    return _box.get(key, defaultValue: defaultValue);
  }

  // Setter method
  Future<void> set(String key, dynamic value) async {
    await _box.put(key, value);
  }
}
