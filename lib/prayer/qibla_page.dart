import 'dart:async';
import 'dart:math' as math;

import 'package:equran/prayer/prayer_location_service.dart';
import 'package:equran/prayer/prayer_map_location_page.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/qibla_compass.dart';
import 'package:equran/prayer/qibla_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:equran/l10n/app_localizations.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({
    super.key,
    this.locationService,
    @visibleForTesting this.compassEvents,
    @visibleForTesting this.initialLocation,
  });

  final PrayerLocationService? locationService;

  /// Replaces the device compass. Tests drive heading through this stream.
  final Stream<CompassEvent>? compassEvents;

  /// Skips reading the saved location and asking the device for one.
  final PrayerLocation? initialLocation;

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  static const QiblaService _qiblaService = QiblaService();
  static const Duration _locationTimeout = Duration(seconds: 15);
  static const Duration _hapticCooldown = Duration(seconds: 4);
  static const double _alignmentThresholdDegrees =
      qiblaAlignmentThresholdDegrees;
  static const double _poorHeadingAccuracyDegrees = 25;
  static const double _headingJitterThresholdDegrees = 0.5;

  late final PrayerLocationService _locationService;

  /// The reliable heading, or null. Only the compass and the guidance text
  /// listen, so a sensor event never rebuilds the page.
  final ValueNotifier<double?> _reliableHeading = ValueNotifier<double?>(null);

  StreamSubscription<CompassEvent>? _compassSubscription;
  PrayerLocation? _currentLocation;
  double? _heading;
  double? _headingAccuracy;
  bool _headingIsReliable = false;
  String? _locationMessage;
  String? _compassMessage;
  bool _isLocating = true;
  bool _wasFacingQibla = false;
  bool _startedCompass = false;
  DateTime? _lastHapticAt;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? const PrayerLocationService();
    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation;
      _isLocating = false;
      return;
    }
    _loadSavedLocation();
    _loadCurrentLocation();
  }

  void _loadSavedLocation() {
    try {
      final PrayerSettingsStore store = PrayerSettingsStore();
      final PrayerLocation? saved = store.getLocation();
      if (saved != null) {
        setState(() {
          _currentLocation = saved;
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedCompass) return;
    _startedCompass = true;
    _startCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _reliableHeading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      body: RedesignPageTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _QiblaHeader(
                title: l.qibla,
                onBack: Navigator.of(context).canPop()
                    ? () => Navigator.of(context).maybePop()
                    : null,
                backTooltip: MaterialLocalizations.of(
                  context,
                ).backButtonTooltip,
                onMap: _currentLocation == null
                    ? null
                    : () => showQiblaMap(context, _currentLocation!),
                mapTooltip: l.chooseOnMap,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final PrayerLocation? location = _currentLocation;
    if (location == null) {
      if (!_isLocating && _locationMessage != null) {
        return _QiblaErrorState(
          message: _locationMessage!,
          onRetry: _loadCurrentLocation,
          onChooseOnMap: _pickLocationOnMap,
        );
      }
      return _QiblaEmptyState(
        isLocating: _isLocating,
        message: _locationMessage,
        onRetry: _loadCurrentLocation,
        onChooseOnMap: _pickLocationOnMap,
      );
    }

    final double? bearing = _qiblaService.calculateBearing(location);
    if (bearing == null) {
      return _QiblaErrorState(
        message: AppLocalizations.of(context)!.qiblaBearingUnavailable,
        onRetry: _loadCurrentLocation,
        onChooseOnMap: _pickLocationOnMap,
      );
    }

    return _QiblaContent(
      bearing: bearing,
      heading: _reliableHeading,
      location: location,
      statusMessage: _compassStatusMessage(AppLocalizations.of(context)!),
      onRefreshLocation: _loadCurrentLocation,
    );
  }

  Future<void> _pickLocationOnMap() async {
    final PrayerLocation? picked = await showPrayerMapLocationPicker(
      context,
      _currentLocation,
    );
    if (picked == null || !mounted) return;

    final PrayerSettingsStore store = PrayerSettingsStore();
    await store.saveLocation(picked);

    setState(() {
      _currentLocation = picked;
      _locationMessage = null;
    });
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    final PrayerSettingsStore store = PrayerSettingsStore();
    final PrayerLocation? saved = store.getLocation();
    if (saved != null) {
      setState(() {
        _currentLocation = saved;
      });
    }

    try {
      final PrayerLocationResult result = await _locationService
          .currentDeviceLocation()
          .timeout(_locationTimeout);
      if (!mounted) return;
      final PrayerLocation? location = result.location;
      setState(() {
        _isLocating = false;
        if (location == null) {
          if (_currentLocation == null) {
            _locationMessage = _messageForLocationResult(
              result,
              AppLocalizations.of(context)!,
            );
          }
        } else {
          if (saved == null || saved.mode == PrayerLocationMode.currentDevice) {
            _currentLocation = location;
          }
          _locationMessage = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        if (_currentLocation == null) {
          _locationMessage = AppLocalizations.of(
            context,
          )!.currentLocationTimedOut;
        }
      });
    }
  }

  void _startCompass() {
    final Stream<CompassEvent>? injected = widget.compassEvents;
    if (injected == null && !_isCompassPlatformSupported) {
      _compassMessage = AppLocalizations.of(context)!.compassUnavailable;
      return;
    }
    try {
      final Stream<CompassEvent>? stream = injected ?? FlutterCompass.events;
      if (stream == null) {
        _compassMessage = AppLocalizations.of(context)!.compassUnavailable;
        return;
      }
      _compassSubscription = stream.listen(
        _onCompassEvent,
        onError: (_) {
          if (!mounted) return;
          _reliableHeading.value = null;
          _updateCompassStatus(
            heading: null,
            accuracy: null,
            reliable: false,
            message: AppLocalizations.of(context)!.compassUnavailable,
          );
        },
      );
    } on MissingPluginException {
      _compassMessage = AppLocalizations.of(context)!.compassUnavailable;
    } catch (_) {
      _compassMessage = AppLocalizations.of(context)!.compassUnavailable;
    }
  }

  void _onCompassEvent(CompassEvent event) {
    final _CompassReading reading = _usableCompassReading(event);
    if (!mounted) return;
    final double? nextHeading = _stableHeading(reading.heading);
    _reliableHeading.value = reading.isReliable ? nextHeading : null;
    _updateCompassStatus(
      heading: nextHeading,
      accuracy: reading.accuracy,
      reliable: reading.isReliable,
      message: nextHeading == null
          ? AppLocalizations.of(context)!.compassUnavailable
          : null,
    );
    _handleQiblaHaptic(nextHeading, isReliable: reading.isReliable);
  }

  /// Rebuild the page only when something the page shows changes; the heading
  /// itself flows through [_reliableHeading].
  void _updateCompassStatus({
    required double? heading,
    required double? accuracy,
    required bool reliable,
    required String? message,
  }) {
    final bool changed =
        reliable != _headingIsReliable ||
        message != _compassMessage ||
        (!reliable && accuracy?.round() != _headingAccuracy?.round());
    _heading = heading;
    _headingAccuracy = accuracy;
    _headingIsReliable = reliable;
    _compassMessage = message;
    if (changed) setState(() {});
  }

  void _handleQiblaHaptic(double? heading, {required bool isReliable}) {
    final PrayerLocation? location = _currentLocation;
    if (!isReliable || heading == null || location == null) {
      _wasFacingQibla = false;
      return;
    }
    final double? bearing = _qiblaService.calculateBearing(location);
    if (bearing == null) return;
    final double relative = _qiblaService.relativeDirection(
      qiblaBearing: bearing,
      heading: heading,
    );
    final bool isFacing = relative.abs() <= _alignmentThresholdDegrees;
    final DateTime now = DateTime.now();
    final bool cooledDown =
        _lastHapticAt == null ||
        now.difference(_lastHapticAt!) >= _hapticCooldown;
    if (isFacing && !_wasFacingQibla && cooledDown) {
      _lastHapticAt = now;
      HapticFeedback.mediumImpact().ignore();
    }
    _wasFacingQibla = isFacing;
  }

  static _CompassReading _usableCompassReading(CompassEvent event) {
    final double? heading = _normalizedHeading(event.heading);
    final double? accuracy = _usableAccuracy(event.accuracy);
    return _CompassReading(
      heading: heading,
      accuracy: accuracy,
      isReliable: heading != null && _isReasonableAccuracy(accuracy),
    );
  }

  static double? _normalizedHeading(double? heading) {
    if (heading == null || !heading.isFinite) return null;
    return _qiblaService.normalizeDegrees(heading);
  }

  double? _stableHeading(double? nextHeading) {
    final double? currentHeading = _heading;
    if (nextHeading == null || currentHeading == null) return nextHeading;
    final double delta = _qiblaService.shortestAngleDeltaDegrees(
      currentHeading,
      nextHeading,
    );
    if (delta.abs() < _headingJitterThresholdDegrees) return currentHeading;
    return nextHeading;
  }

  static double? _usableAccuracy(double? accuracy) {
    if (accuracy == null || !accuracy.isFinite || accuracy < 0) return null;
    return accuracy;
  }

  static bool _isReasonableAccuracy(double? accuracy) {
    if (accuracy == null) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return accuracy >= 2;
    }
    return accuracy <= _poorHeadingAccuracyDegrees;
  }

  String _compassStatusMessage(AppLocalizations localizations) {
    final String hint = localizations.qiblaCalibrationHint;
    final String? message = _compassMessage;
    if (message != null) return '$message $hint';
    if (_heading == null || !_headingIsReliable) {
      final double? accuracy = _headingAccuracy;
      final String accuracyText =
          accuracy == null || defaultTargetPlatform == TargetPlatform.android
          ? localizations.compassAccuracyLow
          : localizations.compassAccuracyLowWithDegrees(accuracy.round());
      return '$accuracyText $hint';
    }
    return hint;
  }

  bool get _isCompassPlatformSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  String _messageForLocationResult(
    PrayerLocationResult result,
    AppLocalizations localizations,
  ) {
    return switch (result.failureReason) {
      PrayerLocationFailureReason.servicesDisabled =>
        localizations.qiblaLocationServicesDisabled,
      PrayerLocationFailureReason.permissionDenied =>
        localizations.qiblaLocationPermissionNeeded,
      PrayerLocationFailureReason.permissionDeniedForever =>
        localizations.qiblaLocationPermissionBlocked,
      PrayerLocationFailureReason.unavailable ||
      null => localizations.qiblaLocationUnavailableMessage,
    };
  }
}

class _CompassReading {
  const _CompassReading({
    required this.heading,
    required this.accuracy,
    required this.isReliable,
  });

  final double? heading;
  final double? accuracy;
  final bool isReliable;
}

class _QiblaHeader extends StatelessWidget {
  const _QiblaHeader({
    required this.title,
    required this.backTooltip,
    required this.mapTooltip,
    this.onBack,
    this.onMap,
  });

  final String title;
  final String backTooltip;
  final String mapTooltip;
  final VoidCallback? onBack;
  final VoidCallback? onMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            IconButton44(
              designIcon: 'back',
              tooltip: backTooltip,
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: redesignDisplayStyle(context),
            ),
          ),
          if (onMap != null)
            IconButton44(
              icon: Icons.map_outlined,
              tooltip: mapTooltip,
              onPressed: onMap,
            ),
        ],
      ),
    );
  }
}

