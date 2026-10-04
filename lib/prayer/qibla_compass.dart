import 'dart:math' as math;

import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A critically damped follower for an angle in degrees.
///
/// The value is kept *unwrapped*: going from 350° to 10° turns +20°, not
/// -340°. One follower driven by a [Ticker] replaces a per-sensor-event
/// animation, which restarts 50 to 100 times a second and stutters.
class AngleSmoother {
  AngleSmoother(double initial, {this.smoothTime = 0.16})
    : _current = initial,
      _target = initial;

  /// Roughly how long the follower takes to close most of a gap, in seconds.
  final double smoothTime;
  double _current;
  double _target;
  double _velocity = 0;

  double get value => _current;
  double get target => _target;
  bool get isSettled =>
      (_target - _current).abs() < 0.02 && _velocity.abs() < 0.05;

  /// Aim at [degrees] (any range) by the shortest way round.
  void aimAt(double degrees) {
    _target += (degrees - _target + 180) % 360 - 180;
  }

  /// Skip the animation, for reduced motion and the first frame.
  void jumpTo(double degrees) {
    _target = _current = degrees;
    _velocity = 0;
  }

  /// Advance by [dt] seconds.
  void step(double dt) {
    if (dt <= 0) return;
    final double clamped = math.min(dt, 0.05);
    final double omega = 2 / smoothTime;
    final double x = omega * clamped;
    final double decay = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);
    final double change = _current - _target;
    final double temp = (_velocity + omega * change) * clamped;
    _velocity = (_velocity - omega * temp) * decay;
    _current = _target + (change + temp) * decay;
    if (isSettled) {
      _current = _target;
      _velocity = 0;
    }
  }
}

const double qiblaAlignmentThresholdDegrees = 5;

/// The Qibla compass: a dial that turns with the device heading, a Kaaba bead
/// riding the rim at the Qibla bearing and a needle pointing at it.
///
/// The dial rotates by -heading. The bead and needle live outside the dial and
/// are placed at `bearing - heading`, so the heading is applied exactly once.
/// Only the transforms are rebuilt per frame; the dial is painted once.
class QiblaCompass extends StatefulWidget {
  const QiblaCompass({
    super.key,
    required this.bearing,
    required this.heading,
    required this.size,
  });

  /// Qibla bearing from true north, in degrees.
  final double bearing;

