import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

/// Ripple radius for row [index] of [count] inside a [GroupedCardSliver]:
/// only the first row's top and the last row's bottom follow the card corners.
BorderRadius groupedInkRadius(int index, int count) => BorderRadius.vertical(
  top: Radius.circular(index == 0 ? EquranRadii.xl : 0),
  bottom: Radius.circular(index == count - 1 ? EquranRadii.xl : 0),
);

/// One surface with a hairline border and hairline-separated rows, as a
/// sliver so long lists (surahs, juz, pages) stay lazy. Rows draw no surface
/// of their own; give each one [groupedInkRadius] for its ripple.
class GroupedCardSliver extends StatelessWidget {
  const GroupedCardSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: context.equranColors.surface,
        borderRadius: BorderRadius.circular(EquranRadii.xl),
        border: Border.all(color: tokens.hair),
      ),
      sliver: SliverList.separated(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (BuildContext context, int index) =>
            Divider(height: 1, thickness: 1, color: tokens.hair),
      ),
    );
  }
}
