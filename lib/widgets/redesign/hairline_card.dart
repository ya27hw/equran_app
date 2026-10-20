import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

/// The redesign's flat, 24 px surface. Layout belongs to its caller.
class HairlineCard extends StatelessWidget {
  const HairlineCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: context.equranColors.surface,
      border: Border.all(color: context.equranTokens.hair),
      borderRadius: BorderRadius.circular(EquranRadii.xl),
    ),
    child: child,
  );
}
