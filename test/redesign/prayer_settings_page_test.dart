import 'package:equran/backend/settings_db.dart';
import 'package:equran/debug/prayer_preview_main.dart' show seedPrayerPreview;
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_dialogs.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_settings_page.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// Prayer settings on the redesign system. The page is pumped for real; the
/// notification permission channel is answered by a fake, so reminders are not
/// scheduled for real (the platform plugin is not available in tests). There is
/// no design preview; the rows follow Settings, the banners and dialogs follow
/// the reader sheet chrome. In debug builds the "1 minute exact test" row shows
/// whenever reminders are on, so it is in these goldens too.
void main() {
  const MethodChannel channel = MethodChannel(
    'com.app.equran/notification_permissions',
  );
  String permission = 'granted';

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
  setUp(() async {
    permission = 'granted';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          return switch (call.method) {
            'checkNotificationPermission' ||
            'requestNotificationPermission' => permission,
            'checkExactAlarmPermission' => permission,
            _ => null,
          };
        });
    await seedPrayerPreview();
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  tearDownAll(Hive.close);

  Future<void> saveSettings(PrayerTimeSettings settings) =>
      PrayerSettingsStore().saveSettings(settings);

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double? height,
  }) async {
    const double dpr = 1.5;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = Size(390 * dpr, (height ?? 6000) * dpr);
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
        home: const Scaffold(body: PrayerTimesSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    if (height == null) {
      final double bottom = tester
          .getBottomLeft(find.byType(ReaderNotice).last)
          .dy;
      tester.view.physicalSize = Size(390 * dpr, (bottom + 40) * dpr);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) => AppLocalizations.of(
    tester.element(find.byType(PrayerTimesSettingsPage)),
  )!;

  PrayerTimeSettings rich() => PrayerTimeSettings.fromJson(null).copyWith(
    method: PrayerCalculationMethod.custom,
    reminderSettings: const PrayerReminderSettings(
      remindersEnabled: true,
      ishaEnabled: false,
      reminderOffsetMinutes: 10,
    ),
  );

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
    testWidgets('Prayer settings golden $name', (tester) async {
      await saveSettings(rich());
      await pump(tester, colors: colors, scale: scale, locale: locale);
      expect(find.byType(ListTile), findsNWidgets(5));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/prayer_settings/$name.png'),
      );
    });
  }

  testWidgets('permission denied shows the warning banners', (tester) async {
    permission = 'denied';
    await saveSettings(rich());
    await pump(tester);
    expect(find.byType(ReaderNotice), findsWidgets);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/prayer_settings/permission-denied.png'),
    );
  });

  final List<(String, EquranColors, double, Locale)> dialogVariants =
      <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ];
  final Map<String, String Function(AppLocalizations)> dialogs =
      <String, String Function(AppLocalizations)>{
        'method': (l) => l.calculationMethod,
        'offset': (l) => 'Fajr',
        'angle': (l) => l.fajrAngle,
        'sunrise-minutes': (l) => l.sunriseProhibitedTime,
      };
  for (final MapEntry<String, String Function(AppLocalizations)> dialog
      in dialogs.entries) {
    for (final (String name, EquranColors colors, double scale, Locale locale)
        in dialogVariants) {
      testWidgets('Prayer settings ${dialog.key} dialog golden $name', (
        tester,
      ) async {
        await saveSettings(rich());
        await pump(
          tester,
          colors: colors,
          scale: scale,
          locale: locale,
          height: 6000,
        );
        final Finder row = find.text(dialog.value(l10n(tester)));
        await tester.tap(dialog.key == 'offset' ? row.last : row.first);
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        tester.view.physicalSize = const Size(390 * 1.5, 844 * 1.5);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/prayer_settings/dialog-${dialog.key}-$name.png',
          ),
        );
      });
    }
  }

  testWidgets('selecting a calculation method saves it', (tester) async {
    await saveSettings(rich());
    await pump(tester, height: 6000);
    await tester.tap(find.text(l10n(tester).calculationMethod).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(PrayerCalculationMethod.values[2].label));
    await tester.pumpAndSettle();
    expect(
      PrayerSettingsStore().getSettings().method,
      PrayerCalculationMethod.values[2],
    );
  });

  testWidgets('the offset dialog keeps its sign and range rules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: savedPreviewTheme(EquranColors.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showReaderDialog<OptionalNumberResult<int>?>(
                context: context,
                builder: (_) => const PrayerSteppedIntDialog(
                  title: 'Offset',
                  currentValue: 5,
                  min: -120,
                  max: 120,
                  helperText: 'helper',
                  allowNullValue: false,
                ),
              ).then((r) => result = r?.value),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    expect(find.text('−'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '300');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerSteppedIntDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '30');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result, -30);
  });
}

int? result;
