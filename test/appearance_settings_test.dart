import 'dart:typed_data';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/home/appearance_settings_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_theme.dart';
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

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      AdaptiveTheme(
        light: AppTheme.buildLightTheme(Colors.cyan),
        dark: AppTheme.buildDarkTheme(
          Colors.cyan,
          pureBlackBackground: SettingsDB().pureBlackBackground,
        ),
        initial: AdaptiveThemeMode.dark,
        builder: (theme, darkTheme) => MaterialApp(
          theme: theme,
          darkTheme: darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AppearanceSettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  EquranColors colors(WidgetTester tester) =>
      tester.element(find.byType(AppearanceSettingsPage)).equranColors;

  testWidgets(
    'toggle follows every dark palette and leaves light mode intact',
    (tester) async {
      await pump(tester);
      expect(find.text('AMOLED'), findsNothing);
      await tester.tap(find.byKey(const Key('pure-black-background-toggle')));
      await tester.pumpAndSettle();
      expect(SettingsDB().pureBlackBackground, isTrue);
      expect(colors(tester).background, Colors.black);

      await tester.ensureVisible(find.text('Sapphire Blue'));
      await tester.tap(find.text('Sapphire Blue'));
      await tester.pumpAndSettle();
      expect(colors(tester).primary, EquranColors.fancyBlueDark.primary);
      expect(colors(tester).background, Colors.black);

      await tester.ensureVisible(find.text('Light'));
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(colors(tester).background, EquranColors.fancyBlueLight.background);
      expect(SettingsDB().pureBlackBackground, isTrue);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(colors(tester).background, Colors.black);

      await tester.tap(find.byKey(const Key('pure-black-background-toggle')));
      await tester.pumpAndSettle();
      expect(colors(tester).background, EquranColors.fancyBlueDark.background);
      expect(SettingsDB().pureBlackBackground, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'former AMOLED selection loads as a toggle that can be disabled',
    (tester) async {
      await SettingsDB().put('themeScheme', 'black');
      await pump(tester);
      expect(colors(tester).background, Colors.black);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('pure-black-background-toggle')),
            )
            .value,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('pure-black-background-toggle')));
      await tester.pumpAndSettle();
      expect(SettingsDB().get('themeScheme'), AppTheme.defaultScheme);
      expect(SettingsDB().pureBlackBackground, isFalse);
      expect(colors(tester).background, EquranColors.dark.background);
      expect(tester.takeException(), isNull);
    },
  );
}
