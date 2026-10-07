import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/features/splash/splash_screen.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/services/device_capability_profile.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The splash keeps its animation and startup hand-off; only its colours and
/// the subtitle font moved to the redesign tokens and the bundled Inter. The
/// golden is the settled frame at 2.9 s (the hand-off to Home is at 3.2 s and
/// is never reached here). Particles are off so the frame is deterministic.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadGalleryFonts();
    DeviceCapabilityService.instance.value = const DeviceCapabilityProfile(
      lowRam: true,
      processorCount: 4,
    );
  });

  final variants = <(String, EquranColors, double, Locale)>[
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
  ];
  for (final (name, colors, scale, locale) in variants) {
    testWidgets('splash golden $name', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      addTearDown(tester.view.reset);
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
          home: const SplashScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2900));
      expect(find.text('eQuran'), findsOneWidget);
      expect(find.text('The Holy Quran & Prayer Companion'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/splash/$name.png'),
      );
      // Leave before the hand-off to Home so no startup work runs.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }
}
