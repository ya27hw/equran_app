import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/common/equran_asset_image.dart';
import 'package:flutter/material.dart';

class PrayerArch extends StatelessWidget {
  const PrayerArch({
    super.key,
    required this.assetName,
    required this.semanticLabel,
    this.width = 34,
    this.height = 42,
  });
  final String assetName;
  final String semanticLabel;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        foregroundPainter: _ArchBorder(context.equranTokens.gold),
        child: ClipPath(
          clipper: const _ArchClipper(),
          child: ExcludeSemantics(
            child: EquranAssetImage(
              assetName,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ),
  );
}

Path _archPath(Size size) =>
    (Path()
          ..moveTo(2, 54)
          ..lineTo(2, 22)
          ..cubicTo(2, 10.4, 10.8, 2, 22, 2)
          ..cubicTo(33.2, 2, 42, 10.4, 42, 22)
          ..lineTo(42, 54)
          ..close())
        .transform(
          Matrix4.diagonal3Values(size.width / 44, size.height / 54, 1).storage,
        );

class _ArchClipper extends CustomClipper<Path> {
  const _ArchClipper();
  @override
  Path getClip(Size size) => _archPath(size);
  @override
  bool shouldReclip(_ArchClipper oldClipper) => false;
}

class _ArchBorder extends CustomPainter {
  const _ArchBorder(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    _archPath(size),
    Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * size.width / 44,
  );
  @override
  bool shouldRepaint(_ArchBorder oldDelegate) => color != oldDelegate.color;
}
