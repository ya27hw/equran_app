import 'dart:math' as math;
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/manual_prayer_location_page.dart';
import 'package:equran/prayer/prayer_location_service.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

typedef PrayerLocationPicker =
    Future<PrayerLocation?> Function(
      BuildContext context,
      PrayerLocation? initialLocation,
    );

Future<PrayerLocation?> showPrayerMapLocationPicker(
  BuildContext context,
  PrayerLocation? initialLocation,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<PrayerLocation>(
      builder: (BuildContext context) =>
          PrayerMapLocationPage(initialLocation: initialLocation),
    ),
  );
}

Future<void> showQiblaMap(BuildContext context, PrayerLocation location) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          PrayerMapLocationPage(initialLocation: location, isPicker: false),
    ),
  );
}

PrayerLocation prayerLocationFromMapSelection({
  required double latitude,
  required double longitude,
  required AppLocalizations localizations,
}) {
  return PrayerLocation(
    latitude: latitude,
    longitude: longitude,
    label: localizations.savedLocation,
    mode: PrayerLocationMode.manual,
  );
}

class PrayerMapLocationPage extends StatefulWidget {
  const PrayerMapLocationPage({
    super.key,
    this.initialLocation,
    this.isPicker = true,
  });

  final PrayerLocation? initialLocation;
  final bool isPicker;

  @override
  State<PrayerMapLocationPage> createState() => _PrayerMapLocationPageState();
}

class _PrayerMapLocationPageState extends State<PrayerMapLocationPage> {
  late final MapController _mapController;
  late LatLng _selectedCenter;
  LatLng? _userLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final PrayerLocation? initialLocation = widget.initialLocation;
    if (initialLocation != null) {
      _userLocation = LatLng(
        initialLocation.latitude,
        initialLocation.longitude,
      );
      _selectedCenter = _userLocation!;
    } else {
      _selectedCenter = const LatLng(0, 0);
    }