  /// Reliable device heading in degrees, or null when there is none.
  final ValueListenable<double?> heading;
  final double size;

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass>
    with TickerProviderStateMixin {
  final AngleSmoother _smoother = AngleSmoother(0);
  final ValueNotifier<double> _angle = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _alignment = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  Duration _lastTick = Duration.zero;
  bool _aligned = false;
  bool _reducedMotion = false;

  bool get _decorative =>
      !_reducedMotion &&
      DeviceCapabilityService.instance.profile.allowsDecorativeEffects;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    final double? initial = widget.heading.value;
    if (initial != null) _smoother.jumpTo(initial);
    _angle.value = _smoother.value;
    widget.heading.addListener(_onHeading);
    _aligned = _isAligned();
    _alignment.value = _aligned ? 1 : 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reducedMotion) {
      _entrance.value = 1;
      _snapToTarget();
    } else if (!_entrance.isAnimating && _entrance.value == 0) {
      _entrance.forward();
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant QiblaCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heading != widget.heading) {
      oldWidget.heading.removeListener(_onHeading);
      widget.heading.addListener(_onHeading);
    }
    _onHeading();
  }

  @override
  void dispose() {
    widget.heading.removeListener(_onHeading);
    _ticker.dispose();
    _entrance.dispose();
    _alignment.dispose();
    _pulse.dispose();
    _angle.dispose();
    super.dispose();
  }

  bool _isAligned() {
    final double? heading = widget.heading.value;
    if (heading == null) return false;
    final double relative = (widget.bearing - heading + 180) % 360 - 180;
    return relative.abs() <= qiblaAlignmentThresholdDegrees;
  }

  void _onHeading() {
    _smoother.aimAt(widget.heading.value ?? 0);
    if (_reducedMotion) {
      _snapToTarget();
    } else if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
    final bool aligned = _isAligned();
    if (aligned != _aligned) {
      _aligned = aligned;
      if (_reducedMotion) {
        _alignment.value = aligned ? 1 : 0;
      } else if (aligned) {
        _alignment.forward();
      } else {
        _alignment.reverse();
      }
      _syncPulse();
    }
  }

  void _snapToTarget() {
    _smoother.jumpTo(_smoother.target);
    _angle.value = _smoother.value;
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _smoother.step(dt);
    _angle.value = _smoother.value;
    if (_smoother.isSettled) _ticker.stop();
  }

  void _syncPulse() {
    if (_aligned && _decorative) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final double size = widget.size;
    final double plateRadius = size / 2 - _QiblaGeometry.margin(size);
    final _DialStyle style = _DialStyle(
      tick: tokens.muted,
      tickStrong: tokens.text2,
      north: tokens.emText,
      numeral: tokens.muted,
      star: tokens.hair2,
      cardinal: EquranTextStyles.displayNumeral(
        context,
        size: size * 0.074,
        height: 1,
        color: tokens.text2,
      ),
      cardinalNorth: EquranTextStyles.displayNumeral(
        context,
        size: size * 0.092,
        height: 1,
        color: tokens.emText,
      ),
      numeralStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: math.max(8.5, size * 0.027),
        fontWeight: FontWeight.w500,
        color: tokens.muted,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
    final Color goldInk =
        ThemeData.estimateBrightnessForColor(tokens.gold) == Brightness.light
        ? Colors.black87
        : Colors.white;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final double t = Curves.easeOutCubic.transform(_entrance.value);
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          );
        },
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _PlatePainter(
                    fill: colors.surface,
                    fillEdge: colors.surfaceAlt,
                    border: tokens.hair2,
                    shadow: tokens.shadow,
                  ),
                ),
              ),
              // The dial: painted once, turned by a transform.
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: _angle,
                  builder: (context, angle, child) => Transform.rotate(
                    angle: -angle * math.pi / 180,
                    child: child,
                  ),
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _DialPainter(style: style)),
                  ),
                ),
              ),
              // The needle points at the Qibla; the bead rides the rim.
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: _angle,
                  builder: (context, angle, child) => Transform.rotate(
                    angle: (widget.bearing - angle) * math.pi / 180,
                    child: child,
                  ),
                  child: CustomPaint(
                    painter: _NeedlePainter(
                      tip: tokens.gold,
                      tail: tokens.hair2,
                      pin: colors.surface,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: _angle,
                  builder: (context, angle, child) {
                    final double radians =
                        (widget.bearing - angle) * math.pi / 180;
                    return Transform.rotate(
                      angle: radians,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: _QiblaGeometry.beadTop(size, plateRadius),
                          ),
                          // Counter-rotate so the glyph stays upright.
                          child: Transform.rotate(
                            angle: -radians,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _alignment,
                    builder: (context, _) => _KaabaBead(
                      diameter: _QiblaGeometry.beadDiameter(size),
                      fill: tokens.gold,
                      ink: goldInk,
                      ring: colors.surface,
                      emphasis: Curves.elasticOut.transform(_alignment.value),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge(<Listenable>[
                      _alignment,
                      _pulse,
                    ]),
                    builder: (context, _) => CustomPaint(
                      painter: _BezelPainter(
                        ringIdle: tokens.hair2,
                        ringAligned: tokens.emText,
                        pointer: tokens.text2,
                        pointerAligned: tokens.emText,
                        aligned: _alignment.value.clamp(0.0, 1.0),
                        breathe: _pulse.value,
                      ),
                    ),
                  ),
                ),
              ),
              _Hub(
                heading: widget.heading,
                bearing: widget.bearing,
                diameter: _QiblaGeometry.hubDiameter(size),
                angle: _angle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared proportions so the painters and bead agree.
class _QiblaGeometry {
  static double margin(double size) => size * 0.045;
  static double beadDiameter(double size) => (size * 0.11).clamp(30, 44);
  static double beadTop(double size, double plateRadius) {
    final double rimY = size / 2 - plateRadius;
    return rimY - beadDiameter(size) / 2 + size * 0.04;
  }

  static double hubDiameter(double size) => size * 0.30;
}

class _Hub extends StatelessWidget {
  const _Hub({
    required this.heading,
    required this.bearing,
    required this.diameter,
    required this.angle,
  });

  final ValueListenable<double?> heading;
  final double bearing;
  final double diameter;
  final ValueListenable<double> angle;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<double?>(
      valueListenable: heading,
      builder: (context, value, _) {
        final double shown = value ?? bearing;
        final String degrees = '${shown.round() % 360}°';
        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(color: tokens.hair2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tokens.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                degrees,
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.noScaling,
                maxLines: 1,
                style: EquranTextStyles.displayNumeral(
                  context,
                  size: diameter * 0.30,
                  height: 1,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: diameter * 0.05),
              Text(
                (value == null ? l.qibla : l.heading).toUpperCase(),
                textScaler: TextScaler.noScaling,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: math.max(8.5, diameter * 0.115),
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: tokens.muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KaabaBead extends StatelessWidget {
  const _KaabaBead({
    required this.diameter,
    required this.fill,
    required this.ink,
    required this.ring,
    required this.emphasis,
  });

  final double diameter;
  final Color fill;
  final Color ink;
  final Color ring;

  /// 0 at rest; overshoots past 1 when the compass lines up.
  final double emphasis;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1 + 0.22 * emphasis,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: ring, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: fill.withValues(alpha: 0.30 + 0.25 * emphasis.clamp(0, 1)),
              blurRadius: 8 + 8 * emphasis.clamp(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          size: Size.square(diameter * 0.58),
          painter: _KaabaGlyphPainter(ink: ink, band: fill),
        ),
      ),
    );
  }
}

/// A dark cube with a gold band and a door, filled, at badge size.
class _KaabaGlyphPainter extends CustomPainter {
  const _KaabaGlyphPainter({required this.ink, required this.band});

  final Color ink;
  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width * 0.84;
    final double h = size.height * 0.88;
    final Rect body = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(size.width * 0.08)),
      Paint()..color = ink,
    );
    final Paint gold = Paint()..color = band;
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top + h * 0.24, w, h * 0.11),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          body.left + w * 0.58,
          body.top + h * 0.56,
          w * 0.16,
          h * 0.44,
        ),
        Radius.circular(size.width * 0.03),
      ),
      gold,
    );
  }

  @override
  bool shouldRepaint(covariant _KaabaGlyphPainter old) =>
      old.ink != ink || old.band != band;
}

