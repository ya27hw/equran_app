import 'package:equran/theme/equran_text_styles.dart';
import 'package:flutter/material.dart';

class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label.toUpperCase(), style: EquranTextStyles.eyebrow(context));
}
