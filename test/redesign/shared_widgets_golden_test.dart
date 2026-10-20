import 'package:equran/debug/redesign_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'gallery_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadGalleryFonts);

  for (final palette in GalleryPalette.values) {
    for (final name in gallerySampleNames) {
      testWidgets('$name · ${palette.label}', (tester) async {
        await pumpGalleryFixture(
          tester,
          palette: palette,
          samplePadding: name != 'floating-dock',
          builder: (context) => gallerySample(context, name),
        );
        await expectLater(
          find.byKey(captureKey),
          matchesGoldenFile('goldens/${palette.label}/$name.png'),
        );
      });
    }
    testWidgets('complete gallery · ${palette.label}', (tester) async {
      await pumpGalleryFixture(
        tester,
        palette: palette,
        viewportHeight: 4000,
        samplePadding: false,
        builder: (_) => const RedesignWidgetGallery(),
      );
      await expectLater(
        find.byKey(captureKey),
        matchesGoldenFile('goldens/${palette.label}/gallery.png'),
      );
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('complete gallery · text 1.3 · ${direction.name}', (
      tester,
    ) async {
      await pumpGalleryFixture(
        tester,
        textScale: 1.3,
        direction: direction,
        viewportHeight: 4500,
        samplePadding: false,
        builder: (_) => const RedesignWidgetGallery(),
      );
      await expectLater(
        find.byKey(captureKey),
        matchesGoldenFile(
          'goldens/emerald-dark/gallery-text-1.3-${direction.name}.png',
        ),
      );
    });
  }
}
