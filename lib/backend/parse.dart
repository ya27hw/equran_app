import "transilteration.dart";

String getTransliteration(int chapter, int verse) {
  try {
    final String t =
        transliteration[chapter - 1]["verses"][verse - 1]["transliteration"];
    return t;
  } catch (e) {
    print("Could not find transliteration");
    return "N/A";
  }
}
