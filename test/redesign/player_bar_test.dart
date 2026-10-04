import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/read_verse_player_bar.dart';
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

  Future<List<String>> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double width = 390,
    bool minimized = false,
    bool playing = true,
    bool loading = false,
    bool auto = true,
    bool repeat = false,
  }) async {
    final List<String> log = <String>[];
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = Size(width * 3, 300 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: colors.background,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ReadVersePlayerBar(
              viewMode: false,
              isMounted: true,
              isVisible: true,
              isMinimized: minimized,
              isMinimizedSettled: minimized,
              isDragging: false,
              isPlaying: playing,
              isLoading: loading,
              continuousPlayback: auto,
              repeatIntervalEnabled: repeat,
              collapseProgress: minimized ? 1 : 0,
              currentChapter: 2,
              currentVerse: 142,
              totalVerses: 286,
              playingVerse: 142,
              positionListenable: ValueNotifier<Duration>(
                const Duration(seconds: 47),
              ),
              durationListenable: ValueNotifier<Duration>(
                const Duration(minutes: 1, seconds: 52),
              ),
              onHidden: () {},
              onMinimizedSettled: () {},
              onExpand: () => log.add('expand'),
              onDismiss: () => log.add('dismiss'),
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              onVerticalDragCancel: () {},
              onSeekStart: (_) => log.add('seekStart'),
              onSeek: (_) => log.add('seek'),
              onSeekEnd: (_) => log.add('seekEnd'),
              onTogglePlayPause: () => log.add('toggle'),
              onContinuousPlaybackChanged: (v) => log.add('auto:$v'),
              onRepeatIntervalPressed: () => log.add('repeat'),
              onAdvancedOptionsPressed: () => log.add('options'),
              onPlayPrevious: () => log.add('prev'),
              onPlayNext: () => log.add('next'),
              isDownloaded: true,
            ),
          ),
        ),
      ),
    );
    if (loading) {
      await tester.pump(const Duration(milliseconds: 600));
    } else {
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    return log;
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ReadVersePlayerBar)))!;

  testWidgets('every expanded control still fires its callback', (
    tester,
  ) async {
    final log = await pump(tester);
    final l = l10n(tester);
    await tester.tap(find.byTooltip(l.pause));
    await tester.tap(find.byTooltip(l.previousAyah));
    await tester.tap(find.byTooltip(l.nextAyah));
    await tester.tap(find.byTooltip(l.autoPlayback));
    await tester.tap(find.byTooltip(l.repeatInterval));
    await tester.tap(find.byTooltip(l.playbackOptions));
    expect(log, ['toggle', 'prev', 'next', 'auto:false', 'repeat', 'options']);
    expect(find.text(localizedSurahName(l, 2)), findsOneWidget);
    expect(find.text(l.ayahNumber(142)), findsOneWidget);
  });

  testWidgets('the play button shows pause while playing and play when not', (
    tester,
  ) async {
    await pump(tester, playing: false);
    expect(find.byTooltip(l10n(tester).play), findsOneWidget);
    await pump(tester, playing: true);
    expect(find.byTooltip(l10n(tester).pause), findsOneWidget);
  });

  testWidgets('the play glyph morphs when playback starts', (tester) async {
    await pump(tester, playing: false);
    final Finder icon = find.byType(AnimatedIcon);
    expect(tester.widget<AnimatedIcon>(icon).progress.value, 0);
    await pump(tester, playing: true);
    expect(tester.widget<AnimatedIcon>(icon).progress.value, 1);
  });

  testWidgets('a loading bar shows a spinner and says so', (tester) async {
    await pump(tester, loading: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip(l10n(tester).unableToReconnect), findsOneWidget);
  });

  testWidgets('the minimized bar plays, expands and dismisses', (tester) async {
    final log = await pump(tester, minimized: true);
    final l = l10n(tester);
    await tester.tap(find.byTooltip(l.pause));
    await tester.tap(find.byTooltip(l.dismissPlayer));
    await tester.tap(find.textContaining(localizedSurahName(l, 2)));
    expect(log, ['toggle', 'dismiss', 'expand']);
    // Settled and static: nothing animates and there is no slider.
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('widescreen keeps the transport and the seek bar', (
    tester,
  ) async {
    final log = await pump(tester, width: 1100);
    expect(find.byType(Slider), findsOneWidget);
    await tester.tap(find.byTooltip(l10n(tester).nextAyah));
    expect(log, ['next']);
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
    testWidgets('Player bar golden $name', (tester) async {
      await pump(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/player/bar-$name.png'),
      );
    });
  }

  testWidgets('Player bar golden widescreen', (tester) async {
    await pump(tester, width: 1100, repeat: true, auto: false);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/player/bar-widescreen.png'),
    );
  });

  for (final (name, colors) in <(String, EquranColors)>[
    ('emerald-dark', EquranColors.dark),
    ('emerald-light', EquranColors.light),
  ]) {
    testWidgets('Player mini bar golden $name', (tester) async {
      await pump(tester, colors: colors, minimized: true);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/player/mini-$name.png'),
      );
    });
  }
}
