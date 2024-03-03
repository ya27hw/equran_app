import 'package:hive_flutter/hive_flutter.dart';

class SettingsDB {
  final _box = Hive.box("settings");

  dynamic get(String key) {
    return _box.get(key);
  }

  Future<void> set(String key ,dynamic value) async {
    await _box.put(key, value);
  }
}
