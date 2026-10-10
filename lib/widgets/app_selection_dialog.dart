import 'package:flutter/widgets.dart';

class AppSelectionOption<T> {
  const AppSelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;

  /// A short status marker shown after the title, such as an icon.
  final Widget? trailing;
}
