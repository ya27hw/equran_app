import 'package:emushaf/backend/settings_db.dart';
import 'package:flutter/material.dart';

class FontSlider extends StatefulWidget {
  double fontSize;
  FontSlider({super.key, required this.fontSize});

  @override
  State<FontSlider> createState() => _FontSliderState();
}

class _FontSliderState extends State<FontSlider> {
  @override
  Widget build(BuildContext context) {
    return Slider(
        value: widget.fontSize,
        min: 30.0,
        max: 60.0,
        label: (widget.fontSize / 2).round().toString(),
        onChanged: (double value) {
          setState(() {
            widget.fontSize = value;
            SettingsDB().set("fontSize", value);
          });
        });
  }
}
