import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

enum PerformanceMode { lite, balanced, enhanced }

@immutable
class DeviceCapabilityProfile {
  const DeviceCapabilityProfile({
    required this.lowRam,
    required this.processorCount,
    this.refreshRate,
    this.batterySaver = false,
    this.reducedMotion = false,
    this.userMode,
  });

  final bool lowRam;
  final int processorCount;
  final double? refreshRate;
  final bool batterySaver;
  final bool reducedMotion;
  final PerformanceMode? userMode;

  PerformanceMode get mode {
    final PerformanceMode? override = userMode;
    if (override != null) return override;
    if (lowRam || processorCount <= 4 || batterySaver || reducedMotion) {
      return PerformanceMode.lite;
    }
    if ((refreshRate ?? 60) >= 90 && processorCount >= 8) {
      return PerformanceMode.enhanced;
    }
    return PerformanceMode.balanced;
  }

  bool get allowsDecorativeEffects => mode != PerformanceMode.lite;
  bool get allowsAdjacentPrefetch => mode != PerformanceMode.lite;
  int get searchBatchSize => mode == PerformanceMode.lite ? 20 : 80;
  int get progressUpdateMilliseconds =>
      mode == PerformanceMode.lite ? 500 : 100;

  DeviceCapabilityProfile copyWith({
    bool? lowRam,
    int? processorCount,
    double? refreshRate,
    bool? batterySaver,
    bool? reducedMotion,
    PerformanceMode? userMode,
    bool clearUserMode = false,
  }) {
    return DeviceCapabilityProfile(
      lowRam: lowRam ?? this.lowRam,
      processorCount: processorCount ?? this.processorCount,
      refreshRate: refreshRate ?? this.refreshRate,
      batterySaver: batterySaver ?? this.batterySaver,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      userMode: clearUserMode ? null : (userMode ?? this.userMode),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'lowRam': lowRam,
    'processorCount': processorCount,
    'refreshRate': refreshRate,
    'batterySaver': batterySaver,
    'reducedMotion': reducedMotion,
    'userMode': userMode?.name,
  };

  static Future<DeviceCapabilityProfile> detect({
    bool reducedMotion = false,
    bool batterySaver = false,
  }) async {
    bool lowRam = false;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        lowRam = (await DeviceInfoPlugin().androidInfo).isLowRamDevice;
      } catch (_) {
        // Unknown capability is treated conservatively by processor count.
      }
    }
    return DeviceCapabilityProfile(
      lowRam: lowRam,
      processorCount: Platform.numberOfProcessors,
      batterySaver: batterySaver,
      reducedMotion: reducedMotion,
    );
  }
}
