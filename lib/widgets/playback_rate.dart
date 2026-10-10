import 'package:equran/backend/library.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

class PlayBackSlider extends StatefulWidget {
  const PlayBackSlider({super.key});

  @override
  State<PlayBackSlider> createState() => _PlayBackSliderState();
}

class _PlayBackSliderState extends State<PlayBackSlider> {
  @override
  Widget build(BuildContext context) {
    double rate = SettingsDB().get("playbackRate", defaultValue: 1.0);
    return ReaderSliderBlock(
      leading: const Icon(Icons.speed_rounded),
      title: AppLocalizations.of(context)!.playbackRate,
      valueLabel: '${rate.toStringAsFixed(2)}x',
      slider: Slider(
        min: 0.5,
        max: 2,
        divisions: 6,
        label: '${rate.toStringAsFixed(2)}x',
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
