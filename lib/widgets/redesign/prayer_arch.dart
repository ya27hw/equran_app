import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

/// Fixed illustration colours for the six prayer arches, from the design.
/// They are artwork (a sky at each prayer), so they do not follow the palette.
class _Sky {
  const _Sky(this.stops, this.colors);
  final List<double> stops;
  final List<Color> colors;
}

const _skies = <PrayerTimeKind, _Sky>{
  PrayerTimeKind.fajr: _Sky(
    [0, .55, 1],
    [Color(0xFF1B2559), Color(0xFF6C5AA6), Color(0xFFF0A58E)],
  ),
  PrayerTimeKind.sunrise: _Sky(
    [0, .6, 1],
    [Color(0xFF5E93D8), Color(0xFFF4BE8C), Color(0xFFF9D87C)],
  ),
  PrayerTimeKind.dhuhr: _Sky([0, 1], [Color(0xFF1F9BC4), Color(0xFF8FE1E8)]),
  PrayerTimeKind.asr: _Sky(
    [0, .6, 1],
    [Color(0xFF1D7893), Color(0xFF6FB0A0), Color(0xFFE9A83A)],
  ),
  PrayerTimeKind.maghrib: _Sky(
    [0, .55, 1],
    [Color(0xFF7E1D5C), Color(0xFFE2472C), Color(0xFFF7A824)],
  ),
  PrayerTimeKind.isha: _Sky([0, 1], [Color(0xFF0A1838), Color(0xFF18305F)]),
};

const _moon = Color(0xFFF6EEC7);
const _star = Color(0xFFFFFFFF);
const _sun = Color(0xFFFFD27A);

/// The arch-shaped sky icon of one prayer, drawn in the design's 44 x 54 grid.
class PrayerArch extends StatelessWidget {
  const PrayerArch({
    super.key,
    required this.kind,
    required this.semanticLabel,
    double? width,
  }) : width = width ?? (kind == PrayerTimeKind.sunrise ? 30 : 34);
  final PrayerTimeKind kind;
  final String semanticLabel;
  final double width;

  double get height => (width * 54 / 44).roundToDouble();

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: _ArchPainter(kind, context.equranTokens.gold),
      ),
    ),
  );
}

Path _archPath() => Path()
  ..moveTo(2, 54)
  ..lineTo(2, 22)
  ..cubicTo(2, 10.4, 10.8, 2, 22, 2)
  ..cubicTo(33.2, 2, 42, 10.4, 42, 22)
  ..lineTo(42, 54)
  ..close();

/// SVG `a rx rx 0 1 0 dx dy`, then the inner edge back, as in the design.
Path _crescent(Offset from, Offset d, double outer, double inner) => Path()
  ..moveTo(from.dx, from.dy)
  ..relativeArcToPoint(
    d,
    radius: Radius.circular(outer),
    largeArc: true,
    clockwise: false,
  )
  ..relativeArcToPoint(-d, radius: Radius.circular(inner), clockwise: true)
  ..close();

class _ArchPainter extends CustomPainter {
  const _ArchPainter(this.kind, this.gold);
  final PrayerTimeKind kind;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 44, size.height / 54);
    final sky = _skies[kind]!;
    final arch = _archPath();
    canvas.save();
    canvas.clipPath(arch);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 44, 54),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky.colors,
          stops: sky.stops,
        ).createShader(const Rect.fromLTWH(0, 0, 44, 54)),
    );
    final fill = Paint();
    void disc(double x, double y, double r, Color c, [double alpha = 1]) =>
        canvas.drawCircle(
          Offset(x, y),
          r,
          fill..color = c.withValues(alpha: alpha),
        );
    switch (kind) {
      case PrayerTimeKind.fajr:
        canvas.drawPath(
          _crescent(const Offset(17, 12), const Offset(5, 10.5), 7, 5.8),
          fill..color = _moon,
        );
        disc(31, 16, 1, _star);
        disc(12, 26, .8, _star);
      case PrayerTimeKind.sunrise:
        disc(22, 50, 11, const Color(0xFFFFE9A0));
        disc(22, 50, 17, const Color(0xFFFFE9A0), .25);
      case PrayerTimeKind.dhuhr:
        disc(22, 22, 14, _star, .22);
        disc(22, 22, 8, const Color(0xFFFFF7C2));
      case PrayerTimeKind.asr:
        disc(29, 38, 12, _sun, .3);
        disc(29, 38, 7, _sun);
      case PrayerTimeKind.maghrib:
        disc(22, 52, 10, const Color(0xFFFFB347));
        disc(22, 52, 17, const Color(0xFFFFB347), .25);
      case PrayerTimeKind.isha:
        canvas.drawPath(
          _crescent(const Offset(27, 13), const Offset(6, 12), 8, 6.6),
          fill..color = _moon,
        );
        disc(12, 14, 1, _star);
        disc(34, 38, .9, _star);
        disc(15, 34, .8, _star);
    }
    canvas.restore();
    canvas.drawPath(
      arch,
      Paint()
        ..color = gold.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_ArchPainter old) => old.kind != kind || old.gold != gold;
}
