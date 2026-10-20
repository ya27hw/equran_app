import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/text_direction.dart';
import 'package:flutter/material.dart';

/// A flat two-to-four way switch in the Statistics range toggle's style: a
/// hairline track with the selected segment on an emerald wash. It only
/// draws; the caller owns the selected index.
class RedesignSegmentedControl extends StatelessWidget {
  const RedesignSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.icons = const <Widget?>[],
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Optional leading icons, one per label; build them with
  /// `DesignIcon(..., color: <inherited>)` so they follow the segment colour.
  final List<Widget?> icons;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.equranColors.surface,
        border: Border.all(color: tokens.hair),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: i == selectedIndex,
                child: TextButton(
                  onPressed: () => onChanged(i),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 9,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: i == selectedIndex
                        ? tokens.emText
                        : tokens.text2,
                    backgroundColor: i == selectedIndex
                        ? tokens.emWash
                        : Colors.transparent,
                    side: BorderSide(
                      color: i == selectedIndex
                          ? tokens.hair2
                          : Colors.transparent,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (i < icons.length && icons[i] != null) ...<Widget>[
                        IconTheme.merge(
                          data: IconThemeData(
                            color: i == selectedIndex
                                ? tokens.emText
                                : tokens.text2,
                            size: 18,
                          ),
                          child: icons[i]!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          textDirection: scriptDirectionIn(context, labels[i]),
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