@immutable
class _DialStyle {
  const _DialStyle({
    required this.tick,
    required this.tickStrong,
    required this.north,
    required this.numeral,
    required this.star,
    required this.cardinal,
    required this.cardinalNorth,
    required this.numeralStyle,
  });

  final Color tick;
  final Color tickStrong;
  final Color north;
  final Color numeral;
  final Color star;
  final TextStyle cardinal;
  final TextStyle cardinalNorth;
  final TextStyle numeralStyle;

  @override
  bool operator ==(Object other) =>
      other is _DialStyle &&
      other.tick == tick &&
      other.tickStrong == tickStrong &&
      other.north == north &&
      other.numeral == numeral &&
      other.star == star &&
      other.cardinal == cardinal &&
      other.cardinalNorth == cardinalNorth &&
      other.numeralStyle == numeralStyle;

  @override
  int get hashCode => Object.hash(
    tick,
    tickStrong,
    north,
    numeral,
    star,
    cardinal,
    cardinalNorth,
    numeralStyle,
  );
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter({
    required this.fill,
    required this.fillEdge,
    required this.border,
    required this.shadow,
  });

  final Color fill;
  final Color fillEdge;
  final Color border;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - _QiblaGeometry.margin(size.width);
    canvas.drawCircle(
      c + Offset(0, size.width * 0.02),
      r,
      Paint()
        ..color = shadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.05),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[fill, Color.lerp(fill, fillEdge, 0.9)!],
          stops: const <double>[0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(covariant _PlatePainter old) =>
      old.fill != fill ||
      old.fillEdge != fillEdge ||
      old.border != border ||
      old.shadow != shadow;
}

/// Ticks, degree numerals, the four cardinal letters and a faint eight-point
/// star. Painted once; rotation is a transform on its layer.
class _DialPainter extends CustomPainter {
  const _DialPainter({required this.style});

  final _DialStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - _QiblaGeometry.margin(size.width);

    // A hairline eight-point star behind the letters.
    final Path star = Path();
    final double starR = r * 0.50;
    for (int i = 0; i < 16; i++) {
      final double a = (i * 22.5 - 90) * math.pi / 180;
      final double rad = i.isEven ? starR : starR * 0.74;
      final Offset p = c + Offset(math.cos(a), math.sin(a)) * rad;
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round
        ..color = style.star,
    );

