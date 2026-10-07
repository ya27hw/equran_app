import 'dart:io';

import 'package:equran/backend/library.dart';
import 'package:equran/backend/playback_cache_service.dart';
import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/home/downloads.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The Downloads page on the redesign system. The page is pumped for real with
/// a fixed summary injected through `loadSummary` (the default scans the file
/// system). There is no design preview; the cards follow the More page and the
/// reader sheet chrome. Delete and clear calls are not exercised against the
/// file system here, only that the confirmation opens.
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
  tearDown(
    () => PlaybackCacheService.instance.activeTrackNotifier.value = null,
  );

  AudioDownloadEntry entry(
    String reciter,
    int surah,
    AudioDownloadType type, {
    int? ayah,
    int size = 4200000,
  }) => AudioDownloadEntry(
    file: File('/none/$reciter-$surah-${ayah ?? 0}.mp3'),
    type: type,
    reciterCode: reciter,
    surah: surah,
    ayah: ayah,
    sizeBytes: size,
  );

  AudioDownloadsSummary fixture() => AudioDownloadsSummary(
    surahDownloads: <AudioDownloadEntry>[
      entry('abdul_basit_murattal', 1, AudioDownloadType.surah, size: 1300000),
      entry('abdul_basit_murattal', 2, AudioDownloadType.surah, size: 41800000),
      entry('abdul_samad', 36, AudioDownloadType.surah, size: 9200000),
    ],
    ayahDownloads: <AudioDownloadEntry>[
      entry('abdul_basit_murattal', 112, AudioDownloadType.ayah, ayah: 1),
      entry('abdul_basit_murattal', 112, AudioDownloadType.ayah, ayah: 2),
      entry('abdul_basit_murattal', 67, AudioDownloadType.ayahSurah),
    ],
  );

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 1180,
    AudioDownloadsSummary? summary,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(390 * 2, height * 2);
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
        home: Scaffold(
          body: DownloadsPage(loadSummary: () async => summary ?? fixture()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DownloadsPage)))!;

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
    testWidgets('Downloads golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1750 : 1180,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/downloads/$name.png'),
      );
    });
  }

  testWidgets('empty state', (tester) async {
    await pump(
      tester,
      height: 800,
      summary: const AudioDownloadsSummary(
        surahDownloads: <AudioDownloadEntry>[],
        ayahDownloads: <AudioDownloadEntry>[],
      ),
    );
    expect(find.text(l10n(tester).noDownloadedAudioYet), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/downloads/empty.png'),
    );
  });

  testWidgets('the file playing offline is marked', (tester) async {
    PlaybackCacheService.instance.activeTrackNotifier.value =
        ActivePlaybackTrack(
          surah: 2,
          reciterCode: 'abdul_basit_murattal',
          isPlaying: true,
          isOffline: true,
        );
    await pump(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/downloads/playing-offline.png'),
    );
  });

  final List<(String, EquranColors, double, Locale)> sheetVariants =
      <(String, EquranColors, double, Locale)>[
        ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
        ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
        ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
        ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
      ];
  for (final (String name, EquranColors colors, double scale, Locale locale)
      in sheetVariants) {
    testWidgets('filter sheet golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: 900,
      );
      await tester.tap(find.byTooltip('Filter & sort'));
      await tester.pumpAndSettle();
      expect(find.text('Filter & Sort Downloads'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/downloads/sheet-$name.png'),
      );
    });

    testWidgets('delete confirmation golden $name', (tester) async {
      await pump(
        tester,
        colors: colors,
        scale: scale,
        locale: locale,
        height: 900,
      );
      await tester.tap(find.byTooltip(l10n(tester).deleteDownload).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n(tester).deleteDownloadQuestion), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/downloads/delete-$name.png'),
      );
    });
  }

  testWidgets('filter sheet applies a search and group by surah', (
    tester,
  ) async {
    await pump(tester, height: 900);
    await tester.tap(find.byTooltip('Filter & sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Surah').first);
    await tester.pumpAndSettle();
    // Switching group-by rewrites the sort, as before.
    expect(find.text('Surah (1 → 114)'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Filter & Sort Downloads'), findsNothing);
    // A filter is active, so the Clear button and the count badge show.
    expect(find.text('Clear'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Clear'), findsNothing);
  });
}
