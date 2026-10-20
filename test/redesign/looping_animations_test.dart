import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/prayer/prayer_map_location_page.dart';
import 'package:equran/services/device_capability_profile.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

/// The map location marker used to repeat forever. It now runs a bounded
/// number of cycles and not at all with reduced motion.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    DeviceCapabilityService.instance.value = const DeviceCapabilityProfile(
      lowRam: true,
      processorCount: 4,
    );
  });

  // One instance: a new ThemeData would start a theme cross-fade.
  final theme = savedPreviewTheme(EquranColors.dark);
  Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: Scaffold(body: Center(child: child)),
  );

  group('map location marker', () {
    const here = LatLng(23.588, 58.3829);
    const elsewhere = LatLng(21.4225, 39.8262);

    Widget marker(LatLng at) => PrayerUserLocationMarker(
      location: at,
      qiblaBearing: 90,
      pulsePeriod: const Duration(milliseconds: 100),
    );

    testWidgets('never pulses with reduced motion', (tester) async {
      await tester.pumpWidget(app(marker(here), reduceMotion: true));
      final state = tester.state<PrayerUserLocationMarkerState>(
        find.byType(PrayerUserLocationMarker),
      );
      expect(state.isPulsing, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(app(marker(elsewhere), reduceMotion: true));
      expect(state.isPulsing, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('pulses a few cycles, then stops; pulses again on a move', (
      tester,
    ) async {
      await tester.pumpWidget(app(marker(here)));
      final state = tester.state<PrayerUserLocationMarkerState>(
        find.byType(PrayerUserLocationMarker),
      );
      expect(state.isPulsing, isTrue);
      // Three cycles of 100 ms: still going at 250 ms, done by 350 ms.
      await tester.pump(const Duration(milliseconds: 250));
      expect(state.isPulsing, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.isPulsing, isFalse);
      // pumpAndSettle only returns when nothing is animating any more.
      await tester.pumpAndSettle();
      expect(state.isPulsing, isFalse);
      expect(tester.binding.transientCallbackCount, 0);

      // A rebuild at the same place stays at rest.
      await tester.pumpWidget(app(marker(here)));
      expect(state.isPulsing, isFalse);

      // A new location pulses once more, then rests again.
      await tester.pumpWidget(app(marker(elsewhere)));
      expect(state.isPulsing, isTrue);
      await tester.pumpAndSettle();
      expect(state.isPulsing, isFalse);
    });
  });
}
