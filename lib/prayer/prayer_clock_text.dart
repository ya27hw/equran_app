import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:flutter/material.dart';

/// Lining, tabular clock figures with the design's smaller day-period suffix.
class PrayerClockText extends StatelessWidget {
  const PrayerClockText(
    this.value, {
    super.key,
    this.size = 22,
    this.suffixSize = 11,
    this.color,
  });
  final String value;
  final double size;
  final double suffixSize;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final split = value.lastIndexOf(' ');
    final digits = split < 0 ? value : value.substring(0, split);
    final suffix = split < 0 ? null : value.substring(split + 1);
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          DisplayNumeral(
            digits,
            size: size,
            height: 1,
            color: color,
            fontWeight: FontWeight.w700,
          ),
          if (suffix != null) ...[
            const SizedBox(width: 4),
            Text(
              suffix,
              style: TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: const ['NotoNaskhArabic'],
                fontSize: suffixSize,
                height: 1,
                fontWeight: FontWeight.w700,
                color: context.equranTokens.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
