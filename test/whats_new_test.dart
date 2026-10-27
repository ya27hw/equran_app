import 'dart:typed_data';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/backend/whats_new_service.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/widgets/whats_new_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  group('WhatsNewService', () {
    test('contains latest release with friendly highlights', () {
      final latest = WhatsNewService.instance.latestRelease;
      expect(latest.version, isNotEmpty);
      expect(latest.title, isNotEmpty);
      expect(latest.highlights, isNotEmpty);

      for (final highlight in latest.highlights) {
        expect(highlight.title, isNotEmpty);
        expect(highlight.description, isNotEmpty);
      }
    });

    test('fresh install quietly records current version and returns false', () {
      expect(SettingsDB().get('lastSeenAppVersion'), isNull);

      final version = WhatsNewService.instance.latestRelease.version;
      final shouldShow = WhatsNewService.instance.shouldShowWhatsNew(version);
      expect(shouldShow, isFalse);
      expect(SettingsDB().get('lastSeenAppVersion'), equals(version));
    });

    test('same version does not show popup', () {
      final version = WhatsNewService.instance.latestRelease.version;
      WhatsNewService.instance.markWhatsNewSeen(version);

      final shouldShow = WhatsNewService.instance.shouldShowWhatsNew(version);
      expect(shouldShow, isFalse);
    });

    test('upgraded version returns true to announce new features', () {
      WhatsNewService.instance.markWhatsNewSeen('4.0.0-beta.3');

      final version = WhatsNewService.instance.latestRelease.version;
      final shouldShow = WhatsNewService.instance.shouldShowWhatsNew(version);
      expect(shouldShow, isTrue);

      // Once marked seen, subsequent check returns false
      WhatsNewService.instance.markWhatsNewSeen(version);
      expect(WhatsNewService.instance.shouldShowWhatsNew(version), isFalse);
    });
  });

  group('WhatsNewDialog Widget', () {
    testWidgets('renders highlights and dismisses on Continue', (tester) async {
      bool dismissed = false;
      final latest = WhatsNewService.instance.latestRelease;

      await tester.pumpWidget(
        AdaptiveTheme(
          light: AppTheme.buildLightTheme(Colors.teal),
          dark: AppTheme.buildDarkTheme(Colors.teal),
          initial: AdaptiveThemeMode.dark,
          builder: (theme, darkTheme) => MaterialApp(
            theme: theme,
            darkTheme: darkTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => WhatsNewDialog.show(
                      context,
                      onDismiss: () => dismissed = true,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.byType(WhatsNewDialog), findsOneWidget);
      expect(find.text('What’s New in eQuran'), findsOneWidget);
      expect(find.text('v${latest.version}'), findsOneWidget);

      // Verify friendly highlights are displayed
      for (final highlight in latest.highlights) {
        expect(find.text(highlight.title), findsOneWidget);
      }
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and callback fired
      expect(find.byType(WhatsNewDialog), findsNothing);
      expect(dismissed, isTrue);
      expect(SettingsDB().get('lastSeenAppVersion'), equals(latest.version));
    });
  });
}
