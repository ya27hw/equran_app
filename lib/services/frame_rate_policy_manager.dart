import 'dart:async';

import 'package:equran/services/android_frame_rate_hints.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

enum _AppliedFrameRateHint { clear, audioIdle30 }

class FrameRatePolicyManager {
  FrameRatePolicyManager._();

  static final FrameRatePolicyManager instance = FrameRatePolicyManager._();

  static const Duration interactionDebounce = Duration(milliseconds: 500);

  final Set<String> _audioPlayingSources = <String>{};
  final Set<String> _expandedPlayerSources = <String>{};
  final Set<String> _miniPlayerSources = <String>{};
  final Set<String> _pointerSources = <String>{};
  final Set<String> _draggingSources = <String>{};
  final Set<String> _transientBlockers = <String>{};

  bool _drawerOpen = false;
  bool _modalOpen = false;
  bool _routeTransitionActive = false;
  bool _settingsOrDownloadsVisible = false;
  bool _appLifecyclePaused = false;
  bool _playerDisposed = false;
  bool _powerSavingsBalancedRequested = false;
  bool _miniSkipLogged = false;
  bool _restoreDebouncePending = false;
  double? _requestedPreferredRefreshRate;
  Timer? _restoreTimer;
  _AppliedFrameRateHint _appliedHint = _AppliedFrameRateHint.clear;
  String? _lastRepeatedClearReason;

  bool get audioPlaying => _audioPlayingSources.isNotEmpty;
  bool get expandedPlayerVisible => _expandedPlayerSources.isNotEmpty;
  bool get miniPlayerVisible => _miniPlayerSources.isNotEmpty;

  void setAudioPlaying(
    bool playing, {
    required String source,
    required String reason,
  }) {
    _setSource(_audioPlayingSources, source, playing);
    _evaluate(reason);
  }

  void updatePlaybackSurface({
    required String source,
    required bool audioPlaying,
    required bool expandedPlayerVisible,
    required bool miniPlayerVisible,
    required String reason,
  }) {
    _setSource(_audioPlayingSources, source, audioPlaying);
    _setSource(_expandedPlayerSources, source, expandedPlayerVisible);
    _setSource(_miniPlayerSources, source, miniPlayerVisible);
    if (expandedPlayerVisible) {
      _setSource(_miniPlayerSources, source, false);
    } else if (miniPlayerVisible) {
      _setSource(_expandedPlayerSources, source, false);
    }
    _evaluate(reason);
  }

  void setExpandedPlayerVisible(
    bool visible, {
    required String source,
    required String reason,
  }) {
    _setSource(_expandedPlayerSources, source, visible);
    if (visible) {
      _setSource(_miniPlayerSources, source, false);
    }
    _evaluate(reason);
  }

  void setMiniPlayerVisible(
    bool visible, {
    required String source,
    required String reason,
  }) {
    _setSource(_miniPlayerSources, source, visible);
    if (visible) {
      _setSource(_expandedPlayerSources, source, false);
    }
    _evaluate(reason);
  }

  void setPointerActive(
    bool active, {
    required String source,
    required String reason,
  }) {
    _setSource(_pointerSources, source, active);
    _evaluate(reason, debounceIfClear: !active);
  }

  void setUserDragging(
    bool dragging, {
    required String source,
    required String reason,
  }) {
    _setSource(_draggingSources, source, dragging);
    _evaluate(reason, debounceIfClear: !dragging);
  }

  void setDrawerOpen(bool open, {required String reason}) {
    _drawerOpen = open;
    _evaluate(reason, debounceIfClear: !open);
  }

  void setModalOpen(bool open, {required String reason}) {
    _modalOpen = open;
    _evaluate(reason, debounceIfClear: !open);
  }

  void setRouteTransitionActive(bool active, {required String reason}) {
    _routeTransitionActive = active;
    _evaluate(reason, debounceIfClear: !active);
  }

  void setSettingsOrDownloadsVisible(bool visible, {required String reason}) {
    _settingsOrDownloadsVisible = visible;
    _evaluate(reason, debounceIfClear: !visible);
  }

  void setAppLifecyclePaused(bool paused, {required String reason}) {
    _appLifecyclePaused = paused;
    _evaluate(reason, debounceIfClear: !paused);
  }

  void setPlayerDisposed(bool disposed, {required String reason}) {
    _playerDisposed = disposed;
    _evaluate(reason, debounceIfClear: !disposed);
  }

  void setTransientBlocker(
    String blocker,
    bool active, {
    required String reason,
  }) {
    _setSource(_transientBlockers, blocker, active);
    _evaluate(reason, debounceIfClear: !active);
  }

  void notifyUserActivity({String reason = 'user_activity'}) {
    _clear(reason: reason, blockers: _activeBlockers);
    _evaluate('$reason settled', debounce: true);
  }

  void resetSource(String source, {required String reason}) {
    _audioPlayingSources.remove(source);
    _expandedPlayerSources.remove(source);
    _miniPlayerSources.remove(source);
    _pointerSources.remove(source);
    _draggingSources.remove(source);
    _evaluate(reason);
  }

  void clearAll({required String reason}) {
    _audioPlayingSources.clear();
    _expandedPlayerSources.clear();
    _miniPlayerSources.clear();
    _pointerSources.clear();
    _draggingSources.clear();
    _transientBlockers.clear();
    _drawerOpen = false;
    _modalOpen = false;
    _routeTransitionActive = false;
    _settingsOrDownloadsVisible = false;
    _appLifecyclePaused = false;
    _playerDisposed = false;
    _evaluate(reason);
  }

