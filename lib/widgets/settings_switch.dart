import 'package:equran/backend/library.dart' show SettingsDB;
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:flutter/material.dart';

class SettingsSwitch extends StatefulWidget {
  final String title;
  final String settingsKey;
  final String? subtitle;
  final ValueChanged<bool>? onChanged;
  final bool defaultValue;
  final Widget? leading;

  const SettingsSwitch({
    super.key,
    required this.title,
    required this.settingsKey,
    this.subtitle,
    this.onChanged,
    this.defaultValue = true,
    this.leading,
  });

  @override
  State<SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<SettingsSwitch> {
  void _setValue(bool value) {
    setState(() {
      SettingsDB().put(widget.settingsKey, value);
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final bool currentValue = SettingsDB().get(
      widget.settingsKey,
      defaultValue: widget.defaultValue,
    );

    return ReaderSwitchRow(
      leading: widget.leading ?? const Icon(Icons.tune_rounded),
      title: widget.title,
      subtitle: widget.subtitle,
      value: currentValue,
      onChanged: _setValue,
    );
  }
}
