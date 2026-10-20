import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/playback_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });

  const delays = <String>[
    'No delay',
    '0.5 seconds',
    '1 second',
    '2 seconds',
    '3 seconds',
    '4 seconds',
    '5 seconds',
    '6 seconds',
    '7 seconds',
    '8 seconds',
    '9 seconds',
    '10 seconds',
  ];

  Future<List<String>> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double rate = 1.25,
    int delayIndex = 2,
    bool surahDownloaded = false,
    bool surahDownloading = false,
    double? progress,
    bool ayahDownloaded = false,
    double height = 1500,
  }) async {
    final log = <String>[];
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = Size(390 * 3, height * 3);
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
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
        home: Scaffold(
          backgroundColor: colors.background,
          body: PlaybackOptionsSheet(
            scrollController: controller,
            reciterName: 'Mishary Rashid Alafasy',
            onReciter: () => log.add('reciter'),
            rate: rate,
            onRateSelected: (v) => log.add('rate:$v'),
            delayLabels: delays,
            delayIndex: delayIndex,
            onDelayChanged: (i) => log.add('delay:$i'),
            onDelayChangeEnd: (i) => log.add('delayEnd:$i'),
            intervalSummary: 'Ayah 1 to Ayah 7',
            onInterval: () => log.add('interval'),
            intervalRepeatLabel: 'Infinite',
            onIntervalRepeat: () => log.add('intervalRepeat'),
            repeatAyahLabel: '1 time',
            onRepeatAyah: () => log.add('repeatAyah'),
            sleepSummary: 'Off',
            onSleepTimer: () => log.add('sleep'),
            surahDownloadProgress: ValueNotifier<double?>(progress),
            surahDownloading: surahDownloading,
            surahDownloaded: surahDownloaded,
            onDownloadSurah: () => log.add('downloadSurah'),
            ayahDownloading: false,
            ayahDownloaded: ayahDownloaded,
            ayahSubtitle: 'Al-Baqarah • Ayah 142',
            onToggleAyah: () => log.add('ayah'),
            onReset: () => log.add('reset'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return log;
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(PlaybackOptionsSheet)))!;

  testWidgets('every option still reaches its callback', (tester) async {
    final log = await pump(tester);
    final l = l10n(tester);
    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f.first);
      await tester.tap(f.first);
    }

    await tap(find.text(l.reciter));
    await tap(find.text(l.sleepTimerOption));
    await tap(find.text(l.intervalOption).last);
    await tap(find.text(l.intervalRepeatOption));
    await tap(find.text(l.repeatEachAyahOption));
    await tap(find.text(l.downloadSurahAudio));
    await tap(find.text(l.downloadCurrentAyah));
    await tap(find.text(l.resetPlaybackOptions));
    expect(log, [
      'reciter',
      'sleep',
      'interval',
      'intervalRepeat',
      'repeatAyah',
      'downloadSurah',
      'ayah',
      'reset',
    ]);
  });

  testWidgets('each speed chip selects exactly its rate', (tester) async {
    final log = await pump(tester);
    for (final v in playbackSpeedSteps) {
      final chip = find.text(playbackSpeedLabel(v));
      await tester.ensureVisible(chip.last);
      await tester.tap(chip.last);
    }
    expect(log, [for (final v in playbackSpeedSteps) 'rate:$v']);
  });

  testWidgets('the current speed is shown and its chip is selected', (
    tester,
  ) async {
    await pump(tester, rate: 0.75);
    // One big readout and one chip carry the same label.
    expect(find.text('0.75×'), findsNWidgets(2));
    expect(find.text('1.5×'), findsOneWidget);
  });

  testWidgets('dragging the delay slider reports steps and a final value', (
    tester,
  ) async {
    final log = await pump(tester);
    final slider = find.byType(Slider);
    await tester.ensureVisible(slider);
    await tester.drag(slider, const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(log.where((e) => e.startsWith('delay:')), isNotEmpty);
    expect(log.last, startsWith('delayEnd:'));
  });

  testWidgets('a downloaded surah hides the single-ayah row and is inert', (
    tester,
  ) async {
    final log = await pump(tester, surahDownloaded: true);
    final l = l10n(tester);
    expect(find.text(l.surahAudioDownloaded), findsOneWidget);
    expect(find.text(l.downloadCurrentAyah), findsNothing);
    await tester.ensureVisible(find.text(l.surahAudioDownloaded));
    await tester.tap(find.text(l.surahAudioDownloaded));
    expect(log, isEmpty);
  });

  testWidgets('a running download shows progress and ignores taps', (
    tester,
  ) async {
    final log = await pump(tester, surahDownloading: true, progress: 0.4);
    final l = l10n(tester);
    expect(find.text('40'), findsOneWidget);
    await tester.ensureVisible(find.text(l.downloadSurahAudio));
    await tester.tap(find.text(l.downloadSurahAudio));
    expect(log, isEmpty);
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
    testWidgets('Options sheet golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1700 : 1400,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/player/options-$name.png'),
      );
    });
  }

  testWidgets('Options sheet golden downloading', (tester) async {
    await pump(
      tester,
      surahDownloading: true,
      progress: 0.4,
      rate: 0.5,
      delayIndex: 0,
      height: 1400,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/player/options-downloading.png'),
    );
  });
}