  Future<void> printDebugDiagnostics({String reason = 'diagnostics'}) async {
    if (!kDebugMode) return;
    final Map<String, Object?>? diagnostics =
        await AndroidFrameRateHints.debugDiagnostics(
          requestedPreferredRefreshRate: _requestedPreferredRefreshRate,
        );
    _debugLog(
      'diagnostics reason=$reason requestedPreferredRefreshRate='
      '$_requestedPreferredRefreshRate state=${_stateSummary()} '
      'android=$diagnostics',
    );
  }

  static void debugLogExpandedProgressTicker({
    required String owner,
    required Duration interval,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[FrameRatePolicy] expanded player capped progress ticker '
      'owner=$owner interval=${interval.inMilliseconds}ms',
    );
  }

  static void debugLogMiniPlayerStatic({required String owner}) {
    if (!kDebugMode) return;
    debugPrint(
      '[FrameRatePolicy] skip mini player: static/event-driven owner=$owner',
    );
  }

  void _evaluate(
    String reason, {
    bool debounce = false,
    bool debounceIfClear = false,
    bool fromDebounceTimer = false,
  }) {
    if (debounce) {
      _scheduleRestore(reason);
      return;
    }

    if (fromDebounceTimer) {
      _restoreTimer = null;
      _restoreDebouncePending = false;
    }

    final List<String> blockers = _activeBlockers;
    if (blockers.isNotEmpty) {
      _cancelRestore();
      _clear(reason: reason, blockers: blockers);
      return;
    }

    if (debounceIfClear) {
      _scheduleRestore(reason);
      return;
    }

    if (miniPlayerVisible && !expandedPlayerVisible) {
      _cancelRestore();
      if (!_miniSkipLogged) {
        _miniSkipLogged = true;
        _debugLog('skip mini player: static/event-driven');
      }
      _clear(reason: reason, blockers: blockers);
      return;
    }
    _miniSkipLogged = false;

    if (expandedPlayerVisible && audioPlaying) {
      if (_restoreDebouncePending && !fromDebounceTimer) {
        return;
      }
      _applyAudioIdle(reason: 'expanded_audio_idle');
      return;
    }

    _cancelRestore();
    _clear(reason: reason, blockers: blockers);
  }

  void _scheduleRestore(String reason) {
    _restoreTimer?.cancel();
    _restoreDebouncePending = true;
    _restoreTimer = Timer(interactionDebounce, () {
      _evaluate(reason, fromDebounceTimer: true);
    });
  }

  void _cancelRestore() {
    _restoreTimer?.cancel();
    _restoreTimer = null;
    _restoreDebouncePending = false;
  }

  void _applyAudioIdle({required String reason}) {
    if (_appliedHint == _AppliedFrameRateHint.audioIdle30) return;
    _appliedHint = _AppliedFrameRateHint.audioIdle30;
    _lastRepeatedClearReason = null;
    _requestedPreferredRefreshRate = 30;
    _debugLog(
      'set preferredRefreshRate=30 reason=$reason '
      'state=${_stateSummary()}',
    );
    if (!_powerSavingsBalancedRequested) {
      _powerSavingsBalancedRequested = true;
      unawaited(AndroidFrameRateHints.setPowerSavingsBalancedIfSupported());
    }
    unawaited(AndroidFrameRateHints.setAudioIdle());
  }

  void _clear({required String reason, required List<String> blockers}) {
    final bool alreadyClear = _appliedHint == _AppliedFrameRateHint.clear;
    final bool shouldLog =
        !alreadyClear ||
        _isImportantClearReason(reason) ||
        _lastRepeatedClearReason != reason;
    _appliedHint = _AppliedFrameRateHint.clear;
    _requestedPreferredRefreshRate = null;

    if (shouldLog) {
      _lastRepeatedClearReason = reason;
      _debugLog(
        'clear reason=$reason blockers=${_formatBlockers(blockers)} '
        'state=${_stateSummary()}',
      );
    }

    if (alreadyClear) return;
    unawaited(AndroidFrameRateHints.clear());
  }

  List<String> get _activeBlockers {
    return <String>[
      if (_pointerSources.isNotEmpty)
        'pointerActive:${_pointerSources.join(",")}',
      if (_draggingSources.isNotEmpty)
        'userDragging:${_draggingSources.join(",")}',
      if (_drawerOpen) 'drawerOpen',
      if (_modalOpen) 'modalOpen',
      if (_routeTransitionActive) 'routeTransitionActive',
      if (_settingsOrDownloadsVisible) 'settingsOrDownloadsVisible',
      if (_appLifecyclePaused) 'appLifecyclePaused',
      if (_playerDisposed) 'playerDisposed',
      if (_transientBlockers.isNotEmpty)
        'transient:${_transientBlockers.join(",")}',
    ];
  }

  String _stateSummary() {
    return 'audio=$audioPlaying '
        'expanded=$expandedPlayerVisible '
        'mini=$miniPlayerVisible '
        'blockers=${_formatBlockers(_activeBlockers)}';
  }

  String _formatBlockers(List<String> blockers) {
    return blockers.isEmpty ? 'none' : blockers.join('|');
  }

  bool _isImportantClearReason(String reason) {
    return reason.contains('drawer') ||
        reason.contains('settings') ||
        reason.contains('download') ||
        reason.contains('modal') ||
        reason.contains('route') ||
        reason.contains('stopped') ||
        reason.contains('disposed');
  }

  void _setSource(Set<String> sources, String source, bool active) {
    if (active) {
      sources.add(source);
    } else {
      sources.remove(source);
    }
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[FrameRatePolicy] $message');
  }
}
