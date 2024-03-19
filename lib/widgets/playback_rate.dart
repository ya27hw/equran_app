import 'package:emushaf/backend/library.dart';
import 'package:flutter/material.dart';

class PlayBackSlider extends StatefulWidget {
  const PlayBackSlider({super.key});

  @override
  State<PlayBackSlider> createState() => _PlayBackSliderState();
}

class _PlayBackSliderState extends State<PlayBackSlider> {
  @override
  Widget build(BuildContext context) {
    double rate = SettingsDB().get("playbackRate", defaultValue: 1.0);
    return ListTile(
      title: const Text("Playback Rate"),
      subtitle: Slider(
        min: 0.5,
        max: 2,
        divisions: 6,
        label: rate.toString(),
        value: rate,
        onChanged: (double value) {
          setState(() {
            rate = value;
            SettingsDB().put("playbackRate", value);
          });
        },
      ),
    );
  }
}
