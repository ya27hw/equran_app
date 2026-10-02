import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// An [Image.asset] that decodes no wider than the space it is painted into.
///
/// Several bundled illustrations are 1000-1254 px square (4-6 MB once decoded)
/// but are shown in slots well under 200 logical pixels wide. Decoding them at
/// full size wastes RAM and decode time, which hurts low-end devices most.
/// [ResizeImage] never upscales, so small sources are unaffected.
class EquranAssetImage extends StatelessWidget {
  const EquranAssetImage(
    this.assetName, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.errorBuilder,
  });

  /// Slot size assumed when the parent gives no bounded width or height.
  static const double _fallbackLogicalSize = 240;

  /// Upper bound so one oversized slot cannot defeat the purpose.
  static const int _maxDecodePixels = 1100;

  final String assetName;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double logicalWidth = _bounded(width, constraints.maxWidth);
        final double logicalHeight = _bounded(height, constraints.maxHeight);
        // The asset is decoded once, so size it for the larger of the two
        // axes; the other axis follows from the aspect ratio.
        final double logicalSize = math.max(logicalWidth, logicalHeight);
        final int cacheWidth = (logicalSize * pixelRatio).ceil().clamp(
          1,
          _maxDecodePixels,
        );
        return Image.asset(
          assetName,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          cacheWidth: cacheWidth,
          errorBuilder: errorBuilder,
        );
      },
    );
  }

  static double _bounded(double? explicit, double constraint) {
    if (explicit != null && explicit.isFinite) return explicit;
    return constraint.isFinite ? constraint : _fallbackLogicalSize;
  }
}