class _QiblaContent extends StatelessWidget {
  const _QiblaContent({
    required this.bearing,
    required this.heading,
    required this.location,
    required this.onRefreshLocation,
    this.statusMessage,
  });

  final double bearing;
  final ValueListenable<double?> heading;
  final PrayerLocation location;
  final VoidCallback onRefreshLocation;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final AppLocalizations l = AppLocalizations.of(context)!;
    final double contentWidth = math.min(media.size.width - 40, 560);
    final bool compactHeight = media.size.height < 640;
    final double compassSize = math.min(
      contentWidth,
      compactHeight ? 300 : 420,
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _LocationRow(location: location, onRefresh: onRefreshLocation),
                const SizedBox(height: 22),
                Center(
                  child: ValueListenableBuilder<double?>(
                    valueListenable: heading,
                    builder: (context, value, child) {
                      final String guidance = value == null
                          ? l.bearingDegrees(_formatCompassDegrees(bearing))
                          : _localizedQiblaGuidance(
                              l,
                              _relative(bearing, value),
                            );
                      return Semantics(
                        container: true,
                        liveRegion: true,
                        label: guidance,
                        child: child,
                      );
                    },
                    child: QiblaCompass(
                      bearing: bearing,
                      heading: heading,
                      size: compassSize,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _Guidance(bearing: bearing, heading: heading),
                const SizedBox(height: 26),
                _StatsCard(
                  bearing: bearing,
                  heading: heading,
                  location: location,
                ),
                if (statusMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _NoteRow(icon: 'info', text: statusMessage!),
                ],
                if (location.mode == PrayerLocationMode.manual) ...<Widget>[
                  const SizedBox(height: 10),
                  _NoteRow(icon: 'pin', text: l.qiblaFixedCoordinates),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _relative(double bearing, double heading) => _QiblaPageState
    ._qiblaService
    .relativeDirection(qiblaBearing: bearing, heading: heading);

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location, required this.onRefresh});

  final PrayerLocation location;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Row(
      children: <Widget>[
        DesignIcon('pin', size: 16, strokeWidth: 1.7, color: tokens.muted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            _currentLocationLabel(location, l),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: tokens.muted),
          ),
        ),
        IconButton44(
          icon: Icons.my_location_rounded,
          ghost: true,
          tooltip: l.refreshCurrentLocation,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

/// "Facing Qibla" or the turn to make, as large display text that cross-fades
/// as the state changes.
class _Guidance extends StatelessWidget {
  const _Guidance({required this.bearing, required this.heading});

  final double bearing;
  final ValueListenable<double?> heading;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<double?>(
      valueListenable: heading,
      builder: (context, value, _) {
        final double? relative = value == null
            ? null
            : _relative(bearing, value);
        final bool aligned =
            relative != null &&
            relative.abs() <= qiblaAlignmentThresholdDegrees;
        final String text = relative == null
            ? l.bearingDegrees(_formatCompassDegrees(bearing))
            : aligned
            ? l.facingQibla
            : _localizedQiblaGuidance(l, relative);
        final String? arrow = aligned
            ? 'check'
            : relative == null
            ? null
            : relative < 0
            ? 'chevl'
            : 'chev';
        final Color color = aligned
            ? tokens.emText
            : relative == null
            ? tokens.muted
            : context.equranColors.textPrimary;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.18),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Row(
            key: ValueKey<String>('$aligned/${relative == null}/$arrow'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (arrow == 'chevl' || arrow == 'check') ...<Widget>[
                DesignIcon(arrow!, size: 22, strokeWidth: 2, color: color),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: redesignDisplayStyle(
                    context,
                    size: relative == null ? 22 : 30,
                    height: 1.1,
                    color: color,
                  ),
                ),
              ),
              if (arrow == 'chev') ...<Widget>[
                const SizedBox(width: 8),
                DesignIcon(arrow!, size: 22, strokeWidth: 2, color: color),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.bearing,
    required this.heading,
    required this.location,
  });

  final double bearing;
  final ValueListenable<double?> heading;
  final PrayerLocation location;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations l = AppLocalizations.of(context)!;
    final Widget divider = Container(width: 1, height: 40, color: tokens.hair);
    return HairlineCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Stat(
                label: l.qiblaStatBearing,
                value: '${_formatCompassDegrees(bearing)}°',
              ),
            ),
            divider,
            Expanded(
              child: ValueListenableBuilder<double?>(
                valueListenable: heading,
                builder: (context, value, _) => _Stat(
                  label: l.heading,
                  value: value == null
                      ? '—'
                      : '${_formatCompassDegrees(value)}°',
                ),
              ),
            ),
            divider,
            Expanded(
              child: _Stat(
                label: l.qiblaStatDistance,
                value: _distanceValue(location, l),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 30 * MediaQuery.textScalerOf(context).scale(1),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DisplayNumeral(value, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: 10.5 * 0.12,
              color: context.equranTokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: DesignIcon(
            icon,
            size: 15,
            strokeWidth: 1.7,
            color: tokens.muted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, height: 1.45, color: tokens.muted),
          ),
        ),
      ],
    );
  }
}

class _QiblaMessageCard extends StatelessWidget {
  const _QiblaMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
  });

  final String icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return HairlineCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.emWash,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: DesignIcon(
              icon,
              size: 24,
              strokeWidth: 1.7,
              color: tokens.emText,
            ),
          ),
          const SizedBox(height: 18),
          Text(title, style: redesignDisplayStyle(context, size: 24)),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, height: 1.45, color: tokens.text2),
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ),
    );
  }
}

