import 'package:eQuran/backend/library.dart';
import 'package:eQuran/home/library.dart';
import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class Item {
  Item(
      {required this.panelTitle,
      required this.children,
      this.isExpanded = false});

  String panelTitle;
  List<String> children;
  bool isExpanded = false;
}

class FavouritesList extends StatefulWidget {
  const FavouritesList({super.key});

  @override
  State<FavouritesList> createState() => _FavouritesListState();
}

class _FavouritesListState extends State<FavouritesList> {
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Item> _data = generateItems();

    return Wrap(direction: Axis.horizontal, children: [
      ExpansionTileGroup(
          spaceBetweenItem: 4,
          toggleType: ToggleType.expandOnlyCurrent,
          children: _data.asMap().entries.map((e) {
            final item = e.value;
            final surah = int.parse(item.panelTitle);

            return ExpansionTileWithoutBorderItem(
                title: Text(quran.getSurahName(surah)),
                children: item.children.asMap().entries.map((ee) {
                  final key = "${item.panelTitle}-${ee.value}";
                  final verse = int.parse(ee.value);
                  final String subtitle =
                      FavouritesDB().get(key, defaultValue: "");
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        await Future.delayed(const Duration(milliseconds: 270));
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ReadPage(
                                  chapter: surah,
                                  startVerse: verse,
                                )));
                      },
                      child: ListTile(
                        title: Text("Ayah $verse"),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          onPressed: () {
                            _showBottomSheetWithOptions(
                                context, key, _controller);
                          },
                        ),
                        subtitle: subtitle.isNotEmpty
                            ? Text(
                                subtitle,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList());
          }).toList())
    ]);
  }
}

List<Item> generateItems() {
  List<dynamic> data = FavouritesDB().getKeys().toList();
  Map<String, List<String>> favouritesMap = {};

  for (var item in data) {
    var parts = item.split('-');
    favouritesMap.putIfAbsent(parts[0], () => []).add(parts[1]);
  }

  return favouritesMap.entries
      .map((entry) => Item(panelTitle: entry.key, children: entry.value))
      .toList();
}

void _showBottomSheetWithOptions(
    BuildContext context, String key, TextEditingController _controller) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Wrap(
        children: <Widget>[
          InkWell(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            onTap: () {
              _showEditNoteDialog(
                  context,
                  key,
                  FavouritesDB().get(key, defaultValue: ""),
                  _controller); // Close the bottom sheet
              // Implement your edit logic here
            },
            child: const ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              FavouritesDB().delete(key);
            },
          ),
        ],
      );
    },
  );
}

void _showEditNoteDialog(BuildContext context, String key, String initialNote,
    TextEditingController _controller) {
  _controller.text = initialNote;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Note'),
        content: TextField(
          controller: _controller,
          maxLines: null, // Allows multiple lines
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              String editedNote = _controller.text;
              // Save the edited note (e.g., update in a database)
              FavouritesDB().put(key, editedNote);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
