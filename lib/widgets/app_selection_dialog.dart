import 'package:flutter/widgets.dart';

class AppSelectionOption<T> {
  const AppSelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
}
