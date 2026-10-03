import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

class IconButton44 extends StatelessWidget {
  const IconButton44({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.ghost = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool ghost;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: 21),
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
