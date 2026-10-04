import 'package:flutter/widgets.dart';

// Hebrew, Arabic and its supplements/presentation forms (covers Persian,
// Urdu and Pashto).
final RegExp _strongRtl = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
final RegExp _anyLetter = RegExp(r'\p{L}', unicode: true);

/// Direction of [text] from its own script (first strong character), so a
/// full stop or `#` lands on the correct side when, say, an English
/// translation or note sits inside an Arabic (RTL) screen, or the reverse.
/// Text without letters keeps [fallback], normally the ambient direction.
TextDirection scriptDirectionOf(
  String text, {
  required TextDirection fallback,
}) {
  for (final int rune in text.runes) {
    final String char = String.fromCharCode(rune);
    if (_strongRtl.hasMatch(char)) return TextDirection.rtl;
    // Any other letter (Latin, Cyrillic, Greek, Bengali, CJK...) is LTR.
    if (_anyLetter.hasMatch(char)) return TextDirection.ltr;
  }
  return fallback;
}

/// [scriptDirectionOf] with the ambient [Directionality] as the fallback.
TextDirection scriptDirectionIn(BuildContext context, String text) =>
    scriptDirectionOf(text, fallback: Directionality.of(context));
