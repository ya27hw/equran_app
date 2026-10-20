import 'dart:math';
import 'package:equran/backend/settings_db.dart';

class HifzLimits {
  static const String _maxNewKey = 'hifzMaxNewPerDay';
  static const String _maxReviewKey = 'hifzMaxReviewPerDay';

  static String _todayKey(String prefix) {
    final d = DateTime.now();
    return '${prefix}_${d.year}-${d.month}-${d.day}';
  }

  static SettingsDB get prefsBox => SettingsDB();

  static int get maxNewPerDay =>
      prefsBox.get(_maxNewKey, defaultValue: 10) as int;

  static int get maxReviewPerDay =>
      prefsBox.get(_maxReviewKey, defaultValue: 50) as int;

  static set maxNewPerDay(int v) => prefsBox.put(_maxNewKey, v);

  static set maxReviewPerDay(int v) => prefsBox.put(_maxReviewKey, v);

  static int get todayIntroducedCount =>
      prefsBox.get(_todayKey('hifzIntroduced'), defaultValue: 0) as int;

  // Compatibility aliases — do not remove
  // the originals above
  static int get todayNewCount => todayIntroducedCount;

  // Returns how many new ayahs can still
  // be introduced today across all units
  static int get remainingIntroducableToday =>
      max(0, maxNewPerDay - todayIntroducedCount);

  // Compatibility aliases — do not remove
  // the originals above
  static int get remainingNewToday => remainingIntroducableToday;

  static int get todayReviewCount =>
      prefsBox.get(_todayKey('hifzReview'), defaultValue: 0) as int;

  static Future<void> incrementIntroduced() async =>
      prefsBox.put(_todayKey('hifzIntroduced'), todayIntroducedCount + 1);

  // Compatibility aliases — do not remove
  // the originals above
  static Future<void> incrementNew() => incrementIntroduced();

  static Future<void> incrementReview() async =>
      prefsBox.put(_todayKey('hifzReview'), todayReviewCount + 1);
}
