import 'package:emushaf/backend/library.dart' show SettingsDB;
import 'package:emushaf/widgets/library.dart' show ReadQuranCard;
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

class FontSlider extends StatefulWidget {
  const FontSlider({super.key});

  @override
  State<FontSlider> createState() => _FontSliderState();
}

class _FontSliderState extends State<FontSlider> {
  @override
  Widget build(BuildContext context) {
    double fontSize = SettingsDB().get("fontSize", defaultValue: 30.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: const Center(child: Text("Font Size")),
              subtitle: Slider(
                  value: fontSize,
                  min: 30.0,
                  max: 65.0,
                  label: (fontSize / 2).round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      fontSize = value;
                      SettingsDB().put("fontSize", value);
                    });
                  }),
            ),
            ReadQuranCard(
                currentChapter: 1,
                currentVerse: 1,
                totalVerses: 7,
                fontSize: fontSize,
                juzNumber: 1,
                url: "",
                translation: quran.getVerseTranslation(1, 1),
                verse: quran.getVerse(1, 1))
          ],
        ),
      ),
    );
  }
}
