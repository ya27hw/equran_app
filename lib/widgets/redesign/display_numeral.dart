import 'package:equran/theme/equran_text_styles.dart';
import 'package:flutter/material.dart';

class DisplayNumeral extends StatelessWidget {
  const DisplayNumeral(
    this.text, {
    super.key,
    this.size = 22,
    this.height = 1,
    this.color,
  });
  final String text;
  final double size;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    // Keep count fractions and clock punctuation in numeric reading order in RTL.
    textDirection: TextDirection.ltr,
    style: EquranTextStyles.displayNumeral(
      context,
      size: size,
      height: height,
      color: color,
    ),
  );
}
