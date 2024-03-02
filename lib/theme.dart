import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTheme {
  static ThemeData lightThemeData(BuildContext context) {
    return ThemeData(
        fontFamily: GoogleFonts.raleway().fontFamily,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light);
  }

  static ThemeData darkThemeData(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.raleway().fontFamily,
      colorSchemeSeed: Colors.blueGrey,
      brightness: Brightness.dark,
    );
  }
}
