import 'package:equran/theme/equran_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:equran/utils/text_case.dart';

class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    upperCaseIn(context, label),
    style: EquranTextStyles.eyebrow(context),
  );
}
