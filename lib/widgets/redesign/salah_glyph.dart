import 'dart:math' as math;
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

/// Presentation states only; the caller maps its own stored prayer status.
enum SalahGlyphState { onTime, late, missed, notLogged, notYet }

class SalahGlyph extends StatelessWidget {
  const SalahGlyph({
    super.key,
    required this.state,
    required this.semanticLabel,
    this.size = 24,
  });
  final SalahGlyphState state;

  /// Localized by the caller, including the prayer name where appropriate.
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SalahPainter(
          state,
          context.equranTokens,
          Directionality.of(context),
        ),
      ),
    ),
  );
}

class _SalahPainter extends CustomPainter {
  const _SalahPainter(this.state, this.tokens, this.direction);
  final SalahGlyphState state;
  final EquranTokens tokens;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    const center = Offset(12, 12);
    final paint = Paint()..isAntiAlias = true;
    switch (state) {
      case SalahGlyphState.onTime:
        canvas.drawCircle(center, 12, paint..color = tokens.filled);
        canvas.drawPath(
          Path()
            ..moveTo(8.23, 12.29)
            ..lineTo(10.67, 14.72)
            ..lineTo(15.78, 9.27),
          paint
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case SalahGlyphState.late:
        final rect = Rect.fromCircle(center: center, radius: 11);
        canvas.drawArc(
          rect,
          direction == TextDirection.ltr ? math.pi / 2 : -math.pi / 2,
          math.pi,
          true,
          paint..color = tokens.gold,
        );
        canvas.drawCircle(
          center,
          11,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case SalahGlyphState.missed:
        canvas.drawCircle(
          center,
          11,
          paint
            ..color = tokens.danger
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          const Offset(7.5, 12),
          const Offset(16.5, 12),
          paint..strokeCap = StrokeCap.round,
        );
      case SalahGlyphState.notLogged:
        canvas.drawCircle(center, 3, paint..color = tokens.muted);
      case SalahGlyphState.notYet:
        paint
          ..color = tokens.hair2
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        for (int i = 0; i < 12; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: 11.25),
            i * math.pi / 6,
            math.pi / 12,
            false,
            paint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_SalahPainter oldDelegate) =>
      state != oldDelegate.state ||
      tokens != oldDelegate.tokens ||
      direction != oldDelegate.direction;
}
