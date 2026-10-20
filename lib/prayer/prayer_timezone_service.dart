import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

abstract class PrayerTimezoneResolver {
  String? timezoneIdForCoordinates(double latitude, double longitude);
}

class DevicePrayerTimezoneResolver implements PrayerTimezoneResolver {
  const DevicePrayerTimezoneResolver();

  @override
  String? timezoneIdForCoordinates(double latitude, double longitude) {
    return PrayerTimezoneService.deviceTimezoneId;
  }
}

class PrayerTimezoneService {
  const PrayerTimezoneService._();

  static bool _databaseInitialized = false;
  static String? _deviceTimezoneId;

  static void ensureDatabaseInitialized() {
    if (_databaseInitialized) return;
    timezone_data.initializeTimeZones();
    _databaseInitialized = true;
  }

  static Future<String?> configureDeviceTimezone() async {
    ensureDatabaseInitialized();
    try {
      final TimezoneInfo localTimezone =
          await FlutterTimezone.getLocalTimezone();
      final String timezoneId = localTimezone.identifier.trim();
      if (timezoneId.isEmpty) return null;
      final timezone.Location? location = locationForId(timezoneId);
      if (location == null) {
        if (kDebugMode) {
          debugPrint(
            'Prayer device timezone has no database entry: $timezoneId',
          );
        }
        return null;
      }
      timezone.setLocalLocation(location);
      _deviceTimezoneId = timezoneId;
      return location.name;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Prayer device timezone lookup failed: $error');
      }
      return null;
    }
  }

  static timezone.Location? locationForId(String? timezoneId) {
    ensureDatabaseInitialized();
    final String? trimmed = _cleanTimezoneId(timezoneId);
    if (trimmed == null) return null;
    try {
      return timezone.getLocation(trimmed);
    } catch (_) {
      final String? alias = _timezoneAliases[trimmed];
      if (alias == null) return null;
      try {
        return timezone.getLocation(alias);
      } catch (_) {
        return null;
      }
    }
  }

  /// Backward-compatibility links that the bundled tz database omits. Each
  /// alias must share its target's current offset and DST rules.
  static const Map<String, String> _timezoneAliases = {
    'Asia/Muscat': 'Asia/Dubai', // Gulf Standard Time (+04), no DST
  };

  static String? validTimezoneId(String? timezoneId) {
    final timezone.Location? location = locationForId(timezoneId);
    return location?.name;
  }

  static String? get deviceTimezoneId {
    return validTimezoneId(_deviceTimezoneId);
  }

  static String? _cleanTimezoneId(String? timezoneId) {
    final String? trimmed = timezoneId?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == 'unknown') {
      return null;
    }
    return trimmed;
  }
}
