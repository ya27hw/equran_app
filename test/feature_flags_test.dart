import 'package:equran/backend/feature_flags.dart';
import 'package:equran/services/device_capability_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roadmap flags default closed and round-trip by stable keys', () {
    const FeatureFlags defaults = FeatureFlags();
    expect(defaults.toMap().values.every((bool enabled) => !enabled), isTrue);

    final FeatureFlags enabled = defaults.copyWith(
      memoryMapEnabled: true,
      journeyCapsulesEnabled: true,
    );
    final FeatureFlags restored = FeatureFlags.fromMap(enabled.toMap());
    expect(restored.isEnabled(RoadmapFeature.memoryMap), isTrue);
    expect(restored.isEnabled(RoadmapFeature.journeyCapsules), isTrue);
    expect(restored.isEnabled(RoadmapFeature.memoryTwin), isFalse);
  });

  test('device profile selects conservative mode for constrained devices', () {
    const DeviceCapabilityProfile profile = DeviceCapabilityProfile(
      lowRam: true,
      processorCount: 8,
      refreshRate: 120,
    );
    expect(profile.mode, PerformanceMode.lite);
    expect(profile.allowsDecorativeEffects, isFalse);
    expect(profile.searchBatchSize, 20);
  });

  test('device profile respects manual mode without labeling hardware', () {
    const DeviceCapabilityProfile profile = DeviceCapabilityProfile(
      lowRam: true,
      processorCount: 2,
      userMode: PerformanceMode.enhanced,
    );
    expect(profile.mode, PerformanceMode.enhanced);
    expect(profile.allowsAdjacentPrefetch, isTrue);
  });
}
