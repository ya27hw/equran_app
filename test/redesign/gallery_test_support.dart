import 'package:equran/debug/redesign_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const captureKey = Key('golden-capture');

Future<void> loadGalleryFonts() async {
  for (final entry in {
    'Newsreader': [
      'assets/media/fonts/newsreader/Newsreader.ttf',
      'assets/media/fonts/newsreader/Newsreader-Italic.ttf',
    ],
    'Inter': ['assets/media/fonts/inter/Inter.ttf'],
    'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}

Future<void> pumpGalleryFixture(
  WidgetTester tester, {
  required WidgetBuilder builder,
  GalleryPalette palette = GalleryPalette.emeraldDark,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  double viewportHeight = 300,
  bool samplePadding = true,
}) async {
  await tester.binding.setSurfaceSize(Size(390, viewportHeight));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: galleryTheme(palette),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(390, viewportHeight),
          devicePixelRatio: 1,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: captureKey,
                child: ColoredBox(
                  color: palette.colors.background,
                  child: Padding(
                    padding: samplePadding
                        ? const EdgeInsets.all(20)
                        : EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      child: Builder(builder: builder),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Resolve local illustration decoding outside the test clock.
  await tester.runAsync(() async {
    final context = tester.element(find.byKey(captureKey));
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}
