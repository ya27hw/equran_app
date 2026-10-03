import 'dart:math' as math;
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    Widget line(bool reverse) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: reverse
                ? [tokens.hair2, Colors.transparent]
                : [Colors.transparent, tokens.hair2],
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
                child: ColoredBox(color: tokens.gold.withValues(alpha: 0.85)),
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
