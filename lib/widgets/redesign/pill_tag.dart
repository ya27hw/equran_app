import 'dart:math' as math;

import 'package:equran/utils/text_direction.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:flutter/material.dart';

/// Non-interactive metadata. Use [ChipButton] for selectable filters.
class PillTag extends StatelessWidget {
  const PillTag(
    this.label, {
    super.key,
    this.selected = false,
    this.gold = false,
    this.icon,
    this.designIcon,
    this.compact = false,
  });
  final String label;
  final bool selected;
  final bool gold;
  final IconData? icon;
  final String? designIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final color = gold
        ? tokens.goldText
        : selected
        ? tokens.emText
        : tokens.text2;
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 22 : 28),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: gold
            ? tokens.goldWash
            : selected
            ? tokens.emWash
            : Colors.transparent,
        borderRadius: BorderRadius.circular(EquranRadii.pill),
        border: Border.all(
          color: gold
              ? Colors.transparent
              : selected
              ? tokens.hair2
              : tokens.hair,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null || designIcon != null) ...[
            designIcon != null
                ? DesignIcon(designIcon!, size: 14, color: color)
                : Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            textDirection: scriptDirectionIn(context, label),
            style: TextStyle(
              fontFamily: 'Inter',
              fontFamilyFallback: const ['NotoNaskhArabic'],
              fontSize: compact ? 10.5 : 12,
              letterSpacing: compact ? .84 : null,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ChipButton extends StatelessWidget {
  const ChipButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.selected = false,
    this.icon,
    this.designIcon,
    this.dashed = false,
    this.count,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final IconData? icon;

  /// A [DesignIcon] name; takes precedence over [icon].
  final String? designIcon;

  /// Draws a dashed hairline instead of a solid one (the "New folder" chip).
  final bool dashed;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected ? tokens.emText : tokens.text2,
        disabledForegroundColor: tokens.muted,
        backgroundColor: selected ? tokens.emWash : Colors.transparent,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: dashed
            ? BorderSide.none
            : BorderSide(color: selected ? tokens.hair2 : tokens.hair),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.pill),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['NotoNaskhArabic'],
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (designIcon != null) ...[
            DesignIcon(
              designIcon!,
              size: 14,
              strokeWidth: 2,
              color: selected ? tokens.emText : tokens.text2,
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
          ],
          Text(label, textDirection: scriptDirectionIn(context, label)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(count!, style: TextStyle(color: tokens.muted, fontSize: 12)),
          ],
        ],
      ),
    );
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: dashed
            ? CustomPaint(
                foregroundPainter: _DashedPillBorderPainter(tokens.hair),
                child: button,
              )
            : button,
      ),
    );
  }
}

class _DashedPillBorderPainter extends CustomPainter {
  const _DashedPillBorderPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 6) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 3, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillBorderPainter old) => color != old.color;
}
