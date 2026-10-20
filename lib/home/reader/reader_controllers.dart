import 'dart:async';

import 'package:equran/services/device_capability_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;

class ReaderPosition {
  const ReaderPosition({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  factory ReaderPosition.validated(int surah, int ayah) {
    final int safeSurah = surah.clamp(1, quran.totalSurahCount).toInt();
    return ReaderPosition(
      surah: safeSurah,
      ayah: ayah.clamp(1, quran.getVerseCount(safeSurah)).toInt(),
    );
  }

  String get id => '$surah:$ayah';

  @override
  bool operator ==(Object other) {
    return other is ReaderPosition &&
        other.surah == surah &&
        other.ayah == ayah;
  }

  @override
  int get hashCode => Object.hash(surah, ayah);
}

@immutable
class ReaderViewState {
  const ReaderViewState({
    required this.position,
    required this.cardView,
    required this.isLoading,
    required this.audioPlaying,
    required this.generation,
  });

  factory ReaderViewState.initial(ReaderPosition position) {
    return ReaderViewState(
      position: position,
      cardView: true,
      isLoading: false,
      audioPlaying: false,
      generation: 0,
    );
  }

  final ReaderPosition position;
  final bool cardView;
  final bool isLoading;
  final bool audioPlaying;
  final int generation;

  ReaderViewState copyWith({
    ReaderPosition? position,
    bool? cardView,
    bool? isLoading,
    bool? audioPlaying,
    int? generation,
  }) {
    return ReaderViewState(
      position: position ?? this.position,
      cardView: cardView ?? this.cardView,
      isLoading: isLoading ?? this.isLoading,
      audioPlaying: audioPlaying ?? this.audioPlaying,
      generation: generation ?? this.generation,
    );
  }
}

/// Small state boundary for reader navigation and stale async work.
class ReadingSessionController extends ValueNotifier<ReaderViewState> {
  ReadingSessionController(ReaderPosition initial)
    : super(ReaderViewState.initial(initial));

  int beginGeneration() {
    final int generation = value.generation + 1;
    value = value.copyWith(generation: generation, isLoading: true);
    return generation;
  }

  bool isCurrent(int generation) => value.generation == generation;

  void setPosition(ReaderPosition position) {
    value = value.copyWith(position: position, isLoading: false);
  }

  void setCardView(bool cardView) => value = value.copyWith(cardView: cardView);

  void setAudioPlaying(bool playing) =>
      value = value.copyWith(audioPlaying: playing);

  void finishGeneration(int generation) {
    if (isCurrent(generation)) value = value.copyWith(isLoading: false);
  }
}

@immutable
class VerseAudioState {
  const VerseAudioState({
    required this.position,
    required this.playing,
    required this.generation,
  });

  final ReaderPosition? position;
  final bool playing;
  final int generation;
}

/// Owns player-request tokens without owning a platform audio engine.
class VerseAudioController {
  VerseAudioController()
    : state = ValueNotifier<VerseAudioState>(
        const VerseAudioState(position: null, playing: false, generation: 0),
      );

  final ValueNotifier<VerseAudioState> state;

  int begin(ReaderPosition position) {
    final int generation = state.value.generation + 1;
    state.value = VerseAudioState(
      position: position,
      playing: true,
      generation: generation,
    );
    return generation;
  }

  bool isCurrent(int generation) => state.value.generation == generation;

  void stop() {
    state.value = VerseAudioState(
      position: state.value.position,
      playing: false,
      generation: state.value.generation + 1,
    );
  }

  void complete(int generation) {
    if (!isCurrent(generation)) return;
    state.value = VerseAudioState(
      position: state.value.position,
      playing: false,
      generation: generation,
    );
  }

  void dispose() => state.dispose();
}

@immutable
class ReaderAudioItem {
  const ReaderAudioItem({required this.position, this.delay = Duration.zero});

  final ReaderPosition position;
  final Duration delay;
}

class AudioSequencePlanner {
  const AudioSequencePlanner();

  List<ReaderAudioItem> plan({
    required ReaderPosition start,
    required int count,
    int repeatCount = 1,
    Duration delay = Duration.zero,
  }) {
    final int safeCount = count.clamp(1, 6236).toInt();
    final int safeRepeats = repeatCount.clamp(1, 20).toInt();
    final List<ReaderAudioItem> result = <ReaderAudioItem>[];
    ReaderPosition cursor = ReaderPosition.validated(start.surah, start.ayah);
    for (int index = 0; index < safeCount; index++) {
      for (int repeat = 0; repeat < safeRepeats; repeat++) {
        result.add(ReaderAudioItem(position: cursor, delay: delay));
      }
      if (cursor.ayah < quran.getVerseCount(cursor.surah)) {
        cursor = ReaderPosition(surah: cursor.surah, ayah: cursor.ayah + 1);
      } else if (cursor.surah < quran.totalSurahCount) {
        cursor = ReaderPosition(surah: cursor.surah + 1, ayah: 1);
      } else {
        break;
      }
    }
    return List<ReaderAudioItem>.unmodifiable(result);
  }
}

class ReaderProgressController extends ValueNotifier<double> {
  ReaderProgressController() : super(0);

  void update(double progress) => value = progress.clamp(0.0, 1.0).toDouble();
}

class ReaderFontController {
  const ReaderFontController();

  List<int> pagesForWindow(int currentPage, DeviceCapabilityProfile profile) {
    final int page = currentPage.clamp(1, 604).toInt();
    if (!profile.allowsAdjacentPrefetch) return <int>[page];
    return <int>{
      page,
      page - 1,
      page + 1,
    }.where((int value) => value >= 1 && value <= 604).toList(growable: false);
  }
}

class ReaderPerformancePolicy {
  const ReaderPerformancePolicy(this.profile);

  final DeviceCapabilityProfile profile;

  int get searchBatchSize => profile.searchBatchSize;
  bool get useAnimatedEffects => profile.allowsDecorativeEffects;
  Duration get progressTick =>
      Duration(milliseconds: profile.progressUpdateMilliseconds);
}

@immutable
class ShareCardSelection {
  const ShareCardSelection({required this.position, required this.text});

  final ReaderPosition position;
  final String text;

  bool get isValid => text.trim().isNotEmpty && text.length <= 10000;
}

/// Coalesces frequent activity writes while retaining a deterministic flush
/// boundary for route disposal and tests.
class ReadingActivityRecorder {
  ReadingActivityRecorder({Duration interval = const Duration(seconds: 20)})
    : _interval = interval;

  final Duration _interval;
  Timer? _timer;
  int _pendingAyahs = 0;
  Future<void> Function(int ayahs)? _flush;

  void start(Future<void> Function(int ayahs) flush) {
    _flush = flush;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => unawaited(flushNow()));
  }

  void recordAyah() => _pendingAyahs++;

  Future<void> flushNow() async {
    final int count = _pendingAyahs;
    if (count == 0 || _flush == null) return;
    _pendingAyahs = 0;
    await _flush!(count);
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await flushNow();
    _flush = null;
  }
}
