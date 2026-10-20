import 'dart:async';

import 'package:equran/services/frame_rate_policy_manager.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

class AndroidAudioDisplayMode {
  AndroidAudioDisplayMode._();

  static const bool kEnableMinimizedPlayerLowRefreshLock = false;
  static const String _legacyAudioSource = 'legacyAudioDisplayMode.audio';
  static const String _legacyVisualSource = 'legacyAudioDisplayMode.visual';
  static const String _legacySuppressionBlocker =
      'legacyAudioDisplayMode.suppression';

  static FrameRatePolicyManager get _policy => FrameRatePolicyManager.instance;

  static Future<void> setAudioPlaybackActive(bool active) async {
    _policy.setAudioPlaying(
      active,
      source: _legacyAudioSource,
      reason: active ? 'legacy_audio_playing' : 'legacy_audio_stopped',
    );
  }

  static Future<void> setVisualProgressActive(bool active) async {
    if (active) {
      _debugLog(
        'visual progress active without expanded player; leaving hints clear',
      );
    }
    _policy.setMiniPlayerVisible(
      active,
      source: _legacyVisualSource,
      reason: active ? 'legacy_visual_progress_active' : 'legacy_visual_idle',
    );
  }

  static void notifyUserActivity({Duration? idleDelay}) {
    _policy.notifyUserActivity(reason: 'legacy_user_activity');
  }

  static Future<void> setIdleAudioFrameRateEnabled(bool enabled) async {
    _debugLog('ignored legacy idle frame-rate toggle enabled=$enabled');
  }

  static Future<void> setLowFpsSuppressed(bool suppressed) async {
    _policy.setTransientBlocker(
      _legacySuppressionBlocker,
      suppressed,
      reason: suppressed
          ? 'legacy_interaction_suppressed'
          : 'legacy_interaction_settled',
    );
  }

  static Future<void> addLowRefreshBlocker(
    String blocker, {
    String reason = '',
  }) async {
    _policy.setTransientBlocker(
      blocker,
      true,
      reason: reason.isEmpty ? 'legacy_blocker_$blocker' : reason,
    );
  }

  static Future<void> removeLowRefreshBlocker(
    String blocker, {
    String reason = '',
  }) async {
    _policy.setTransientBlocker(
      blocker,
      false,
      reason: reason.isEmpty ? 'legacy_blocker_removed_$blocker' : reason,
    );
  }

  static Future<void> clearStaticMinimizedAudioRefreshRate({
    bool force = false,
    bool clearWanted = true,
  }) async {
    _policy.setMiniPlayerVisible(
      false,
      source: _legacyVisualSource,
      reason: 'legacy_static_minimized_clear',
    );
  }

  static void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('AndroidAudioDisplayMode: $message');
  }
}
