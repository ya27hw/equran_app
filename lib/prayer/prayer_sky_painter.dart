import 'dart:math' as math;

import 'package:equran/prayer/prayer_sky_scene.dart';
import 'package:flutter/material.dart';

class PrayerSkyPainter extends CustomPainter {
  const PrayerSkyPainter({
    required this.scene,
    required this.textDirection,
    required this.decorativeEffects,
  });

  final PrayerSkyScene scene;
  final TextDirection textDirection;
  final bool decorativeEffects;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[scene.top, scene.middle, scene.horizon],
          stops: const <double>[0, 0.61, 1],
        ).createShader(bounds),
    );
    if (textDirection == TextDirection.rtl) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final double w = size.width;
    final double h = size.height;
    final Offset sun = Offset(
      w * (0.12 + 0.76 * scene.sunProgress),
      h * (0.824 - 0.688 * math.sin(math.pi * scene.sunProgress)),
    );
    if (decorativeEffects) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.9),
            radius: 0.7,
            colors: <Color>[
              PrayerSkyScene.sunGlow.withValues(
                alpha: 0.35 * (1 - scene.stars),
              ),
              PrayerSkyScene.sunGlow.withValues(alpha: 0),
            ],
          ).createShader(bounds),
      );
      if (scene.sunVisibility > 0) {
        final Rect glow = Rect.fromCircle(center: sun, radius: 95);
        canvas.drawCircle(
          sun,
          95,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                PrayerSkyScene.sunGlow.withValues(
                  alpha: 0.6 * scene.sunVisibility,
                ),
                PrayerSkyScene.sunGlow.withValues(
                  alpha: 0.18 * scene.sunVisibility,
                ),
                PrayerSkyScene.sunGlow.withValues(alpha: 0),
              ],
              stops: const <double>[0, 0.25, 1],
            ).createShader(glow),
        );
      }
      for (int i = 0; i < 2; i++) {
        final Rect cloud = Rect.fromCenter(
          center: Offset(w * (i == 0 ? 0.13 : 0.89), h * (i == 0 ? 0.3 : 0.47)),
          width: w * 0.45,
          height: h * 0.12,
        );
        canvas.save();
        canvas.translate(cloud.center.dx, cloud.center.dy);
        canvas.scale(cloud.width / 2, cloud.height / 2);
        canvas.drawCircle(
          Offset.zero,
          1,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                PrayerSkyScene.foreground.withValues(
                  alpha: 0.14 * (1 - scene.stars),
                ),
                PrayerSkyScene.foreground.withValues(alpha: 0),
              ],
            ).createShader(const Rect.fromLTWH(-1, -1, 2, 2)),
        );
        canvas.restore();
      }
    }
    if (scene.stars > 0) {
      final Paint star = Paint()
        ..color = PrayerSkyScene.foreground.withValues(alpha: scene.stars);
      for (int i = 0; i < 12; i++) {
        canvas.drawCircle(
          Offset(
            w * (0.08 + ((i * 37) % 89) / 100),
            h * (0.07 + ((i * 19) % 36) / 100),
          ),
          i.isEven ? 0.8 : 0.55,
          star,
        );
      }
      final Offset moon = Offset(w * 0.78, h * 0.19);
      final Path crescent = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: 10)),
        Path()..addOval(
          Rect.fromCircle(center: moon + const Offset(5, -2), radius: 9),
        ),
      );
      canvas.drawPath(crescent, star);
    }
    final Path completedArc = Path();
    for (int i = 0; i <= 80; i++) {
      final double t = i / 80;
      final Offset point = Offset(
        w * (0.12 + 0.76 * t),
        h * (0.824 - 0.688 * math.sin(math.pi * t)),
      );
      if (i == 0) {
        completedArc.moveTo(point.dx, point.dy);
      } else if (t <= scene.sunProgress) {
        completedArc.lineTo(point.dx, point.dy);
      }
      if (i % 3 == 0) {
        canvas.drawCircle(
          point,
          0.55,
          Paint()..color = PrayerSkyScene.sunGlow.withValues(alpha: 0.3),
        );
      }
    }
    if (scene.sunVisibility > 0) {
      canvas.drawPath(
        completedArc,
        Paint()
          ..color = PrayerSkyScene.sunGlow.withValues(
            alpha: 0.48 * scene.sunVisibility,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        sun,
        12,
        Paint()
          ..color = PrayerSkyScene.sun.withValues(alpha: scene.sunVisibility),
      );
    }
    // Three quiet terrain layers, with no bitmap, blur, or offscreen saveLayer.
    final Path far = Path()
      ..moveTo(0, h * 0.835)
      ..quadraticBezierTo(w * 0.16, h * 0.69, w * 0.39, h * 0.83)
      ..quadraticBezierTo(w * 0.7, h * 0.95, w, h * 0.75)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      far,
      Paint()..color = PrayerSkyScene.farLand.withValues(alpha: 0.18),
    );
    final Path middle = Path()
      ..moveTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.29, h * 0.74, w * 0.57, h * 0.87)
      ..quadraticBezierTo(w * 0.8, h, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      middle,
      Paint()..color = PrayerSkyScene.middleLand.withValues(alpha: 0.4),
    );
    final Path near = Path()
      ..moveTo(0, h)
      ..quadraticBezierTo(w * 0.33, h * 0.84, w * 0.62, h * 0.94)
      ..quadraticBezierTo(w * 0.84, h * 1.04, w, h * 0.88)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      near,
      Paint()..color = PrayerSkyScene.nearLand.withValues(alpha: 0.5),
    );
    if (textDirection == TextDirection.rtl) canvas.restore();
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.28),
          radius: 0.72,
          colors: <Color>[
            PrayerSkyScene.scrim.withValues(alpha: 0.62),
            PrayerSkyScene.scrim.withValues(alpha: 0.42),
            PrayerSkyScene.scrim.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.5, 1],
        ).createShader(bounds),
    );
    if (decorativeEffects) {
      final Paint grain = Paint()
        ..color = PrayerSkyScene.foreground.withValues(alpha: 0.035);
      for (int i = 0; i < 100; i++) {
        canvas.drawCircle(
          Offset(w * ((i * 71) % 101) / 101, h * ((i * 47) % 103) / 103),
          0.45,
          grain,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PrayerSkyPainter oldDelegate) =>
      scene != oldDelegate.scene ||
      textDirection != oldDelegate.textDirection ||
      decorativeEffects != oldDelegate.decorativeEffects;
}
