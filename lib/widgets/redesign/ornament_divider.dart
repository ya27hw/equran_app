import 'dart:math' as math;
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.onHero = false});

  /// Draws the gold rule and diamond of a `HeroPanel` instead of the page's.
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final Color rule = onHero ? tokens.featRule : tokens.hair2;
    final Color diamond = onHero ? tokens.featGold : tokens.gold;
    Widget line(bool reverse) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reverse
                ? [rule, Colors.transparent]
                : [Colors.transparent, rule],
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: 9,
        child: Row(
          children: [
            line(false),
            const SizedBox(width: 12),
            Transform.rotate(
              angle: math.pi / 4,
              child: SizedBox.square(
                dimension: 6,
                child: ColoredBox(color: diamond.withValues(alpha: 0.85)),
              ),
            ),
            const SizedBox(width: 12),
            line(true),
          ],
        ),
      ),
    );
  }
}
