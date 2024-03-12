import 'package:emushaf/utils/settings_db.dart';
import 'package:emushaf/widgets/read_quran_card.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:quran/quran.dart' as quran;
import 'package:vibration/vibration.dart';

class ReadPage extends StatefulWidget {
  final int chapter;
  final int? startVerse;
  const ReadPage({super.key, required this.chapter, this.startVerse});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  late int _currentVerse;
  late Box _bookmarks;
  late int _currentChapter;
  late ScrollController _scrollController;
  late int _totalVerses;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _bookmarks = Hive.box("bookmarks");
    _currentChapter = widget.chapter;
    if(widget.startVerse == null) {
      _currentVerse = _bookmarks.get(_currentChapter) ?? 1;
    } else {
      _currentVerse = widget.startVerse!;
    }

    _getTotalVerses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    // Define margin values for different screen sizes
    double marginValue;
    if (screenSize.width > 1200) {
      marginValue = 90.0; // Large screen
    } else if (screenSize.width > 700) {
      marginValue = 40.0; // Medium screen
    } else {
      marginValue = 8.0; // Small screen
    }
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(quran.getSurahName(_currentChapter)),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.restart_alt),
              onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                        title: const Text("Reset"),
                        content: const Text("Would you like to start over?"),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel")),
                          TextButton(
                            child: const Text("OK"),
                            onPressed: () {
                              _reset();
                              _delete();
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      )))
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: marginValue),
                  child: LinearPercentIndicator(
                      barRadius: const Radius.circular(30),
                      animation: true,
                      animateFromLastPercent: true,
                      backgroundColor: Theme.of(context).colorScheme.onTertiary,
                      lineHeight: 20.0,
                      percent: _currentVerse  / _totalVerses,
                      progressColor: Theme.of(context).colorScheme.tertiary),
                ),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ReadQuranCard(
                      currentChapter: _currentChapter,
                      currentVerse: _currentVerse,
                      totalVerses: _totalVerses,
                      fontSize: SettingsDB().get("fontSize", 30.0),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 60,
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 70,
              color: Theme.of(context).colorScheme.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Distribute buttons horizontally
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle left button action
                      _vibrate();
                      if (_currentVerse != 1) {
                        _decrement();
                        _updateDB();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 30,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _vibrate();
                      _scrollUp();
                      if (_currentVerse != _totalVerses) {
                        _increment();
                        _updateDB();
                      } else {
                        // New Chapter
                        _delete();
                        _reset();
                        if (_currentChapter != 114) {
                          _incrementChapter();
                        } else {
                          _resetChapter();
                        }
                        _getTotalVerses();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _increment() {
    setState(() {
      _currentVerse++;
    });
  }

  void _decrement() {
    setState(() {
      _currentVerse--;
    });
  }

  void _reset() {
    setState(() {
      _currentVerse = 1;
    });
  }

  void _getTotalVerses() {
    setState(() {
      _totalVerses = quran.getVerseCount(_currentChapter);
    });
  }

  void _incrementChapter() {
    setState(() {
      _currentChapter++;
    });
  }

  void _resetChapter() {
    setState(() {
      _currentChapter = 1;
    });
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() != null) {
      Vibration.vibrate(duration: 10);
    }
  }

  void _scrollUp() {
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  void _updateDB() {
    _bookmarks.put(_currentChapter, _currentVerse);
  }

  void _delete() {
    _bookmarks.delete(_currentChapter);
  }
}
