import 'package:eQuran/backend/base_db.dart';

class FavouritesDB extends BaseDB {
  FavouritesDB._privateConstructor() : super("favourites");

  static final FavouritesDB _instance = FavouritesDB._privateConstructor();

  factory FavouritesDB() {
    return _instance;
  }
}
