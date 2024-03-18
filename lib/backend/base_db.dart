import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BaseDB {
  final String boxName;

  // Constructor
  BaseDB(this.boxName);

  late final Box _box;

  Future<void> initBox() async {
    _box = await Hive.openBox(boxName);
  }

  dynamic get(dynamic key, {dynamic defaultValue}) {
    return _box.get(key, defaultValue: defaultValue);
  }

  bool contains(dynamic key) {
    return _box.containsKey(key);
  }

  Future<void> put(dynamic key, dynamic value) async {
    await _box.put(key, value);
  }

  Future<void> delete(dynamic key) async {
    await _box.delete(key);
  }

  int get length => _box.length;

  Iterable<dynamic> getKeys() {
    return _box.keys;
  }

  Future<void> clear() async {
    await _box.clear();
  }

  ValueListenable<Box<dynamic>> get listener => _box.listenable();
}
