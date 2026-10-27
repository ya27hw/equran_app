import 'dart:typed_data';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/widgets/font_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'redesign/gallery_test_support.dart' show loadGalleryFonts;

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
    await loadGalleryFonts();
  });

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await SettingsDB().clear();
  });

  tearDownAll(Hive.close);

  Future<void> pumpSlider(
    WidgetTester tester, {
    bool showTranslationControls = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      AdaptiveTheme(
        light: AppTheme.buildLightTheme(Colors.cyan),
        dark: AppTheme.buildDarkTheme(Colors.cyan),
        initial: AdaptiveThemeMode.dark,
        builder: (theme, darkTheme) => MaterialApp(
          theme: theme,
          darkTheme: darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FontSlider(
                showTranslationControls: showTranslationControls,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('default translation font size is 16', () {
    expect(kDefaultTranslationFontSize, equals(16.0));
    expect(kMinTranslationFontSize, equals(10.0));
    expect(kMaxTranslationFontSize, equals(30.0));
  });

  testWidgets(
    'FontSlider shows translation controls, has default 16, and updates value and preview',
    (tester) async {
      await pumpSlider(tester, showTranslationControls: true);

      expect(find.text('Translation text size'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));

      final Slider translationSlider = tester.widget<Slider>(
        find.byType(Slider).at(1),
      );
      expect(translationSlider.min, equals(10.0));
      expect(translationSlider.max, equals(30.0));
      expect(translationSlider.value, equals(16.0));
      expect(find.text('16'), findsOneWidget);

      // Verify initial preview translation text font size is 16
      final Text previewTranslation = tester.widget<Text>(
        find.descendant(
          of: find.byType(FontSlider),
          matching: find.textContaining('In the name of Allah'),
        ),
      );
      expect(previewTranslation.style?.fontSize, equals(16.0));

      // Drag the translation slider to the right
      await tester.drag(find.byType(Slider).at(1), const Offset(80, 0));
      await tester.pumpAndSettle();

      final double updated = (SettingsDB().get('fontSizeTranslation') as num)
          .toDouble();
      expect(updated, greaterThan(16.0));

      final Slider updatedSlider = tester.widget<Slider>(
        find.byType(Slider).at(1),
      );
      expect(updatedSlider.value, equals(updated));

      // Verify preview translation text font size updated to the new value
      final Text updatedPreviewTranslation = tester.widget<Text>(
        find.descendant(
          of: find.byType(FontSlider),
          matching: find.textContaining('In the name of Allah'),
        ),
      );
      expect(updatedPreviewTranslation.style?.fontSize, equals(updated));
    },
  );

  testWidgets('FontSlider hides translation controls when disabled', (
    tester,
  ) async {
    await pumpSlider(tester, showTranslationControls: false);

    expect(find.text('Translation text size'), findsNothing);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.textContaining('In the name of Allah'), findsNothing);
  });

  testWidgets(
    'FontSlider toggles font family, bold, and high contrast accessibility options',
    (tester) async {
      await pumpSlider(tester, showTranslationControls: true);

      // Verify accessibility section is visible
      expect(find.text('ACCESSIBILITY & STYLE'), findsOneWidget);
      expect(find.text('Serif'), findsOneWidget);
      expect(find.text('Sans'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);
      expect(find.text('High Contrast'), findsOneWidget);

      // Default font family is Newsreader (italic)
      expect(SettingsDB().translationFontFamily, equals('Newsreader'));
      expect(SettingsDB().translationFontBold, isFalse);
      expect(SettingsDB().translationHighContrast, isFalse);

      Text preview = tester.widget<Text>(
        find.descendant(
          of: find.byType(FontSlider),
          matching: find.textContaining('In the name of Allah'),
        ),
      );
      expect(preview.style?.fontFamily, equals('Newsreader'));
      expect(preview.style?.fontWeight, equals(FontWeight.w400));
      expect(preview.style?.fontStyle, equals(FontStyle.italic));

      // Switch to Sans (Inter)
      await tester.tap(find.text('Sans'));
      await tester.pumpAndSettle();

      expect(SettingsDB().translationFontFamily, equals('Inter'));
      preview = tester.widget<Text>(
        find.descendant(
          of: find.byType(FontSlider),
          matching: find.textContaining('In the name of Allah'),
        ),
      );
      expect(preview.style?.fontFamily, equals('Inter'));
      expect(preview.style?.fontStyle, equals(FontStyle.normal));

      // Toggle Bold
      await tester.tap(find.text('Bold'));
      await tester.pumpAndSettle();

      expect(SettingsDB().translationFontBold, isTrue);
      preview = tester.widget<Text>(
        find.descendant(
          of: find.byType(FontSlider),
          matching: find.textContaining('In the name of Allah'),
        ),
      );
      expect(preview.style?.fontWeight, equals(FontWeight.w700));

      // Toggle High Contrast
      await tester.tap(find.text('High Contrast'));
      await tester.pumpAndSettle();

      expect(SettingsDB().translationHighContrast, isTrue);
      preview = tester.widget<Text>(
        find.descendant(
          of: find.byType(FontSlider),
          matching: find.textContaining('In the name of Allah'),
        ),
      );
      expect(preview.style?.color, equals(Colors.white));
    },
  );
}
