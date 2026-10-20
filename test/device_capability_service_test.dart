import 'package:equran/services/device_capability_profile.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to a balanced profile before detection', () {
    final DeviceCapabilityProfile profile =
        DeviceCapabilityService.instance.profile;
    expect(profile.mode, PerformanceMode.balanced);
    expect(profile.allowsDecorativeEffects, isTrue);
  });

  test(
    'detect completes without throwing and yields a usable profile',
    () async {
      await DeviceCapabilityService.instance.detect();
      final DeviceCapabilityProfile profile =
          DeviceCapabilityService.instance.profile;
      expect(profile.processorCount, greaterThan(0));
      expect(PerformanceMode.values, contains(profile.mode));
    },
  );
}
