import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_timezone_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum PrayerLocationFailureReason {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

enum PrayerLocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
}

class PrayerRawPosition {
  const PrayerRawPosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class PrayerLocationResult {
  const PrayerLocationResult._({
    this.location,
    this.failureReason,
    this.message,
  });

  factory PrayerLocationResult.success(PrayerLocation location) {
    return PrayerLocationResult._(location: location);
  }

  factory PrayerLocationResult.failure({
    required PrayerLocationFailureReason reason,
    required String message,
  }) {
    return PrayerLocationResult._(failureReason: reason, message: message);
  }

  final PrayerLocation? location;
  final PrayerLocationFailureReason? failureReason;
  final String? message;

  bool get isSuccess => location != null;
}

class PrayerResolvedAddress {
  const PrayerResolvedAddress({required this.label, this.countryCode});

  final String label;
  final String? countryCode;
}

class PrayerAddressPlacemark {
  const PrayerAddressPlacemark({
    this.name,
    this.street,
    this.locality,
    this.subLocality,
    this.administrativeArea,
    this.subAdministrativeArea,
    this.country,
    this.isoCountryCode,
  });

  final String? name;
  final String? street;
  final String? locality;
  final String? subLocality;
  final String? administrativeArea;
  final String? subAdministrativeArea;
  final String? country;
  final String? isoCountryCode;

  @override
  String toString() {
    return 'PrayerAddressPlacemark('
        'name: $name, '
        'street: $street, '
        'subLocality: $subLocality, '
        'locality: $locality, '
        'subAdministrativeArea: $subAdministrativeArea, '
        'administrativeArea: $administrativeArea, '
        'country: $country, '
        'isoCountryCode: $isoCountryCode'
        ')';
  }
}

abstract class PrayerReverseGeocoder {
  Future<List<PrayerAddressPlacemark>> placemarksFromCoordinates(
    double latitude,
    double longitude,
  );
}

/// Coordinates never leave the device, so no reverse geocoding happens here.
/// Labels come from the user, or fall back to the coordinates.
class DisabledPrayerReverseGeocoder implements PrayerReverseGeocoder {
  const DisabledPrayerReverseGeocoder();

  @override
  Future<List<PrayerAddressPlacemark>> placemarksFromCoordinates(
    double latitude,
    double longitude,
  ) async => const <PrayerAddressPlacemark>[];
}

abstract class PrayerPositionProvider {
  Future<bool> isLocationServiceEnabled();

  Future<PrayerLocationPermissionStatus> checkPermission();

  Future<PrayerLocationPermissionStatus> requestPermission();

  Future<PrayerRawPosition> getCurrentPosition();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}

class GeolocatorPrayerPositionProvider implements PrayerPositionProvider {
  const GeolocatorPrayerPositionProvider();

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<PrayerLocationPermissionStatus> checkPermission() async {
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<PrayerLocationPermissionStatus> requestPermission() async {
    return _mapPermission(await Geolocator.requestPermission());
  }

  @override
  Future<PrayerRawPosition> getCurrentPosition() async {
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return PrayerRawPosition(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  PrayerLocationPermissionStatus _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.denied => PrayerLocationPermissionStatus.denied,
      LocationPermission.deniedForever =>
        PrayerLocationPermissionStatus.deniedForever,
      LocationPermission.whileInUse =>
        PrayerLocationPermissionStatus.whileInUse,
      LocationPermission.always => PrayerLocationPermissionStatus.always,
      LocationPermission.unableToDetermine =>
        PrayerLocationPermissionStatus.denied,
    };
  }
}

class PrayerLocationService {
  const PrayerLocationService({
    PrayerPositionProvider provider = const GeolocatorPrayerPositionProvider(),
    PrayerReverseGeocoder reverseGeocoder =
        const DisabledPrayerReverseGeocoder(),
    PrayerTimezoneResolver timezoneResolver =
        const DevicePrayerTimezoneResolver(),
  }) : _provider = provider,
       _reverseGeocoder = reverseGeocoder,
       _timezoneResolver = timezoneResolver;

  final PrayerPositionProvider _provider;
  final PrayerReverseGeocoder _reverseGeocoder;
  final PrayerTimezoneResolver _timezoneResolver;

