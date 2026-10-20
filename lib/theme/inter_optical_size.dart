import 'package:flutter/material.dart' show TextTheme;
import 'package:flutter/painting.dart';

/// Inter's `opsz` axis runs from 14 to 32. Browsers apply
/// `font-optical-sizing: auto` (opsz equals the font size), so the design
/// previews show tighter, narrower Inter at larger sizes. Flutter keeps the
/// axis at its default (14) unless the style sets it, which made app text
/// about 9% wider than the design at 32 px (about 3% at 20 px, unchanged at
/// 14 px and below).
///
/// Only `opsz` is set here. Flutter still derives `wght` from
/// [TextStyle.fontWeight] (verified for 400, 500, 600, 700 and 900), so
/// weights keep working.
const double interOpszMin = 14;
const double interOpszMax = 32;

/// The `opsz` variation for Inter text of [fontSize] logical pixels.
FontVariation interOpticalSize(double fontSize) =>
    FontVariation('opsz', fontSize.clamp(interOpszMin, interOpszMax));

/// Whether [family] is Inter, including google_fonts' `Inter_regular` names.
/// A null family inherits the ambient one, which is Inter for interface text.
bool _isInterFamily(String? family) =>
    family == null || family.startsWith('Inter');

extension InterOpticalSize on TextStyle {
  /// Sets `opsz = fontSize` for Inter text, replacing an `opsz` inherited
  /// from a theme slot and keeping any other variation.
  ///
  /// Returns the style untouched when it has no font size or names another
  /// family (Newsreader, Noto Naskh, the Quran fonts), so their own axes and
  /// the Arabic script are never altered.
  ///
  /// Call it on the final style, after `fontSize` is known. In a `const`
  /// context write `fontVariations: const [FontVariation('opsz', 16)]` next
  /// to the literal `fontSize` instead.
  TextStyle withInterOpticalSize() {
    final double? size = fontSize;
    if (size == null || !_isInterFamily(fontFamily)) return this;
    return copyWith(
      fontVariations: <FontVariation>[
        ...?fontVariations?.where((FontVariation v) => v.axis != 'opsz'),
        interOpticalSize(size),
      ],
    );
  }
}

extension InterOpticalTextTheme on TextTheme {
  /// Applies [InterOpticalSize.withInterOpticalSize] to every slot.
  TextTheme withInterOpticalSizes() => copyWith(
    displayLarge: displayLarge?.withInterOpticalSize(),
    displayMedium: displayMedium?.withInterOpticalSize(),
    displaySmall: displaySmall?.withInterOpticalSize(),
    headlineLarge: headlineLarge?.withInterOpticalSize(),
    headlineMedium: headlineMedium?.withInterOpticalSize(),
    headlineSmall: headlineSmall?.withInterOpticalSize(),
    titleLarge: titleLarge?.withInterOpticalSize(),
    titleMedium: titleMedium?.withInterOpticalSize(),
    titleSmall: titleSmall?.withInterOpticalSize(),
    bodyLarge: bodyLarge?.withInterOpticalSize(),
    bodyMedium: bodyMedium?.withInterOpticalSize(),
    bodySmall: bodySmall?.withInterOpticalSize(),
    labelLarge: labelLarge?.withInterOpticalSize(),
    labelMedium: labelMedium?.withInterOpticalSize(),
    labelSmall: labelSmall?.withInterOpticalSize(),
  );
}
