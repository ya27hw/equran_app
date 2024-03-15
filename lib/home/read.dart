import 'package:emushaf/backend/bookmark_db.dart';
import 'package:emushaf/backend/library.dart' show SettingsDB;
import 'package:emushaf/widgets/library.dart' show ReadQuranCard;
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:quran/quran.dart' as quran;
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:vibration/vibration.dart';

class ReadPage extends StatefulWidget {
  final int chapter;
  final bool juzMode;
  final int? startVerse;

  const ReadPage(
      {super.key,
      required this.chapter,
      this.startVerse,
      this.juzMode = false});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  late int _currentVerse;
  late int _currentChapter;
  late ScrollController _scrollController;
  late int _totalVerses;
  late FocusNode _buttonFocusNode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentChapter = widget.chapter;
    _currentVerse = widget.startVerse is int ? widget.startVerse! : 1;
    _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
    _getTotalVerses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    int _picker = _currentVerse;

    // Define margin values for different screen sizes
    double marginValue;
    if (screenSize.width > 1200) {
      marginValue = 90.0; // Large screen
    } else if (screenSize.width > 700) {
      marginValue = 40.0; // Medium screen
    } else {
      marginValue = 8.0; // Small screen
    }
    return SimpleGestureDetector(
      onHorizontalSwipe: (SwipeDirection direction) {
        if (direction == SwipeDirection.left) {
          _increase();
        } else if (direction == SwipeDirection.right) {
          _decrease();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(quran.getSurahName(_currentChapter)),
          centerTitle: true,
          actions: <Widget>[
            MenuAnchor(
              childFocusNode: _buttonFocusNode,
              menuChildren: <Widget>[
                MenuItemButton(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 120, bottom: 10, top: 10, left: 5),
                    child: Text(
                      "Reset",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                            icon: const Icon(Icons.warning_amber),
                            title: const Text(
                              "Reset",
                            ),
                            content: const Text(
                              "Would you like to start over?",
                            ),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("CANCEL")),
                              TextButton(
                                child: const Text("OK"),
                                onPressed: () {
                                  _reset();
                                  _delete();
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          )),
                ),
                MenuItemButton(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: 10, top: 10, left: 5),
                      child: Text(
                        "Jump to Verse",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    onPressed: () => showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text("Select Verse"),
                            actions: [
                              TextButton(
                                  child: const Text("CONFIRM"),
                                  onPressed: () {
                                    _setVerse(_picker);
                                    _updateDB();
                                    Navigator.of(context).pop();
                                  }),
                              TextButton(
                                  child: const Text("CANCEL"),
                                  onPressed: () => Navigator.of(context).pop())
                            ],
                            content: StatefulBuilder(
                              builder: (context, SBsetState) => NumberPicker(
                                  minValue: 1,
                                  maxValue: _totalVerses,
                                  value: _picker,
                                  onChanged: (int value) {
                                    setState(() => _picker = value);
                                    SBsetState(() => _picker = value);
                                  }),
                            ),
                          ),
                        )),
              ],
              child: const Text('Background Color'),
              builder: (BuildContext context, MenuController controller,
                  Widget? child) {
                return TextButton(
                    focusNode: _buttonFocusNode,
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: const Icon(Icons.more_vert));
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(
                        left: marginValue, right: marginValue, top: 20),
                    child: LinearPercentIndicator(
                        barRadius: const Radius.circular(30),
                        animation: true,
                        animateFromLastPercent: true,
                        backgroundColor:
                            Theme.of(context).colorScheme.onTertiary,
                        lineHeight: 20.0,
                        percent: _currentVerse / _totalVerses,
                        progressColor: Theme.of(context).colorScheme.tertiary),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ReadQuranCard(
                      currentChapter: _currentChapter,
                      currentVerse: _currentVerse,
                      totalVerses: _totalVerses,
                      juzNumber:
                          quran.getJuzNumber(_currentChapter, _currentVerse),
                      basmala: _currentChapter != 1 &&
                              _currentVerse == 1 &&
                              _currentChapter != 9
                          ? quran.basmala
                          : null,
                      verse: quran.getVerse(_currentChapter, _currentVerse),
                      translation: quran.getVerseTranslation(
                          _currentChapter, _currentVerse),
                      fontSize:
                          SettingsDB().get("fontSize", defaultValue: 30.0),
                    ),
                  ),
                  const SizedBox(
                    height: 120,
                  )
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 80,
                padding: const EdgeInsets.only(right: 12, left: 12),
                color: Theme.of(context).colorScheme.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Distribute buttons horizontally
                  children: [
                    ElevatedButton(
                      onPressed: () => _decrease(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 18),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 30,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _increase(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 18),
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
      ),
    );
  }

  void _increase() {
    _vibrate();
    _scrollUp();
    if (_currentVerse != _totalVerses) {
      _incrementVerse();
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
  }

  void _decrease() {
    _vibrate();
    _scrollUp();
    if (_currentVerse != 1) {
      _decrementVerse();
      _updateDB();
    }
  }

  void _incrementVerse() {
    setState(() {
      _currentVerse++;
    });
  }

  void _setVerse(int value) {
    setState(() {
      _currentVerse = value;
    });
  }

  void _decrementVerse() {
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
    if (SettingsDB().get("vibration", defaultValue: true) == true) {
      if (await Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 10);
      }
    }
  }

  void _scrollUp() {
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  void _updateDB() {
    // BookmarkDB().put("lastRead", "$_currentChapter-$_currentVerse");
    BookmarkDB().updateLastRead("$_currentChapter-$_currentVerse");
  }

  void _delete() {
    BookmarkDB().deleteLastRead();
  }
}