  Future<PrayerLocationResult> currentDeviceLocation() async {
    try {
      final bool serviceEnabled = await _provider.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return PrayerLocationResult.failure(
          reason: PrayerLocationFailureReason.servicesDisabled,
          message: 'Turn on location services to use your current location.',
        );
      }

      PrayerLocationPermissionStatus permission = await _provider
          .checkPermission();
      if (permission == PrayerLocationPermissionStatus.denied) {
        permission = await _provider.requestPermission();
      }

      if (permission == PrayerLocationPermissionStatus.denied) {
        return PrayerLocationResult.failure(
          reason: PrayerLocationFailureReason.permissionDenied,
          message:
              'Location permission is needed to calculate prayer times from your current device location.',
        );
      }

      if (permission == PrayerLocationPermissionStatus.deniedForever) {
        return PrayerLocationResult.failure(
          reason: PrayerLocationFailureReason.permissionDeniedForever,
          message:
              'Location permission is blocked. Enable it from app settings to use current location.',
        );
      }

      final PrayerRawPosition position = await _provider.getCurrentPosition();
      return PrayerLocationResult.success(
        await resolveLocationForSave(
          PrayerLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            label: 'Saved location',
            mode: PrayerLocationMode.currentDevice,
          ),
        ),
      );
    } catch (_) {
      return PrayerLocationResult.failure(
        reason: PrayerLocationFailureReason.unavailable,
        message:
            'We could not read your current location. Try again or enter coordinates manually.',
      );
    }
  }

  Future<bool> openLocationSettings() {
    return _provider.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return _provider.openAppSettings();
  }

  Future<PrayerResolvedAddress?> resolveAddress(
    double latitude,
    double longitude,
  ) async {
    _debugLog(
      'Prayer reverse geocoding started for '
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
    );
    try {
      final List<PrayerAddressPlacemark> placemarks = await _reverseGeocoder
          .placemarksFromCoordinates(latitude, longitude);
      _debugLog('Prayer reverse geocoding placemarks: $placemarks');
      for (final PrayerAddressPlacemark placemark in placemarks) {
        final String? label = shortPrayerAddressLabel(placemark);
        if (label == null) continue;
        _debugLog('Prayer reverse geocoding resolved label: "$label"');
        return PrayerResolvedAddress(
          label: label,
          countryCode: _normalizedCountryCode(placemark.isoCountryCode),
        );
      }
      _debugLog(
        'Prayer reverse geocoding fallback reason: no usable placemark',
      );
    } catch (error) {
      _debugLog('Prayer reverse geocoding fallback reason: $error');
      return null;
    }
    return null;
  }

  Future<PrayerLocation> resolveLocationForSave(
    PrayerLocation location, {
    PrayerLocation? previousLocation,
    bool preserveCustomLabel = false,
  }) async {
    final bool coordinatesChanged =
        previousLocation == null ||
        !_sameCoordinates(location, previousLocation);
    final bool hasCustomLabel = _isCustomLocationLabel(location.label);
    final bool labelChangedFromPrevious =
        previousLocation != null &&
        _fallbackLabel(location.label) !=
            _fallbackLabel(previousLocation.label);
    final bool shouldPreserveCustomLabel =
        hasCustomLabel &&
        (preserveCustomLabel ||
            (coordinatesChanged && labelChangedFromPrevious));
    final bool previousHasGenericLabel =
        previousLocation != null &&
        _isGenericOrCoordinateLabel(previousLocation.label);
    final bool shouldResolve =
        coordinatesChanged ||
        (!preserveCustomLabel && (!hasCustomLabel || previousHasGenericLabel));

    if (!shouldResolve) {
      final PrayerLocation previous = previousLocation;
      final PrayerLocation savedLocation = PrayerLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        label: _fallbackLabel(location.label),
        countryCode: location.countryCode ?? previous.countryCode,
        timezoneId:
            location.timezoneId ??
            previous.timezoneId ??
            _resolveTimezoneId(location),
        mode: location.mode,
      );
      _debugLog(
        'Prayer reverse geocoding skipped; final saved label: '
        '"${savedLocation.label}"',
      );
      return savedLocation;
    }

