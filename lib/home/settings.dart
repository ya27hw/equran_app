import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:emushaf/backend/favourites_db.dart';
import 'package:emushaf/backend/library.dart' show SettingsDB;
import 'package:emushaf/widgets/library.dart' show FontSlider;
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
              "General",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            title: const Text("Clear Favourites"),
            subtitle: const Text("Removes all verses you have liked. "),
            onTap: () => showDialog<void>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      title: const Text("Clear Favourites"),
                      icon: const Icon(Icons.warning_amber_rounded),
                      content: const Text(
                        "WARNING: Are you sure you want to clear favourites?",
                        style: TextStyle(color: Colors.white),
                      ),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              "NO",
                              style: TextStyle(color: Colors.white),
                            )),
                        TextButton(
                            onPressed: () async {
                              await FavouritesDB().clear();
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "YES",
                              style: TextStyle(color: Colors.white),
                            ))
                      ],
                    )),
          ),
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
                    icon: const Icon(Icons.format_paint_rounded),
                    content: Wrap(
                      runSpacing: 10,
                      spacing: 10.0, // Add spacing between circles
                      children: List.generate(Colors.primaries.length, (index) {
                        final color = Colors.primaries[index];
                        return InkWell(
                          onTap: () {
                            SettingsDB().put("color", index);

                            AdaptiveTheme.of(context).setTheme(
                                light: ThemeData(colorSchemeSeed: color),
                                dark: ThemeData(
                                    colorSchemeSeed: color,
                                    brightness: Brightness.dark));
                          },
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 18.0,
                            // Adjust radius as needed
                          ),
                        );
                      }),
                    ),
                  );
                },
              );
            },
            title: const Text("Theme"),
            subtitle: const Text("Pick your desired color scheme."),
            // trailing: CircleAvatar(
            //   backgroundColor: Theme.of(context).colorScheme.primary,
            //   radius: 12.5, // Adjust radius as needed
            // ),
          ),
          const FontSlider(),
        ],
      ),
    );
  }
}