    final Paint tick = Paint()..strokeCap = StrokeCap.round;
    for (int deg = 0; deg < 360; deg += 5) {
      final bool cardinal = deg % 90 == 0;
      final bool major = deg % 30 == 0;
      final bool mid = deg % 15 == 0;
      final double length = cardinal
          ? r * 0.105
          : major
          ? r * 0.082
          : mid
          ? r * 0.058
          : r * 0.036;
      tick
        ..strokeWidth = cardinal
            ? 2.2
            : major
            ? 1.6
            : 1
        ..color = deg == 0
            ? style.north
            : (major ? style.tickStrong : style.tick).withValues(
                alpha: major ? 0.9 : 0.55,
              );
      final double a = (deg - 90) * math.pi / 180;
      final Offset dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * (r - r * 0.035),
        c + dir * (r - r * 0.035 - length),
        tick,
      );
    }

    // Radial degree numerals, upright toward the rim.
    for (int deg = 30; deg < 360; deg += 30) {
      if (deg % 90 == 0) continue;
      _paintRadial(
        canvas,
        c,
        r * 0.69,
        deg.toDouble(),
        TextSpan(text: '$deg', style: style.numeralStyle),
      );
    }

    const List<String> letters = <String>['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      _paintRadial(
        canvas,
        c,
        r * 0.69,
        i * 90.0,
        TextSpan(
          text: letters[i],
          style: i == 0 ? style.cardinalNorth : style.cardinal,
        ),
        // Cardinals stay legible as the dial turns; they point to the rim.
      );
    }
  }

  void _paintRadial(
    Canvas canvas,
    Offset center,
    double radius,
    double degrees,
    TextSpan span,
  ) {
    final TextPainter painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.translate(0, -radius);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.style != style;
}

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({
    required this.tip,
    required this.tail,
    required this.pin,
  });

  final Color tip;
  final Color tail;
  final Color pin;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - _QiblaGeometry.margin(size.width);
    final double hub = _QiblaGeometry.hubDiameter(size.width) / 2;
    final double half = size.width * 0.024;
    final Path forward = Path()
      ..moveTo(c.dx, c.dy - r * 0.80)
      ..lineTo(c.dx + half, c.dy - hub * 0.9)
      ..lineTo(c.dx - half, c.dy - hub * 0.9)
      ..close();
    final Path back = Path()
      ..moveTo(c.dx, c.dy + r * 0.34)
      ..lineTo(c.dx + half, c.dy + hub * 0.9)
      ..lineTo(c.dx - half, c.dy + hub * 0.9)
      ..close();
    canvas.drawPath(back, Paint()..color = tail);
    canvas.drawPath(
      forward,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[tip, tip.withValues(alpha: 0.35)],
        ).createShader(Rect.fromLTWH(c.dx - half, c.dy - r, half * 2, r)),
    );
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) =>
      old.tip != tip || old.tail != tail || old.pin != pin;
}

/// The fixed part: the lubber pointer at twelve o'clock and the rim, which
/// turns emerald when the phone faces the Qibla.
class _BezelPainter extends CustomPainter {
  const _BezelPainter({
    required this.ringIdle,
    required this.ringAligned,
    required this.pointer,
    required this.pointerAligned,
    required this.aligned,
    required this.breathe,
  });

  final Color ringIdle;
  final Color ringAligned;
  final Color pointer;
  final Color pointerAligned;
  final double aligned;
  final double breathe;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - _QiblaGeometry.margin(size.width);
    if (aligned > 0) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + 2.2 * aligned + 0.9 * breathe
          ..color = ringAligned.withValues(
            alpha: aligned * (0.78 + 0.22 * breathe),
          ),
      );
    }
    final Color color = Color.lerp(pointer, pointerAligned, aligned)!;
    final double w = size.width * 0.026;
    final Path lubber = Path()
      ..moveTo(c.dx - w, 1)
      ..lineTo(c.dx + w, 1)
      ..lineTo(c.dx, 1 + w * 1.7)
      ..close();
    canvas.drawPath(
      lubber,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      lubber,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.5,
    );
    // Keep the rim readable when idle.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ringIdle.withValues(alpha: (1 - aligned) * ringIdle.a),
    );
  }

  @override
  bool shouldRepaint(covariant _BezelPainter old) =>
      old.aligned != aligned ||
      old.breathe != breathe ||
      old.ringIdle != ringIdle ||
      old.ringAligned != ringAligned ||
      old.pointer != pointer ||
      old.pointerAligned != pointerAligned;
}
