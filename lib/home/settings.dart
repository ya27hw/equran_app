import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:emushaf/backend/bookmark_db.dart';
import 'package:emushaf/backend/favourites_db.dart';
import 'package:emushaf/backend/library.dart' show SettingsDB;
import 'package:emushaf/widgets/library.dart'
    show FontSlider, PlayBackSlider, SettingsSwitch;
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          const SettingsSwitch(
            title: "Vibration",
            settingsKey: "vibration",
          ),
          const SettingsSwitch(
            title: "Card View",
            settingsKey: "viewMode",
          ),
          const SettingsSwitch(
            title: "Show reading history",
            settingsKey: "showLastRead",
            subtitle: "Shows you up to 7 last read Surahs.",
          ),
          const PlayBackSlider(),
          ListTile(
            title: const Text("Clear reading history"),
            subtitle: const Text("Removes all your reading history."),
            onTap: () => showDialog<void>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      title: Text(
                        "Clear reading history",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded),
                      content: Text(
                        "WARNING: Are you sure you want to clear your reading history?",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              "NO",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer),
                            )),
                        TextButton(
                            onPressed: () async {
                              await BookmarkDB().clear();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "YES",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer),
                            ))
                      ],
                    )),
          ),
          ListTile(
            title: const Text("Clear Favourites"),
            subtitle: const Text("Removes all verses you have liked. "),
            onTap: () => showDialog<void>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      title: Text(
                        "Clear Favourites",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded),
                      content: Text(
                        "WARNING: Are you sure you want to clear favourites?",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              "NO",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer),
                            )),
                        TextButton(
                            onPressed: () async {
                              await FavouritesDB().clear();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "YES",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer),
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