    final PrayerResolvedAddress? address = await resolveAddress(
      location.latitude,
      location.longitude,
    );
    final String label = shouldPreserveCustomLabel
        ? _fallbackLabel(location.label)
        : address?.label ??
              _fallbackLabelAfterFailedResolve(
                location,
                previousLocation: previousLocation,
                coordinatesChanged: coordinatesChanged,
              );
    final PrayerLocation savedLocation = PrayerLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      label: label,
      countryCode:
          address?.countryCode ??
          (coordinatesChanged
              ? null
              : location.countryCode ?? previousLocation.countryCode),
      timezoneId: coordinatesChanged
          ? _resolveTimezoneId(location)
          : location.timezoneId ??
                previousLocation.timezoneId ??
                _resolveTimezoneId(location),
      mode: location.mode,
    );
    _debugLog(
      'Prayer reverse geocoding final saved label: "${savedLocation.label}"',
    );
    return savedLocation;
  }

  String coordinateLabel(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static bool _sameCoordinates(PrayerLocation a, PrayerLocation b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  String? _resolveTimezoneId(PrayerLocation location) {
    final String? timezoneId = _timezoneResolver.timezoneIdForCoordinates(
      location.latitude,
      location.longitude,
    );
    _debugLog(
      timezoneId == null
          ? 'Prayer timezone lookup fallback: using device timezone'
          : 'Prayer timezone resolved: $timezoneId',
    );
    return timezoneId;
  }
}

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

String? shortPrayerAddressLabel(PrayerAddressPlacemark placemark) {
  final String? subLocality = _cleanAddressPart(placemark.subLocality);
  final String? locality = _cleanAddressPart(placemark.locality);
  final String? subAdministrativeArea = _cleanAddressPart(
    placemark.subAdministrativeArea,
  );
  final String? administrativeArea = _cleanAddressPart(
    placemark.administrativeArea,
  );
  final String? country = _cleanAddressPart(placemark.country);

  if (subLocality != null &&
      locality != null &&
      !_sameAddressPart(subLocality, locality)) {
    return _joinAddressParts(<String>[subLocality, locality]);
  }

  final String? place = locality ?? subLocality ?? subAdministrativeArea;
  if (place != null) {
    final bool usingNeighborhood =
        subLocality != null && _sameAddressPart(place, subLocality);
    final bool usingSubAdmin =
        subAdministrativeArea != null &&
        _sameAddressPart(place, subAdministrativeArea);
    final String? secondary = usingNeighborhood || usingSubAdmin
        ? administrativeArea ?? country
        : country ?? administrativeArea;
    return _joinDistinctAddressParts(<String?>[place, secondary]);
  }

  if (administrativeArea != null) return administrativeArea;
  if (country != null) return country;

  return _cleanAddressPart(placemark.street) ??
      _cleanAddressPart(placemark.name);
}

String _fallbackLabel(String label) {
  final String trimmed = label.trim();
  if (trimmed.isEmpty ||
      _isGenericLocationLabel(trimmed) ||
      _looksLikeCoordinateLabel(trimmed)) {
    return 'Saved location';
  }
  return trimmed;
}

String _fallbackLabelAfterFailedResolve(
  PrayerLocation location, {
  required PrayerLocation? previousLocation,
  required bool coordinatesChanged,
}) {
  if (!coordinatesChanged || previousLocation == null) {
    return _fallbackLabel(location.label);
  }
  return 'Saved location';
}

bool _isCustomLocationLabel(String label) {
  final String trimmed = label.trim();
  return trimmed.isNotEmpty &&
      !_isGenericLocationLabel(trimmed) &&
      !_looksLikeCoordinateLabel(trimmed);
}

bool _isGenericOrCoordinateLabel(String? label) {
  final String trimmed = label?.trim() ?? '';
  return trimmed.isEmpty ||
      _isGenericLocationLabel(trimmed) ||
      _looksLikeCoordinateLabel(trimmed);
}

bool _isGenericLocationLabel(String label) {
  return label == 'Current location' ||
      label == 'Current device location' ||
      label == 'Manual location' ||
      label == 'Selected location' ||
      label == 'Saved location';
}

String? _cleanAddressPart(String? value) {
  final String? trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (RegExp(r'^\d+$').hasMatch(trimmed)) return null;
  return trimmed.replaceAll(RegExp(r'\s+'), ' ');
}

String _joinDistinctAddressParts(List<String?> parts) {
  final List<String> distinctParts = <String>[];
  for (final String? part in parts) {
    if (part == null) continue;
    if (distinctParts.any(
      (String existing) => _sameAddressPart(existing, part),
    )) {
      continue;
    }
    distinctParts.add(part);
  }
  return _joinAddressParts(distinctParts);
}

String _joinAddressParts(List<String> parts) {
  return parts.join(', ');
}

bool _sameAddressPart(String a, String b) {
  return _normalizedAddressPart(a) == _normalizedAddressPart(b);
}

String _normalizedAddressPart(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String? _normalizedCountryCode(String? value) {
  final String? trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toUpperCase();
}

bool _looksLikeCoordinateLabel(String value) {
  return RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$').hasMatch(value);
}
