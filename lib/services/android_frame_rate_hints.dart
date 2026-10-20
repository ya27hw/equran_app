import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/services.dart';

class AndroidFrameRateHints {
  AndroidFrameRateHints._();

  static const MethodChannel _channel = MethodChannel(
    'equran/frame_rate_hints',
  );

  static bool get _isAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> setAudioPlaybackHint30() {
    return setPreferredRefreshRate(30);
  }

  static Future<void> setAudioIdle() {
    return setAudioPlaybackHint30();
  }

  static Future<void> setPreferredRefreshRate(double hz) async {
    if (!_isAndroid) return;

    try {
      await _channel.invokeMethod<void>(
        'setPreferredRefreshRate',
        <String, double>{'preferredRefreshRate': hz},
      );
    } on MissingPluginException {
      _debugLog('missing Android frame-rate plugin for $hz Hz');
    } on PlatformException catch (error) {
      _debugLog('failed to request $hz Hz: ${error.message}');
    }
  }

  static Future<void> clear() async {
    if (!_isAndroid) return;

    try {
      await _channel.invokeMethod<void>('clearPreferredRefreshRate');
    } on MissingPluginException {
      _debugLog('missing Android frame-rate plugin while clearing');
    } on PlatformException catch (error) {
      _debugLog('failed to clear frame-rate hint: ${error.message}');
    }
  }

  static Future<void> setPowerSavingsBalancedIfSupported() async {
    if (!_isAndroid) return;

    try {
      await _channel.invokeMethod<void>('setPowerSavingsBalanced');
    } on MissingPluginException {
      _debugLog('missing Android power-savings frame-rate plugin');
    } on PlatformException catch (error) {
      _debugLog('failed to enable power-savings balanced: ${error.message}');
    }
  }

  static Future<Map<String, Object?>?> debugDiagnostics({
    double? requestedPreferredRefreshRate,
  }) async {
    if (!_isAndroid) return null;

    try {
      final Object? result = await _channel.invokeMethod<Object?>(
        'debugDiagnostics',
        <String, double?>{
          'requestedPreferredRefreshRate': requestedPreferredRefreshRate,
        },
      );
      if (result is Map) {
        return result.map(
          (dynamic key, dynamic value) =>
              MapEntry<String, Object?>(key.toString(), value),
        );
      }
    } on MissingPluginException {
      _debugLog('missing Android frame-rate diagnostics plugin');
    } on PlatformException catch (error) {
      _debugLog('failed to read frame-rate diagnostics: ${error.message}');
    }
    return null;
  }

  static void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[AndroidFrameRateHints] $message');
  }
}
