import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:emushaf/utils/settings_db.dart';
import 'package:emushaf/widgets/font_slider.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        children: [
          ListTile(
            title: Text(
              "Appearance",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Choose a Color'),
                    content: Wrap(
                      runSpacing: 10,
                      spacing: 10.0, // Add spacing between circles
                      children: List.generate(Colors.primaries.length, (index) {
                        final color = Colors.primaries[index];
                        return InkWell(
                          onTap: () {
                            SettingsDB().set("color", index);

                            AdaptiveTheme.of(context).setTheme(
                                light: ThemeData(colorSchemeSeed: color),
                                dark: ThemeData(
                                    colorSchemeSeed: color,
                                    brightness: Brightness.dark));
                          },
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 17.0,
                            // Adjust radius as needed
                          ),
                        );
                      }),
                    ),
                  );
                },
              );
            },
            title: Text("Theme"),
            subtitle: Text("Pick your desired color scheme."),
            // trailing: CircleAvatar(
            //   backgroundColor: Theme.of(context).colorScheme.primary,
            //   radius: 12.5, // Adjust radius as needed
            // ),
          ),
          ListTile(
            title: Text("Font Size"),
            subtitle: FontSlider(fontSize: SettingsDB().get("fontSize", 30.0)),
          ),
        ],
      ),
    );
  }
}