    // Automatically detect user location and recenter map if initialLocation is not provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialLocation == null) {
        _detectUserLocation(shouldCenterMap: true);
      } else {
        if (!widget.isPicker) {
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              _fitUserAndKaabaBounds();
            }
          });
        }
      }
    });
  }

  void _fitUserAndKaabaBounds() {
    final LatLng? userLoc = _userLocation;
    if (userLoc == null) return;
    final LatLng kaaba = const LatLng(21.4225, 39.8262);
    final LatLngBounds bounds = LatLngBounds.fromPoints(<LatLng>[
      userLoc,
      kaaba,
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
      ),
    );
  }

  Future<void> _detectUserLocation({required bool shouldCenterMap}) async {
    if (_isLoadingLocation) return;
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      final PrayerLocationResult result = await const PrayerLocationService()
          .currentDeviceLocation();
      if (!mounted) return;
      if (result.isSuccess && result.location != null) {
        final LatLng userCoords = LatLng(
          result.location!.latitude,
          result.location!.longitude,
        );
        setState(() {
          _userLocation = userCoords;
        });
        if (shouldCenterMap) {
          if (widget.isPicker) {
            _mapController.move(userCoords, 13.0);
          } else {
            _fitUserAndKaabaBounds();
          }
        }
      } else {
        if (shouldCenterMap && result.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.message!)));
        }
      }
    } catch (e) {
      debugPrint('Error detecting current location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  List<LatLng> _calculateGreatCirclePath(
    LatLng start,
    LatLng end, {
    int segments = 100,
  }) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lon1 = start.longitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double lon2 = end.longitude * math.pi / 180;

    final double d =
        2 *
        math.asin(
          math.sqrt(
            math.pow(math.sin((lat2 - lat1) / 2), 2) +
                math.cos(lat1) *
                    math.cos(lat2) *
                    math.pow(math.sin((lon2 - lon1) / 2), 2),
          ),
        );

    if (d.abs() < 1e-7) {
      return <LatLng>[start, end];
    }

    final List<LatLng> path = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final double f = i / segments;
      final double a = math.sin((1 - f) * d) / math.sin(d);
      final double b = math.sin(f * d) / math.sin(d);

      final double x =
          a * math.cos(lat1) * math.cos(lon1) +
          b * math.cos(lat2) * math.cos(lon2);
      final double y =
          a * math.cos(lat1) * math.sin(lon1) +
          b * math.cos(lat2) * math.sin(lon2);
      final double z = a * math.sin(lat1) + b * math.sin(lat2);

      final double lat = math.atan2(z, math.sqrt(x * x + y * y));
      final double lon = math.atan2(y, x);

      path.add(LatLng(lat * 180 / math.pi, lon * 180 / math.pi));
    }
    return path;
  }

  double? _calculateQiblaBearing() {
    final LatLng? loc =
        _userLocation ??
        (widget.initialLocation != null
            ? LatLng(
                widget.initialLocation!.latitude,
                widget.initialLocation!.longitude,
              )
            : null);
    if (loc == null) return null;
    final double bearing = adhan.Qibla.qibla(
      adhan.Coordinates(loc.latitude, loc.longitude),
    );
    if (!bearing.isFinite) return null;
    final double normalized = bearing % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  String _distanceToKaabaLabel(LatLng userLoc, AppLocalizations localizations) {
    const double kaabaLatitude = 21.4225;
    const double kaabaLongitude = 39.8262;
    const double earthRadiusKm = 6371;
    final double userLat = userLoc.latitude * math.pi / 180;
    final double kaabaLat = kaabaLatitude * math.pi / 180;
    final double deltaLat = (kaabaLatitude - userLoc.latitude) * math.pi / 180;
    final double deltaLng =
        (kaabaLongitude - userLoc.longitude) * math.pi / 180;
    final double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(userLat) *
            math.cos(kaabaLat) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final double distanceKm =
        earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    if (!distanceKm.isFinite) return localizations.distanceUnavailable;
    if (distanceKm >= 1000) {
      return localizations.kilometersToKaaba(distanceKm.round().toString());
    }
    return localizations.kilometersToKaaba(distanceKm.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final EquranColors equranColors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final String locationLabel = widget.isPicker
        ? localizations.selectedLocation
        : (widget.initialLocation?.label ?? localizations.currentLocation);

    final double displayLat = widget.isPicker
        ? _selectedCenter.latitude
        : (_userLocation?.latitude ?? widget.initialLocation?.latitude ?? 0.0);
    final double displayLng = widget.isPicker
        ? _selectedCenter.longitude
        : (_userLocation?.longitude ??
              widget.initialLocation?.longitude ??
              0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPicker ? localizations.chooseOnMap : localizations.qibla,
        ),
        backgroundColor: equranColors.background,
        foregroundColor: equranColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: equranColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: equranColors.textSecondary),
        actionsIconTheme: IconThemeData(color: equranColors.textSecondary),
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedCenter,
              initialZoom: widget.initialLocation == null ? 2 : 13,
              minZoom: 2,
              maxZoom: 18,
              backgroundColor: colors.surfaceContainerHighest,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (widget.isPicker) {
                  setState(() {
                    _selectedCenter = camera.center;
                  });
                }
              },
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // Public tile servers have usage policies. Significant
                // production traffic should use a suitable provider or
                // self-hosted tiles, and keep a valid User-Agent configured.
                userAgentPackageName: 'com.app.equran',
                errorTileCallback: (_, _, _) {},
              ),
              if (_userLocation != null) ...<Widget>[
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(
                      points: _calculateGreatCirclePath(
                        _userLocation!,
                        const LatLng(21.4225, 39.8262),
                      ),
                      strokeWidth: 3.5,
                      color: const Color(0xFFFFB300),
                      pattern: StrokePattern.dashed(segments: <double>[10, 8]),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: _UserLocationMarker(
                        qiblaBearing: _calculateQiblaBearing(),
                      ),
                    ),
                    Marker(
                      point: const LatLng(21.4225, 39.8262),
                      width: 58,
                      height: 58,
                      child: const _KaabaMarker(),
                    ),
                  ],
                ),
              ],
              RichAttributionWidget(
                attributions: <SourceAttribution>[
                  TextSourceAttribution(
                    localizations.openStreetMapContributors,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.isPicker) ...<Widget>[
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Icon(
                    Icons.location_pin,
                    size: 48,
                    color: colors.primary,
                    shadows: <Shadow>[
                      Shadow(
                        color: colors.shadow.withValues(alpha: 0.32),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            top: 14,
            right: 14,
            child: SafeArea(
              bottom: false,
              child: FloatingActionButton(
                onPressed: () => _detectUserLocation(shouldCenterMap: true),
                backgroundColor: colors.surfaceContainerLow,
                foregroundColor: colors.primary,
                mini: true,
                child: _isLoadingLocation
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  border: Border.all(color: colors.outlineVariant),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        locationLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prayerMapCoordinatePreview(displayLat, displayLng),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (_userLocation != null ||
                          widget.initialLocation != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.explore_outlined,
                              size: 16,
                              color: Color(0xFFFFB300),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${localizations.qibla}: ${_calculateQiblaBearing()?.toStringAsFixed(1)}° • ${_distanceToKaabaLabel(_userLocation ?? LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude), localizations)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.isPicker) ...<Widget>[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _useSelectedLocation,
                          icon: const Icon(Icons.pin_drop_outlined),
                          label: Text(localizations.usePinLocation),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _isLoadingLocation
                              ? null
                              : _useLiveLocation,
                          icon: _isLoadingLocation
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: Text(localizations.useLiveLocation),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _enterCoordinatesManually,
                          icon: const Icon(Icons.edit_location_alt_outlined),
                          label: Text(localizations.enterCoordinatesManually),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _useSelectedLocation() {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    Navigator.of(context).pop(
      prayerLocationFromMapSelection(
        latitude: _selectedCenter.latitude,
        longitude: _selectedCenter.longitude,
        localizations: localizations,
      ),
    );
  }

  Future<void> _useLiveLocation() async {
    LatLng? coords = _userLocation;
    if (coords == null) {
      if (_isLoadingLocation) return;
      setState(() {
        _isLoadingLocation = true;
      });
      try {
        final PrayerLocationResult result = await const PrayerLocationService()
            .currentDeviceLocation();
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
        });
        if (result.isSuccess && result.location != null) {
          final LatLng detectedCoords = LatLng(
            result.location!.latitude,
            result.location!.longitude,
          );
          coords = detectedCoords;
          setState(() {
            _userLocation = detectedCoords;
            _selectedCenter = detectedCoords;
          });
          _mapController.move(detectedCoords, 13.0);
        } else {
          if (mounted && result.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(result.message!)));
          }
          return;
        }
      } catch (e) {
        debugPrint('Error getting live location: $e');
        return;
      }
    }

    if (mounted) {
      final PrayerLocation liveLocation = PrayerLocation(
        latitude: coords.latitude,
        longitude: coords.longitude,
        label: AppLocalizations.of(context)!.currentLocation,
        mode: PrayerLocationMode.currentDevice,
      );

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final AppLocalizations localizations = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(localizations.confirmLiveLocationTitle),
            content: Text(
              '${localizations.confirmLiveLocationMessage}\n\n'
              '${liveLocation.latitude.toStringAsFixed(5)}, ${liveLocation.longitude.toStringAsFixed(5)}',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(localizations.confirm),
              ),
            ],
          );
        },
      );
      if (confirm == true && mounted) {
        Navigator.of(context).pop(liveLocation);
      }
    }
  }

  Future<void> _enterCoordinatesManually() async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final PrayerLocation? location = await Navigator.of(context).push(
      MaterialPageRoute<PrayerLocation>(
        builder: (BuildContext context) => ManualPrayerLocationPage(
          initialLocation: prayerLocationFromMapSelection(
            latitude: _selectedCenter.latitude,
            longitude: _selectedCenter.longitude,
            localizations: localizations,
          ),
        ),
      ),
    );
    if (location == null || !mounted) return;
    Navigator.of(context).pop(location);
  }
}

String prayerMapCoordinatePreview(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker({required this.qiblaBearing});

  final double? qiblaBearing;

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 24 * (1 + _controller.value * 0.8),
              height: 24 * (1 + _controller.value * 0.8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: (1 - _controller.value) * 0.5),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            if (widget.qiblaBearing != null)
              Transform.rotate(
                angle: widget.qiblaBearing! * math.pi / 180,
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: const Icon(
                    Icons.navigation_rounded,
                    size: 14,
                    color: Color(0xFFFFB300),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KaabaMarker extends StatelessWidget {
  const _KaabaMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFB300), width: 1.8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/media/images/app/kaabah.webp',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
