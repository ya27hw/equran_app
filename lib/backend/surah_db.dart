import 'package:eQuran/backend/base_db.dart';

class SurahDB extends BaseDB {
  SurahDB._privateConstructor() : super("surahs");

  static final SurahDB _instance = SurahDB._privateConstructor();

  factory SurahDB() {
    return _instance;
  }
}
