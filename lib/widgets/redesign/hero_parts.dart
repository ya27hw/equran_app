import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/text_direction.dart';
import 'package:flutter/material.dart';

/// Small parts for the content of a `HeroPanel`. Their colours come from the
/// panel's own tokens (`onFeat`, `featGold`), not the page's.

/// A pill on a hero panel.
class HeroPill extends StatelessWidget {
  const HeroPill(this.label, {super.key, this.icon, this.strong = false});

  final String label;

  /// A `DesignIcon` or `Icon`; it is tinted and sized here.
  final Widget? icon;

  /// A brighter fill, for the state that matters.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.equranTokens.onFeat;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: strong ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(EquranRadii.pill),
        border: Border.all(color: ink.withValues(alpha: strong ? 0.34 : 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            IconTheme.merge(
              data: IconThemeData(color: ink, size: 14),
              child: icon!,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              textDirection: scriptDirectionIn(context, label),
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded progress bar on a hero panel: [color] on a faint track.
class HeroProgressBar extends StatelessWidget {
  const HeroProgressBar({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(EquranRadii.pill),
    child: LinearProgressIndicator(
      minHeight: 8,
      value: value,
      color: color,
      backgroundColor: context.equranTokens.onFeat.withValues(alpha: 0.16),
    ),
  );
}
