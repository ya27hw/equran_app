import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:equran/prayer/prayer_models.dart';

class QiblaService {
  const QiblaService();

  double? calculateBearing(PrayerLocation location) {
    if (!_hasValidCoordinates(location)) return null;
    final double bearing = adhan.Qibla.qibla(
      adhan.Coordinates(location.latitude, location.longitude),
    );
    if (!bearing.isFinite) return null;
    return normalizeDegrees(bearing);
  }

  double relativeDirection({
    required double qiblaBearing,
    required double heading,
  }) {
    return normalizeDegrees180(qiblaBearing - heading);
  }

  double normalizeDegrees(double degrees) {
    return normalizeDegrees360(degrees);
  }

  double normalizeDegrees360(double degrees) {
    final double normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double normalizeDegrees180(double degrees) {
    final double normalized = normalizeDegrees360(degrees + 180) - 180;
    return normalized == -180 ? 180 : normalized;
  }

  double shortestAngleDeltaDegrees(double from, double to) {
    return normalizeDegrees180(to - from);
  }

  bool _hasValidCoordinates(PrayerLocation location) {
    return location.latitude.isFinite &&
        location.longitude.isFinite &&
        location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }
}
