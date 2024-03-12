import 'package:emushaf/backend/library.dart' show SettingsDB;
import 'package:flutter/material.dart';

class FontSlider extends StatefulWidget {
  const FontSlider({super.key});

  @override
  State<FontSlider> createState() => _FontSliderState();
}

class _FontSliderState extends State<FontSlider> {
  @override
  Widget build(BuildContext context) {
    double fontSize = SettingsDB().get("fontSize", defaultValue: 30.0);

    return Slider(
        value: fontSize,
        min: 30.0,
        max: 60.0,
        label: (fontSize / 2).round().toString(),
        onChanged: (double value) {
          setState(() {
            fontSize = value;
            SettingsDB().put("fontSize", value);
          });
        });
  }
}
