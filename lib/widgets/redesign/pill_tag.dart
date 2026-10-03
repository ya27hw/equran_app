import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

/// Non-interactive metadata. Use [ChipButton] for selectable filters.
class PillTag extends StatelessWidget {
  const PillTag(
    this.label, {
    super.key,
    this.selected = false,
    this.gold = false,
    this.icon,
  });
  final String label;
  final bool selected;
  final bool gold;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final color = gold
        ? tokens.goldText
        : selected
        ? tokens.emText
        : tokens.text2;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 11,
        vertical: 5,
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
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
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
    this.count,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final IconData? icon;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: TextButton(
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
            side: BorderSide(color: selected ? tokens.hair2 : tokens.hair),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EquranRadii.pill),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 6),
              ],
              Text(label),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  count!,
                  style: TextStyle(color: tokens.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
