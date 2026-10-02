import 'package:equran/home/reader/reader_controllers.dart';
import 'package:equran/services/device_capability_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reader generation tokens reject stale navigation work', () {
    final ReadingSessionController controller = ReadingSessionController(
      ReaderPosition.validated(1, 1),
    );
    final int first = controller.beginGeneration();
    final int second = controller.beginGeneration();

    expect(controller.isCurrent(first), isFalse);
    expect(controller.isCurrent(second), isTrue);
    controller.finishGeneration(first);
    expect(controller.value.isLoading, isTrue);
    controller.finishGeneration(second);
    expect(controller.value.isLoading, isFalse);
    controller.dispose();
  });

  test(
    'audio planner bounds repeats and crosses canonical surah boundaries',
    () {
      const AudioSequencePlanner planner = AudioSequencePlanner();
      final List<ReaderAudioItem> items = planner.plan(
        start: const ReaderPosition(surah: 1, ayah: 7),
        count: 2,
        repeatCount: 2,
      );

      expect(items.map((ReaderAudioItem item) => item.position.id), <String>[
        '1:7',
        '1:7',
        '2:1',
        '2:1',
      ]);
    },
  );

  test('font window and progress policy adapt to lite mode', () {
    const DeviceCapabilityProfile lite = DeviceCapabilityProfile(
      lowRam: true,
      processorCount: 2,
    );
    expect(const ReaderFontController().pagesForWindow(1, lite), <int>[1]);
    expect(const ReaderPerformancePolicy(lite).useAnimatedEffects, isFalse);

    final ReaderProgressController progress = ReaderProgressController();
    progress.update(2);
    expect(progress.value, 1);
    progress.dispose();
  });
}
