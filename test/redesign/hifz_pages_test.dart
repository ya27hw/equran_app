import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/hifz/hifz.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart' as quran;
import 'gallery_test_support.dart' show loadGalleryFonts;

/// Hifz session and completion screens on the redesign system. There is no
/// design preview for them; the look follows the finished redesign pages. The
/// real pages are pumped against in-memory Hive boxes, so queue building,
/// phases and ratings run exactly as in the app. Audio is never started.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The page creates an audio player for the listen phase; no platform
    // implementation exists in tests and nothing is ever played.
    for (final channel in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel(channel),
            (call) async => null,
          );
    }
    registerCompanionStorageAdapters();
    await Hive.openBox<HifzEntry>(HifzDB.entriesBoxName, bytes: Uint8List(0));
    await Hive.openBox<HifzReviewLog>(HifzDB.logsBoxName, bytes: Uint8List(0));
    await Hive.openBox<HifzUnit>(HifzDB.unitsBoxName, bytes: Uint8List(0));
    GoogleFonts.config.allowRuntimeFetching = false;
    final settings = SettingsDB();
    await Hive.openBox(settings.boxName, bytes: Uint8List(0));
    await settings.initBox();
    await quran.initializeQuran();
    await loadGalleryFonts();
    for (final (family, asset) in [
      (
        'NotoNaskhArabic',
        'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
      ),
      ('UthmanicHafs', 'assets/media/fonts/UthmanicHafs_V22.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });
  tearDownAll(() async {
    await Hive.close();
  });

  HifzUnit unit(String id, int surah) => HifzUnit()
    ..id = id
    ..unitType = 'surah'
    ..unitNumber = surah
    ..frontierSurah = surah
    ..frontierAyah = 6
    ..startedAt = DateTime(2026, 9, 1)
    ..isComplete = false;

  HifzEntry entry(
    int surah,
    int ayah, {
    required String unitId,
    required String status,
    required int index,
    DateTime? due,
    DateTime? learned,
  }) => HifzEntry()
    ..surah = surah
    ..ayah = ayah
    ..status = status
    ..track = status == 'learning' ? 'sabaq' : 'sabqi'
    ..dueDate = due ?? DateTime.now().subtract(const Duration(days: 1))
    ..unitId = unitId
    ..sequenceIndex = index
    ..firstLearnedAt = learned;

  /// 'revise' has one revision card (with a cue ayah before it); 'fresh' has
  /// one new ayah; 'none' has nothing due.
  Future<HifzUnit> seed(String kind) async {
    await Hive.box<HifzEntry>(HifzDB.entriesBoxName).clear();
    await Hive.box<HifzUnit>(HifzDB.unitsBoxName).clear();
    await Hive.box<HifzReviewLog>(HifzDB.logsBoxName).clear();
    final u = switch (kind) {
      'revise' => unit('surah_94', 94),
      'fresh' => unit('surah_1', 1),
      _ => unit('surah_112', 112),
    };
    await Hive.box<HifzUnit>(HifzDB.unitsBoxName).put(u.id, u);
    if (kind == 'revise') {
      await HifzDB.saveEntry(
        entry(
          94,
          4,
          unitId: u.id,
          status: 'mastered',
          index: 3,
          due: DateTime.now().add(const Duration(days: 30)),
          learned: DateTime.now().subtract(const Duration(days: 40)),
        ),
      );
      await HifzDB.saveEntry(
        entry(
          94,
          5,
          unitId: u.id,
          status: 'review',
          index: 4,
          learned: DateTime.now().subtract(const Duration(days: 2)),
        ),
      );
    } else if (kind == 'fresh') {
      await HifzDB.saveEntry(
        entry(1, 2, unitId: u.id, status: 'learning', index: 1),
      );
    }
    return u;
  }

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 844,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(390 * 2, height * 2);
    addTearDown(tester.view.reset);
    // The audio player's event streams have no platform side in tests.
    final report = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is MissingPluginException &&
          details.exception.toString().contains('xyz.luan/audioplayers')) {
        return;
      }
      report?.call(details);
    };
    addTearDown(() => FlutterError.onError = report);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: KeyedSubtree(key: UniqueKey(), child: home),
      ),
    );
    // The page loads its first ayah asynchronously.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Material).first))!;

  testWidgets('a new ayah starts in listen, then recall, then rating', (
    tester,
  ) async {
    final u = await seed('fresh');
    await pumpApp(tester, HifzSessionPage(unit: u));
    final l = l10n(tester);
    expect(find.text(l.hifzImReady), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text(l.hifzTrackNewLabel), findsOneWidget);
    await tester.tap(find.text(l.hifzImReady));
    await tester.pumpAndSettle();
    expect(find.text(l.hifzRevealAll), findsOneWidget);
    await tester.tap(find.text(l.hifzRevealAll));
    await tester.pumpAndSettle();
    expect(find.text(l.hifzRatingTryAgain), findsOneWidget);
    expect(find.text(l.hifzRatingGotIt), findsOneWidget);
  });

  testWidgets('a revision card shows pass and fail with intervals and rates', (
    tester,
  ) async {
    final u = await seed('revise');
    await pumpApp(tester, HifzSessionPage(unit: u));
    final l = l10n(tester);
    expect(find.text(l.hifzRevealAll), findsOneWidget);
    expect(find.text(l.hifzTrackRevisionLabel), findsOneWidget);
    await tester.tap(find.text(l.hifzRevealAll));
    await tester.pumpAndSettle();
    expect(find.text('Fail'), findsOneWidget);
    expect(find.text('Pass'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Pass'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    // The scheduler saved the rating and the page moved to the summary.
    expect(find.text(l.hifzCompleteTitle), findsOneWidget);
    expect(find.text('Pass'), findsOneWidget);
    expect(
      HifzDB.getEntry(94, 5)!.dueDate.isAfter(DateTime.now()),
      isTrue,
      reason: 'a passed card is rescheduled by the unchanged scheduler',
    );
  });

  testWidgets('the close button asks before leaving and keeps the page', (
    tester,
  ) async {
    final u = await seed('fresh');
    await pumpApp(tester, HifzSessionPage(unit: u));
    final l = l10n(tester);
    await tester.tap(find.byTooltip(l.close));
    await tester.pumpAndSettle();
    expect(find.text(l.hifzExitSessionTitle), findsOneWidget);
    await tester.tap(find.text(l.hifzExitCancel));
    await tester.pumpAndSettle();
    expect(find.text(l.hifzImReady), findsOneWidget);
  });

  testWidgets('tapping the disabled audio button shows its message here', (
    tester,
  ) async {
    final u = await seed('revise');
    await pumpApp(tester, HifzSessionPage(unit: u));
    final l = l10n(tester);
    await tester.tap(find.byIcon(Icons.volume_up_outlined));
    await tester.pump();
    expect(find.text(l.hifzAudioDisabledTooltip), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  final variants = <(String, EquranColors, double, Locale)>[
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
  ];
  for (final (name, colors, scale, locale) in variants) {
    testWidgets('Hifz session and completion golden $name', (tester) async {
      var u = await seed('fresh');
      await pumpApp(
        tester,
        HifzSessionPage(unit: u),
        colors: colors,
        scale: scale,
        locale: locale,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz/$name-listen.png'),
      );
      final l = l10n(tester);
      await tester.tap(find.text(l.hifzImReady));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.hifzRevealAll));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz/$name-rate-new.png'),
      );

      u = await seed('revise');
      await pumpApp(
        tester,
        HifzSessionPage(unit: u),
        colors: colors,
        scale: scale,
        locale: locale,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz/$name-recall.png'),
      );
      await tester.tap(find.text(l.hifzRevealAll));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz/$name-rate-review.png'),
      );

      await seed('revise');
      await pumpApp(
        tester,
        HifzCompleteScreen(
          ratingCounts: const {'again': 1, 'gotIt': 3, 'fail': 1, 'pass': 6},
          sessionDuration: const Duration(minutes: 7),
          totalReviewed: 11,
          newGraduated: 2,
          unit: unit('surah_94', 94),
        ),
        colors: colors,
        scale: scale,
        locale: locale,
        height: 1100,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/hifz/$name-complete.png'),
      );
    });
  }

  testWidgets('an empty queue shows the all-done state', (tester) async {
    final u = await seed('none');
    await pumpApp(tester, HifzSessionPage(unit: u));
    final l = l10n(tester);
    expect(find.text(l.hifzEmptySessionTitle), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/hifz/emerald-dark-empty.png'),
    );
  });

  testWidgets('a completed unit adds its banner to the summary', (
    tester,
  ) async {
    final u = await seed('none');
    u.isComplete = true;
    await pumpApp(
      tester,
      HifzCompleteScreen(
        ratingCounts: const {'gotIt': 2},
        sessionDuration: const Duration(seconds: 20),
        totalReviewed: 2,
        newGraduated: 0,
        unit: u,
      ),
      height: 1100,
    );
    final l = l10n(tester);
    expect(find.text(l.hifzUnitCompleteTitle(u.displayName)), findsOneWidget);
    expect(find.text(l.hifzCompleteAllCaughtUp), findsOneWidget);
    expect(find.text(l.hifzCompleteBackButton), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/hifz/emerald-dark-complete-unit.png'),
    );
  });
}
