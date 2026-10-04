import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:flutter/material.dart';

class IconButton44 extends StatelessWidget {
  const IconButton44({
    super.key,
    this.icon,
    this.designIcon,
    required this.tooltip,
    required this.onPressed,
    this.ghost = false,
  }) : assert(icon != null || designIcon != null);
  final IconData? icon;

  /// A [DesignIcon] name; use instead of [icon] to match the design's icons.
  final String? designIcon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool ghost;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: designIcon != null
        ? DesignIcon(
            designIcon!,
            size: 21,
            strokeWidth: 1.7,
            mirrorInRtl: const {'back', 'chev', 'chevl'}.contains(designIcon),
          )
        : Icon(icon, size: 21),
    style: IconButton.styleFrom(
      fixedSize: const Size.square(44),
      minimumSize: const Size.square(44),
      maximumSize: const Size.square(44),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: context.equranTokens.text2,
      disabledForegroundColor: context.equranTokens.muted,
      backgroundColor: ghost
          ? Colors.transparent
          : context.equranColors.surface,
      side: BorderSide(
        color: ghost ? Colors.transparent : context.equranTokens.hair,
      ),
      shape: const CircleBorder(),
    ),
  );
}