class _QiblaEmptyState extends StatelessWidget {
  const _QiblaEmptyState({
    required this.isLocating,
    required this.onRetry,
    this.message,
    this.onChooseOnMap,
  });

  final bool isLocating;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback? onChooseOnMap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _QiblaMessageCard(
              icon: 'compass',
              title: isLocating
                  ? l.findingYourLocation
                  : l.currentLocationRequired,
              message: message ?? l.qiblaRequiresLocation,
              actions: <Widget>[
                FilledButton.icon(
                  onPressed: isLocating ? null : onRetry,
                  icon: isLocating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(isLocating ? l.findingLocation : l.retry),
                ),
                if (!isLocating && onChooseOnMap != null)
                  OutlinedButton.icon(
                    onPressed: onChooseOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l.chooseOnMap),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QiblaErrorState extends StatelessWidget {
  const _QiblaErrorState({
    required this.message,
    required this.onRetry,
    this.onChooseOnMap,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onChooseOnMap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _QiblaMessageCard(
              icon: 'pin',
              title: l.currentLocationUnavailable,
              message: message,
              actions: <Widget>[
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(l.retry),
                ),
                if (onChooseOnMap != null)
                  OutlinedButton.icon(
                    onPressed: onChooseOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l.chooseOnMap),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _currentLocationLabel(
  PrayerLocation location,
  AppLocalizations localizations,
) {
  final String label = location.label.trim();
  if (label.isEmpty ||
      label == location.coordinateLabel ||
      _isGenericLocationLabel(label)) {
    return localizations.currentLocation;
  }
  return label;
}

String _formatCompassDegrees(double degrees) {
  final int rounded = _QiblaPageState._qiblaService
      .normalizeDegrees360(degrees)
      .round();
  return '${rounded == 360 ? 0 : rounded}';
}

String _localizedQiblaGuidance(
  AppLocalizations localizations,
  double relativeDirection,
) {
  final int degrees = relativeDirection.abs().round();
  if (degrees <= 5) return localizations.facingQibla;
  if (relativeDirection > 0) return localizations.turnRightDegrees(degrees);
  return localizations.turnLeftDegrees(degrees);
}

String _distanceValue(PrayerLocation location, AppLocalizations l) {
  final double distanceKm = _distanceToKaabaKm(location);
  if (!distanceKm.isFinite) return l.distanceUnavailable;
  return l.kilometersValue(
    distanceKm >= 1000
        ? distanceKm.round().toString()
        : distanceKm.toStringAsFixed(1),
  );
}

double _distanceToKaabaKm(PrayerLocation location) {
  const double kaabaLatitude = 21.4225;
  const double kaabaLongitude = 39.8262;
  const double earthRadiusKm = 6371;
  final double userLat = _degreesToRadians(location.latitude);
  final double kaabaLat = _degreesToRadians(kaabaLatitude);
  final double deltaLat = _degreesToRadians(kaabaLatitude - location.latitude);
  final double deltaLng = _degreesToRadians(
    kaabaLongitude - location.longitude,
  );
  final double a =
      math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(userLat) *
          math.cos(kaabaLat) *
          math.sin(deltaLng / 2) *
          math.sin(deltaLng / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

bool _isGenericLocationLabel(String label) {
  final List<String> parts = label.toLowerCase().split(RegExp(r'\s+'));
  return parts.isNotEmpty && parts.last == 'location' && parts.length <= 3;
}
