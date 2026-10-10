import 'dart:typed_data';

import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home/downloadable_resources_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart' show ReaderSheetFrame;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Two resources of different types and sizes, so grouping, search, the status
/// filter and the size sort all have something to act on. Nothing is installed
/// in these tests, so every row offers a download.
ResourceManifest _manifest() {
  return ResourceManifest.fromJson(<String, Object?>{
    'version': 1,
    'resources': <Map<String, Object?>>[
      <String, Object?>{
        'id': 'translation-alpha',
        'type': 'translation',
        'name': 'Alpha translation',
        'language': 'en',
        'version': '1.0.0',
        'url': 'https://example.invalid/alpha.json',
        'sizeBytes': 2000000,
      },
      <String, Object?>{
        'id': 'tafsir-beta',
        'type': 'tafsir',
        'name': 'Beta tafsir',
        'language': 'ar',
        'version': '1.0.0',
        'url': 'https://example.invalid/beta.json',
        'sizeBytes': 9000000,
      },
    ],
  });
}

void main() {
  final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
  });
  tearDownAll(Hive.close);

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 900 * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(EquranColors.dark),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: DownloadableResourcesPage(
          manifest: Future<ResourceManifest>.value(_manifest()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the filter sheet, taps each label in turn, then taps Apply.
  Future<void> applyFilters(WidgetTester tester, List<String> labels) async {
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    for (final String label in labels) {
      // The options are a lazy list, so a row lower in the sheet is built only
      // once the list has scrolled to it.
      final Finder target = find.text(label);
      if (target.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          target,
          120,
          scrollable: find
              .descendant(
                of: find.byType(ReaderSheetFrame),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(en.apply));
    await tester.pumpAndSettle();
  }

  testWidgets('search narrows the list to matching resources', (tester) async {
    await pump(tester);
    expect(find.text('Alpha translation'), findsOneWidget);
    expect(find.text('Beta tafsir'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pumpAndSettle();

    expect(find.text('Beta tafsir'), findsOneWidget);
    expect(find.text('Alpha translation'), findsNothing);
  });

  testWidgets('the status filter shows only installed resources', (
    tester,
  ) async {
    await pump(tester);

    await applyFilters(tester, <String>[en.installed]);

    expect(find.text(en.resourcesNoMatches), findsOneWidget);
    expect(find.text('Alpha translation'), findsNothing);
    expect(find.text('Beta tafsir'), findsNothing);
  });

  testWidgets('size sort with no grouping lists the largest first', (
    tester,
  ) async {
    await pump(tester);

    await applyFilters(tester, <String>[
      en.downloadsSortSizeDesc,
      en.resourceViewNone,
    ]);

    final double tafsirTop = tester.getTopLeft(find.text('Beta tafsir')).dy;
    final double translationTop = tester
        .getTopLeft(find.text('Alpha translation'))
        .dy;
    expect(tafsirTop, lessThan(translationTop));
  });
}
