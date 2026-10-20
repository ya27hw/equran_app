import 'package:flutter/foundation.dart';

class PlaybackCacheService {
  PlaybackCacheService._privateConstructor();
  static final PlaybackCacheService instance =
      PlaybackCacheService._privateConstructor();

  final ValueNotifier<ActivePlaybackTrack?> activeTrackNotifier =
      ValueNotifier<ActivePlaybackTrack?>(null);
}

class ActivePlaybackTrack {
  final int surah;
  final String reciterCode;
  final bool isPlaying;
  final bool isOffline;

  ActivePlaybackTrack({
    required this.surah,
    required this.reciterCode,
    required this.isPlaying,
    required this.isOffline,
  });
}
