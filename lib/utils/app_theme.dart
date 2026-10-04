import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_theme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const String defaultScheme = 'default';
  static const String fancyBlueScheme = 'fancyBlue';
  static const String fancyPurpleScheme = 'fancyPurple';
  static const String sepiaScheme = 'sepia';
  static const String blackScheme = 'black';
  static const String redScheme = 'red';

  static ThemeData buildLightTheme(Color seedColor, {String? schemeId}) {
    assert(seedColor.a >= 0);
    return EquranTheme.fromColors(
      EquranColors.forScheme(schemeId, false),
      Brightness.light,
    );
  }

  static ThemeData buildDarkTheme(
    Color seedColor, {
    String? schemeId,
    bool? pureBlackBackground,
  }) {
    assert(seedColor.a >= 0);
    return EquranTheme.fromColors(
      EquranColors.forScheme(
        schemeId,
        true,
        pureBlackBackground: pureBlackBackground,
      ),
      Brightness.dark,
    );
  }
}
