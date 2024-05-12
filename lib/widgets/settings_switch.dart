import 'package:eQuran/backend/library.dart' show SettingsDB;
import 'package:flutter/material.dart';

class SettingsSwitch extends StatefulWidget {
  final String title;
  final String settingsKey;
  final String? subtitle;

  const SettingsSwitch(
      {super.key,
      required this.title,
      required this.settingsKey,
      this.subtitle});

  @override
  State<SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<SettingsSwitch> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      trailing: Switch(
        value: SettingsDB().get(widget.settingsKey, defaultValue: true),
        onChanged: (bool value) {
          setState(() {
            SettingsDB().put(widget.settingsKey, value);
          });
        },
      ),
    );
  }
}
