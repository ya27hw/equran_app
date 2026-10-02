import 'package:equran/services/device_capability_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Process-wide holder for the detected [DeviceCapabilityProfile].
///
/// Until [detect] completes the profile is a balanced mid-range assumption, so
/// widgets can read [profile] synchronously and simply pick up the real value
/// (via [ValueListenable]) once it is known.
class DeviceCapabilityService extends ValueNotifier<DeviceCapabilityProfile> {
  DeviceCapabilityService._()
    : super(const DeviceCapabilityProfile(lowRam: false, processorCount: 6));

  static final DeviceCapabilityService instance = DeviceCapabilityService._();

  DeviceCapabilityProfile get profile => value;

  Future<void> detect() async {
    try {
      final bool reducedMotion = WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations;
      value = await DeviceCapabilityProfile.detect(
        reducedMotion: reducedMotion,
      );
    } catch (error) {
      // Keep the balanced default; capability detection must never block start.
      debugPrint('Device capability detection failed: $error');
    }
  }
}
