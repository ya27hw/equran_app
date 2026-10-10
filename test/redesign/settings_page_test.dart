import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home/settings.dart';
import 'package:equran/home/settings_dialogs.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/redesign/settings_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Settings page with every group open, and its dialogs. `SettingsPage`
/// is pumped for real (it only needs the settings box); the resource manifest
/// has no network in tests, so the downloads group shows its unavailable
/// state. There is no design preview: the rows and dialogs follow the reader
/// sheet chrome and the finished More page.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await Hive.openBox(SettingsDB().boxName, bytes: Uint8List(0));
    await SettingsDB().initBox();
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });
  tearDownAll(Hive.close);

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 900,
    double dpr = 2,
    bool expandAll = false,
  }) async {
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = Size(390 * dpr, height * dpr);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();
    if (expandAll) {
      // Open the groups that start closed, then shrink the view to the
      // content so the golden shows the whole page.
      tester.view.physicalSize = Size(390 * dpr, 6000 * dpr);
      await tester.pumpAndSettle();
      // General and Reading start open; open Appearance, Audio and Data.
      for (final int i in <int>[1, 3, 4]) {
        await tester.tap(
          find
              .descendant(
                of: find.byType(ExpansionTile).at(i),
                matching: find.byType(ListTile),
              )
              .first,
        );
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      final double bottom = tester
          .getBottomLeft(find.byType(SettingsGroupCard).last)
          .dy;
      tester.view.physicalSize = Size(390 * dpr, (bottom + 40) * dpr);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(SettingsPage)))!;

  testWidgets('shows the serif title and grouped cards', (tester) async {
    await pump(tester);
    final AppLocalizations l = l10n(tester);
    expect(find.text(l.settings), findsOneWidget);
    expect(find.text(l.general), findsOneWidget);
    expect(find.text(l.appearance), findsWidgets);
  });

  testWidgets('every setting row is on the redesign rows, not list tiles', (
    tester,
  ) async {
    await pump(tester, expandAll: true, height: 900);
    // The only list tiles left are the group headers.
    expect(
      find.byType(ListTile).evaluate().length,
      find.byType(ExpansionTile).evaluate().length,
    );
  });

  final List<(String, EquranColors, double, Locale)> variants =
      <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
        ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
        ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ];
  for (final (String name, EquranColors colors, double scale, Locale locale)
      in variants) {
    testWidgets('Settings golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        expandAll: true,
        dpr: 1.5,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/settings/$name.png'),
      );
    });
  }

  // Dialogs are opened from the real page, then captured.
  final List<(String, EquranColors, double, Locale)> dialogVariants =
      <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ];

  Future<void> openDialogByText(
    WidgetTester tester,
    String Function(AppLocalizations) label,
  ) async {
    final Finder row = find.text(label(l10n(tester)));
    await tester.ensureVisible(row.first);
    await tester.tap(row.first);
    await tester.pumpAndSettle();
  }

  final Map<String, String Function(AppLocalizations)> dialogs =
      <String, String Function(AppLocalizations)>{
        'language': (l) => l.language,
        'daily-goal': (l) => l.dailyQuranGoal,
        'clear-history': (l) => l.clearReadingHistory,
        'restore': (l) => l.restoreData,
      };
  for (final MapEntry<String, String Function(AppLocalizations)> dialog
      in dialogs.entries) {
    for (final (String name, EquranColors colors, double scale, Locale locale)
        in dialogVariants) {
      testWidgets('Settings ${dialog.key} dialog golden $name', (tester) async {
        await pump(tester, colors: colors, scale: scale, locale: locale);
        if (dialog.key.startsWith('clear') || dialog.key == 'restore') {
          // The Data group starts closed and sits at the bottom.
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -4000),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find
                .descendant(
                  of: find.byType(ExpansionTile).last,
                  matching: find.byType(ListTile),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -4000),
          );
          await tester.pumpAndSettle();
        }
        await openDialogByText(tester, dialog.value);
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/settings/dialog-${dialog.key}-$name.png'),
        );
      });
    }
  }

  testWidgets('the daily goal dialog keeps its 1 to 1000 validation', (
    tester,
  ) async {
    await pump(tester);
    await openDialogByText(tester, (l) => l.dailyQuranGoal);
    expect(find.byType(DailyGoalDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.widgetWithText(FilledButton, l10n(tester).save));
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).enterGoalRange), findsOneWidget);
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.widgetWithText(FilledButton, l10n(tester).save));
    await tester.pumpAndSettle();
    expect(find.byType(DailyGoalDialog), findsNothing);
    expect(SettingsDB().get('dailyQuranGoalAyahs'), 25);
  });

  testWidgets('clear data awaits the action before the dialog closes', (
    tester,
  ) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: savedPreviewTheme(EquranColors.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ClearDataDialog(
          title: 'Clear',
          message: 'Sure?',
          onConfirm: () async => log.add('cleared'),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(log, <String>['cleared']);
  });
}
