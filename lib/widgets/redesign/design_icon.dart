import 'dart:math' as math;

import 'package:equran/widgets/redesign/design_icon_data.dart';
import 'package:flutter/material.dart';

final RegExp _number = RegExp(r'-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?');
final Map<String, List<_Shape>> _cache = {};

/// One of the redesign's stroke icons, drawn from the same SVG data as the
/// design (see [designIconMarkup]). Round caps and joins, no fill by default.
class DesignIcon extends StatelessWidget {
  const DesignIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.strokeWidth = 1.6,
    this.color,
    this.filled = false,
    this.mirrorInRtl = false,
  });
  final String name;
  final double size;
  final double strokeWidth;
  final Color? color;
  final bool filled;

  /// Chevrons and back arrows flip in right-to-left layouts.
  final bool mirrorInRtl;

  @override
  Widget build(BuildContext context) {
    final shapes = _shapesFor(name);
    final rtl = mirrorInRtl && Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Transform.flip(
          flipX: rtl,
          child: CustomPaint(
            painter: _IconPainter(
              shapes,
              color ?? IconTheme.of(context).color ?? Colors.white,
              strokeWidth,
              filled,
            ),
          ),
        ),
      ),
    );
  }
}

class _Shape {
  const _Shape(this.path);
  final Path path;
}

List<_Shape> _shapesFor(String name) => _cache.putIfAbsent(name, () {
  final markup = designIconMarkup[name];
  assert(markup != null, 'Unknown design icon "$name"');
  return _parse(markup ?? '');
});

String? _attr(String tag, String name) =>
    RegExp('$name="([^"]*)"').firstMatch(tag)?.group(1);

List<_Shape> _parse(String markup) {
  final shapes = <_Shape>[];
  for (final m in RegExp(r'<(path|circle|rect)\b[^>]*>').allMatches(markup)) {
    final tag = m.group(0)!;
    double n(String a) => double.parse(_attr(tag, a) ?? '0');
    switch (m.group(1)) {
      case 'path':
        shapes.add(_Shape(_parsePath(_attr(tag, 'd')!)));
      case 'circle':
        shapes.add(
          _Shape(
            Path()..addOval(
              Rect.fromCircle(center: Offset(n('cx'), n('cy')), radius: n('r')),
            ),
          ),
        );
      case 'rect':
        shapes.add(
          _Shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(n('x'), n('y'), n('width'), n('height')),
                Radius.circular(n('rx')),
              ),
            ),
          ),
        );
    }
  }
  return shapes;
}

/// Enough of SVG path syntax for the icon set: M L H V C S A Z, both cases.
Path _parsePath(String d) {
  final path = Path();
  final tokens = RegExp(
    '[MmLlHhVvCcSsAaZz]|${_number.pattern}',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cx = 0.0, cy = 0.0, sx = 0.0, sy = 0.0;
  double? lcx, lcy; // last cubic control, for S
  String cmd = '';
  double next() => double.parse(tokens[i++]);
  bool isCmd(String t) => RegExp('[A-Za-z]').hasMatch(t);
  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    final up = cmd.toUpperCase();
    double x(double v) => rel ? cx + v : v;
    double y(double v) => rel ? cy + v : v;
    switch (up) {
      case 'M':
        final nx = x(next()), ny = y(next());
        path.moveTo(nx, ny);
        cx = sx = nx;
        cy = sy = ny;
        cmd = rel ? 'l' : 'L';
        lcx = null;
      case 'L':
        final nx = x(next()), ny = y(next());
        path.lineTo(nx, ny);
        cx = nx;
        cy = ny;
        lcx = null;
      case 'H':
        final nx = x(next());
        path.lineTo(nx, cy);
        cx = nx;
        lcx = null;
      case 'V':
        final ny = y(next());
        path.lineTo(cx, ny);
        cy = ny;
        lcx = null;
      case 'C':
        final x1 = x(next()), y1 = y(next());
        final x2 = x(next()), y2 = y(next());
        final nx = x(next()), ny = y(next());
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lcx = x2;
        lcy = y2;
        cx = nx;
        cy = ny;
      case 'S':
        final x1 = lcx == null ? cx : 2 * cx - lcx;
        final y1 = lcx == null ? cy : 2 * cy - lcy!;
        final x2 = x(next()), y2 = y(next());
        final nx = x(next()), ny = y(next());
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        lcx = x2;
        lcy = y2;
        cx = nx;
        cy = ny;
      case 'A':
        final rx = next(), ry = next(), rot = next();
        final large = next() != 0, sweep = next() != 0;
        final nx = x(next()), ny = y(next());
        path.arcToPoint(
          Offset(nx, ny),
          radius: Radius.elliptical(rx, ry),
          rotation: rot * math.pi / 180,
          largeArc: large,
          clockwise: sweep,
        );
        cx = nx;
        cy = ny;
        lcx = null;
      case 'Z':
        path.close();
        cx = sx;
        cy = sy;
        lcx = null;
    }
  }
  return path;
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.shapes, this.color, this.strokeWidth, this.filled);
  final List<_Shape> shapes;
  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    for (final s in shapes) {
      if (filled) canvas.drawPath(s.path, fill);
      canvas.drawPath(s.path, stroke);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.shapes != shapes ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.filled != filled;
}
