import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:equran/backend/settings_db.dart';
import 'package:equran/backend/startup_coordinator.dart';
import 'package:equran/home/library.dart' show HomePage;
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/common/geometric_pattern.dart';
import 'package:flutter/material.dart';

/// Startup gate shown by [MyApp] before the home page.
///
/// It always waits for [StartupCoordinator.startDeferred], because the home
/// page reads boxes opened there. With the "startup animation" setting on, a
/// short one-shot animation plays in parallel with that work and the screen
/// leaves as soon as both are done (about 1.1 s on a fast device). With the
/// setting off, or when the system asks for reduced motion, there is no
/// animation: the screen leaves the moment startup work is done.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.enabled, this.ready, this.nextBuilder});

  /// Overrides the saved setting. Tests only.
  final bool? enabled;

  /// Startup work to wait for. Defaults to the deferred startup stage.
  final Future<void> Function()? ready;

  /// Destination once the splash is done. Defaults to [HomePage].
  final WidgetBuilder? nextBuilder;

  /// Total length of the intro animation.
  static const Duration introDuration = Duration(milliseconds: 1300);

  /// Cross-fade into the next page.
  static const Duration exitDuration = Duration(milliseconds: 300);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _draw;
  late final Animation<double> _fill;
  late final Animation<double> _settle;
  late final Animation<double> _title;

  late final bool _enabled;
  bool _animate = false;
  bool _started = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled ?? SettingsDB().showSplashScreen;
    _controller = AnimationController(
      vsync: this,
      duration: SplashScreen.introDuration,
    );
    CurvedAnimation interval(double begin, double end, Curve curve) =>
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: curve),
        );
    _draw = interval(0.0, 0.55, Curves.easeInOutCubic);
    _fill = interval(0.40, 0.75, Curves.easeOut);
    _settle = interval(0.0, 0.75, Curves.easeOutCubic);
    _title = interval(0.55, 0.90, Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _animate = _enabled && !MediaQuery.disableAnimationsOf(context);
    if (_enabled && !_animate) {
      // Reduced motion: show the finished mark, no movement.
      _controller.value = 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final Future<void> Function() ready =
        widget.ready ?? StartupCoordinator.instance.startDeferred;
    final Future<void> startup = () async {
      try {
        await ready();
      } catch (_) {
        // Startup steps report their own issues; never trap the user here.
      }
    }();
    if (_animate && mounted) {
      await _controller.forward();
    }
    await startup;
    _leave();
  }

  void _skip() {
    // `stop(canceled: false)` completes the pending `forward()` future; the
    // `value` setter alone would cancel it and leave `_run` waiting forever.
    _controller
      ..stop(canceled: false)
      ..value = 1;
  }

  void _leave() {
    if (!mounted || _left) return;
    _left = true;
    final Duration fade = _animate ? SplashScreen.exitDuration : Duration.zero;
    final WidgetBuilder next = widget.nextBuilder ?? (_) => const HomePage();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => next(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: fade,
        reverseTransitionDuration: fade,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    if (!_enabled) {
      return Scaffold(backgroundColor: colors.background);
    }

    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Size size = MediaQuery.sizeOf(context);
    final double markSize = math.min(size.shortestSide * 0.44, 190);
    final bool decorative =
        DeviceCapabilityService.instance.profile.allowsDecorativeEffects;

    return Scaffold(
      backgroundColor: colors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Tap to skip the rest of the animation.
        onTap: _skip,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (decorative)
              FadeTransition(
                opacity: _fill,
                child: GeometricPattern(
                  color: colors.accentGold,
                  anchor: AlignmentDirectional.center,
                  reach: 0.62,
                  maxOpacity: 0.16,
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: (1 - _settle.value) * -math.pi / 8,
                          child: Transform.scale(
                            scale: 0.9 + 0.1 * _settle.value,
                            child: SizedBox.square(
                              dimension: markSize,
                              child: CustomPaint(
                                painter: _StarMarkPainter(
                                  draw: _draw.value,
                                  fill: _fill.value,
                                  gold: colors.accentGold,
                                  glow: colors.primary,
                                  glowAlpha: dark ? 0.28 : 0.12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _title,
                    builder: (context, child) => Opacity(
                      opacity: _title.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - _title.value) * 12),
                        child: child,
                      ),
                    ),
                    child: _Wordmark(colors: colors),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Latin brand name is fixed on purpose: the bundled Newsreader subset only
/// covers Latin glyphs, and the wordmark should not change with the UI locale.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.colors});

  final EquranColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'eQuran',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontFamily: 'Newsreader',
            fontSize: 36,
            fontWeight: FontWeight.w500,
            fontVariations: const <FontVariation>[
              FontVariation('opsz', 36),
              FontVariation('wght', 500),
            ],
            letterSpacing: 1,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(width: 120, child: OrnamentDivider(color: colors.accentGold)),
      ],
    );
  }
}

/// Eight-pointed star (Rub el Hizb): two squares drawn in opposite directions,
/// then a soft fill, an inner ring and a centre dot.
class _StarMarkPainter extends CustomPainter {
  const _StarMarkPainter({
    required this.draw,
    required this.fill,
    required this.gold,
    required this.glow,
    required this.glowAlpha,
  });

  final double draw;
  final double fill;
  final Color gold;
  final Color glow;
  final double glowAlpha;

  static const double _innerRatio = 0.76536;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 * 0.9;

    if (fill > 0) {
      canvas.drawCircle(
        center,
        radius * 1.55,
        Paint()
          ..shader =
              RadialGradient(
                colors: <Color>[
                  glow.withValues(alpha: glowAlpha * fill),
                  glow.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: center, radius: radius * 1.55),
              ),
      );

      final Path union = Path();
      for (int i = 0; i < 16; i++) {
        final double r = i.isEven ? radius : radius * _innerRatio;
        final double a = i * math.pi / 8 - math.pi / 2;
        final Offset p = center + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? union.moveTo(p.dx, p.dy) : union.lineTo(p.dx, p.dy);
      }
      union.close();
      canvas.drawPath(
        union,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              gold.withValues(alpha: 0.26 * fill),
              gold.withValues(alpha: 0.03 * fill),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );

      final Paint ring = Paint()
        ..color = gold.withValues(alpha: 0.5 * fill)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius * _innerRatio * 0.78, ring);
      canvas.drawCircle(
        center,
        3,
        Paint()..color = gold.withValues(alpha: 0.95 * fill),
      );
    }

    if (draw > 0) {
      final Paint stroke = Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final bool clockwise in <bool>[true, false]) {
        final Path square = Path();
        for (int i = 0; i < 4; i++) {
          final int step = clockwise ? i : -i;
          final double a =
              (clockwise ? 0 : math.pi / 4) + step * math.pi / 2 - math.pi / 2;
          final Offset p = center + Offset(math.cos(a), math.sin(a)) * radius;
          i == 0 ? square.moveTo(p.dx, p.dy) : square.lineTo(p.dx, p.dy);
        }
        square.close();
        for (final PathMetric metric in square.computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * draw), stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StarMarkPainter old) =>
      old.draw != draw ||
      old.fill != fill ||
      old.gold != gold ||
      old.glow != glow ||
      old.glowAlpha != glowAlpha;
}
