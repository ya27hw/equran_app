import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat, TextBox, lerpDouble;
import 'package:like_button/like_button.dart';
import 'package:equran/backend/bookmark_db.dart';
import 'package:equran/backend/library.dart'
    show
        AndroidAudioDisplayMode,
        AudioDownloadService,
        DownloadNotifications,
        FavouritesDB,
        QuranActivityDB,
        QuranActivityDay,
        QuranBookmarkEntry,
        QuranBookmarkService,
        QuranBookmarksDB,
        QuranStatsDB,
        QuranStatsSnapshot,
        QuranTranslationService,
        QuranTransliterationService,
        QuranAudioService,
        hasQuranReadingActivity,
        ReadingPlansDB,
        ReadingPlanEntry,
        ResumeStateDB,
        ResumeStateEntry,
        DownloadableResource,
        ResourceDownloadPhase,
        ResourceDownloadProgress,
        ResourceDownloadService,
        ResourceInstallException,
        ResourceInstallState,
        ResourceInstallStore,
        ResourceManifest,
        ResourceRepository,
        ResourceType,
        RoutineDayProgressDB,
        RoutineDayProgressEntry,
        SettingsDB,
        TafsirVerseResult,
        TafsirService,
        prettyBytes,
        getResourceSize;
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/reading_plans/routine_progress.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:equran/utils/reciter.dart';
import 'package:equran/backend/quran_stream_url.dart';
import 'package:equran/utils/responsive_nav.dart';
import 'package:equran/utils/translation_display.dart';
import 'package:equran/services/frame_rate_policy_manager.dart';
import 'package:equran/widgets/library.dart'
    show
        AppSelectionDialog,
        AppSelectionOption,
        ReadQuranCard,
        readQuranCardHorizontalMarginForWidth,
        ReadVersePlayerBar;
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/gestures.dart'
    show
        PointerCancelEvent,
        PointerDownEvent,
        PointerMoveEvent,
        PointerSignalEvent,
        PointerUpEvent;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show
        PipelineOwner,
        RenderParagraph,
        RenderRepaintBoundary,
        RenderView,
        ScrollDirection,
        ViewConfiguration;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:equran/l10n/app_localizations.dart';

class _OfflineAudioPlaybackException implements Exception {
  const _OfflineAudioPlaybackException();
}

class _CancelledAudioPlaybackException implements Exception {
  const _CancelledAudioPlaybackException();
}

class _AudioPlaybackStalledException implements Exception {
  const _AudioPlaybackStalledException();
}

class QuranPosition {
  const QuranPosition({required this.surah, required this.ayah});

  factory QuranPosition.current(int surah, int ayah) {
    return QuranPosition(
      surah: surah.clamp(1, 114).toInt(),
      ayah: ayah
          .clamp(1, quran.getVerseCount(surah.clamp(1, 114).toInt()))
          .toInt(),
    );
  }

  final int surah;
  final int ayah;

  int compareTo(QuranPosition other) {
    final int surahCompare = surah.compareTo(other.surah);
    if (surahCompare != 0) return surahCompare;
    return ayah.compareTo(other.ayah);
  }

  bool isBefore(QuranPosition other) => compareTo(other) < 0;

  bool isAfter(QuranPosition other) => compareTo(other) > 0;

  Map<String, int> toJson() => <String, int>{'surah': surah, 'ayah': ayah};

  static QuranPosition? fromJson(dynamic value) {
    if (value is! Map) return null;
    final int? surah = _readInt(value['surah']);
    final int? ayah = _readInt(value['ayah']);
    if (surah == null || ayah == null) return null;
    if (surah < 1 || surah > 114) return null;
    final int verseCount = quran.getVerseCount(surah);
    if (ayah < 1 || ayah > verseCount) return null;
    return QuranPosition(surah: surah, ayah: ayah);
  }
}

class _ReadingAudioProgressSource {
  const _ReadingAudioProgressSource({
    required this.requestId,
    required this.surah,
    required this.ayah,
    required this.reciterCode,
  });

  final int requestId;
  final int surah;
  final int ayah;
  final String reciterCode;

  @override
  bool operator ==(Object other) {
    return other is _ReadingAudioProgressSource &&
        other.requestId == requestId &&
        other.surah == surah &&
        other.ayah == ayah &&
        other.reciterCode == reciterCode;
  }

  @override
  int get hashCode => Object.hash(requestId, surah, ayah, reciterCode);
}

class _ReadingAudioSequenceItem {
  const _ReadingAudioSequenceItem({
    required this.position,
    required this.fromOffline,
    required this.isDelay,
    required this.repeatOrdinal,
    required this.cycleOrdinal,
  });

  final QuranPosition position;
  final bool fromOffline;
  final bool isDelay;
  final int repeatOrdinal;
  final int cycleOrdinal;

  bool get isStream => !fromOffline && !isDelay;
}

class _PreparedReadingAudioSource {
  const _PreparedReadingAudioSource({required this.item, required this.source});

  final _ReadingAudioSequenceItem item;
  final ja.AudioSource source;
}

class _ReadingAudioPlanCursor {
  _ReadingAudioPlanCursor({
    required this.position,
    required this.repeatIndex,
    required this.cycleIndex,
    required this.exhausted,
  });

  QuranPosition position;
  int repeatIndex;
  int cycleIndex;
  bool exhausted;

  _ReadingAudioPlanCursor copy() {
    return _ReadingAudioPlanCursor(
      position: position,
      repeatIndex: repeatIndex,
      cycleIndex: cycleIndex,
      exhausted: exhausted,
    );
  }
}

class PlaybackInterval {
  const PlaybackInterval({required this.start, required this.end});

  final QuranPosition start;
  final QuranPosition end;

  bool get isValid => !end.isBefore(start);

  bool contains(QuranPosition position) {
    return !position.isBefore(start) && !position.isAfter(end);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'start': start.toJson(), 'end': end.toJson()};
  }

  static PlaybackInterval? fromJson(dynamic value) {
    if (value is! Map) return null;
    final QuranPosition? start = QuranPosition.fromJson(value['start']);
    final QuranPosition? end = QuranPosition.fromJson(value['end']);
    if (start == null || end == null) return null;
    final PlaybackInterval interval = PlaybackInterval(start: start, end: end);
    return interval.isValid ? interval : null;
  }
}

enum RepeatChoice {
  one(1, 'Once'),
  three(3, '3 times'),
  five(5, '5 times'),
  eleven(11, '11 times'),
  nineteen(19, '19 times'),
  infinite(null, 'Infinite');

  const RepeatChoice(this.count, this.label);

  final int? count;
  final String label;

  bool get isInfinite => count == null;

  int get storageValue => count ?? 0;

  String localizedLabel(AppLocalizations localizations) {
    final bool arabic = isArabicLocalizations(localizations);
    return switch (this) {
      RepeatChoice.one => arabic ? 'مرة واحدة' : label,
      RepeatChoice.three => arabic ? '3 مرات' : label,
      RepeatChoice.five => arabic ? '5 مرات' : label,
      RepeatChoice.eleven => arabic ? '11 مرة' : label,
      RepeatChoice.nineteen => arabic ? '19 مرة' : label,
      RepeatChoice.infinite => arabic ? 'بلا حد' : label,
    };
  }

  static RepeatChoice fromStorage(
    dynamic value, {
    required RepeatChoice fallback,
  }) {
    final int? count = _readInt(value);
    if (count == null) return fallback;
    return RepeatChoice.values.firstWhere(
      (RepeatChoice choice) => choice.storageValue == count,
      orElse: () => fallback,
    );
  }
}

enum _ReadingOptionsAction {
  goToAyah,
  shareCurrentAyah,
  translationLanguage,
  tafsirSources,
}

enum _ShareImageMode {
  story('Story 9:16', Size(1080, 1920)),
  square('Square 1:1', Size(1080, 1080)),
  classic('Classic', Size(1080, 1350));

  const _ShareImageMode(this.label, this.size);

  final String label;
  final Size size;
}

enum _ShareImageContentTier { compact, medium, long, veryLong }

class _ShareImageContentLayout {
  const _ShareImageContentLayout({
    required this.tier,
    required this.canvasPadding,
    required this.headerWidth,
    required this.headerGap,
    required this.compactHeader,
    required this.cardWidth,
    required this.cardHeight,
    required this.cardPadding,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.transliterationFontSize,
    required this.footerFontSize,
    required this.arabicGap,
    required this.translationDividerTopGap,
    required this.translationDividerBottomGap,
    required this.footerDividerTopGap,
    required this.footerDividerBottomGap,
    required this.scaleContentDown,
  });

  final _ShareImageContentTier tier;
  final EdgeInsets canvasPadding;
  final double headerWidth;
  final double headerGap;
  final bool compactHeader;
  final double cardWidth;
  final double cardHeight;
  final EdgeInsets cardPadding;
  final double arabicFontSize;
  final double translationFontSize;
  final double transliterationFontSize;
  final double footerFontSize;
  final double arabicGap;
  final double translationDividerTopGap;
  final double translationDividerBottomGap;
  final double footerDividerTopGap;
  final double footerDividerBottomGap;
  final bool scaleContentDown;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

enum ReadPageMode { normal, routine }

class ReadPage extends StatefulWidget {
  final int chapter;
  final bool juzMode;
  final int? startVerse;
  final ReadPageMode mode;
  final String? routineId;

  const ReadPage({
    super.key,
    required this.chapter,
    this.startVerse,
    this.juzMode = false,
    this.mode = ReadPageMode.normal,
    this.routineId,
  }) : assert(
         mode != ReadPageMode.routine || (routineId != null && routineId != ''),
       );

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> with WidgetsBindingObserver {
  static const MethodChannel _readPageChannel = MethodChannel(
    'com.app.equran/read_page',
  );
  static const String _frameRatePolicySource = 'read_page_player';
  static const String _readPagePointerSource = 'read_page_pointer';
  static const String _readPlayerDragSource = 'read_page_player_drag';
  static const String _readPlayerSeekSource = 'read_page_player_seek';
  static const String _readProgressScrubSource = 'read_page_progress_scrub';
  static const double _cardSwipeEdgeInset = 40;
  static const double _cardSwipeMinVelocity = 300;
  static const double _cardSwipeMinDistance = 82;
  static const double _cardSwipeAssistDistance = 46;
  static const double _cardSwipeAxisLockRatio = 1.18;
  static const double _playerBarMinimizeDistance = 44;
  bool get _isRoutineReading =>
      widget.mode == ReadPageMode.routine &&
      widget.routineId?.isNotEmpty == true;
  static const double _playerBarExpandDistance = 34;
  static const double _playerBarDismissDistance = 52;
  static const double _playerBarMinVelocity = 220;
  static const double _ayahDetailsArabicFontSize = 31.0;
  static const String _ayahDelaySettingsKey = 'ayahDelaySeconds';
  static const List<double> _delaySteps = <double>[
    0.0,
    0.5,
    1.0,
    2.0,
    3.0,
    4.0,
    5.0,
    6.0,
    7.0,
    8.0,
    9.0,
    10.0,
  ];
  static const String _intervalRepeatSettingsKey = 'intervalRepeatCount';
  static const String _repeatAyahSettingsKey = 'repeatAyahCount';
  static const String _playbackIntervalSettingsKey = 'playbackInterval';
  static const Duration _expandedPlayerProgressTickInterval = Duration(
    milliseconds: 33,
  );
  static const Duration _readingTimeFlushInterval = Duration(seconds: 20);
  int? _loadedChapter;
  int? _loadedVerse;
  static const Duration _lowRefreshIdleDelay = Duration(milliseconds: 900);
  static const Duration _playerSettleAnimationDelay = Duration(
    milliseconds: 280,
  );
  static const Duration _audioBufferingReconnectDelay = Duration(seconds: 5);
  static const Duration _audioReconnectDelay = Duration(seconds: 3);
  static const Duration _audioReconnectMaxDuration = Duration(seconds: 30);
  static const Duration _audioReconnectAttemptTimeout = Duration(seconds: 5);
  static const int _audioReconnectMaxAttempts = 10;
  static const int _readingAudioInitialBatchSize = 10;
  static const int _readingAudioAppendBatchSize = 10;
  static const int _readingAudioAppendThreshold = 4;

  final ja.AudioPlayer _versePlayer = ja.AudioPlayer();
  late int _currentVerse;
  late int _currentChapter;
  late ScrollController _scrollController;
  late int _totalVerses;
  late FocusNode _pageFocusNode;
  late bool _viewMode;
  bool _hasSavedOnExit = false;
  bool _playerVisible = false;
  bool _playerMounted = false;
  bool _playerMinimized = false;
  bool _playerMinimizedSettled = false;
  bool _isVersePlaying = false;
  bool _isVerseLoading = false;
  bool _isStartingVersePlayback = false;
  bool _isAttemptingAudioReconnect = false;
  bool _currentVerseSourceIsStream = false;
  bool _isReadingAudioDelaySource = false;
  bool _isExtendingReadingAudioSequence = false;
  Future<void>? _readingAudioSequenceExtensionFuture;
  bool _isReadPageForeground = true;
  bool _isDownloadingSurahAyahs = false;
  final Set<String> _downloadingAyahKeys = <String>{};
  bool _hasDownloadedSurahAyahs = false;
  bool _hasDownloadedCurrentAyah = false;
  static const String _sleepTimerDurationMode = 'duration';
  static const String _sleepTimerEndSurahMode = 'endSurah';

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndsAt;
  String? _sleepTimerLabel;
  String? _sleepTimerMode;
  bool _continuousPlayback = false;
  bool _repeatIntervalEnabled = false;
  PlaybackInterval? _playbackInterval;
  RepeatChoice _intervalRepeatChoice = RepeatChoice.infinite;
  RepeatChoice _repeatAyahChoice = RepeatChoice.one;
  double _ayahDelaySeconds = 0.0;
  int _intervalCyclesCompleted = 0;
  int _currentAyahPlayCount = 1;
  final Set<String> _preloadingAyahKeys = <String>{};
  int _playbackRequestId = 0;
  int _visibleProgressRequestId = 0;
  _ReadingAudioProgressSource? _activeProgressSource;
  _ReadingAudioProgressSource? _visibleProgressSource;
  bool _isHandlingVerseCompletion = false;
  int? _playingVerse;
  Duration _playerPosition = Duration.zero;
  Duration _playerDuration = Duration.zero;
  double _currentVersePlaybackRate = 1.0;
  final ValueNotifier<Duration> _playerPositionValue = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<double?> _surahDownloadProgressNotifier =
      ValueNotifier<double?>(null);
  final ValueNotifier<Duration> _playerDurationValue = ValueNotifier<Duration>(
    Duration.zero,
  );
  StreamSubscription<Duration>? _playerPositionSubscription;
  StreamSubscription<Duration?>? _playerDurationSubscription;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _playerIndexSubscription;
  StreamSubscription<ja.PlayerException>? _playerErrorSubscription;
  Timer? _pageScrollProgressTimer;
  Timer? _inlineVerseHighlightTimer;
  Timer? _lowRefreshIdleTimer;
  Timer? _playerSettleTimer;
  Timer? _bottomPlayerProgressTicker;
  Timer? _readingTimeFlushTimer;
  Timer? _audioBufferingRetryTimer;
  DateTime? _readingTimeActiveSince;
  Future<void> _readingTimeWriteChain = Future<void>.value();
  DateTime? _playerPositionSampledAt;
  bool _isPreparingReadingAudioSource = false;
  bool _readingAudioSequenceActive = false;
  int _readingAudioSequenceRequestId = 0;
  int _readingAudioSequenceMutationId = 0;
  int? _activeReadingAudioSequenceIndex;
  final List<_ReadingAudioSequenceItem> _readingAudioSequence =
      <_ReadingAudioSequenceItem>[];
  _ReadingAudioPlanCursor? _readingAudioPlanCursor;
  final GlobalKey _pageViewViewportKey = GlobalKey();
  final GlobalKey _inlineSurahTextKey = GlobalKey();
  List<int>? _verseTextCumulativeLengths;
  int _verseTextTotalLength = 0;
  String? _inlineSurahTextCache;
  int? _selectedInlineVerse;
  bool _isProgrammaticPageScroll = false;
  bool _isScrubbingProgress = false;
  bool _isPreparingShareImage = false;
  _ShareImageMode _shareImageMode = _ShareImageMode.story;
  bool _isBottomPlayerSeeking = false;
  int _progressVisualBlockCount = 0;
  int? _scrubStartVerse;
  double? _scrubStartDx;
  double? _scrubStartDy;
  double _scrubPrecision = 1.0;
  double? _cardSwipeStartX;
  double _cardSwipeDistance = 0;
  double _cardSwipeVerticalDistance = 0;
  double _playerBarDragDistance = 0;
  double _playerCollapseProgress = 0;
  double _playerBarDragStartProgress = 0;
  bool _isDraggingPlayerBar = false;
  bool _isPlayerGestureActive = false;
  bool _isPlayerSettleAnimating = false;
  bool _lowRefreshRequested = false;
  int _lowRefreshAnimationBlockCount = 0;
  int _activePointerCount = 0;
  int? _transliterationChapter;
  List<String> _chapterTransliterations = const <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewMode = SettingsDB().get("viewMode", defaultValue: true);

    _scrollController = ScrollController();
    _currentChapter = widget.chapter;
    _currentVerse = widget.startVerse is int ? widget.startVerse! : 1;
    _loadPlaybackOptions();
    _isDownloadingSurahAyahs = AudioDownloadService()
        .isSurahAyahsDownloadInProgress(_currentChapter);
    unawaited(_refreshSurahAyahDownloadState());
    unawaited(_refreshCurrentAyahDownloadState());
    _pageFocusNode = FocusNode(debugLabel: 'Read Page Keyboard Focus');
    _getTotalVerses();
    unawaited(_loadChapterTransliterations());
    _bindVersePlayer();
    _startReadingTimeTracking();
    if (!_viewMode && _currentVerse > 1) {
      unawaited(
        _scrollToInlineVerse(_currentVerse, animate: false, highlight: true),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markReadingAudioStoppedForExit();
    _pauseReadingTimeTracking(flush: true);
    if (!_hasSavedOnExit) {
      _syncCurrentVerseWithVisibleText();
      if (_isRoutineReading) {
        unawaited(_refreshCurrentAyahDownloadState());
      } else {
        BookmarkDB().addReadingEntry(_currentChapter, _currentVerse);
      }
    }
    _sleepTimer?.cancel();
    unawaited(_setKeepScreenOn(false));
    _lowRefreshIdleTimer?.cancel();
    _playerSettleTimer?.cancel();
    _stopBottomPlayerProgressTicker('dispose');
    _readingTimeFlushTimer?.cancel();
    _audioBufferingRetryTimer?.cancel();
    FrameRatePolicyManager.instance.setPlayerDisposed(
      true,
      reason: 'read_player_disposed',
    );
    FrameRatePolicyManager.instance.resetSource(
      _frameRatePolicySource,
      reason: 'read_player_disposed',
    );
    FrameRatePolicyManager.instance.setPointerActive(
      false,
      source: _readPagePointerSource,
      reason: 'read_page_disposed',
    );
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readPlayerDragSource,
      reason: 'read_player_disposed',
    );
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readPlayerSeekSource,
      reason: 'read_player_disposed',
    );
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readProgressScrubSource,
      reason: 'read_player_disposed',
    );
    FrameRatePolicyManager.instance.setPlayerDisposed(
      false,
      reason: 'read_player_dispose_complete',
    );
    unawaited(
      AndroidAudioDisplayMode.clearStaticMinimizedAudioRefreshRate(force: true),
    );
    unawaited(AndroidAudioDisplayMode.setIdleAudioFrameRateEnabled(true));
    unawaited(AndroidAudioDisplayMode.setVisualProgressActive(false));
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
    unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));
    _playerPositionSubscription?.cancel();
    _playerDurationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _playerIndexSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _pageScrollProgressTimer?.cancel();
    _inlineVerseHighlightTimer?.cancel();
    _versePlayer.dispose();
    _playerPositionValue.dispose();
    _playerDurationValue.dispose();
    _surahDownloadProgressNotifier.dispose();
    _scrollController.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  void _markReadingAudioStoppedForExit() {
    _playbackRequestId++;
    _visibleProgressRequestId = _playbackRequestId;
    _activeProgressSource = null;
    _visibleProgressSource = null;
    _isPreparingReadingAudioSource = false;
    _audioBufferingRetryTimer?.cancel();
    _isAttemptingAudioReconnect = false;
    _currentVerseSourceIsStream = false;
    _clearReadingAudioSequenceState();
    _isStartingVersePlayback = false;
    _isVersePlaying = false;
    _isVerseLoading = false;
    _playerVisible = false;
    _playerMinimized = false;
    _playerMinimizedSettled = false;
    _playerCollapseProgress = 0;
    _isDraggingPlayerBar = false;
    _continuousPlayback = false;
    _repeatIntervalEnabled = false;
    _playingVerse = null;
    _playerPosition = Duration.zero;
    _playerDuration = Duration.zero;
    _playerPositionSampledAt = null;
    if (_playerPositionValue.value != Duration.zero) {
      _playerPositionValue.value = Duration.zero;
    }
    if (_playerDurationValue.value != Duration.zero) {
      _playerDurationValue.value = Duration.zero;
    }
  }

  Future<void> _stopReadingAudioForRouteExit() async {
    _markReadingAudioStoppedForExit();
    _syncReadingTimeTracking();
    _syncBottomPlayerProgressPolicy();
    try {
      await _versePlayer.stop();
    } catch (_) {
      // The page may already be disposing; disposal also releases the player.
    }
    await AndroidAudioDisplayMode.setAudioPlaybackActive(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isReadPageForeground = true;
      _syncReadingTimeTracking();
      FrameRatePolicyManager.instance.setAppLifecyclePaused(
        false,
        reason: 'read_page_resumed',
      );
      unawaited(_syncReadingAudioStateFromPlayer());
      _syncReadingPlayerRefreshMode(
        'read page resumed',
        scheduleLowRefresh: true,
      );
      _syncFrameRatePolicy('read_page_resumed');
      return;
    }

    _isReadPageForeground = false;
    _pauseReadingTimeTracking(flush: true);
    FrameRatePolicyManager.instance.setAppLifecyclePaused(
      true,
      reason: 'read_page_lifecycle_paused',
    );
    _pageScrollProgressTimer?.cancel();
    _inlineVerseHighlightTimer?.cancel();
    _playerSettleTimer?.cancel();
    _activePointerCount = 0;
    _isPlayerGestureActive = false;
    _isPlayerSettleAnimating = false;
    _isDraggingPlayerBar = false;
    _syncBottomPlayerProgressPolicy();
    _syncFrameRatePolicy('read_page_lifecycle_paused');
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
    unawaited(AndroidAudioDisplayMode.setVisualProgressActive(false));
  }

  void _notifyAudioUserActivity() {
    AndroidAudioDisplayMode.notifyUserActivity();
    _syncReadingPlayerRefreshMode('user activity', scheduleLowRefresh: true);
  }

  void _syncFrameRatePolicy(String reason) {
    if (!mounted) {
      FrameRatePolicyManager.instance.resetSource(
        _frameRatePolicySource,
        reason: 'read page unmounted',
      );
      return;
    }

    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final bool routeCurrent = route?.isCurrent ?? true;
    final bool pageVisible = _isReadPageForeground && routeCurrent;
    final bool expandedPlayerVisible =
        pageVisible &&
        _playerMounted &&
        _playerVisible &&
        !_playerMinimized &&
        !_playerMinimizedSettled &&
        _progressVisualBlockCount == 0;
    final bool miniPlayerVisible =
        pageVisible &&
        _playerMounted &&
        _playerVisible &&
        _playerMinimized &&
        _playerMinimizedSettled;

    FrameRatePolicyManager.instance.updatePlaybackSurface(
      source: _frameRatePolicySource,
      audioPlaying: _isVersePlaying,
      expandedPlayerVisible: expandedPlayerVisible,
      miniPlayerVisible: miniPlayerVisible,
      reason: reason,
    );
  }

  void _startReadingTimeTracking() {
    _readingTimeFlushTimer ??= Timer.periodic(
      _readingTimeFlushInterval,
      (_) => _syncReadingTimeTracking(flush: true),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncReadingTimeTracking();
    });
  }

  bool get _shouldTrackReadingTime {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    return mounted &&
        _isReadPageForeground &&
        (route?.isCurrent ?? true) &&
        !_isVersePlaying &&
        !_isVerseLoading;
  }

  void _syncReadingTimeTracking({bool flush = false}) {
    final DateTime now = DateTime.now();
    if (!_shouldTrackReadingTime) {
      _pauseReadingTimeTracking(flush: true, now: now);
      return;
    }

    _readingTimeActiveSince ??= now;
    if (flush) {
      _flushReadingTime(now: now);
    }
  }

  void _pauseReadingTimeTracking({required bool flush, DateTime? now}) {
    if (flush) {
      _flushReadingTime(now: now ?? DateTime.now());
    }
    _readingTimeActiveSince = null;
  }

  void _flushReadingTime({DateTime? now}) {
    final DateTime effectiveNow = now ?? DateTime.now();
    final DateTime? activeSince = _readingTimeActiveSince;
    if (activeSince == null) return;

    final int seconds = effectiveNow.difference(activeSince).inSeconds;
    _readingTimeActiveSince = effectiveNow;
    if (seconds <= 0) return;

    _readingTimeWriteChain = _readingTimeWriteChain.then(
      (_) => _recordReadingTime(seconds, now: effectiveNow),
    );
    unawaited(_readingTimeWriteChain);
  }

  Future<void> _recordReadingTime(int seconds, {required DateTime now}) async {
    if (seconds <= 0) return;

    final String todayKey = _readingDateKey(now);
    final dynamic existingActivity = QuranActivityDB().get(todayKey);
    final QuranActivityDay activity = existingActivity is QuranActivityDay
        ? existingActivity
        : QuranActivityDay(dateKey: todayKey, updatedAt: now);

    await QuranActivityDB().put(
      todayKey,
      QuranActivityDay(
        dateKey: todayKey,
        ayahsRead: activity.ayahsRead,
        pagesRead: activity.pagesRead,
        listeningSeconds: activity.listeningSeconds,
        readingSeconds: activity.readingSeconds + seconds,
        readAyahKeys: activity.readAyahKeys,
        updatedAt: now,
        schemaVersion: activity.schemaVersion,
      ),
    );

    final dynamic existingStats = QuranStatsDB().get('summary');
    final QuranStatsSnapshot stats = existingStats is QuranStatsSnapshot
        ? existingStats
        : QuranStatsSnapshot(id: 'summary', updatedAt: now);
    await QuranStatsDB().put(
      'summary',
      QuranStatsSnapshot(
        id: 'summary',
        totalAyahsRead: stats.totalAyahsRead,
        estimatedLettersRead: stats.estimatedLettersRead,
        listeningSeconds: stats.listeningSeconds,
        totalReadingSeconds: stats.totalReadingSeconds + seconds,
        currentStreak: stats.currentStreak,
        updatedAt: now,
        schemaVersion: stats.schemaVersion,
      ),
    );
  }

  void _syncReadingPlayerRefreshMode(
    String reason, {
    bool forceLowRefresh = false,
    bool scheduleLowRefresh = false,
  }) {
    assert(reason.isNotEmpty);
    if (_shouldRequestLowRefresh) {
      if (scheduleLowRefresh) {
        _scheduleLowRefreshAfterIdle();
      } else {
        _requestLowRefreshIfEligible(force: forceLowRefresh);
      }
      return;
    }

    _clearLowRefreshForInteraction(force: forceLowRefresh);
  }

  void _handleReadPagePointerDown(PointerDownEvent event) {
    _activePointerCount++;
    FrameRatePolicyManager.instance.setPointerActive(
      true,
      source: _readPagePointerSource,
      reason: 'read_page_pointer_down',
    );
    _syncReadingPlayerRefreshMode('page pointer down', forceLowRefresh: true);
    AndroidAudioDisplayMode.notifyUserActivity();
  }

  void _handleReadPagePointerMove(PointerMoveEvent event) {
    _syncReadingPlayerRefreshMode('page pointer move');
    AndroidAudioDisplayMode.notifyUserActivity();
  }

  void _handleReadPagePointerUp(PointerUpEvent event) {
    if (_activePointerCount > 0) {
      _activePointerCount--;
    }
    FrameRatePolicyManager.instance.setPointerActive(
      _activePointerCount > 0,
      source: _readPagePointerSource,
      reason: 'read_page_pointer_up',
    );
    AndroidAudioDisplayMode.notifyUserActivity();
    _syncReadingPlayerRefreshMode('page pointer up', scheduleLowRefresh: true);
  }

  void _handleReadPagePointerCancel(PointerCancelEvent event) {
    if (_activePointerCount > 0) {
      _activePointerCount--;
    }
    FrameRatePolicyManager.instance.setPointerActive(
      _activePointerCount > 0,
      source: _readPagePointerSource,
      reason: 'read_page_pointer_cancel',
    );
    AndroidAudioDisplayMode.notifyUserActivity();
    _syncReadingPlayerRefreshMode(
      'page pointer cancel',
      scheduleLowRefresh: true,
    );
  }

  void _handleReadPagePointerSignal(PointerSignalEvent event) {
    _syncReadingPlayerRefreshMode('page pointer signal', forceLowRefresh: true);
    AndroidAudioDisplayMode.notifyUserActivity();
    _syncReadingPlayerRefreshMode(
      'page pointer signal idle',
      scheduleLowRefresh: true,
    );
  }

  bool get _shouldRequestLowRefresh {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    return mounted &&
        _isReadPageForeground &&
        _playerMounted &&
        _playerVisible &&
        _playerMinimized &&
        _playerMinimizedSettled &&
        _activePointerCount == 0 &&
        !_isDraggingPlayerBar &&
        !_isPlayerGestureActive &&
        !_isPlayerSettleAnimating &&
        !_isProgrammaticPageScroll &&
        !_isBottomPlayerSeeking &&
        !_isScrubbingProgress &&
        _lowRefreshAnimationBlockCount == 0 &&
        _progressVisualBlockCount == 0 &&
        (route?.isCurrent ?? true);
  }

  void _requestLowRefreshIfEligible({bool force = false}) {
    _lowRefreshIdleTimer?.cancel();
    _lowRefreshIdleTimer = null;

    if (!_shouldRequestLowRefresh) {
      _clearLowRefreshForInteraction();
      return;
    }

    if (_lowRefreshRequested && !force) return;
    _lowRefreshRequested = true;
    FrameRatePolicyManager.debugLogMiniPlayerStatic(owner: 'read_page');
    _syncFrameRatePolicy(
      force
          ? 'static_minimized_player_force_evaluated'
          : 'static_minimized_player_idle',
    );
  }

  void _clearLowRefreshForInteraction({bool force = false}) {
    _lowRefreshIdleTimer?.cancel();
    _lowRefreshIdleTimer = null;
    if (!_lowRefreshRequested && !force) return;

    _lowRefreshRequested = false;
    unawaited(
      AndroidAudioDisplayMode.clearStaticMinimizedAudioRefreshRate(
        force: force,
      ),
    );
  }

  void _scheduleLowRefreshAfterIdle() {
    _lowRefreshIdleTimer?.cancel();
    _lowRefreshIdleTimer = null;
    if (!_shouldRequestLowRefresh) return;

    _lowRefreshIdleTimer = Timer(_lowRefreshIdleDelay, () {
      if (!mounted) return;
      _requestLowRefreshIfEligible();
    });
  }

  void _beginLowRefreshAnimationBlock() {
    _lowRefreshAnimationBlockCount++;
    _clearLowRefreshForInteraction(force: true);
  }

  void _endLowRefreshAnimationBlock() {
    if (_lowRefreshAnimationBlockCount > 0) {
      _lowRefreshAnimationBlockCount--;
    }
    _syncReadingPlayerRefreshMode(
      'auto-advance animation complete',
      scheduleLowRefresh: true,
    );
  }

  void _beginPlayerInteraction(String reason) {
    _playerSettleTimer?.cancel();
    _playerSettleTimer = null;
    _isPlayerGestureActive = true;
    _isPlayerSettleAnimating = false;
    FrameRatePolicyManager.instance.setUserDragging(
      true,
      source: _readPlayerDragSource,
      reason: reason,
    );
    AndroidAudioDisplayMode.notifyUserActivity();
    _syncReadingPlayerRefreshMode(reason, forceLowRefresh: true);
  }

  void _endPlayerInteraction(String reason) {
    if (!_isPlayerGestureActive) return;
    _isPlayerGestureActive = false;
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readPlayerDragSource,
      reason: reason,
    );
    _syncReadingPlayerRefreshMode(reason, scheduleLowRefresh: true);
  }

  void _beginPlayerSettleAnimation(String reason) {
    _playerSettleTimer?.cancel();
    _isPlayerGestureActive = false;
    _isPlayerSettleAnimating = true;
    FrameRatePolicyManager.instance.setUserDragging(
      true,
      source: _readPlayerDragSource,
      reason: reason,
    );
    _syncReadingPlayerRefreshMode(reason, forceLowRefresh: true);
    _playerSettleTimer = Timer(_playerSettleAnimationDelay, () {
      if (!mounted) return;
      _finishPlayerSettleAnimation('$reason fallback complete');
    });
  }

  void _finishPlayerSettleAnimation(String reason) {
    _playerSettleTimer?.cancel();
    _playerSettleTimer = null;
    _isPlayerGestureActive = false;
    _isPlayerSettleAnimating = false;
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readPlayerDragSource,
      reason: reason,
    );
    if (mounted &&
        _playerMinimized &&
        _playerCollapseProgress >= 1 &&
        !_playerMinimizedSettled) {
      setState(() {
        _playerMinimizedSettled = true;
      });
    }
    _syncReadingPlayerRefreshMode(reason, scheduleLowRefresh: true);
  }

  void _handlePlayerBarPointerDown(PointerDownEvent event) {
    _beginPlayerInteraction('player pointer down');
  }

  void _handlePlayerBarPointerUp(PointerUpEvent event) {
    if (!_isDraggingPlayerBar) {
      _endPlayerInteraction('player pointer up');
    }
  }

  void _handlePlayerBarPointerCancel(PointerCancelEvent event) {
    _isDraggingPlayerBar = false;
    _endPlayerInteraction('player pointer cancel');
  }

  Future<T> _withLowFpsSuppressed<T>(Future<T> Function() action) async {
    AndroidAudioDisplayMode.notifyUserActivity();
    _pushProgressVisualBlock();
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(true));
    try {
      return await action();
    } finally {
      _popProgressVisualBlock();
      unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
    }
  }

  void _pushProgressVisualBlock() {
    _syncReadingPlayerRefreshMode(
      'visual overlay opened',
      forceLowRefresh: true,
    );
    _progressVisualBlockCount++;
    FrameRatePolicyManager.instance.setModalOpen(
      true,
      reason: 'read_modal_open',
    );
    _syncBottomPlayerProgressPolicy();
  }

  void _popProgressVisualBlock() {
    if (_progressVisualBlockCount > 0) {
      _progressVisualBlockCount--;
    }
    if (_progressVisualBlockCount == 0) {
      FrameRatePolicyManager.instance.setModalOpen(
        false,
        reason: 'read_modal_closed',
      );
    }
    _syncBottomPlayerProgressPolicy(syncPosition: true);
    _syncReadingPlayerRefreshMode(
      'visual overlay closed',
      scheduleLowRefresh: true,
    );
  }

  void _handleCardVisualOverlayChanged(bool visible) {
    if (visible) {
      _pushProgressVisualBlock();
    } else {
      _popProgressVisualBlock();
    }
  }

  bool get _shouldRenderLivePlayerProgress {
    // This is the single gate for audio-position driven UI. Minimized/static
    // mode still receives audio ticks, but they only update _playerPosition.
    if (!mounted) return false;
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    return _isReadPageForeground &&
        (route?.isCurrent ?? true) &&
        _playerMounted &&
        _playerVisible &&
        !_playerMinimized &&
        !_playerMinimizedSettled &&
        _progressVisualBlockCount == 0;
  }

  bool get _shouldAnimateBottomPlayerProgress {
    return _shouldRenderLivePlayerProgress &&
        _isVersePlaying &&
        !_isVerseLoading &&
        !_isBottomPlayerSeeking;
  }

  bool get _shouldRunBottomPlayerProgressTicker {
    return _shouldAnimateBottomPlayerProgress;
  }

  String get _bottomPlayerProgressMode {
    if (!_isReadPageForeground) return 'hidden';
    if (!mounted) return 'disposed';
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (!(route?.isCurrent ?? true)) return 'covered';
    if (_isBottomPlayerSeeking || _isScrubbingProgress) return 'dragging';
    if (_playerMinimized || _playerMinimizedSettled) return 'minimized';
    return 'expanded';
  }

  void _syncBottomPlayerProgressPolicy({bool syncPosition = false}) {
    if (!mounted) return;

    // Progress drawing is capped with _bottomPlayerProgressTicker. Android
    // refresh hints are evaluated separately by FrameRatePolicyManager.
    unawaited(AndroidAudioDisplayMode.setVisualProgressActive(false));
    _syncFrameRatePolicy('read_player_progress_policy');

    if (_shouldRunBottomPlayerProgressTicker) {
      _startBottomPlayerProgressTicker();
    } else {
      _stopBottomPlayerProgressTicker('policy stopped');
    }

    if (syncPosition && _shouldRenderLivePlayerProgress) {
      _syncBottomPlayerProgressValue();
      _syncBottomPlayerDurationValue();
    }
  }

  void _syncBottomPlayerProgressValue() {
    if (!mounted || !_shouldRenderLivePlayerProgress) return;
    final Duration position = _estimatedBottomPlayerPosition();
    _setVisiblePlayerPosition(position);
  }

  void _syncBottomPlayerDurationValue() {
    if (!mounted || !_shouldRenderLivePlayerProgress) return;
    _setVisiblePlayerDuration(_playerDuration);
  }

  void _setPlayerPosition(
    Duration position, {
    bool render = false,
    bool allowBackward = false,
    bool fromPlayerStream = false,
    bool canEstimateFromSample = true,
  }) {
    final Duration normalizedPosition = position < Duration.zero
        ? Duration.zero
        : position;
    if (fromPlayerStream &&
        !allowBackward &&
        _shouldGuardVisibleProgressBackwards) {
      if (_isPreparingReadingAudioSource &&
          _playerPositionValue.value == Duration.zero &&
          normalizedPosition > Duration.zero) {
        return;
      }
      if (normalizedPosition == Duration.zero &&
          _playerPositionValue.value > Duration.zero) {
        return;
      }
      if (normalizedPosition < _playerPositionValue.value) {
        return;
      }
    }
    _playerPosition = normalizedPosition;
    _playerPositionSampledAt = canEstimateFromSample ? DateTime.now() : null;
    if (render ||
        (_shouldRenderLivePlayerProgress &&
            !_shouldRunBottomPlayerProgressTicker)) {
      _setVisiblePlayerPosition(
        normalizedPosition,
        allowBackward: allowBackward,
        fromPlayerStream: fromPlayerStream,
      );
    }
  }

  void _setPlayerDuration(Duration duration, {bool allowReset = false}) {
    final Duration normalizedDuration = duration < Duration.zero
        ? Duration.zero
        : duration;
    if (!allowReset &&
        _isPreparingReadingAudioSource &&
        normalizedDuration > Duration.zero &&
        _shouldGuardVisibleProgressBackwards) {
      return;
    }
    if (!allowReset &&
        normalizedDuration == Duration.zero &&
        _playerDuration > Duration.zero &&
        _shouldGuardVisibleProgressBackwards) {
      return;
    }

    _playerDuration = normalizedDuration;
    if (_shouldRenderLivePlayerProgress) {
      _setVisiblePlayerDuration(normalizedDuration, allowReset: allowReset);
    }
  }

  bool get _shouldGuardVisibleProgressBackwards {
    return _playerMounted &&
        _playingVerse != null &&
        !_isBottomPlayerSeeking &&
        !_isScrubbingProgress &&
        _activeProgressSource != null &&
        _activeProgressSource!.requestId == _playbackRequestId &&
        _visibleProgressSource == _activeProgressSource &&
        _visibleProgressRequestId == _playbackRequestId;
  }

  void _setVisiblePlayerPosition(
    Duration position, {
    bool allowBackward = false,
    bool fromPlayerStream = false,
  }) {
    final Duration currentPosition = _playerPositionValue.value;
    if (!allowBackward && _shouldGuardVisibleProgressBackwards) {
      if (fromPlayerStream &&
          _isPreparingReadingAudioSource &&
          currentPosition == Duration.zero &&
          position > Duration.zero) {
        return;
      }
      if (position < currentPosition) {
        return;
      }
    }
    if (currentPosition != position) {
      _playerPositionValue.value = position;
    }
  }

  void _setVisiblePlayerDuration(Duration duration, {bool allowReset = false}) {
    if (!allowReset &&
        duration == Duration.zero &&
        _playerDurationValue.value > Duration.zero &&
        _shouldGuardVisibleProgressBackwards) {
      return;
    }
    if (_playerDurationValue.value != duration) {
      _playerDurationValue.value = duration;
    }
  }

  void _resetVisiblePlayerProgressForRequest(int requestId) {
    _visibleProgressRequestId = requestId;
    _activeProgressSource = null;
    _visibleProgressSource = null;
    _isPreparingReadingAudioSource = false;
    _playerPosition = Duration.zero;
    _playerDuration = Duration.zero;
    _playerPositionSampledAt = null;
    _playerPositionValue.value = Duration.zero;
    _playerDurationValue.value = Duration.zero;
  }

  _ReadingAudioProgressSource _progressSourceFor({
    required int requestId,
    required int surah,
    required int ayah,
  }) {
    return _ReadingAudioProgressSource(
      requestId: requestId,
      surah: surah,
      ayah: ayah,
      reciterCode: QuranAudioService().selectedReciter.code,
    );
  }

  void _beginNewReadingAudioSource(_ReadingAudioProgressSource source) {
    _stopBottomPlayerProgressTicker('new reading audio source');
    _activeProgressSource = source;
    _visibleProgressSource = source;
    _visibleProgressRequestId = source.requestId;
    _isPreparingReadingAudioSource = true;
    _playerPosition = Duration.zero;
    _playerDuration = Duration.zero;
    _playerPositionSampledAt = null;
    if (_playerPositionValue.value != Duration.zero) {
      _playerPositionValue.value = Duration.zero;
    }
    if (_playerDurationValue.value != Duration.zero) {
      _playerDurationValue.value = Duration.zero;
    }
  }

  void _markReadingAudioSourceReady(
    _ReadingAudioProgressSource source, {
    required Duration position,
    Duration? duration,
  }) {
    if (_activeProgressSource != source) return;
    _isPreparingReadingAudioSource = false;
    if (duration != null) {
      _setPlayerDuration(duration, allowReset: true);
    }
    _setPlayerPosition(
      position,
      render: true,
      allowBackward: true,
      canEstimateFromSample: false,
    );
    _syncBottomPlayerProgressPolicy(syncPosition: true);
  }

  void _startBottomPlayerProgressTicker() {
    if (_bottomPlayerProgressTicker != null) return;
    _logBottomPlayerProgressTicker(
      'started expanded reading progress ticker '
      'interval=${_expandedPlayerProgressTickInterval.inMilliseconds}ms '
      'mode=$_bottomPlayerProgressMode',
    );
    FrameRatePolicyManager.debugLogExpandedProgressTicker(
      owner: 'read_page',
      interval: _expandedPlayerProgressTickInterval,
    );
    final int requestId = _playbackRequestId;
    _bottomPlayerProgressTicker = Timer.periodic(
      _expandedPlayerProgressTickInterval,
      (_) => _tickBottomPlayerProgress(requestId),
    );
  }

  void _stopBottomPlayerProgressTicker(String reason) {
    final Timer? ticker = _bottomPlayerProgressTicker;
    if (ticker == null) return;
    ticker.cancel();
    _bottomPlayerProgressTicker = null;
    _logBottomPlayerProgressTicker(
      'stopped expanded reading progress ticker ($reason) '
      'mode=$_bottomPlayerProgressMode',
    );
  }

  void _tickBottomPlayerProgress(int requestId) {
    if (requestId != _playbackRequestId) {
      _stopBottomPlayerProgressTicker('playback request changed');
      return;
    }
    if (!_shouldRunBottomPlayerProgressTicker) {
      _stopBottomPlayerProgressTicker('tick found inactive');
      return;
    }

    _syncBottomPlayerProgressValue();
    _syncBottomPlayerDurationValue();
  }

  Duration _estimatedBottomPlayerPosition() {
    final DateTime? sampledAt = _playerPositionSampledAt;
    Duration position = _playerPosition;
    if (_isVersePlaying &&
        !_isVerseLoading &&
        !_isBottomPlayerSeeking &&
        sampledAt != null) {
      final Duration elapsed = DateTime.now().difference(sampledAt);
      final int elapsedMicros =
          (elapsed.inMicroseconds * _currentVersePlaybackRate).round();
      position += Duration(microseconds: elapsedMicros);
    }
    if (_playerDuration > Duration.zero && position > _playerDuration) {
      return _playerDuration;
    }
    if (position < Duration.zero) return Duration.zero;
    return position;
  }

  void _logBottomPlayerProgressTicker(String message) {
    if (!kDebugMode) return;
    debugPrint('ReadPage: $message');
  }

  void _syncPageProgressFromScroll() {
    if (_viewMode ||
        !_scrollController.hasClients ||
        _isProgrammaticPageScroll) {
      return;
    }

    _pageScrollProgressTimer?.cancel();
    _pageScrollProgressTimer = Timer(const Duration(milliseconds: 80), () {
      if (!mounted || _viewMode || _isProgrammaticPageScroll) return;
      final int visibleVerse = _verseForCurrentScrollOffset();
      if (visibleVerse == _currentVerse) return;
      _currentVerse = visibleVerse;
      _updateDB();
    });
  }

  void _ensureVerseTextMetrics() {
    if (_verseTextCumulativeLengths != null) return;

    _inlineSurahText();
  }

  String _inlineSurahText() {
    final String? cachedText = _inlineSurahTextCache;
    if (cachedText != null) return cachedText;

    final StringBuffer buffer = StringBuffer();
    final List<int> lengths = <int>[0];
    int total = 0;
    for (int verse = 1; verse <= _totalVerses; verse++) {
      final String segment = _inlineVerseTextSegment(verse);
      buffer.write(segment);
      total += segment.length;
      lengths.add(total);
    }

    _verseTextCumulativeLengths = lengths;
    _verseTextTotalLength = total;
    _inlineSurahTextCache = buffer.toString();
    return _inlineSurahTextCache!;
  }

  void _clearVerseTextMetrics() {
    _verseTextCumulativeLengths = null;
    _verseTextTotalLength = 0;
    _inlineSurahTextCache = null;
  }

  Future<void> _loadChapterTransliterations() async {
    final int chapter = _currentChapter;
    final List<String> transliterations = await QuranTransliterationService
        .instance
        .versesForSurah(chapter);
    if (!mounted || chapter != _currentChapter) return;
    setState(() {
      _transliterationChapter = chapter;
      _chapterTransliterations = transliterations;
    });
  }

  String _transliterationForVerse(int verse) {
    if (_transliterationChapter != _currentChapter) return '';
    if (verse < 1 || verse > _chapterTransliterations.length) return '';
    return _chapterTransliterations[verse - 1].trim();
  }

  String _cardTransliterationForVerse(int verse) {
    final String cached = _transliterationForVerse(verse);
    if (cached.isNotEmpty) return cached;

    unawaited(_loadChapterTransliterations());
    return '';
  }

  int _verseForCurrentScrollOffset() {
    if (!_scrollController.hasClients) {
      return _currentVerse;
    }

    final BuildContext? textContext = _inlineSurahTextKey.currentContext;
    final BuildContext? viewportContext = _pageViewViewportKey.currentContext;
    final RenderObject? textRenderObject = textContext?.findRenderObject();
    final RenderObject? viewportRenderObject = viewportContext
        ?.findRenderObject();

    if (textRenderObject is RenderParagraph &&
        viewportRenderObject is RenderBox) {
      final Offset textGlobalTopLeft = textRenderObject.localToGlobal(
        Offset.zero,
      );
      final double viewportTop = viewportRenderObject
          .localToGlobal(Offset.zero)
          .dy;
      final double localY = (viewportTop + 24 - textGlobalTopLeft.dy)
          .clamp(0.0, textRenderObject.size.height)
          .toDouble();
      return _verseForLocalTextY(textRenderObject, localY);
    }

    _ensureVerseTextMetrics();
    final List<int> lengths = _verseTextCumulativeLengths ?? <int>[0];
    if (_verseTextTotalLength <= 0 || lengths.length <= 1) return _currentVerse;

    final ScrollPosition position = _scrollController.position;
    final double maxScrollExtent = position.maxScrollExtent;
    if (maxScrollExtent <= 0) return 1;

    final double scrollFraction = (position.pixels / maxScrollExtent).clamp(
      0.0,
      1.0,
    );
    final int targetLength = (_verseTextTotalLength * scrollFraction).round();

    int low = 1;
    int high = lengths.length - 1;
    while (low < high) {
      final int mid = (low + high) >> 1;
      if (lengths[mid] < targetLength) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low.clamp(1, _totalVerses).toInt();
  }

  void _syncCurrentVerseWithVisibleText({bool persist = false}) {
    if (_viewMode) return;

    final int visibleVerse = _verseForCurrentScrollOffset();
    if (visibleVerse == _currentVerse) return;
    _currentVerse = visibleVerse;
    if (persist) {
      _updateDB();
    }
  }

  void _highlightInlineVerseBriefly(
    int verse, {
    Duration duration = const Duration(milliseconds: 1600),
  }) {
    if (_viewMode) return;
    if (verse < 1 || verse > _totalVerses) return;

    _inlineVerseHighlightTimer?.cancel();
    setState(() {
      _selectedInlineVerse = verse;
    });
    _inlineVerseHighlightTimer = Timer(duration, () {
      if (!mounted || _selectedInlineVerse != verse) return;
      setState(() {
        _selectedInlineVerse = null;
      });
    });
  }

  double _scrollOffsetForVerse(int verse) {
    if (!_scrollController.hasClients) return 0;

    final BuildContext? textContext = _inlineSurahTextKey.currentContext;
    final BuildContext? viewportContext = _pageViewViewportKey.currentContext;
    final RenderObject? textRenderObject = textContext?.findRenderObject();
    final RenderObject? viewportRenderObject = viewportContext
        ?.findRenderObject();

    final ScrollPosition position = _scrollController.position;
    if (textRenderObject is! RenderParagraph ||
        viewportRenderObject is! RenderBox) {
      return _estimatedScrollOffsetForVerse(verse);
    }

    final List<TextBox> boxes = _textBoxesForVerse(textRenderObject, verse);
    if (boxes.isEmpty) {
      return _estimatedScrollOffsetForVerse(verse);
    }

    final double verseTop = boxes.map((TextBox box) => box.top).reduce(min);
    final double verseGlobalY = textRenderObject
        .localToGlobal(Offset(0, verseTop))
        .dy;
    final double viewportTop = viewportRenderObject
        .localToGlobal(Offset.zero)
        .dy;

    return (position.pixels + verseGlobalY - viewportTop - 12)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
  }

  double _estimatedScrollOffsetForVerse(int verse) {
    _ensureVerseTextMetrics();
    final List<int> lengths = _verseTextCumulativeLengths ?? <int>[0];
    if (_verseTextTotalLength <= 0 || lengths.length <= 1) return 0;

    final int safeVerse = verse.clamp(1, _totalVerses).toInt();
    final int previousLength = lengths[safeVerse - 1];
    final double scrollFraction = previousLength / _verseTextTotalLength;
    final ScrollPosition position = _scrollController.position;
    return (position.maxScrollExtent * scrollFraction)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
  }

  ({int start, int end}) _textRangeForVerse(int verse) {
    _ensureVerseTextMetrics();
    final List<int> lengths = _verseTextCumulativeLengths ?? <int>[0];
    final int safeVerse = verse.clamp(1, _totalVerses).toInt();
    if (lengths.length <= safeVerse) return (start: 0, end: 0);

    final int start = (lengths[safeVerse - 1] + 1)
        .clamp(0, _verseTextTotalLength)
        .toInt();
    final int end = (lengths[safeVerse] - 3)
        .clamp(start, _verseTextTotalLength)
        .toInt();
    return (start: start, end: end);
  }

  List<TextBox> _textBoxesForVerse(RenderParagraph paragraph, int verse) {
    final range = _textRangeForVerse(verse);
    if (range.start >= range.end) return const <TextBox>[];

    return paragraph.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
  }

  int _verseForLocalTextY(RenderParagraph paragraph, double localY) {
    int closestVerse = 1;
    double closestTop = double.negativeInfinity;

    for (int verse = 1; verse <= _totalVerses; verse++) {
      final List<TextBox> boxes = _textBoxesForVerse(paragraph, verse);
      if (boxes.isEmpty) continue;

      for (final TextBox box in boxes) {
        if (localY >= box.top - 0.5 && localY <= box.bottom + 0.5) {
          return verse;
        }
      }

      final double verseTop = boxes.map((TextBox box) => box.top).reduce(min);
      if (verseTop <= localY && verseTop >= closestTop) {
        closestVerse = verse;
        closestTop = verseTop;
      } else if (verseTop > localY && closestTop.isFinite) {
        break;
      }
    }

    return closestVerse.clamp(1, _totalVerses).toInt();
  }

  int _verseForTextOffset(int textOffset) {
    _ensureVerseTextMetrics();
    final List<int> lengths = _verseTextCumulativeLengths ?? <int>[0];
    if (_verseTextTotalLength <= 0 || lengths.length <= 1) {
      return _currentVerse;
    }

    final int offset = textOffset.clamp(0, _verseTextTotalLength).toInt();
    int low = 1;
    int high = lengths.length - 1;
    while (low < high) {
      final int mid = (low + high) >> 1;
      if (lengths[mid] <= offset) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low.clamp(1, _totalVerses).toInt();
  }

  String _inlineVerseTextSegment(int verse) {
    return inlineQuranVerseSegment(_currentChapter, verse);
  }

  String _cardVerseText(int chapter, int verse) {
    return quranVerseText(chapter, verse);
  }

  Future<void> _loadFontsForCurrentSurah() async {
    if (SettingsDB().quranScriptStyle != 'qpc-v4') return;

    final int currentPage = EquranTextStyles.getPageNumber(
      _currentChapter,
      _currentVerse,
    );
    final bool currentLoaded = await QpcV4FontService.instance
        .ensureFontLoadedForPage(currentPage);
    if (currentLoaded && mounted) {
      setState(() {});
    }

    if (currentPage != 1) {
      unawaited(
        QpcV4FontService.instance.ensureFontLoadedForPage(1).then((success) {
          if (success && mounted) {
            setState(() {});
          }
        }),
      );
    }

    final List<int> pages = quran.getSurahPages(_currentChapter);
    final int currentIndex = pages.indexOf(currentPage);
    final Set<int> boundedPages = <int>{currentPage, 1};
    if (currentIndex > 0) boundedPages.add(pages[currentIndex - 1]);
    if (currentIndex >= 0 && currentIndex + 1 < pages.length) {
      boundedPages.add(pages[currentIndex + 1]);
    }
    for (final int page in boundedPages) {
      if (page == currentPage || page == 1) continue;
      unawaited(
        QpcV4FontService.instance.ensureFontLoadedForPage(page).then((success) {
          if (success && mounted) {
            setState(() {});
          }
        }),
      );
    }
  }

  void _ensureFontsLoadedForCurrentState() {
    if (SettingsDB().quranScriptStyle != 'qpc-v4') return;
    if (_loadedChapter == _currentChapter && _loadedVerse == _currentVerse) {
      return;
    }

    _loadedChapter = _currentChapter;
    _loadedVerse = _currentVerse;

    _loadFontsForCurrentSurah();
  }

  @override
  Widget build(BuildContext context) {
    _ensureFontsLoadedForCurrentState();
    Size screenSize = MediaQuery.of(context).size;
    final EquranColors colors = context.equranColors;

    // Define margin values for different screen sizes
    double marginValue;
    if (screenSize.width > 1200) {
      marginValue = 90.0; // Large screen
    } else if (screenSize.width > 700) {
      marginValue = 40.0; // Medium screen
    } else {
      marginValue = 8.0; // Small screen
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          unawaited(_stopReadingAudioForRouteExit());
          await _saveProgressOnExit();
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleReadPagePointerDown,
        onPointerMove: _handleReadPagePointerMove,
        onPointerUp: _handleReadPagePointerUp,
        onPointerCancel: _handleReadPagePointerCancel,
        onPointerSignal: _handleReadPagePointerSignal,
        child: Focus(
          autofocus: true,
          focusNode: _pageFocusNode,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) {
              return KeyEventResult.ignored;
            }

            _notifyAudioUserActivity();

            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _increase();
              return KeyEventResult.handled;
            }

            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _decrease();
              return KeyEventResult.handled;
            }

            return KeyEventResult.ignored;
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: ResponsiveNav.toolbarHeight(context),
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              iconTheme: IconThemeData(
                color: colors.textSecondary,
                size: ResponsiveNav.iconSize(context),
              ),
              actionsIconTheme: IconThemeData(
                color: colors.textSecondary,
                size: ResponsiveNav.iconSize(context),
              ),
              leading: const BackButton(),
              title: Text(
                localizedSurahName(
                  AppLocalizations.of(context)!,
                  _currentChapter,
                ),
              ),
              centerTitle: true,
              actions: <Widget>[
                if (!_viewMode)
                  IconButton(
                    tooltip: _isVersePlaying && _playingVerse == _currentVerse
                        ? AppLocalizations.of(context)!.pause
                        : AppLocalizations.of(context)!.playThisAyah,
                    onPressed: _togglePageViewPlayback,
                    icon: Icon(
                      _isVersePlaying && _playingVerse == _currentVerse
                          ? Icons.pause_circle_rounded
                          : Icons.play_circle_rounded,
                      size: 24,
                    ),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                  ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.readingOptions,
                  onPressed: _showReadingOptionsSheet,
                  icon: const Icon(Icons.more_horiz_rounded, size: 24),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                ),
                const SizedBox(width: 10),
              ],
            ),
            body: _viewMode
                ? cardView(marginValue: marginValue)
                : listView(marginValue: marginValue),
          ),
        ),
      ),
    );
  }

  Future<void> _showReadingOptionsSheet() async {
    AndroidAudioDisplayMode.notifyUserActivity();
    final localizations = AppLocalizations.of(context)!;
    final String surahName = localizedSurahName(localizations, _currentChapter);

    final _ReadingOptionsAction? action = await _withLowFpsSuppressed(() {
      return showModalBottomSheet<_ReadingOptionsAction>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
        builder: (sheetContext) {
          final ThemeData theme = Theme.of(sheetContext);
          final ColorScheme colorScheme = theme.colorScheme;
          final AppLocalizations localizations = AppLocalizations.of(
            sheetContext,
          )!;

          return SafeArea(
            top: false,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.38,
              maxChildSize: 0.88,
              builder: (context, scrollController) {
                return StatefulBuilder(
                  builder: (context, setSheetState) {
                    final bool translationEnabled =
                        SettingsDB().get(
                          "enableTranslation",
                          defaultValue: true,
                        ) ==
                        true;
                    final bool transliterationEnabled =
                        SettingsDB().get(
                          "showTransliteration",
                          defaultValue: false,
                        ) ==
                        true;
                    final bool cardViewEnabled =
                        SettingsDB().get("viewMode", defaultValue: true) ==
                        true;

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(18),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.medium,
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    localizations.readingOptions,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    localizations.surahLabel(
                                      surahName,
                                      _currentVerse,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _ReadingOptionsSection(
                          title: localizations.navigation,
                          children: <Widget>[
                            _ReadingOptionTile(
                              icon: Icons.double_arrow_outlined,
                              title: localizations.goToAyah,
                              subtitle: localizations.jumpToAyahIn(surahName),
                              onTap: () => Navigator.of(
                                sheetContext,
                              ).pop(_ReadingOptionsAction.goToAyah),
                            ),
                          ],
                        ),
                        _ReadingOptionsSection(
                          title: localizations.displayAndSharing,
                          children: <Widget>[
                            SwitchListTile(
                              secondary: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(18),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.small,
                                  ),
                                ),
                                child: Icon(
                                  Icons.translate_rounded,
                                  color: colorScheme.primary,
                                  size: 21,
                                ),
                              ),
                              title: Text(localizations.translation),
                              subtitle: Text(localizations.showAyahTranslation),
                              value: translationEnabled,
                              onChanged: (value) async {
                                await SettingsDB().put(
                                  "enableTranslation",
                                  value,
                                );
                                if (!mounted) return;
                                setState(() {});
                                setSheetState(() {});
                              },
                            ),
                            SwitchListTile(
                              secondary: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(18),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.small,
                                  ),
                                ),
                                child: Icon(
                                  Icons.text_fields_rounded,
                                  color: colorScheme.primary,
                                  size: 21,
                                ),
                              ),
                              title: Text(localizations.transliterationOption),
                              subtitle: Text(
                                localizations.showLatinTransliteration,
                              ),
                              value: transliterationEnabled,
                              onChanged: (value) async {
                                await SettingsDB().put(
                                  "showTransliteration",
                                  value,
                                );
                                if (!mounted) return;
                                setState(() {});
                                setSheetState(() {});
                              },
                            ),
                            SwitchListTile(
                              secondary: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(18),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.small,
                                  ),
                                ),
                                child: Icon(
                                  Icons.view_agenda_outlined,
                                  color: colorScheme.primary,
                                  size: 21,
                                ),
                              ),
                              title: Text(localizations.cardViewOption),
                              subtitle: Text(localizations.readOneAyahPerCard),
                              value: cardViewEnabled,
                              onChanged: (value) async {
                                await SettingsDB().put("viewMode", value);
                                if (!mounted) return;
                                setState(() {
                                  _viewMode = value;
                                });
                                setSheetState(() {});
                              },
                            ),
                            if (translationEnabled)
                              _ReadingOptionTile(
                                icon: Icons.language_rounded,
                                title: localizations.translationLanguage,
                                subtitle:
                                    localizations.chooseTranslationShownOnCards,
                                onTap: () => Navigator.of(sheetContext).pop(
                                  _ReadingOptionsAction.translationLanguage,
                                ),
                              ),
                            _ReadingOptionTile(
                              icon: Icons.auto_stories_outlined,
                              title: localizations.tafsirSources,
                              subtitle:
                                  localizations.chooseDownloadedExplanations,
                              onTap: () => Navigator.of(
                                sheetContext,
                              ).pop(_ReadingOptionsAction.tafsirSources),
                            ),
                            _ReadingOptionTile(
                              icon: Icons.ios_share_outlined,
                              title: localizations.shareCurrentAyah,
                              subtitle: localizations.createImageForThisAyah,
                              onTap: () => Navigator.of(
                                sheetContext,
                              ).pop(_ReadingOptionsAction.shareCurrentAyah),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      );
    });

    if (!mounted || action == null) return;

    switch (action) {
      case _ReadingOptionsAction.goToAyah:
        await _showJumpToVerseDialog(context);
        break;
      case _ReadingOptionsAction.shareCurrentAyah:
        await _shareCurrentAyahImage();
        break;
      case _ReadingOptionsAction.translationLanguage:
        await _openCardTranslationLanguagePicker();
        break;
      case _ReadingOptionsAction.tafsirSources:
        await _showTafsirSourceSelectorSheet();
        break;
    }
  }

  void _bindVersePlayer() {
    _playerPositionSubscription = _versePlayer.positionStream.listen((
      position,
    ) {
      if (!mounted) return;
      if (_isReadingAudioDelaySource) return;
      _setPlayerPosition(
        position,
        fromPlayerStream: true,
        canEstimateFromSample: _isVersePlaying && !_isVerseLoading,
      );
    });

    _playerDurationSubscription = _versePlayer.durationStream.listen((
      duration,
    ) {
      if (!mounted) return;
      if (_isReadingAudioDelaySource) return;
      _setPlayerDuration(duration ?? Duration.zero);
      _syncBottomPlayerProgressPolicy(syncPosition: true);
    });

    _playerIndexSubscription = _versePlayer.currentIndexStream.listen((index) {
      if (!mounted) return;
      unawaited(_handleReadingAudioSequenceIndexChanged(index));
    });

    _playerStateSubscription = _versePlayer.playerStateStream.listen((
      state,
    ) async {
      if (!mounted) return;
      final bool isDelaySource = _isReadingAudioDelaySource;
      final Duration actualPosition = _versePlayer.position;
      final bool isBuffering =
          state.processingState == ja.ProcessingState.buffering;
      final bool isLoading =
          !isDelaySource &&
          (state.processingState == ja.ProcessingState.loading || isBuffering);
      final bool isPlaybackActive =
          !isDelaySource &&
          state.playing &&
          state.processingState != ja.ProcessingState.completed;
      final bool isAudiblyPlaying =
          isPlaybackActive &&
          state.processingState == ja.ProcessingState.ready &&
          !_isAttemptingAudioReconnect;
      setState(() {
        _isVersePlaying = isAudiblyPlaying;
        _isVerseLoading = _isAttemptingAudioReconnect || isLoading;
        if (state.processingState == ja.ProcessingState.completed ||
            (!state.playing &&
                state.processingState == ja.ProcessingState.ready)) {
          _isVerseLoading = _isAttemptingAudioReconnect;
        }
        if (!isDelaySource &&
            (!_isPreparingReadingAudioSource ||
                actualPosition == Duration.zero ||
                isAudiblyPlaying)) {
          _setPlayerPosition(
            actualPosition,
            render: true,
            allowBackward: true,
            fromPlayerStream: true,
            canEstimateFromSample: isAudiblyPlaying,
          );
        }
      });
      _syncReadingTimeTracking();
      unawaited(_updateKeepScreenOn());
      unawaited(
        AndroidAudioDisplayMode.setAudioPlaybackActive(
          isPlaybackActive && !_isAttemptingAudioReconnect,
        ),
      );
      _syncBottomPlayerProgressPolicy(syncPosition: true);

      if (!isDelaySource &&
          isBuffering &&
          state.playing &&
          _currentVerseSourceIsStream) {
        _scheduleAudioBufferingReconnect();
      } else if (!isBuffering) {
        _audioBufferingRetryTimer?.cancel();
      }

      if (state.processingState == ja.ProcessingState.completed) {
        if (_readingAudioSequenceActive) {
          await _handleReadingAudioSequenceComplete();
        } else {
          await _handleVerseCompleteFromPlayer();
        }
      }
    });

    _playerErrorSubscription = _versePlayer.errorStream.listen((
      ja.PlayerException error,
    ) {
      _handleVersePlayerError(error);
    });
  }

  void _scheduleAudioBufferingReconnect() {
    if (_isStartingVersePlayback || _isAttemptingAudioReconnect) return;
    if (_audioBufferingRetryTimer?.isActive ?? false) return;

    final int requestId = _playbackRequestId;
    _audioBufferingRetryTimer = Timer(_audioBufferingReconnectDelay, () {
      if (!mounted || requestId != _playbackRequestId) return;
      if (_isStartingVersePlayback ||
          _isAttemptingAudioReconnect ||
          !_currentVerseSourceIsStream) {
        return;
      }
      final ja.PlayerState state = _versePlayer.playerState;
      if (state.playing &&
          state.processingState == ja.ProcessingState.buffering) {
        _handleVersePlayerError(const _AudioPlaybackStalledException());
      }
    });
  }

  void _handleVersePlayerError(Object error) {
    _syncPlayingPositionFromSequenceIndex();
    if (!mounted ||
        _isStartingVersePlayback ||
        _isAttemptingAudioReconnect ||
        !_currentVerseSourceIsStream ||
        _playingVerse == null) {
      return;
    }

    unawaited(_attemptAudioReconnect(error));
  }

  void _syncPlayingPositionFromSequenceIndex() {
    if (!_readingAudioSequenceActive) return;
    final int? index = _versePlayer.currentIndex;
    if (index == null || index < 0 || index >= _readingAudioSequence.length) {
      return;
    }
    final _ReadingAudioSequenceItem item = _readingAudioSequence[index];
    if (item.isDelay) return;
    _currentVerseSourceIsStream = item.isStream;
    _playingVerse = item.position.ayah;
    _currentVerse = item.position.ayah;
    if (item.position.surah != _currentChapter) {
      _currentChapter = item.position.surah;
      _totalVerses = quran.getVerseCount(_currentChapter);
    }
  }

  Future<void> _attemptAudioReconnect(Object initialError) async {
    if (!mounted || _isAttemptingAudioReconnect) return;

    final int requestId = _playbackRequestId;
    final QuranPosition position = _playingPosition;
    final Duration resumePosition = _resumePositionForReconnect(
      _estimatedBottomPlayerPosition(),
    );
    final Stopwatch stopwatch = Stopwatch()..start();
    Object lastError = initialError;
    bool reconnectFailed = false;

    _audioBufferingRetryTimer?.cancel();
    setState(() {
      _isAttemptingAudioReconnect = true;
      _isVerseLoading = true;
      _isVersePlaying = false;
      _setPlayerPosition(
        resumePosition,
        render: true,
        allowBackward: true,
        canEstimateFromSample: false,
      );
    });
    _syncReadingTimeTracking();
    _syncBottomPlayerProgressPolicy(syncPosition: true);
    unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));

    try {
      for (
        int attempt = 1;
        attempt <= _audioReconnectMaxAttempts &&
            stopwatch.elapsed < _audioReconnectMaxDuration;
        attempt++
      ) {
        await Future<void>.delayed(_audioReconnectDelay);
        _throwIfPlaybackRequestCancelled(requestId);

        if (_hasCurrentVersePlaybackRecovered) return;

        final bool online = await _hasInternetConnection();
        _throwIfPlaybackRequestCancelled(requestId);
        if (!online) {
          lastError = const _OfflineAudioPlaybackException();
          continue;
        }

        try {
          await _playVerseWithRetry(
            position.surah,
            position.ayah,
            requestId,
            startPosition: resumePosition,
          ).timeout(_audioReconnectAttemptTimeout);
          _throwIfPlaybackRequestCancelled(requestId);
          if (!mounted) return;
          setState(() {
            _isVerseLoading = false;
            _isVersePlaying = true;
            _setPlayerPosition(
              resumePosition,
              render: true,
              allowBackward: true,
              canEstimateFromSample: true,
            );
          });
          _syncReadingTimeTracking();
          _syncBottomPlayerProgressPolicy(syncPosition: true);
          unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(true));
          return;
        } catch (error) {
          lastError = error;
          if (!mounted || requestId != _playbackRequestId) {
            throw const _CancelledAudioPlaybackException();
          }
          _setPlayerPosition(
            resumePosition,
            render: true,
            allowBackward: true,
            canEstimateFromSample: false,
          );
          _syncBottomPlayerProgressPolicy(syncPosition: true);
        }
      }

      if (!mounted || requestId != _playbackRequestId) return;
      try {
        await _pauseCurrentVerseAudio();
      } catch (_) {
        // Keep the sampled progress even if the platform player is already idle.
      }
      if (!mounted || requestId != _playbackRequestId) return;
      setState(() {
        _isVerseLoading = false;
        _isVersePlaying = false;
        _setPlayerPosition(
          resumePosition,
          render: true,
          allowBackward: true,
          canEstimateFromSample: false,
        );
      });
      _syncReadingTimeTracking();
      _syncBottomPlayerProgressPolicy(syncPosition: true);
      unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));
      reconnectFailed = true;
      _showAudioPlaybackMessage(
        'Audio connection was interrupted. Check your internet and try again.',
      );
      if (kDebugMode) {
        debugPrint('ReadPage audio reconnect failed: $lastError');
      }
    } on _CancelledAudioPlaybackException {
      return;
    } finally {
      stopwatch.stop();
      if (mounted && requestId == _playbackRequestId) {
        _isAttemptingAudioReconnect = false;
        if (reconnectFailed) {
          _syncBottomPlayerProgressPolicy(syncPosition: true);
        } else {
          unawaited(_syncReadingAudioStateFromPlayer());
        }
      } else {
        _isAttemptingAudioReconnect = false;
      }
    }
  }

  bool get _hasCurrentVersePlaybackRecovered {
    final ja.PlayerState state = _versePlayer.playerState;
    return !_isReadingAudioDelaySource &&
        state.playing &&
        state.processingState == ja.ProcessingState.ready;
  }

  Duration _resumePositionForReconnect(Duration position) {
    if (position <= Duration.zero) return Duration.zero;
    final Duration duration = _playerDuration;
    if (duration > const Duration(milliseconds: 600) && position >= duration) {
      return duration - const Duration(milliseconds: 500);
    }
    return position;
  }

  void _showAudioPlaybackMessage(String message) {
    if (!mounted || !_isReadPageForeground) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _handleReadingAudioSequenceIndexChanged(int? index) async {
    if (!mounted ||
        !_readingAudioSequenceActive ||
        _readingAudioSequenceRequestId != _playbackRequestId ||
        index == null ||
        index < 0 ||
        index >= _readingAudioSequence.length ||
        index == _activeReadingAudioSequenceIndex) {
      return;
    }

    _activeReadingAudioSequenceIndex = index;
    final _ReadingAudioSequenceItem item = _readingAudioSequence[index];
    if (item.isDelay) {
      _audioBufferingRetryTimer?.cancel();
      setState(() {
        _isReadingAudioDelaySource = true;
        _currentVerseSourceIsStream = false;
        _isVerseLoading = false;
        _isVersePlaying = false;
        _setPlayerPosition(
          _playerDuration,
          render: true,
          allowBackward: true,
          canEstimateFromSample: false,
        );
      });
      _syncReadingTimeTracking();
      _syncBottomPlayerProgressPolicy(syncPosition: true);
      unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));
      unawaited(_maybeExtendReadingAudioSequence(index));
      return;
    }

    final QuranPosition position = item.position;
    final bool chapterChanged = position.surah != _currentChapter;
    final _ReadingAudioProgressSource progressSource = _progressSourceFor(
      requestId: _playbackRequestId,
      surah: position.surah,
      ayah: position.ayah,
    );
    final ja.PlayerState state = _versePlayer.playerState;
    final bool isLoading =
        state.processingState == ja.ProcessingState.loading ||
        state.processingState == ja.ProcessingState.buffering;
    final bool isPlaying =
        state.playing &&
        state.processingState == ja.ProcessingState.ready &&
        !isLoading;

    setState(() {
      if (chapterChanged) {
        _clearVerseTextMetrics();
        _currentChapter = position.surah;
        _totalVerses = quran.getVerseCount(_currentChapter);
        _isDownloadingSurahAyahs = AudioDownloadService()
            .isSurahAyahsDownloadInProgress(_currentChapter);
        _hasDownloadedSurahAyahs = false;
        _hasDownloadedCurrentAyah = false;
      }
      _isReadingAudioDelaySource = false;
      _currentVerseSourceIsStream = item.isStream;
      _currentAyahPlayCount = item.repeatOrdinal;
      _intervalCyclesCompleted = max(0, item.cycleOrdinal - 1);
      _playingVerse = position.ayah;
      _currentVerse = position.ayah;
      _isVerseLoading = isLoading;
      _isVersePlaying = isPlaying;
      _beginNewReadingAudioSource(progressSource);
    });
    _markReadingAudioSourceReady(
      progressSource,
      position: _versePlayer.position,
      duration: _versePlayer.duration,
    );
    if (chapterChanged) {
      unawaited(_refreshSurahAyahDownloadState());
      unawaited(_loadChapterTransliterations());
    }
    unawaited(_refreshCurrentAyahDownloadState());
    _updateDB();
    if (_isReadPageForeground) {
      unawaited(_scrollToVerseIfNeeded(position.ayah, smooth: true));
    }
    _syncReadingTimeTracking();
    _syncBottomPlayerProgressPolicy(syncPosition: true);
    unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(isPlaying));
    unawaited(_maybeExtendReadingAudioSequence(index));
  }

  Future<void> _handleReadingAudioSequenceComplete() async {
    if (_isHandlingVerseCompletion) return;
    _isHandlingVerseCompletion = true;
    try {
      if (!mounted || !_readingAudioSequenceActive) return;
      final int requestId = _playbackRequestId;
      if (_readingAudioPlanCursor?.exhausted == false) {
        await _extendReadingAudioSequenceWithRetry(requestId);
        if (!mounted || requestId != _playbackRequestId) return;
        if (_versePlayer.playerState.processingState !=
            ja.ProcessingState.completed) {
          return;
        }
        if (_versePlayer.hasNext) {
          await _versePlayer.seekToNext();
          unawaited(_versePlayer.play());
          return;
        }
      }
      await _stopBottomPlayer();
    } finally {
      _isHandlingVerseCompletion = false;
    }
  }

  Future<void> _maybeExtendReadingAudioSequence(int currentIndex) async {
    if (!_readingAudioSequenceActive ||
        _readingAudioSequenceRequestId != _playbackRequestId ||
        _isExtendingReadingAudioSequence ||
        (_readingAudioPlanCursor?.exhausted ?? true)) {
      return;
    }
    final int remainingSources =
        _readingAudioSequence.length - currentIndex - 1;
    if (remainingSources > _readingAudioAppendThreshold) return;
    await _extendReadingAudioSequenceWithRetry(_playbackRequestId);
  }

  Future<void> _extendReadingAudioSequenceWithRetry(int requestId) async {
    if (_isExtendingReadingAudioSequence) {
      await _readingAudioSequenceExtensionFuture;
      if (!mounted ||
          requestId != _playbackRequestId ||
          (_readingAudioPlanCursor?.exhausted ?? true)) {
        return;
      }
      await _extendReadingAudioSequenceWithRetry(requestId);
      return;
    }
    const List<Duration> retryDelays = <Duration>[
      Duration(milliseconds: 500),
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2200),
    ];

    final Completer<void> extensionCompleter = Completer<void>();
    _isExtendingReadingAudioSequence = true;
    _readingAudioSequenceExtensionFuture = extensionCompleter.future;
    try {
      Object? lastError;
      for (int attempt = 0; attempt <= retryDelays.length; attempt++) {
        try {
          _throwIfPlaybackRequestCancelled(requestId);
          await _appendReadingAudioSources(
            requestId,
            audioItemLimit: _readingAudioAppendBatchSize,
          );
          return;
        } catch (error) {
          lastError = error;
          _throwIfPlaybackRequestCancelled(requestId);
          if (attempt == retryDelays.length) break;
          await Future<void>.delayed(retryDelays[attempt]);
        }
      }
      if (kDebugMode && lastError != null) {
        debugPrint('ReadPage audio sequence append failed: $lastError');
      }
    } on _CancelledAudioPlaybackException {
      return;
    } finally {
      _isExtendingReadingAudioSequence = false;
      if (_readingAudioSequenceExtensionFuture == extensionCompleter.future) {
        _readingAudioSequenceExtensionFuture = null;
      }
      if (!extensionCompleter.isCompleted) {
        extensionCompleter.complete();
      }
    }
  }

  Future<void> _showJumpToVerseDialog(BuildContext context) async {
    if (!_viewMode) {
      _syncCurrentVerseWithVisibleText(persist: true);
    }

    final TextEditingController controller = TextEditingController(
      text: _currentVerse.toString(),
    );
    final FocusNode focusNode = FocusNode();
    String? errorText;
    bool sheetOpen = true;
    bool initialFocusRequested = false;
    bool isSubmitting = false;

    AndroidAudioDisplayMode.notifyUserActivity();
    _pushProgressVisualBlock();
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(true));

    int? selectedVerse;

    try {
      selectedVerse = await showModalBottomSheet<int>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        requestFocus: false,
        builder: (sheetContext) {
          final ThemeData theme = Theme.of(sheetContext);
          final ColorScheme colorScheme = theme.colorScheme;
          final AppLocalizations localizations = AppLocalizations.of(
            sheetContext,
          )!;

          if (!initialFocusRequested) {
            initialFocusRequested = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(
                Future<void>.delayed(const Duration(milliseconds: 220), () {
                  if (sheetOpen && focusNode.canRequestFocus) {
                    focusNode.requestFocus();
                  }
                }),
              );
            });
          }

          Future<void> submit(StateSetter setSheetState) async {
            if (isSubmitting) return;
            final int? value = int.tryParse(controller.text.trim());

            if (value == null || value < 1 || value > _totalVerses) {
              setSheetState(() {
                errorText = localizations.enterAyahRange(_totalVerses);
              });
              return;
            }

            isSubmitting = true;
            focusNode.unfocus();
            if (Navigator.of(sheetContext).canPop()) {
              Navigator.of(sheetContext).pop(value);
            }
          }

          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      localizations.goToAyah,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      localizations.enterAyahRange(_totalVerses),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.go,
                      textAlign: TextAlign.center,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: localizations.ayahNumberHint,
                        errorText: errorText,
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setSheetState(() {
                            errorText = null;
                          });
                        }
                      },
                      onSubmitted: (_) => submit(setSheetState),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => submit(setSheetState),
                      child: Text(localizations.go),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(localizations.cancel),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      sheetOpen = false;
      _popProgressVisualBlock();
      unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
      await WidgetsBinding.instance.endOfFrame;
      controller.dispose();
      focusNode.dispose();
    }

    if (selectedVerse == null || !mounted) return;

    final bool shouldRetargetContinuousPlayback =
        _isVersePlaying &&
        _continuousPlayback &&
        !_repeatIntervalEnabled &&
        selectedVerse != (_playingVerse ?? _currentVerse);
    _setVerse(selectedVerse);
    if (!_viewMode) {
      unawaited(_scrollToInlineVerse(selectedVerse, highlight: true));
    } else {
      _scrollUp();
    }
    _updateDB();

    if (shouldRetargetContinuousPlayback) {
      unawaited(
        _playVerse(
          _currentChapter,
          selectedVerse,
          continuous: true,
          smoothScroll: !_viewMode,
        ),
      );
    }
  }

  Future<void> _saveProgressOnExit() async {
    if (_hasSavedOnExit) return;

    _hasSavedOnExit = true;
    _pauseReadingTimeTracking(flush: true);
    _syncCurrentVerseWithVisibleText();
    if (_isRoutineReading) {
      unawaited(_refreshCurrentAyahDownloadState());
      return;
    }
    await BookmarkDB().addReadingEntry(_currentChapter, _currentVerse);
  }

  Future<void> _setKeepScreenOn(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _readPageChannel.invokeMethod<void>(
        'setKeepScreenOn',
        <String, bool>{'enabled': enabled},
      );
    } catch (_) {
      // Ignore platform-channel failures on unsupported builds.
    }
  }

  Future<void> _updateKeepScreenOn() async {
    await _setKeepScreenOn(
      _playerVisible && (_continuousPlayback || _repeatIntervalEnabled),
    );
  }

  Future<void> _refreshCurrentAyahDownloadState() async {
    final bool hasAyah = await AudioDownloadService().hasAyah(
      _currentChapter,
      _currentVerse,
    );
    if (!mounted) return;
    setState(() {
      _hasDownloadedCurrentAyah = hasAyah;
    });
  }

  Future<void> _playVerse(
    int surah,
    int verse, {
    bool continuous = false,
    bool smoothScroll = false,
    bool preservePlayerPresentationState = false,
    bool preserveRefreshState = false,
    bool resetPlaybackCounters = true,
  }) async {
    if (_isVerseLoading) return;

    _pauseReadingTimeTracking(flush: true);
    final int requestId = ++_playbackRequestId;
    _audioBufferingRetryTimer?.cancel();
    _isAttemptingAudioReconnect = false;
    _currentVerseSourceIsStream = false;
    final int safeSurah = surah.clamp(1, 114).toInt();
    final int safeVerse = verse
        .clamp(1, quran.getVerseCount(safeSurah))
        .toInt();
    final _ReadingAudioProgressSource progressSource = _progressSourceFor(
      requestId: requestId,
      surah: safeSurah,
      ayah: safeVerse,
    );
    final bool chapterChanged = safeSurah != _currentChapter;
    final bool shouldPreservePresentation =
        preservePlayerPresentationState && _playerMounted && _playerVisible;
    final bool nextPlayerMinimized = shouldPreservePresentation
        ? _playerMinimized
        : false;
    final double nextPlayerCollapseProgress = shouldPreservePresentation
        ? _playerCollapseProgress
        : 0;
    final bool nextPlayerMinimizedSettled =
        nextPlayerMinimized && nextPlayerCollapseProgress >= 1;
    final bool shouldDelayLowRefreshForAutoAdvance =
        preserveRefreshState && nextPlayerMinimizedSettled;
    final bool shouldAnimateVisualsForAutoAdvance =
        _isReadPageForeground && shouldDelayLowRefreshForAutoAdvance;
    if (shouldAnimateVisualsForAutoAdvance) {
      _beginLowRefreshAnimationBlock();
    }

    bool lowFpsSuppressed = false;
    if (_isReadPageForeground && !shouldDelayLowRefreshForAutoAdvance) {
      AndroidAudioDisplayMode.notifyUserActivity();
      _syncReadingPlayerRefreshMode(
        'play verse starts active UI',
        forceLowRefresh: true,
      );
      lowFpsSuppressed = true;
      unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(true));
    }

    setState(() {
      if (resetPlaybackCounters) {
        _resetPlaybackCounters();
      }
      if (chapterChanged) {
        _clearVerseTextMetrics();
        _currentChapter = safeSurah;
        _totalVerses = quran.getVerseCount(_currentChapter);
        _isDownloadingSurahAyahs = AudioDownloadService()
            .isSurahAyahsDownloadInProgress(_currentChapter);
        _hasDownloadedSurahAyahs = false;
        _hasDownloadedCurrentAyah = false;
      }
      _playerVisible = true;
      _playerMounted = true;
      _playerMinimized = nextPlayerMinimized;
      _playerMinimizedSettled = nextPlayerMinimizedSettled;
      _playerCollapseProgress = nextPlayerCollapseProgress;
      _isDraggingPlayerBar = false;
      _isVerseLoading = true;
      _isVersePlaying = false;
      _continuousPlayback = continuous;
      _playingVerse = safeVerse;
      _currentVerse = safeVerse;
      _beginNewReadingAudioSource(progressSource);
    });
    if (chapterChanged) {
      unawaited(_refreshSurahAyahDownloadState());
      unawaited(_loadChapterTransliterations());
    }
    _syncBottomPlayerProgressPolicy();
    _syncReadingPlayerRefreshMode(
      'play verse presentation updated',
      forceLowRefresh: shouldDelayLowRefreshForAutoAdvance,
    );
    _updateDB();
    final Future<void> visualTransition = _isReadPageForeground
        ? _scrollToVerseIfNeeded(safeVerse, smooth: smoothScroll)
        : Future<void>.value();

    try {
      _isStartingVersePlayback = true;
      await _playVerseWithRetry(safeSurah, safeVerse, requestId);
      if (continuous && mounted && requestId == _playbackRequestId) {
        unawaited(_preloadNextContinuousAyahs(safeSurah, safeVerse));
      }
    } on _CancelledAudioPlaybackException {
      return;
    } on _OfflineAudioPlaybackException {
      if (mounted) {
        _showAudioPlaybackMessage(
          'You are offline. Download this ayah or reconnect to stream it.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showAudioPlaybackMessage('Unable to play ayah audio.');
      }
    } finally {
      if (requestId == _playbackRequestId) {
        _isStartingVersePlayback = false;
      }
      if (mounted && requestId == _playbackRequestId) {
        setState(() {
          _isVerseLoading = false;
        });
        _syncReadingTimeTracking();
        _syncBottomPlayerProgressPolicy(syncPosition: true);
      }
      if (lowFpsSuppressed) {
        unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
      }
      await visualTransition;
      if (shouldAnimateVisualsForAutoAdvance) {
        _endLowRefreshAnimationBlock();
      } else if (_isReadPageForeground && preserveRefreshState) {
        _syncReadingPlayerRefreshMode(
          'preserved playback refresh restored',
          forceLowRefresh: true,
        );
      }
    }
  }

  Future<void> _playVerseWithRetry(
    int surah,
    int verse,
    int requestId, {
    Duration startPosition = Duration.zero,
  }) async {
    const List<Duration> retryDelays = <Duration>[
      Duration(milliseconds: 350),
      Duration(milliseconds: 800),
      Duration(milliseconds: 1400),
    ];

    Object? lastError;
    for (int attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        _throwIfPlaybackRequestCancelled(requestId);
        await _playVerseSequence(
          surah,
          verse,
          requestId,
          startPosition: startPosition,
        );
        return;
      } on _CancelledAudioPlaybackException {
        rethrow;
      } on _OfflineAudioPlaybackException {
        rethrow;
      } catch (error) {
        lastError = error;
        _throwIfPlaybackRequestCancelled(requestId);
        if (!await _hasInternetConnection()) {
          _throwIfPlaybackRequestCancelled(requestId);
          throw const _OfflineAudioPlaybackException();
        }
        if (attempt == retryDelays.length) break;
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    Error.throwWithStackTrace(
      lastError ?? Exception('Audio playback failed.'),
      StackTrace.current,
    );
  }

  Future<void> _playVerseSequence(
    int surah,
    int verse,
    int requestId, {
    Duration startPosition = Duration.zero,
  }) async {
    await _stopCurrentVerseAudio();
    _throwIfPlaybackRequestCancelled(requestId);
    final double rate = _playbackRate();
    await _setCurrentVersePlaybackRate(rate);
    final _ReadingAudioPlanCursor cursor = _initialReadingAudioPlanCursor(
      QuranPosition(surah: surah, ayah: verse),
    );
    final List<_PreparedReadingAudioSource> prepared =
        await _prepareReadingAudioBatch(
          cursor,
          requestId,
          audioItemLimit: _readingAudioInitialBatchSize,
        );
    _throwIfPlaybackRequestCancelled(requestId);
    if (prepared.isEmpty) {
      throw Exception('No audio sources prepared.');
    }

    _clearReadingAudioSequenceState();
    _readingAudioSequenceActive = true;
    _readingAudioSequenceRequestId = requestId;
    _readingAudioPlanCursor = cursor;
    _readingAudioSequence.addAll(
      prepared.map((_PreparedReadingAudioSource source) => source.item),
    );
    _activeReadingAudioSequenceIndex = null;
    _isReadingAudioDelaySource = false;
    final _ReadingAudioSequenceItem firstItem = _readingAudioSequence.first;
    _currentVerseSourceIsStream = firstItem.isStream;
    final _ReadingAudioProgressSource progressSource = _progressSourceFor(
      requestId: requestId,
      surah: firstItem.position.surah,
      ayah: firstItem.position.ayah,
    );
    final Duration? loadedDuration = await _versePlayer.setAudioSources(
      prepared
          .map((_PreparedReadingAudioSource preparedSource) {
            return preparedSource.source;
          })
          .toList(growable: false),
      initialIndex: 0,
      initialPosition: startPosition,
    );
    _throwIfPlaybackRequestCancelled(requestId);
    _markReadingAudioSourceReady(
      progressSource,
      position: startPosition,
      duration: loadedDuration ?? _versePlayer.duration,
    );
    await _setCurrentVersePlaybackRate(rate);
    _throwIfPlaybackRequestCancelled(requestId);
    unawaited(_versePlayer.play());
  }

  _ReadingAudioPlanCursor _initialReadingAudioPlanCursor(
    QuranPosition position,
  ) {
    QuranPosition safePosition = QuranPosition.current(
      position.surah,
      position.ayah,
    );
    if (_repeatIntervalEnabled) {
      final PlaybackInterval interval = _effectiveInterval;
      if (!interval.contains(safePosition)) {
        safePosition = interval.start;
      }
    }
    return _ReadingAudioPlanCursor(
      position: safePosition,
      repeatIndex: 1,
      cycleIndex: 0,
      exhausted: false,
    );
  }

  Future<void> _appendReadingAudioSources(
    int requestId, {
    required int audioItemLimit,
  }) async {
    final _ReadingAudioPlanCursor? currentCursor = _readingAudioPlanCursor;
    if (currentCursor == null || currentCursor.exhausted) return;
    final int mutationId = _readingAudioSequenceMutationId;
    final _ReadingAudioPlanCursor nextCursor = currentCursor.copy();
    final List<_PreparedReadingAudioSource> prepared =
        await _prepareReadingAudioBatch(
          nextCursor,
          requestId,
          audioItemLimit: audioItemLimit,
        );
    _throwIfPlaybackRequestCancelled(requestId);
    if (mutationId != _readingAudioSequenceMutationId) return;
    if (prepared.isEmpty) {
      _readingAudioPlanCursor = nextCursor;
      return;
    }
    await _versePlayer.addAudioSources(
      prepared
          .map((_PreparedReadingAudioSource preparedSource) {
            return preparedSource.source;
          })
          .toList(growable: false),
    );
    _throwIfPlaybackRequestCancelled(requestId);
    if (mutationId != _readingAudioSequenceMutationId) return;
    _readingAudioSequence.addAll(
      prepared.map((_PreparedReadingAudioSource source) => source.item),
    );
    _readingAudioPlanCursor = nextCursor;
  }

  Future<List<_PreparedReadingAudioSource>> _prepareReadingAudioBatch(
    _ReadingAudioPlanCursor cursor,
    int requestId, {
    required int audioItemLimit,
  }) async {
    final List<_PreparedReadingAudioSource> prepared =
        <_PreparedReadingAudioSource>[];
    for (int i = 0; i < audioItemLimit && !cursor.exhausted; i++) {
      _throwIfPlaybackRequestCancelled(requestId);
      final QuranPosition position = cursor.position;
      final int repeatOrdinal = cursor.repeatIndex;
      final int cycleOrdinal = cursor.cycleIndex + 1;
      final _PreparedReadingAudioSource audioSource;
      try {
        audioSource = await _prepareAyahAudioSource(
          position: position,
          repeatOrdinal: repeatOrdinal,
          cycleOrdinal: cycleOrdinal,
          requestId: requestId,
        );
      } catch (_) {
        if (prepared.isNotEmpty) break;
        rethrow;
      }
      prepared.add(audioSource);
      _advanceReadingAudioPlanCursor(cursor);
      if (_ayahDelaySeconds > 0 && !cursor.exhausted) {
        prepared.add(
          await _prepareDelayAudioSource(
            afterPosition: position,
            repeatOrdinal: repeatOrdinal,
            cycleOrdinal: cycleOrdinal,
          ),
        );
      }
    }
    return prepared;
  }

  Future<_PreparedReadingAudioSource> _prepareAyahAudioSource({
    required QuranPosition position,
    required int repeatOrdinal,
    required int cycleOrdinal,
    required int requestId,
  }) async {
    final AudioDownloadService downloads = AudioDownloadService();
    final File? offlineFile = kIsWeb
        ? null
        : await downloads.playbackAyahFile(position.surah, position.ayah);
    _throwIfPlaybackRequestCancelled(requestId);

    final Uri sourceUri;
    final bool fromOffline;
    if (!kIsWeb && offlineFile != null && offlineFile.existsSync()) {
      sourceUri = Uri.file(offlineFile.path);
      fromOffline = true;
    } else {
      final AppReciter reciter = QuranAudioService().selectedReciter;
      final ReciterProfile activeProfile = QuranAudioCatalog.findById(
        reciter.code,
      );
      final String url = QuranAudioStreamResolver.buildAyahUrl(
        reciter: activeProfile,
        surah: position.surah,
        ayah: position.ayah,
      );
      _throwIfPlaybackRequestCancelled(requestId);
      sourceUri = Uri.parse(url);
      fromOffline = false;
      if (!kIsWeb) {
        unawaited(downloads.cacheAyah(position.surah, position.ayah));
      }
    }

    final String sourceKind = fromOffline ? 'offline' : 'stream';
    final AppReciter reciter = QuranAudioService().selectedReciter;
    return _PreparedReadingAudioSource(
      item: _ReadingAudioSequenceItem(
        position: position,
        fromOffline: fromOffline,
        isDelay: false,
        repeatOrdinal: repeatOrdinal,
        cycleOrdinal: cycleOrdinal,
      ),
      source: ja.AudioSource.uri(
        sourceUri,
        tag: MediaItem(
          id:
              'ayah-${position.surah}-${position.ayah}-$sourceKind-'
              '${reciter.code}-$cycleOrdinal-$repeatOrdinal',
          album: 'eQuran',
          title: '${quran.getSurahName(position.surah)} ${position.ayah}',
          artist: reciter.englishName,
          displayDescription: 'Ayah ${position.surah}:${position.ayah}',
          artUri: Uri.parse('asset:///assets/media/images/icon.webp'),
        ),
      ),
    );
  }

  Future<_PreparedReadingAudioSource> _prepareDelayAudioSource({
    required QuranPosition afterPosition,
    required int repeatOrdinal,
    required int cycleOrdinal,
  }) async {
    final Duration duration = Duration(
      milliseconds: (_ayahDelaySeconds * 1000).round(),
    );
    final File file = await _silenceAudioFile(duration);
    return _PreparedReadingAudioSource(
      item: _ReadingAudioSequenceItem(
        position: afterPosition,
        fromOffline: true,
        isDelay: true,
        repeatOrdinal: repeatOrdinal,
        cycleOrdinal: cycleOrdinal,
      ),
      source: ja.AudioSource.uri(
        Uri.file(file.path),
        tag: MediaItem(
          id:
              'ayah-delay-${duration.inMilliseconds}-'
              '${afterPosition.surah}-${afterPosition.ayah}',
          album: 'eQuran',
          title: 'Ayah delay',
          artist: QuranAudioService().selectedReciter.englishName,
          displayDescription:
              'Delay after ayah '
              '${afterPosition.surah}:${afterPosition.ayah}',
          artUri: Uri.parse('asset:///assets/media/images/icon.webp'),
        ),
      ),
    );
  }

  Future<File> _silenceAudioFile(Duration duration) async {
    final int milliseconds = duration.inMilliseconds.clamp(1, 10000).toInt();
    final Directory directory = await getTemporaryDirectory();
    final File file = File(
      '${directory.path}/equran_silence_$milliseconds.wav',
    );
    if (await file.exists()) return file;

    const int sampleRate = 8000;
    const int channels = 1;
    const int bitsPerSample = 16;
    final int sampleCount = (sampleRate * milliseconds / 1000).round();
    final int dataSize = sampleCount * channels * (bitsPerSample ~/ 8);
    final Uint8List bytes = Uint8List(44 + dataSize);
    final ByteData data = ByteData.sublistView(bytes);

    void writeAscii(int offset, String value) {
      for (int i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(
      28,
      sampleRate * channels * (bitsPerSample ~/ 8),
      Endian.little,
    );
    data.setUint16(32, channels * (bitsPerSample ~/ 8), Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, dataSize, Endian.little);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _advanceReadingAudioPlanCursor(_ReadingAudioPlanCursor cursor) {
    if (cursor.exhausted) return;
    final int repeatCount = _repeatAyahChoice.count ?? 1;
    if (cursor.repeatIndex < repeatCount) {
      cursor.repeatIndex++;
      return;
    }

    cursor.repeatIndex = 1;
    if (_repeatAyahChoice.isInfinite) {
      return;
    }

    if (_repeatIntervalEnabled) {
      final PlaybackInterval interval = _effectiveInterval;
      if (cursor.position.isBefore(interval.end)) {
        final QuranPosition? next = _nextQuranPosition(cursor.position);
        if (next == null || !interval.contains(next)) {
          cursor.exhausted = true;
        } else {
          cursor.position = next;
        }
        return;
      }

      final int? intervalRepeatCount = _intervalRepeatChoice.count;
      if (_intervalRepeatChoice.isInfinite ||
          (intervalRepeatCount != null &&
              cursor.cycleIndex + 1 < intervalRepeatCount)) {
        cursor.cycleIndex++;
        cursor.position = interval.start;
      } else {
        cursor.exhausted = true;
      }
      return;
    }

    if (_continuousPlayback) {
      final QuranPosition? next = _nextQuranPosition(cursor.position);
      if (next == null) {
        cursor.exhausted = true;
      } else {
        cursor.position = next;
      }
      return;
    }

    cursor.exhausted = true;
  }

  void _clearReadingAudioSequenceState() {
    _readingAudioSequenceActive = false;
    _readingAudioSequenceRequestId = 0;
    _readingAudioSequenceMutationId++;
    _activeReadingAudioSequenceIndex = null;
    _readingAudioSequence.clear();
    _readingAudioPlanCursor = null;
    _isReadingAudioDelaySource = false;
    _isExtendingReadingAudioSequence = false;
    _readingAudioSequenceExtensionFuture = null;
  }

  Future<void> _refreshUpcomingReadingAudioSequenceForModeChange() async {
    if (!_readingAudioSequenceActive || _readingAudioSequence.isEmpty) return;
    final int requestId = _playbackRequestId;
    _readingAudioSequenceMutationId++;
    final int? nullableCurrentIndex =
        _versePlayer.currentIndex ?? _activeReadingAudioSequenceIndex;
    if (nullableCurrentIndex == null ||
        nullableCurrentIndex < 0 ||
        nullableCurrentIndex >= _readingAudioSequence.length) {
      return;
    }

    final int currentIndex = nullableCurrentIndex;
    final _ReadingAudioSequenceItem currentItem =
        _readingAudioSequence[currentIndex];
    final int removeStart = currentIndex + 1;
    if (removeStart < _readingAudioSequence.length) {
      final int removeEnd = _readingAudioSequence.length;
      final int playerRemoveEnd = min(
        removeEnd,
        _versePlayer.audioSources.length,
      );
      if (removeStart < playerRemoveEnd) {
        await _versePlayer.removeAudioSourceRange(removeStart, playerRemoveEnd);
      }
      if (!mounted || requestId != _playbackRequestId) return;
      _readingAudioSequence.removeRange(removeStart, removeEnd);
    }

    _readingAudioPlanCursor = _cursorAfterReadingAudioSequenceItem(currentItem);
    if (_readingAudioPlanCursor?.exhausted ?? true) return;
    await _extendReadingAudioSequenceWithRetry(requestId);
  }

  _ReadingAudioPlanCursor _cursorAfterReadingAudioSequenceItem(
    _ReadingAudioSequenceItem item,
  ) {
    final _ReadingAudioPlanCursor cursor = _ReadingAudioPlanCursor(
      position: item.position,
      repeatIndex: item.repeatOrdinal,
      cycleIndex: max(0, item.cycleOrdinal - 1),
      exhausted: false,
    );
    _advanceReadingAudioPlanCursor(cursor);
    return cursor;
  }

  Future<void> _setCurrentVersePlaybackRate(double rate) async {
    final Duration currentPosition = _versePlayer.position;
    _playerPosition = currentPosition;
    _playerPositionSampledAt = _isVersePlaying ? DateTime.now() : null;
    _currentVersePlaybackRate = rate;
    _syncBottomPlayerProgressPolicy(syncPosition: true);
    await _versePlayer.setSpeed(rate);
  }

  Future<void> _pauseCurrentVerseAudio() async {
    _audioBufferingRetryTimer?.cancel();
    await _versePlayer.pause();
    _setPlayerPosition(
      _versePlayer.position,
      render: true,
      allowBackward: true,
      canEstimateFromSample: false,
    );
  }

  Future<void> _resumeCurrentVerseAudio() async {
    _setPlayerPosition(
      _versePlayer.position,
      render: true,
      allowBackward: true,
      canEstimateFromSample: false,
    );
    _syncBottomPlayerProgressPolicy(syncPosition: true);
    unawaited(_versePlayer.play());
  }

  Future<void> _stopCurrentVerseAudio() async {
    _audioBufferingRetryTimer?.cancel();
    await _versePlayer.stop();
  }

  Future<void> _seekCurrentVerseAudio(Duration position) async {
    await _versePlayer.seek(position);
  }

  Future<bool> _seekReadingAudioSequenceToPosition(
    QuranPosition target, {
    required int direction,
  }) async {
    if (!_readingAudioSequenceActive || _readingAudioSequence.isEmpty) {
      return false;
    }
    final int currentIndex =
        _versePlayer.currentIndex ?? _activeReadingAudioSequenceIndex ?? 0;
    final Iterable<int> searchOrder;
    if (direction < 0) {
      searchOrder = <int>[
        for (
          int i = min(currentIndex - 1, _readingAudioSequence.length - 1);
          i >= 0;
          i--
        )
          i,
      ];
    } else {
      searchOrder = <int>[
        for (
          int i = max(currentIndex + 1, 0);
          i < _readingAudioSequence.length;
          i++
        )
          i,
      ];
    }

    for (final int index in searchOrder) {
      final _ReadingAudioSequenceItem item = _readingAudioSequence[index];
      if (item.isDelay) continue;
      if (item.position.surah == target.surah &&
          item.position.ayah == target.ayah) {
        await _versePlayer.seek(Duration.zero, index: index);
        unawaited(_versePlayer.play());
        return true;
      }
    }
    return false;
  }

  Future<void> _preloadNextContinuousAyahs(int surah, int verse) async {
    final AudioDownloadService downloads = AudioDownloadService();
    QuranPosition? nextPosition = _nextQuranPosition(
      QuranPosition(surah: surah, ayah: verse),
    );
    for (int i = 0; i < 2 && nextPosition != null; i++) {
      final String key = '${nextPosition.surah}-${nextPosition.ayah}';
      if (_preloadingAyahKeys.contains(key)) continue;
      _preloadingAyahKeys.add(key);
      try {
        await downloads.cacheAyah(nextPosition.surah, nextPosition.ayah);
      } catch (_) {
        // Best-effort preload; foreground playback should never wait on this.
      } finally {
        _preloadingAyahKeys.remove(key);
      }
      nextPosition = _nextQuranPosition(nextPosition);
    }
  }

  void _throwIfPlaybackRequestCancelled(int requestId) {
    if (!mounted || requestId != _playbackRequestId) {
      throw const _CancelledAudioPlaybackException();
    }
  }

  Future<bool> _hasInternetConnection() async {
    if (kIsWeb) return true;

    final http.Client client = http.Client();
    try {
      final http.Response response = await client
          .head(Uri.parse('https://quranapi.pages.dev/api/1/1.json'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  double _playbackRate() {
    final dynamic value = SettingsDB().get("playbackRate", defaultValue: 1.0);
    if (value is num) {
      return value.toDouble().clamp(0.5, 2.0);
    }
    return 1.0;
  }

  void _loadPlaybackOptions() {
    final dynamic delayVal = SettingsDB().get(
      _ayahDelaySettingsKey,
      defaultValue: 0.0,
    );
    double delaySeconds = 0.0;
    if (delayVal is num) {
      delaySeconds = delayVal.toDouble();
    }
    _ayahDelaySeconds = delaySeconds.clamp(0.0, 10.0);
    _intervalRepeatChoice = RepeatChoice.fromStorage(
      SettingsDB().get(
        _intervalRepeatSettingsKey,
        defaultValue: RepeatChoice.infinite.storageValue,
      ),
      fallback: RepeatChoice.infinite,
    );
    _repeatAyahChoice = RepeatChoice.fromStorage((
      _repeatAyahSettingsKey,
      defaultValue: RepeatChoice.one.storageValue,
    ), fallback: RepeatChoice.one);
    _playbackInterval = PlaybackInterval.fromJson(
      SettingsDB().get(_playbackIntervalSettingsKey),
    );
  }

  Future<void> _persistPlaybackOptions() async {
    final SettingsDB settings = SettingsDB();
    await settings.put(_ayahDelaySettingsKey, _ayahDelaySeconds);
    await settings.put(
      _intervalRepeatSettingsKey,
      _intervalRepeatChoice.storageValue,
    );
    await settings.put(_repeatAyahSettingsKey, _repeatAyahChoice.storageValue);
    final PlaybackInterval? interval = _playbackInterval;
    if (interval == null) {
      await settings.delete(_playbackIntervalSettingsKey);
    } else {
      await settings.put(_playbackIntervalSettingsKey, interval.toJson());
    }
  }

  Future<void> _setPlaybackRate(double rate) async {
    final double normalizedRate = _normalizePlaybackRate(rate);
    await SettingsDB().put("playbackRate", normalizedRate);
    if (_playerMounted || _isVersePlaying || _isVerseLoading) {
      await _setCurrentVersePlaybackRate(normalizedRate);
    }
  }

  double _normalizePlaybackRate(double rate) {
    return (rate * 4).round().clamp(2, 8) / 4;
  }

  QuranPosition get _currentPosition {
    return QuranPosition(surah: _currentChapter, ayah: _currentVerse);
  }

  QuranPosition get _playingPosition {
    return QuranPosition(
      surah: _currentChapter,
      ayah: _playingVerse ?? _currentVerse,
    );
  }

  PlaybackInterval get _effectiveInterval {
    return _playbackInterval ??
        PlaybackInterval(start: _currentPosition, end: _currentPosition);
  }

  QuranPosition? _nextQuranPosition(QuranPosition position) {
    final int verseCount = quran.getVerseCount(position.surah);
    if (position.ayah < verseCount) {
      return QuranPosition(surah: position.surah, ayah: position.ayah + 1);
    }
    if (position.surah >= 114) return null;
    return QuranPosition(surah: position.surah + 1, ayah: 1);
  }

  QuranPosition? _previousQuranPosition(QuranPosition position) {
    if (position.ayah > 1) {
      return QuranPosition(surah: position.surah, ayah: position.ayah - 1);
    }
    if (position.surah <= 1) return null;
    final int previousSurah = position.surah - 1;
    return QuranPosition(
      surah: previousSurah,
      ayah: quran.getVerseCount(previousSurah),
    );
  }

  bool get _canPlayPreviousAyah {
    final QuranPosition position = _playingPosition;
    if (_repeatIntervalEnabled) {
      return position.isAfter(_effectiveInterval.start);
    }
    return _previousQuranPosition(position) != null;
  }

  bool get _canPlayNextAyah {
    final QuranPosition position = _playingPosition;
    if (_repeatIntervalEnabled) {
      return position.isBefore(_effectiveInterval.end) ||
          _intervalRepeatChoice.isInfinite;
    }
    return _nextQuranPosition(position) != null;
  }

  String _formatPosition(QuranPosition position, {bool useNames = false}) {
    if (!useNames) return '${position.surah}:${position.ayah}';
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return localizations.surahLabel(
      localizedSurahName(localizations, position.surah),
      position.ayah,
    );
  }

  String _formatIntervalSummary(PlaybackInterval? interval) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (interval == null) return localizations.currentAyahOnly;
    if (interval.start.surah == interval.end.surah) {
      return localizations.surahAyahRange(
        interval.end.ayah,
        interval.start.ayah,
        localizedSurahName(localizations, interval.start.surah),
      );
    }
    return '${_formatPosition(interval.start)} → ${_formatPosition(interval.end)}';
  }

  void _resetPlaybackCounters() {
    _intervalCyclesCompleted = 0;
    _currentAyahPlayCount = 1;
  }

  Future<void> _delayBeforeNextPlayback(int requestId) async {
    if (_ayahDelaySeconds <= 0) return;
    await Future<void>.delayed(
      Duration(milliseconds: (_ayahDelaySeconds * 1000).round()),
    );
    _throwIfPlaybackRequestCancelled(requestId);
  }

  Future<void> _handleVerseCompleteFromPlayer() async {
    if (_isHandlingVerseCompletion) return;
    _isHandlingVerseCompletion = true;
    try {
      await _handleVerseComplete();
    } finally {
      _isHandlingVerseCompletion = false;
    }
  }

  Future<void> _syncReadingAudioStateFromPlayer() async {
    final Duration position = await _currentVerseAudioPosition();
    final Duration duration = await _currentVerseAudioDuration();
    final ja.PlayerState state = _versePlayer.playerState;
    final bool isLoading =
        _isAttemptingAudioReconnect ||
        state.processingState == ja.ProcessingState.loading ||
        state.processingState == ja.ProcessingState.buffering;
    final bool isPlaying =
        state.playing &&
        state.processingState == ja.ProcessingState.ready &&
        !isLoading;
    if (!mounted) return;

    setState(() {
      _setPlayerPosition(
        position,
        fromPlayerStream: true,
        canEstimateFromSample: isPlaying,
      );
      _setPlayerDuration(duration);
      _isVersePlaying = isPlaying;
      _isVerseLoading = isLoading;
    });
    _syncReadingTimeTracking();
    _syncBottomPlayerProgressPolicy(syncPosition: true);
    unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(isPlaying));
  }

  Future<Duration> _currentVerseAudioPosition() async {
    if (_isReadingAudioDelaySource) return _playerDuration;
    return _versePlayer.position;
  }

  Future<Duration> _currentVerseAudioDuration() async {
    if (_isReadingAudioDelaySource) return _playerDuration;
    return _versePlayer.duration ?? Duration.zero;
  }

  Future<void> _handleVerseComplete() async {
    final int requestId = _playbackRequestId;
    final QuranPosition completedPosition = _playingPosition;
    final int? repeatAyahCount = _repeatAyahChoice.count;
    if (_repeatAyahChoice.isInfinite ||
        (repeatAyahCount != null && _currentAyahPlayCount < repeatAyahCount)) {
      if (!_repeatAyahChoice.isInfinite) {
        _currentAyahPlayCount++;
      }
      await _delayBeforeNextPlayback(requestId);
      await _playVerse(
        completedPosition.surah,
        completedPosition.ayah,
        continuous: _continuousPlayback,
        smoothScroll: false,
        preservePlayerPresentationState: true,
        preserveRefreshState: true,
        resetPlaybackCounters: false,
      );
      return;
    }

    _currentAyahPlayCount = 1;

    if (_repeatIntervalEnabled) {
      final PlaybackInterval interval = _effectiveInterval;
      QuranPosition? nextPosition;
      if (completedPosition.isBefore(interval.end)) {
        nextPosition = _nextQuranPosition(completedPosition);
      } else {
        final int? intervalRepeatCount = _intervalRepeatChoice.count;
        if (_intervalRepeatChoice.isInfinite ||
            (intervalRepeatCount != null &&
                _intervalCyclesCompleted + 1 < intervalRepeatCount)) {
          _intervalCyclesCompleted++;
          nextPosition = interval.start;
        }
      }

      if (nextPosition == null || !interval.contains(nextPosition)) {
        if (!mounted) return;
        await _stopBottomPlayer();
        return;
      }

      await _delayBeforeNextPlayback(requestId);
      await _playVerse(
        nextPosition.surah,
        nextPosition.ayah,
        smoothScroll: true,
        preservePlayerPresentationState: true,
        preserveRefreshState: true,
        resetPlaybackCounters: false,
      );
      return;
    }

    final QuranPosition? nextContinuousPosition = _nextQuranPosition(
      completedPosition,
    );
    if (_sleepTimerMode == _sleepTimerEndSurahMode) {
      if (nextContinuousPosition == null ||
          nextContinuousPosition.surah != completedPosition.surah) {
        _cancelSleepTimer();
        if (mounted) {
          await _stopBottomPlayer();
        }
        return;
      }
    }
    if (_continuousPlayback && nextContinuousPosition != null) {
      await _delayBeforeNextPlayback(requestId);
      await _playVerse(
        nextContinuousPosition.surah,
        nextContinuousPosition.ayah,
        continuous: true,
        smoothScroll: true,
        preservePlayerPresentationState: true,
        preserveRefreshState: true,
        resetPlaybackCounters: false,
      );
      return;
    }

    if (!mounted) return;
    await _stopBottomPlayer();
  }

  Future<void> _toggleBottomPlayer() async {
    if (_isVerseLoading) return;
    if (_isVersePlaying) {
      await _pauseCurrentVerseAudio();
      return;
    }

    if (_playingVerse != null && _playerPosition > Duration.zero) {
      await _resumeCurrentVerseAudio();
      return;
    }

    await _playVerse(
      _currentChapter,
      _playingVerse ?? _currentVerse,
      continuous: _continuousPlayback,
    );
  }

  Future<void> _playAdjacentPageViewAyah(int direction) async {
    if (_isVerseLoading) return;

    final QuranPosition currentPosition = _playingPosition;
    QuranPosition? targetPosition = direction < 0
        ? _previousQuranPosition(currentPosition)
        : _nextQuranPosition(currentPosition);
    if (_repeatIntervalEnabled && targetPosition != null) {
      final PlaybackInterval interval = _effectiveInterval;
      if (targetPosition.isBefore(interval.start)) return;
      if (targetPosition.isAfter(interval.end)) {
        if (direction > 0 && _intervalRepeatChoice.isInfinite) {
          targetPosition = interval.start;
        } else {
          return;
        }
      }
    }
    if (targetPosition == null) return;
    _resetPlaybackCounters();
    if (await _seekReadingAudioSequenceToPosition(
      targetPosition,
      direction: direction,
    )) {
      return;
    }

    await _playVerse(
      targetPosition.surah,
      targetPosition.ayah,
      continuous: _continuousPlayback,
      smoothScroll: true,
    );
  }

  void _togglePageViewPlayback() {
    if (!_viewMode) {
      _syncCurrentVerseWithVisibleText(persist: true);
    }

    if (_isVersePlaying && _playingVerse == _currentVerse) {
      unawaited(_toggleBottomPlayer());
      return;
    }

    final bool continuous = !_viewMode;
    if (_viewMode) {
      _continuousPlayback = false;
    }
    unawaited(
      _playVerse(_currentChapter, _currentVerse, continuous: continuous),
    );
  }

  Future<void> _downloadCurrentSurahAyahs() async {
    if (_isDownloadingSurahAyahs) return;

    setState(() {
      _isDownloadingSurahAyahs = true;
    });
    _surahDownloadProgressNotifier.value = 0.0;

    final int notificationId = DownloadNotifications.notificationId(
      'surah-ayahs-$_currentChapter',
    );
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String surahName = localizedSurahName(localizations, _currentChapter);
    final String title = localizations.downloadingSurahAyahs(surahName);

    try {
      await DownloadNotifications.progress(
        id: notificationId,
        title: title,
        progress: null,
      );
      await AudioDownloadService().downloadSurahAyahs(
        _currentChapter,
        onProgress: (progress) {
          _surahDownloadProgressNotifier.value = progress.fraction;
          unawaited(
            DownloadNotifications.progress(
              id: notificationId,
              title: title,
              progress: progress.fraction,
            ),
          );
        },
      );
      await DownloadNotifications.complete(
        id: notificationId,
        title: localizations.downloadedSurahAyahs(surahName),
      );
      await _refreshSurahAyahDownloadState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.downloadedAllAyahsFor(surahName)),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error downloading surah: $e');
      debugPrint('$stackTrace');
      await DownloadNotifications.fail(
        id: notificationId,
        title: localizations.failedDownloadSurahAyahs(surahName),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.failedDownloadSurahAyahs(surahName)),
          ),
        );
      }
    } finally {
      _surahDownloadProgressNotifier.value = null;
      if (mounted) {
        setState(() {
          _isDownloadingSurahAyahs = false;
        });
      }
    }
  }

  Future<void> _downloadCurrentAyah() async {
    final int chapter = _currentChapter;
    final int verse = _currentVerse;
    final String downloadKey = '$chapter-$verse';
    if (_downloadingAyahKeys.contains(downloadKey)) return;

    final AppLocalizations localizations = AppLocalizations.of(context)!;

    try {
      setState(() {
        _downloadingAyahKeys.add(downloadKey);
      });

      final int notificationId = DownloadNotifications.notificationId(
        'ayah-$chapter-$verse',
      );
      final String title = localizations.downloadingName(
        'ayah $chapter:$verse',
      );
      await DownloadNotifications.progress(
        id: notificationId,
        title: title,
        progress: null,
      );
      await AudioDownloadService().downloadAyah(
        chapter,
        verse,
        onProgress: (progress) => unawaited(
          DownloadNotifications.progress(
            id: notificationId,
            title: title,
            progress: progress.fraction,
          ),
        ),
      );
      await DownloadNotifications.complete(
        id: notificationId,
        title: localizations.downloadedName('ayah $chapter:$verse'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.downloadedName('ayah $chapter:$verse')),
        ),
      );
    } catch (_) {
      await DownloadNotifications.fail(
        id: DownloadNotifications.notificationId('ayah-$chapter-$verse'),
        title: localizations.failedDownloadName('ayah $chapter:$verse'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.failedDownloadAyahAudio)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAyahKeys.remove(downloadKey);
        });
      }
      unawaited(_refreshCurrentAyahDownloadState());
    }
  }

  Future<void> _confirmDeleteCurrentAyahDownload() async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool? confirm = await _withLowFpsSuppressed(() {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: Text(localizations.deleteDownloadedAyah),
          content: Text(
            localizations.removeSurahFromOffline(
              'ayah $_currentChapter:$_currentVerse',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations.delete),
            ),
          ],
        ),
      );
    });

    if (confirm != true) return;
    await _deleteCurrentAyahDownload();
  }

  Future<void> _deleteCurrentAyahDownload() async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    try {
      await AudioDownloadService().deleteAyah(_currentChapter, _currentVerse);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.deletedDownload(
              'ayah $_currentChapter:$_currentVerse audio',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.failedDeleteDownloadedAyah)),
      );
    } finally {
      await _refreshCurrentAyahDownloadState();
      await _refreshSurahAyahDownloadState();
    }
  }

  Future<void> _setSleepTimer(
    Duration duration,
    String label, {
    String mode = _sleepTimerDurationMode,
    bool startPlayback = true,
  }) async {
    if (duration <= Duration.zero) return;
    _sleepTimer?.cancel();
    final DateTime endsAt = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () async {
      await _stopBottomPlayer();
      if (mounted) {
        setState(() {
          _sleepTimer = null;
          _sleepTimerEndsAt = null;
          _sleepTimerLabel = null;
          _sleepTimerMode = null;
        });
      }
    });
    if (mounted) {
      setState(() {
        _sleepTimerEndsAt = endsAt;
        _sleepTimerLabel = label;
        _sleepTimerMode = mode;
        _continuousPlayback = true;
        _repeatIntervalEnabled = false;
      });
    }
    if (startPlayback) {
      await _startOrContinuePlaybackForSleepTimer();
    }
  }

  Future<void> _startOrContinuePlaybackForSleepTimer() async {
    if (_isVersePlaying || _isVerseLoading) return;
    if (_playingVerse != null && _playerPosition > Duration.zero) {
      await _resumeCurrentVerseAudio();
      return;
    }
    await _playVerse(
      _currentChapter,
      _playingVerse ?? _currentVerse,
      continuous: _continuousPlayback,
    );
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    if (mounted) {
      setState(() {
        _sleepTimer = null;
        _sleepTimerEndsAt = null;
        _sleepTimerLabel = null;
        _sleepTimerMode = null;
      });
    }
  }

  String _sleepTimerSummary() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime? endsAt = _sleepTimerEndsAt;
    if (endsAt == null) return l10n.off;
    final Duration remaining = endsAt.difference(DateTime.now());
    if (remaining.isNegative) return l10n.sleepingSoon;
    final int minutes =
        remaining.inMinutes + (remaining.inSeconds % 60 == 0 ? 0 : 1);
    return l10n.sleepingInMinutes(minutes);
  }

  String _sleepTimerOptionsSubtitle() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_sleepTimerEndsAt != null) return _sleepTimerSummary();
    if (_sleepTimerMode == _sleepTimerEndSurahMode) {
      return l10n.pendingLabel(_sleepTimerLabel ?? l10n.endOfSurah);
    }
    return l10n.off;
  }

  Future<void> _applySleepTimerSelection(String value) async {
    if (value.startsWith('duration:')) {
      final int? minutes = int.tryParse(value.substring('duration:'.length));
      if (minutes == null) return;
      await _setSleepTimer(
        Duration(minutes: minutes),
        AppLocalizations.of(context)!.minutesShort(minutes),
        mode: _sleepTimerDurationMode,
      );
      return;
    }

    if (value == _sleepTimerEndSurahMode) {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      if (mounted) {
        setState(() {
          _sleepTimerLabel = l10n.endOfSurah;
          _sleepTimerMode = _sleepTimerEndSurahMode;
          _continuousPlayback = true;
          _repeatIntervalEnabled = false;
        });
      }
      await _startOrContinuePlaybackForSleepTimer();
    }
  }

  Future<void> _showUpgradedSleepTimerSheet() async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final EquranColors colors = context.equranColors;

    int minutes = 15;
    if (_sleepTimerEndsAt != null) {
      minutes = _sleepTimerEndsAt!
          .difference(DateTime.now())
          .inMinutes
          .clamp(1, 120);
    }
    bool endOfSurah = _sleepTimerMode == _sleepTimerEndSurahMode;

    final TextEditingController textController = TextEditingController(
      text: '$minutes',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.large),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void increment(int val) {
              int current = int.tryParse(textController.text) ?? 15;
              current = (current + val).clamp(1, 240);
              textController.text = '$current';
              setSheetState(() {
                minutes = current;
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(18),
                          borderRadius: BorderRadius.circular(AppRadii.medium),
                        ),
                        child: Icon(
                          Icons.bedtime_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.sleepTimerSettings,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Numeric Minute Picker Container
                  Card(
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.medium),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            localizations.numericMinutesDuration,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              // Minus Button
                              IconButton(
                                onPressed: endOfSurah
                                    ? null
                                    : () => increment(-5),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                                color: colorScheme.primary,
                                iconSize: 28,
                              ),
                              // Text Field Input
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: TextField(
                                    controller: textController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    enabled: !endOfSurah,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: endOfSurah
                                              ? colorScheme.onSurfaceVariant
                                                    .withAlpha(128)
                                              : colorScheme.onSurface,
                                        ),
                                    decoration: InputDecoration(
                                      suffixText: localizations
                                          .minutesShort(0)
                                          .replaceAll('0', '')
                                          .trim(),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      final int? parsed = int.tryParse(val);
                                      if (parsed != null) {
                                        minutes = parsed.clamp(1, 240);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              // Plus Button
                              IconButton(
                                onPressed: endOfSurah
                                    ? null
                                    : () => increment(5),
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                color: colorScheme.primary,
                                iconSize: 28,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // End of Surah Toggle Card
                  Card(
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.medium),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                      ),
                      secondary: Icon(
                        Icons.queue_music_rounded,
                        color: endOfSurah
                            ? colorScheme.primary
                            : colors.textSecondary,
                      ),
                      title: Text(
                        localizations.endOfSurah,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(localizations.endOfSurahSubtitle),
                      value: endOfSurah,
                      onChanged: (val) {
                        setSheetState(() {
                          endOfSurah = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Apply / Stop Buttons
                  Row(
                    children: <Widget>[
                      if (_sleepTimerEndsAt != null ||
                          _sleepTimerMode != null) ...<Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _cancelSleepTimer();
                              Navigator.of(context).pop();
                            },
                            child: Text(localizations.turnOff),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (endOfSurah) {
                              await _applySleepTimerSelection(
                                _sleepTimerEndSurahMode,
                              );
                            } else {
                              final int val =
                                  int.tryParse(textController.text) ?? minutes;
                              await _setSleepTimer(
                                Duration(minutes: val),
                                localizations.minutesShort(val),
                                mode: _sleepTimerDurationMode,
                              );
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(localizations.setTimer),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(textController.dispose);
  }

  Future<void> _refreshSurahAyahDownloadState() async {
    if (kIsWeb) return;

    final AudioDownloadService downloads = AudioDownloadService();
    final int chapter = _currentChapter;
    final int totalVerses = quran.getVerseCount(chapter);
    for (int ayah = 1; ayah <= totalVerses; ayah++) {
      if (!await downloads.hasAyah(chapter, ayah)) {
        if (mounted && chapter == _currentChapter) {
          setState(() {
            _hasDownloadedSurahAyahs = false;
          });
        }
        return;
      }
    }

    if (mounted && chapter == _currentChapter) {
      setState(() {
        _hasDownloadedSurahAyahs = true;
      });
    }
  }

  bool _isVerseDownloaded(int chapter, int verse) {
    if (kIsWeb) return false;
    if (_hasDownloadedSurahAyahs) return true;
    if (chapter == _currentChapter && verse == _currentVerse) {
      return _hasDownloadedCurrentAyah;
    }
    return false;
  }

  Future<bool> _isSurahDownloadedForReciter(
    int chapter,
    String reciterCode,
  ) async {
    if (kIsWeb) return false;
    final int totalVerses = quran.getVerseCount(chapter);
    final Directory dir = await AudioDownloadService().ayahDirectory();
    for (int ayah = 1; ayah <= totalVerses; ayah++) {
      final String fileName =
          '${reciterCode}_${chapter.toString().padLeft(3, '0')}_${ayah.toString().padLeft(3, '0')}.mp3';
      final File file = File('${dir.path}/$fileName');
      if (!file.existsSync() || file.lengthSync() == 0) {
        return false;
      }
    }
    return true;
  }

  Future<void> _stopBottomPlayer() async {
    if (!mounted) return;
    _playbackRequestId++;
    _audioBufferingRetryTimer?.cancel();
    _isAttemptingAudioReconnect = false;
    _currentVerseSourceIsStream = false;
    _clearReadingAudioSequenceState();
    _playerSettleTimer?.cancel();
    _isPlayerGestureActive = false;
    _isPlayerSettleAnimating = false;
    _syncReadingPlayerRefreshMode('player stopped', forceLowRefresh: true);
    setState(() {
      _resetPlaybackCounters();
      _playerVisible = false;
      _playerMinimized = false;
      _playerMinimizedSettled = false;
      _playerCollapseProgress = 0;
      _isDraggingPlayerBar = false;
      _isVersePlaying = false;
      _isVerseLoading = false;
      _continuousPlayback = false;
      _repeatIntervalEnabled = false;
      _playingVerse = null;
      _resetVisiblePlayerProgressForRequest(_playbackRequestId);
    });
    _syncReadingTimeTracking();
    _syncBottomPlayerProgressPolicy();
    await _stopCurrentVerseAudio();
    await _setKeepScreenOn(false);
    await AndroidAudioDisplayMode.setAudioPlaybackActive(false);
    await AndroidAudioDisplayMode.clearStaticMinimizedAudioRefreshRate(
      force: true,
    );
  }

  void _toggleContinuousPlayback(bool value) {
    if (!value) {
      _sleepTimer?.cancel();
    }
    final bool shouldRefreshUpcomingSequence =
        (_playerMounted || _isVersePlaying || _isVerseLoading) &&
        _playingVerse != null;
    _beginPlayerSettleAnimation('continuous toggle expands player');
    setState(() {
      if (!shouldRefreshUpcomingSequence) {
        _resetPlaybackCounters();
      }
      _continuousPlayback = value;
      if (value) {
        _repeatIntervalEnabled = false;
      } else {
        _sleepTimer = null;
        _sleepTimerEndsAt = null;
        _sleepTimerLabel = null;
        _sleepTimerMode = null;
      }
      _playerVisible = true;
      _playerMounted = true;
      _playerMinimized = false;
      _playerMinimizedSettled = false;
      _playerCollapseProgress = 0;
      _isDraggingPlayerBar = false;
      _playingVerse ??= _currentVerse;
    });
    _syncBottomPlayerProgressPolicy();
    _syncReadingPlayerRefreshMode('continuous toggle complete');
    unawaited(_updateKeepScreenOn());
    if (shouldRefreshUpcomingSequence) {
      unawaited(_refreshUpcomingReadingAudioSequenceForModeChange());
    }
  }

  Future<void> _showIntervalSelectionSheet({
    bool enableIntervalAfterSelection = false,
  }) async {
    _notifyAudioUserActivity();
    final PlaybackInterval initialInterval =
        _playbackInterval ??
        PlaybackInterval(start: _currentPosition, end: _currentPosition);
    int startSurah = initialInterval.start.surah;
    int startAyah = initialInterval.start.ayah;
    int endSurah = initialInterval.end.surah;
    int endAyah = initialInterval.end.ayah;
    String? errorText;

    final PlaybackInterval? selected = await _withLowFpsSuppressed(() {
      return showModalBottomSheet<PlaybackInterval>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          final AppLocalizations localizations = AppLocalizations.of(context)!;
          return StatefulBuilder(
            builder: (context, setSheetState) {
              void clampAyahs() {
                startAyah = startAyah
                    .clamp(1, quran.getVerseCount(startSurah))
                    .toInt();
                endAyah = endAyah
                    .clamp(1, quran.getVerseCount(endSurah))
                    .toInt();
              }

              PlaybackInterval currentSelection() {
                clampAyahs();
                return PlaybackInterval(
                  start: QuranPosition(surah: startSurah, ayah: startAyah),
                  end: QuranPosition(surah: endSurah, ayah: endAyah),
                );
              }

              void applySelection() {
                final PlaybackInterval interval = currentSelection();
                if (!interval.isValid) {
                  setSheetState(() {
                    errorText = localizations.intervalEndBeforeStartError;
                  });
                  return;
                }
                Navigator.of(context).pop(interval);
              }

              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _notifyAudioUserActivity(),
                onPointerMove: (_) => _notifyAudioUserActivity(),
                onPointerSignal: (_) => _notifyAudioUserActivity(),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.viewInsetsOf(context).bottom + 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                localizations.intervalRange,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              tooltip: localizations.close,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        Text(
                          localizations.intervalRangeHint,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 14),
                        _buildIntervalPickerRow(
                          context: context,
                          label: localizations.start,
                          surah: startSurah,
                          ayah: startAyah,
                          onSurahChanged: (value) {
                            _notifyAudioUserActivity();
                            setSheetState(() {
                              startSurah = value;
                              startAyah = startAyah
                                  .clamp(1, quran.getVerseCount(startSurah))
                                  .toInt();
                              errorText = null;
                            });
                          },
                          onAyahChanged: (value) {
                            _notifyAudioUserActivity();
                            setSheetState(() {
                              startAyah = value;
                              errorText = null;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildIntervalPickerRow(
                          context: context,
                          label: localizations.end,
                          surah: endSurah,
                          ayah: endAyah,
                          onSurahChanged: (value) {
                            _notifyAudioUserActivity();
                            setSheetState(() {
                              endSurah = value;
                              endAyah = endAyah
                                  .clamp(1, quran.getVerseCount(endSurah))
                                  .toInt();
                              errorText = null;
                            });
                          },
                          onAyahChanged: (value) {
                            _notifyAudioUserActivity();
                            setSheetState(() {
                              endAyah = value;
                              errorText = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: errorText == null
                              ? Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    _formatIntervalSummary(currentSelection()),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                )
                              : Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    errorText!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          height: 1.35,
                                        ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(localizations.cancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: applySelection,
                                child: Text(localizations.apply),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    });

    if (selected == null) return;
    if (!mounted) return;
    if (!enableIntervalAfterSelection && !_repeatIntervalEnabled) {
      setState(() {
        _resetPlaybackCounters();
        _playbackInterval = selected;
      });
      unawaited(_persistPlaybackOptions());
      return;
    }

    final QuranPosition start = selected.start;
    final QuranPosition currentPlayingPosition = _playingPosition;
    final bool hasActivePlayback =
        (_playerMounted || _isVersePlaying || _isVerseLoading) &&
        _playingVerse != null;
    final bool shouldStartPlayback =
        enableIntervalAfterSelection || _isVersePlaying || _isVerseLoading;
    final bool shouldKeepCurrentPlayback =
        hasActivePlayback && selected.contains(currentPlayingPosition);

    _beginPlayerSettleAnimation('repeat interval expands player');
    setState(() {
      if (!shouldKeepCurrentPlayback) {
        _resetPlaybackCounters();
      }
      _playbackInterval = selected;
      _repeatIntervalEnabled =
          enableIntervalAfterSelection || _repeatIntervalEnabled;
      if (_repeatIntervalEnabled) {
        _continuousPlayback = false;
      }
      _playerVisible = true;
      _playerMounted = true;
      _playerMinimized = false;
      _playerMinimizedSettled = false;
      _playerCollapseProgress = 0;
      _playingVerse = shouldKeepCurrentPlayback
          ? currentPlayingPosition.ayah
          : start.ayah;
    });
    unawaited(_persistPlaybackOptions());
    _syncReadingPlayerRefreshMode('repeat interval configured');
    unawaited(_updateKeepScreenOn());
    if (shouldKeepCurrentPlayback) {
      await _refreshUpcomingReadingAudioSequenceForModeChange();
      return;
    }
    if (!shouldStartPlayback) {
      return;
    }
    await _playVerse(start.surah, start.ayah);
  }

  Future<void> _seekBottomPlayer(double value) async {
    if (_playerDuration.inMilliseconds <= 0) return;
    final int milliseconds = (_playerDuration.inMilliseconds * value).round();
    final Duration position = Duration(milliseconds: milliseconds);
    _setPlayerPosition(
      position,
      render: true,
      allowBackward: true,
      canEstimateFromSample: _isVersePlaying && !_isVerseLoading,
    );
    await _seekCurrentVerseAudio(position);
  }

  Widget _buildIntervalPickerRow({
    required BuildContext context,
    required String label,
    required int surah,
    required int ayah,
    required ValueChanged<int> onSurahChanged,
    required ValueChanged<int> onAyahChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final int maxAyah = quran.getVerseCount(surah);

    Future<void> pickSurah() async {
      _notifyAudioUserActivity();
      final int? selected = await _showNumberChoiceDialog(
        title: localizations.intervalPickerTitle(
          localizations.surahOption,
          label,
        ),
        icon: Icons.menu_book_rounded,
        selectedValue: surah,
        min: 1,
        max: 114,
        titleBuilder: (value) =>
            '$value. ${localizedSurahName(localizations, value)}',
      );
      if (selected == null || !mounted) return;
      onSurahChanged(selected);
    }

    Future<void> pickAyah() async {
      _notifyAudioUserActivity();
      final int? selected = await _showNumberChoiceDialog(
        title: localizations.intervalPickerTitle(
          localizations.ayahsLabel,
          label,
        ),
        icon: Icons.format_list_numbered_rounded,
        selectedValue: ayah.clamp(1, maxAyah).toInt(),
        min: 1,
        max: maxAyah,
        titleBuilder: localizations.ayahNumber,
      );
      if (selected == null || !mounted) return;
      onAyahChanged(selected);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _NumberStepperTile(
                    label: localizations.surahOption,
                    value: surah,
                    min: 1,
                    max: 114,
                    helper: localizedSurahName(localizations, surah),
                    onTap: pickSurah,
                    onChanged: onSurahChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberStepperTile(
                    label: localizations.ayahsLabel,
                    value: ayah.clamp(1, maxAyah).toInt(),
                    min: 1,
                    max: maxAyah,
                    helper: '1-$maxAyah',
                    onTap: pickAyah,
                    onChanged: onAyahChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomPlayerSeekStart(double value) {
    _notifyAudioUserActivity();
    _isBottomPlayerSeeking = true;
    FrameRatePolicyManager.instance.setUserDragging(
      true,
      source: _readPlayerSeekSource,
      reason: 'read_player_seek_start',
    );
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(true));
    _syncBottomPlayerProgressPolicy();
    unawaited(_seekBottomPlayer(value));
  }

  void _handleBottomPlayerSeekEnd(double value) {
    unawaited(_seekBottomPlayer(value));
    _isBottomPlayerSeeking = false;
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readPlayerSeekSource,
      reason: 'read_player_seek_end',
    );
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
    _syncBottomPlayerProgressPolicy();
  }

  Future<void> _scrollToVerseIfNeeded(int verse, {bool smooth = false}) {
    if (_viewMode) {
      _scrollUp();
      return Future<void>.value();
    }

    return _scrollToInlineVerse(verse, smooth: smooth);
  }

  Future<void> _scrollToInlineVerse(
    int verse, {
    bool animate = true,
    bool smooth = false,
    bool highlight = false,
  }) {
    if (_viewMode) {
      _scrollUp();
      return Future<void>.value();
    }

    final Completer<void> completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) {
        completer.complete();
        return;
      }

      _isProgrammaticPageScroll = true;
      try {
        final double offset = _scrollOffsetForVerse(verse);
        if (animate) {
          await _scrollController.animateTo(
            offset,
            duration: smooth
                ? const Duration(milliseconds: 700)
                : const Duration(milliseconds: 320),
            curve: smooth ? Curves.easeInOutCubic : Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(offset);
        }
      } catch (_) {
        // Programmatic scroll is a visual affordance; playback must continue.
      } finally {
        if (mounted) {
          _isProgrammaticPageScroll = false;
          if (highlight) {
            _highlightInlineVerseBriefly(verse);
            await WidgetsBinding.instance.endOfFrame;
          }
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    return completer.future;
  }

  void _increase() {
    _vibrate();
    _scrollUp();
    unawaited(_markCurrentRoutineAyahRead());
    if (!_viewMode) {
      _goToNextSurah();
      return;
    }

    if (_playerMounted) {
      _stopBottomPlayer();
    }

    if (_currentVerse != _totalVerses) {
      _incrementVerse();
      _updateDB();
    } else {
      // Surah completed: remove its last-read progress, then move to next chapter.
      BookmarkDB().delete(_currentChapter);
      _reset();
      if (_currentChapter != 114) {
        _incrementChapter();
      } else {
        _resetChapter();
      }
      _getTotalVerses();
      _updateDB();
    }
  }

  void _decrease() {
    _vibrate();
    _scrollUp();
    if (!_viewMode) {
      _goToPreviousSurah();
      return;
    }

    if (_playerMounted) {
      _stopBottomPlayer();
    }

    if (_currentVerse != 1) {
      _decrementVerse();
      _updateDB();
    } else {
      _goToPreviousSurah();
    }
  }

  void _goToNextSurah() {
    if (_playerMounted || _playingVerse != null) {
      unawaited(_stopBottomPlayer());
    }
    BookmarkDB().delete(_currentChapter);
    _clearVerseTextMetrics();
    setState(() {
      _currentChapter = _currentChapter == 114 ? 1 : _currentChapter + 1;
      _currentVerse = 1;
      _totalVerses = quran.getVerseCount(_currentChapter);
      _isDownloadingSurahAyahs = AudioDownloadService()
          .isSurahAyahsDownloadInProgress(_currentChapter);
      _hasDownloadedSurahAyahs = false;
    });
    unawaited(_refreshSurahAyahDownloadState());
    unawaited(_loadChapterTransliterations());
    _updateDB();
  }

  void _goToPreviousSurah() {
    if (_currentChapter == 1) return;
    if (_playerMounted || _playingVerse != null) {
      unawaited(_stopBottomPlayer());
    }
    _clearVerseTextMetrics();
    final int previousChapter = _currentChapter - 1;
    setState(() {
      _currentChapter = previousChapter;
      _totalVerses = quran.getVerseCount(_currentChapter);
      _currentVerse = _totalVerses;
      _isDownloadingSurahAyahs = AudioDownloadService()
          .isSurahAyahsDownloadInProgress(_currentChapter);
      _hasDownloadedSurahAyahs = false;
    });
    unawaited(_refreshSurahAyahDownloadState());
    unawaited(_refreshCurrentAyahDownloadState());
    unawaited(_loadChapterTransliterations());
    _updateDB();
  }

  void _incrementVerse() {
    setState(() {
      _currentVerse++;
    });
  }

  void _setVerse(int value) {
    setState(() {
      _currentVerse = value;
    });
    unawaited(_refreshCurrentAyahDownloadState());
  }

  void _decrementVerse() {
    setState(() {
      _currentVerse--;
    });
  }

  void _reset() {
    setState(() {
      _currentVerse = 1;
    });
  }

  void _getTotalVerses() {
    _clearVerseTextMetrics();
    setState(() {
      _totalVerses = quran.getVerseCount(_currentChapter);
    });
  }

  void _incrementChapter() {
    _clearVerseTextMetrics();
    setState(() {
      _currentChapter++;
    });
    unawaited(_loadChapterTransliterations());
  }

  void _resetChapter() {
    _clearVerseTextMetrics();
    setState(() {
      _currentChapter = 1;
    });
    unawaited(_loadChapterTransliterations());
  }

  void _vibrate() async {
    if (SettingsDB().get("vibration", defaultValue: true) != true) return;
    if (kIsWeb) return;

    final bool supportedPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!supportedPlatform) return;

    try {
      final bool hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;
      await Vibration.vibrate(duration: 10);
    } catch (_) {
      // Ignore vibration failures on unsupported platforms/devices.
    }
  }

  void _scrollUp() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  void _updateDB() {
    if (!_isRoutineReading) {
      BookmarkDB().addReadingEntry(_currentChapter, _currentVerse);
      _recordReadingProgress(_currentChapter, _currentVerse);
    }
    unawaited(_refreshCurrentAyahDownloadState());
  }

  Future<void> _markCurrentRoutineAyahRead() async {
    if (!_isRoutineReading) return;
    final int chapter = _currentChapter;
    final int verse = _currentVerse;
    await _recordRoutineReadingProgress(chapter, verse);
    if (!mounted) return;
    setState(() {});
  }

  void _recordReadingProgress(int surah, int verse) {
    final int safeSurah = surah.clamp(1, 114).toInt();
    final int safeVerse = verse
        .clamp(1, quran.getVerseCount(safeSurah))
        .toInt();
    final DateTime now = DateTime.now();
    final String todayKey = _readingDateKey(now);

    if (_isRoutineReading) {
      unawaited(_recordRoutineReadingProgress(safeSurah, safeVerse));
      return;
    }

    unawaited(
      ResumeStateDB().put(
        'reading:$safeSurah',
        ResumeStateEntry(
          id: 'reading:$safeSurah',
          kind: 'reading',
          surah: safeSurah,
          ayah: safeVerse,
          title: quran.getSurahName(safeSurah),
          subtitle: 'Ayah $safeVerse',
          updatedAt: now,
        ),
      ),
    );

    _recordAyahStats(safeSurah, safeVerse, now: now, todayKey: todayKey);
  }

  Future<void> _recordRoutineReadingProgress(int surah, int verse) async {
    final int safeSurah = surah.clamp(1, 114).toInt();
    final int safeVerse = verse
        .clamp(1, quran.getVerseCount(safeSurah))
        .toInt();
    final DateTime now = DateTime.now();
    final String todayKey = _readingDateKey(now);
    await _advanceActiveReadingPlans(
      safeSurah,
      safeVerse,
      routineId: widget.routineId!,
    );
    _recordAyahStats(safeSurah, safeVerse, now: now, todayKey: todayKey);
  }

  void _recordAyahStats(
    int safeSurah,
    int safeVerse, {
    required DateTime now,
    required String todayKey,
  }) {
    if (_isVersePlaying && _continuousPlayback) return;

    final String key = '$safeSurah:$safeVerse';
    final dynamic existingActivity = QuranActivityDB().get(todayKey);
    final QuranActivityDay activity = existingActivity is QuranActivityDay
        ? existingActivity
        : QuranActivityDay(dateKey: todayKey, updatedAt: now);
    final Set<String> readKeys = activity.readAyahKeys.toSet();
    final bool isNewToday = readKeys.add(key);

    if (!isNewToday) return;

    final QuranActivityDay updatedActivity = QuranActivityDay(
      dateKey: todayKey,
      ayahsRead: activity.ayahsRead + 1,
      pagesRead: activity.pagesRead,
      listeningSeconds: activity.listeningSeconds,
      readingSeconds: activity.readingSeconds,
      readAyahKeys: readKeys.toList()..sort(),
      updatedAt: now,
      schemaVersion: activity.schemaVersion,
    );
    unawaited(QuranActivityDB().put(todayKey, updatedActivity));

    final dynamic existingStats = QuranStatsDB().get('summary');
    final QuranStatsSnapshot stats = existingStats is QuranStatsSnapshot
        ? existingStats
        : QuranStatsSnapshot(id: 'summary', updatedAt: now);
    unawaited(
      QuranStatsDB().put(
        'summary',
        QuranStatsSnapshot(
          id: 'summary',
          totalAyahsRead: stats.totalAyahsRead + 1,
          estimatedLettersRead:
              stats.estimatedLettersRead +
              _estimatedArabicLetters(safeSurah, safeVerse),
          listeningSeconds: stats.listeningSeconds,
          totalReadingSeconds: stats.totalReadingSeconds,
          currentStreak: _readingStreakIncluding(todayKey),
          updatedAt: now,
          schemaVersion: stats.schemaVersion,
        ),
      ),
    );
  }

  Future<void> _advanceActiveReadingPlans(
    int surah,
    int verse, {
    required String routineId,
  }) async {
    final int globalAyah = _globalAyahIndex(surah, verse);
    final DateTime now = DateTime.now();
    final String todayKey = _readingDateKey(now);
    for (final ReadingPlanEntry plan
        in ReadingPlansDB().box.values.whereType<ReadingPlanEntry>()) {
      if (!plan.active ||
          plan.id != routineId ||
          globalAyah < plan.startGlobalAyah ||
          globalAyah > plan.targetGlobalAyah) {
        continue;
      }
      final RoutineDayProgressEntry? existingProgress = RoutineDayProgressDB()
          .progressFor(plan.id, todayKey);
      final Set<int> completedTodayGlobalAyahs =
          (existingProgress?.completedGlobalAyahs ?? const <int>[])
              .where(
                (int ayah) =>
                    ayah >= plan.startGlobalAyah &&
                    ayah <= plan.targetGlobalAyah,
              )
              .toSet()
            ..add(globalAyah);
      final Set<int> completedGlobalAyahs = routineProgressSummary(
        plan,
      ).completedGlobalAyahs..addAll(completedTodayGlobalAyahs);
      final RoutineProgressSummary updatedProgress = routineProgressSummary(
        plan,
      );
      final int completedToday = updatedProgress.todayRequiredGlobalAyahs
          .where(completedGlobalAyahs.contains)
          .length
          .clamp(0, updatedProgress.todayPortionAyahs)
          .toInt();
      await RoutineDayProgressDB().saveProgress(
        RoutineDayProgressEntry(
          routineId: plan.id,
          dateKey: todayKey,
          currentSurah: surah,
          currentAyah: verse,
          completedAyahCount: completedToday,
          lastOpenedSurah: surah,
          lastOpenedAyah: verse,
          updatedAt: now,
          completedGlobalAyahs: completedGlobalAyahs.toList()..sort(),
        ),
      );
      final int updatedLastCompleted = routineContiguousCompletedGlobalAyah(
        plan,
        completedGlobalAyahs,
      );
      if (updatedLastCompleted != plan.lastCompletedGlobalAyah) {
        await ReadingPlansDB().put(
          plan.id,
          ReadingPlanEntry(
            id: plan.id,
            type: plan.type,
            title: plan.title,
            startedAt: plan.startedAt,
            finishBy: plan.finishBy,
            startGlobalAyah: plan.startGlobalAyah,
            targetGlobalAyah: plan.targetGlobalAyah,
            lastCompletedGlobalAyah: updatedLastCompleted,
            active: plan.active,
            schemaVersion: plan.schemaVersion,
          ),
        );
      }
    }
  }

  void _updateVerseFromProgress({
    required double localDx,
    required double localDy,
    required double width,
    bool vibrateOnChange = false,
  }) {
    if (_totalVerses <= 0 || width <= 0) return;

    final double startDx = _scrubStartDx ?? localDx;
    final double startDy = _scrubStartDy ?? localDy;
    final int anchorVerse = _scrubStartVerse ?? _currentVerse;
    final double downwardOffset = (localDy - startDy).clamp(
      0.0,
      double.infinity,
    );

    double precision = 1.0;
    if (downwardOffset > 120) {
      precision = 0.12;
    } else if (downwardOffset > 80) {
      precision = 0.2;
    } else if (downwardOffset > 40) {
      precision = 0.35;
    } else if (downwardOffset > 16) {
      precision = 0.6;
    }

    if ((precision - _scrubPrecision).abs() > 0.0001) {
      _scrubPrecision = precision;
      _scrubStartDx = localDx;
      _scrubStartDy = localDy;
      _scrubStartVerse = _currentVerse;
      return;
    }

    final double verseDelta =
        (((localDx - startDx) * precision) / width) * (_totalVerses - 1);
    final int preciseTargetVerse = (anchorVerse + verseDelta.round()).clamp(
      1,
      _totalVerses,
    );

    if (preciseTargetVerse == _currentVerse) return;

    _setVerse(preciseTargetVerse);
    _updateDB();

    if (vibrateOnChange) {
      _vibrate();
    }
  }

  Widget _buildProgressBar(double marginValue) {
    if (_isRoutineReading) {
      return _buildRoutineProgressBar(marginValue);
    }

    final EquranColors colors = context.equranColors;
    final double progress = _totalVerses <= 0
        ? 0
        : (_currentVerse / _totalVerses).clamp(0.0, 1.0).toDouble();
    final BorderRadius radius = BorderRadius.circular(AppRadii.pill);

    return Padding(
      padding: EdgeInsets.fromLTRB(marginValue, 12, marginValue, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: (details) =>
                    _handleProgressScrubStart(details, constraints.maxWidth),
                onLongPressMoveUpdate: (details) =>
                    _handleProgressScrubUpdate(details, constraints.maxWidth),
                onLongPressEnd: (_) => _resetProgressScrub(),
                onLongPressCancel: _resetProgressScrub,
                child: SizedBox(
                  height: 12,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: radius,
                      child: SizedBox(
                        height: 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.border,
                                borderRadius: radius,
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: progress),
                              duration: _isScrubbingProgress
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              builder: (context, animatedProgress, child) {
                                return FractionallySizedBox(
                                  alignment: AlignmentDirectional.centerStart,
                                  widthFactor: animatedProgress,
                                  child: child,
                                );
                              },
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: radius,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineProgressBar(double marginValue) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ReadingPlanEntry? plan = _routinePlanForPage();
    if (plan == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(marginValue, 12, marginValue, 8),
        child: const SizedBox.shrink(),
      );
    }

    final RoutineProgressSummary progress = routineProgressSummary(plan);
    final BorderRadius radius = BorderRadius.circular(AppRadii.pill);
    final int completedToday = progress.todayCompletedAyahs.clamp(
      0,
      progress.todayPortionAyahs,
    );
    final int todayQuota = progress.todayPortionAyahs;

    return Padding(
      padding: EdgeInsets.fromLTRB(marginValue, 10, marginValue, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withAlpha(230),
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: colors.border.withAlpha(150)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    localizations.readingRoutine,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    localizations.completedTodayQuota(
                      completedToday,
                      todayQuota,
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (progress.catchUpAyahs > 0)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.mint,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          localizations.includesCatchUpAyahs(
                            progress.catchUpAyahs,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: radius,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: progress.todayFraction),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedProgress, child) {
                          return FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: animatedProgress.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: radius,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ReadingPlanEntry? _routinePlanForPage() {
    final String? routineId = widget.routineId;
    if (routineId == null || routineId.isEmpty) return null;
    for (final ReadingPlanEntry plan
        in ReadingPlansDB().box.values.whereType<ReadingPlanEntry>()) {
      if (plan.id == routineId && plan.active) return plan;
    }
    return null;
  }

  void _handleProgressScrubStart(LongPressStartDetails details, double width) {
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(true));
    FrameRatePolicyManager.instance.setUserDragging(
      true,
      source: _readProgressScrubSource,
      reason: 'read_progress_scrub_start',
    );
    setState(() {
      _isScrubbingProgress = true;
      _scrubStartVerse = _currentVerse;
      _scrubStartDx = details.localPosition.dx;
      _scrubStartDy = details.localPosition.dy;
      _scrubPrecision = 1.0;
    });
    _updateVerseFromProgress(
      localDx: details.localPosition.dx,
      localDy: details.localPosition.dy,
      width: width,
    );
  }

  void _handleProgressScrubUpdate(
    LongPressMoveUpdateDetails details,
    double width,
  ) {
    _updateVerseFromProgress(
      localDx: details.localPosition.dx,
      localDy: details.localPosition.dy,
      width: width,
      vibrateOnChange: true,
    );
  }

  void _resetProgressScrub() {
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readProgressScrubSource,
      reason: 'read_progress_scrub_end',
    );
    setState(() {
      _isScrubbingProgress = false;
      _scrubStartVerse = null;
      _scrubStartDx = null;
      _scrubStartDy = null;
      _scrubPrecision = 1.0;
    });
  }

  void _setPlayerMinimized(bool minimized) {
    if (!mounted || _playerMinimized == minimized) return;
    _beginPlayerSettleAnimation(
      minimized ? 'player minimizing' : 'player expanding',
    );
    setState(() {
      _playerMinimized = minimized;
      _playerMinimizedSettled = false;
      _playerCollapseProgress = minimized ? 1 : 0;
      _isDraggingPlayerBar = false;
    });
    _syncBottomPlayerProgressPolicy(syncPosition: !minimized);
    if (!minimized) {
      _syncBottomPlayerProgressValue();
      _syncBottomPlayerDurationValue();
    }
  }

  void _handlePlayerBarDragStart(DragStartDetails details) {
    _beginPlayerInteraction('player drag start');
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(true));
    _playerBarDragDistance = 0;
    _playerBarDragStartProgress = _playerCollapseProgress;
    if (_playerMinimizedSettled) {
      setState(() {
        _isDraggingPlayerBar = true;
        _playerMinimizedSettled = false;
      });
    } else {
      _isDraggingPlayerBar = true;
    }
    _syncBottomPlayerProgressPolicy();
  }

  void _handlePlayerBarDragUpdate(DragUpdateDetails details) {
    _playerBarDragDistance += details.primaryDelta ?? 0;
    final double width = MediaQuery.sizeOf(context).width;
    final double dragRange = width < 900 ? 110 : 96;
    setState(() {
      _playerCollapseProgress =
          (_playerBarDragStartProgress + (_playerBarDragDistance / dragRange))
              .clamp(0.0, 1.0);
    });
  }

  void _handlePlayerBarDragCancel() {
    _playerBarDragDistance = 0;
    _isDraggingPlayerBar = false;
    _isPlayerGestureActive = false;
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readPlayerDragSource,
      reason: 'player drag cancel',
    );
    if (_playerMinimized) {
      setState(() {
        _playerCollapseProgress = 1;
        _playerMinimizedSettled = true;
      });
    }
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
    _syncBottomPlayerProgressPolicy();
    _syncReadingPlayerRefreshMode(
      'player drag cancel',
      scheduleLowRefresh: true,
    );
  }

  void _handlePlayerBarDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    final double distance = _playerBarDragDistance;
    final double progress = _playerCollapseProgress;
    _playerBarDragDistance = 0;
    _isDraggingPlayerBar = false;
    _isPlayerGestureActive = false;
    FrameRatePolicyManager.instance.setUserDragging(
      false,
      source: _readPlayerDragSource,
      reason: 'player drag end',
    );
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));

    if (_playerMinimized) {
      if (distance <= -_playerBarExpandDistance ||
          velocity <= -_playerBarMinVelocity ||
          progress <= 0.55) {
        _setPlayerMinimized(false);
        return;
      }

      if (distance >= _playerBarDismissDistance ||
          velocity >= _playerBarMinVelocity) {
        unawaited(_stopBottomPlayer());
        return;
      }
      setState(() {
        _playerCollapseProgress = 1;
        _playerMinimizedSettled = true;
      });
      _syncBottomPlayerProgressPolicy();
      _syncReadingPlayerRefreshMode(
        'player minimized drag settled',
        scheduleLowRefresh: true,
      );
      return;
    }

    if (distance >= _playerBarMinimizeDistance ||
        velocity >= _playerBarMinVelocity ||
        progress >= 0.45) {
      _setPlayerMinimized(true);
      return;
    }

    setState(() {
      _playerCollapseProgress = 0;
      _playerMinimizedSettled = false;
    });
    _syncBottomPlayerProgressPolicy();
    _beginPlayerSettleAnimation('player expanded drag settled');
  }

  void _resetCardSwipeGesture() {
    _cardSwipeStartX = null;
    _cardSwipeDistance = 0;
    _cardSwipeVerticalDistance = 0;
  }

  void _handleCardSwipeStart(DragStartDetails details) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double width = mediaQuery.size.width;
    final double startX = details.localPosition.dx;
    final double leftSystemInset = mediaQuery.systemGestureInsets.left;
    final double rightSystemInset = mediaQuery.systemGestureInsets.right;
    final double leftBlockedEdge = max(
      _cardSwipeEdgeInset,
      leftSystemInset + 12,
    );
    final double rightBlockedEdge = max(
      _cardSwipeEdgeInset,
      rightSystemInset + 12,
    );
    final bool startsAtEdge =
        startX <= leftBlockedEdge || startX >= width - rightBlockedEdge;

    _cardSwipeStartX = startsAtEdge ? null : startX;
    _cardSwipeDistance = 0;
    _cardSwipeVerticalDistance = 0;
  }

  void _handleCardSwipeUpdate(DragUpdateDetails details) {
    if (_cardSwipeStartX == null) return;
    _cardSwipeDistance += details.delta.dx;
    _cardSwipeVerticalDistance += details.delta.dy.abs();
  }

  void _handleCardSwipeEnd(DragEndDetails details) {
    if (_cardSwipeStartX == null) {
      _resetCardSwipeGesture();
      return;
    }

    final double distance = _cardSwipeDistance;
    final double verticalDistance = _cardSwipeVerticalDistance;
    final double velocity = details.primaryVelocity ?? 0;
    final double minDistance = min(
      140.0,
      max(_cardSwipeMinDistance, MediaQuery.sizeOf(context).width * 0.12),
    );
    final double assistedDistance = min(
      84.0,
      max(_cardSwipeAssistDistance, minDistance * 0.56),
    );
    final double horizontalDistance = distance.abs();
    final bool isMostlyHorizontal =
        horizontalDistance >= verticalDistance * _cardSwipeAxisLockRatio;

    _resetCardSwipeGesture();

    if (!isMostlyHorizontal) return;

    final bool triggersForward =
        distance <= -minDistance ||
        (distance <= -assistedDistance && velocity <= -_cardSwipeMinVelocity);
    final bool triggersBackward =
        distance >= minDistance ||
        (distance >= assistedDistance && velocity >= _cardSwipeMinVelocity);

    final bool reverseSwipeDirection =
        Directionality.of(context) == TextDirection.rtl;
    if (triggersForward) {
      reverseSwipeDirection ? _decrease() : _increase();
    } else if (triggersBackward) {
      reverseSwipeDirection ? _increase() : _decrease();
    }
  }

  Widget _buildVersePlayerBar() {
    if (_playerMinimizedSettled) {
      return _wrapPlayerRefreshPointerGate(_buildStaticMinimizedPlayerBar());
    }

    return _wrapPlayerRefreshPointerGate(
      ReadVersePlayerBar(
        viewMode: _viewMode,
        isMounted: _playerMounted,
        isVisible: _playerVisible,
        isMinimized: _playerMinimized,
        isMinimizedSettled: _playerMinimizedSettled,
        isDragging: _isDraggingPlayerBar,
        isPlaying: _isVersePlaying,
        isLoading: _isVerseLoading,
        continuousPlayback: _continuousPlayback,
        repeatIntervalEnabled: _repeatIntervalEnabled,
        collapseProgress: _playerCollapseProgress,
        currentChapter: _currentChapter,
        currentVerse: _currentVerse,
        totalVerses: _totalVerses,
        playingVerse: _playingVerse,
        positionListenable: _playerPositionValue,
        durationListenable: _playerDurationValue,
        onHidden: _handleVersePlayerHidden,
        onMinimizedSettled: _handleVersePlayerMinimizedSettled,
        onExpand: () => _setPlayerMinimized(false),
        onDismiss: () => unawaited(_stopBottomPlayer()),
        onVerticalDragStart: _handlePlayerBarDragStart,
        onVerticalDragUpdate: _handlePlayerBarDragUpdate,
        onVerticalDragEnd: _handlePlayerBarDragEnd,
        onVerticalDragCancel: _handlePlayerBarDragCancel,
        onSeekStart: _handleBottomPlayerSeekStart,
        onSeek: (value) => unawaited(_seekBottomPlayer(value)),
        onSeekEnd: _handleBottomPlayerSeekEnd,
        onTogglePlayPause: () => unawaited(_toggleBottomPlayer()),
        onContinuousPlaybackChanged: _toggleContinuousPlayback,
        onRepeatIntervalPressed: _handleRepeatIntervalPressed,
        onAdvancedOptionsPressed: _showAdvancedPlaybackOptions,
        onPlayPrevious: () => unawaited(_playAdjacentPageViewAyah(-1)),
        onPlayNext: () => unawaited(_playAdjacentPageViewAyah(1)),
        canPlayPrevious: _canPlayPreviousAyah,
        canPlayNext: _canPlayNextAyah,
        isDownloaded: _isVerseDownloaded(
          _currentChapter,
          _playingVerse ?? _currentVerse,
        ),
      ),
    );
  }

  Widget _wrapPlayerRefreshPointerGate(Widget child) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePlayerBarPointerDown,
      onPointerUp: _handlePlayerBarPointerUp,
      onPointerCancel: _handlePlayerBarPointerCancel,
      child: child,
    );
  }

  Widget _buildStaticMinimizedPlayerBar() {
    if (!_playerMounted) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final double width = MediaQuery.sizeOf(context).width;
    final double horizontalInset = _viewMode
        ? _readCardHorizontalInset(width)
        : (width > 700 ? 16 : 8);
    final int verse = _playingVerse ?? _currentVerse;

    // Guaranteed static minimized mode: no ValueListenableBuilder, Slider,
    // StreamBuilder, progress text, opacity wrapper, or progress subtree.
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, 13),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            colorScheme.primary.withAlpha(10),
            colorScheme.surfaceContainerLow.withAlpha((0.92 * 255).round()),
          ),
          borderRadius: BorderRadius.circular(AppRadii.large),
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha((0.52 * 255).round()),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colorScheme.shadow.withAlpha((0.12 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 65,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: _isVerseLoading
                          ? 'Reconnecting'
                          : _isVersePlaying
                          ? 'Pause'
                          : 'Play',
                      onPressed: _isVerseLoading
                          ? null
                          : () => unawaited(_toggleBottomPlayer()),
                      icon: _isVerseLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              _isVersePlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                      color: colorScheme.primary,
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.large),
                        onTap: () => _setPlayerMinimized(false),
                        child: SizedBox(
                          height: double.infinity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    localizedSurahAyahLabel(
                                      AppLocalizations.of(context)!,
                                      _currentChapter,
                                      verse,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_isVerseDownloaded(
                                  _currentChapter,
                                  verse,
                                )) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.offline_pin_rounded,
                                    size: 15,
                                    color: _isVersePlaying
                                        ? Colors.green
                                        : colorScheme.onSurfaceVariant
                                              .withAlpha(140),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.dismissPlayer,
                      onPressed: () => unawaited(_stopBottomPlayer()),
                      icon: const Icon(Icons.close_rounded),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleVersePlayerHidden() {
    if (!mounted || _playerVisible) return;
    _playerSettleTimer?.cancel();
    _isPlayerGestureActive = false;
    _isPlayerSettleAnimating = false;
    _syncReadingPlayerRefreshMode('player hidden', forceLowRefresh: true);
    setState(() {
      _playerMounted = false;
      _playerMinimizedSettled = false;
    });
    _syncBottomPlayerProgressPolicy();
    _syncReadingPlayerRefreshMode('player hidden complete');
  }

  void _handleVersePlayerMinimizedSettled() {
    if (!mounted || !_playerVisible || !_playerMinimized) return;
    if (_playerMinimizedSettled) return;
    setState(() {
      _playerMinimizedSettled = true;
    });
    _syncBottomPlayerProgressPolicy();
    _finishPlayerSettleAnimation('player minimized animation complete');
  }

  void _handleRepeatIntervalPressed() {
    if (_repeatIntervalEnabled) {
      setState(() {
        _repeatIntervalEnabled = false;
      });
      unawaited(_updateKeepScreenOn());
      return;
    }

    unawaited(_showIntervalSelectionSheet(enableIntervalAfterSelection: true));
  }

  Future<void> _showAdvancedPlaybackOptions() async {
    _notifyAudioUserActivity();
    await _withLowFpsSuppressed(() {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final ThemeData theme = Theme.of(sheetContext);
              final ColorScheme colorScheme = theme.colorScheme;
              final AppLocalizations localizations = AppLocalizations.of(
                sheetContext,
              )!;
              final double rate = _playbackRate();
              final bool currentAyahDownloading = _downloadingAyahKeys.contains(
                '$_currentChapter-$_currentVerse',
              );

              Future<void> selectReciter() async {
                final AppReciter? selected = await _showReciterPickerDialog();
                if (selected == null || !mounted) return;
                await SettingsDB().put("reciter", selected.code);

                final bool isDownloading = AudioDownloadService()
                    .isSurahAyahsDownloadInProgress(_currentChapter);
                setState(() {
                  _isDownloadingSurahAyahs = isDownloading;
                  _hasDownloadedSurahAyahs = false;
                  _hasDownloadedCurrentAyah = false;
                });
                unawaited(_refreshSurahAyahDownloadState());
                unawaited(_refreshCurrentAyahDownloadState());

                if (_playerMounted || _isVersePlaying || _isVerseLoading) {
                  _playbackRequestId++;
                  final QuranPosition position = _playingPosition;
                  await _playVerse(
                    position.surah,
                    position.ayah,
                    continuous: _continuousPlayback,
                    smoothScroll: false,
                    preservePlayerPresentationState: true,
                    preserveRefreshState: true,
                    resetPlaybackCounters: false,
                  );
                }
                if (!sheetContext.mounted) return;
                setSheetState(() {});
              }

              Future<void> selectIntervalRepeat() async {
                final RepeatChoice? selected = await _showRepeatChoiceDialog(
                  title: localizations.intervalRepeatOption,
                  icon: Icons.repeat_rounded,
                  selectedValue: _intervalRepeatChoice,
                );
                if (selected == null) return;
                setState(() {
                  _intervalRepeatChoice = selected;
                  _intervalCyclesCompleted = 0;
                });
                unawaited(_persistPlaybackOptions());
                if (_playerMounted || _isVersePlaying || _isVerseLoading) {
                  final QuranPosition position = _playingPosition;
                  unawaited(
                    _playVerse(
                      position.surah,
                      position.ayah,
                      continuous: _continuousPlayback,
                      smoothScroll: false,
                      preservePlayerPresentationState: true,
                      preserveRefreshState: true,
                      resetPlaybackCounters: false,
                    ),
                  );
                }
                if (sheetContext.mounted) setSheetState(() {});
              }

              Future<void> selectRepeatAyah() async {
                final RepeatChoice? selected = await _showRepeatChoiceDialog(
                  title: localizations.repeatEachAyahOption,
                  icon: Icons.repeat_one_rounded,
                  selectedValue: _repeatAyahChoice,
                );
                if (selected == null) return;
                setState(() {
                  _repeatAyahChoice = selected;
                  _currentAyahPlayCount = 1;
                });
                unawaited(_persistPlaybackOptions());
                if (_playerMounted || _isVersePlaying || _isVerseLoading) {
                  final QuranPosition position = _playingPosition;
                  unawaited(
                    _playVerse(
                      position.surah,
                      position.ayah,
                      continuous: _continuousPlayback,
                      smoothScroll: false,
                      preservePlayerPresentationState: true,
                      preserveRefreshState: true,
                      resetPlaybackCounters: false,
                    ),
                  );
                }
                if (sheetContext.mounted) setSheetState(() {});
              }

              Future<void> resetOptions() async {
                setState(() {
                  _ayahDelaySeconds = 0;
                  _playbackInterval = null;
                  _repeatIntervalEnabled = false;
                  _intervalRepeatChoice = RepeatChoice.infinite;
                  _repeatAyahChoice = RepeatChoice.one;
                  _resetPlaybackCounters();
                });
                await _setPlaybackRate(1.0);
                await _persistPlaybackOptions();
                if (_playerMounted || _isVersePlaying || _isVerseLoading) {
                  final QuranPosition position = _playingPosition;
                  unawaited(
                    _playVerse(
                      position.surah,
                      position.ayah,
                      continuous: _continuousPlayback,
                      smoothScroll: false,
                      preservePlayerPresentationState: true,
                      preserveRefreshState: true,
                      resetPlaybackCounters: false,
                    ),
                  );
                }
                if (sheetContext.mounted) setSheetState(() {});
                unawaited(_updateKeepScreenOn());
              }

              Future<void> downloadSurahAudio() async {
                if (!sheetContext.mounted) return;
                final AppLocalizations localizations = AppLocalizations.of(
                  context,
                )!;
                final String surahName = localizedSurahName(
                  localizations,
                  _currentChapter,
                );
                final bool? confirm = await _withLowFpsSuppressed(() {
                  return showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: const Icon(Icons.download_for_offline_rounded),
                      title: Text(localizations.downloadAllAyahs),
                      content: Text(
                        localizations.downloadAllAyahsForSurah(surahName),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(localizations.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(localizations.download),
                        ),
                      ],
                    ),
                  );
                });

                if (confirm != true) return;

                // Rebuild sheet to show downloading state immediately
                setSheetState(() {});

                // Trigger download in background without blocking the sheet
                unawaited(
                  _downloadCurrentSurahAyahs().then((_) {
                    if (sheetContext.mounted) {
                      setSheetState(() {});
                    }
                  }),
                );
              }

              Future<void> toggleCurrentAyahAudio() async {
                if (!sheetContext.mounted) return;
                if (_hasDownloadedCurrentAyah) {
                  await _confirmDeleteCurrentAyahDownload();
                } else {
                  await _downloadCurrentAyah();
                }
                if (sheetContext.mounted) {
                  setSheetState(() {});
                }
              }

              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.78,
                minChildSize: 0.42,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(18),
                              borderRadius: BorderRadius.circular(
                                AppRadii.medium,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  localizations.playbackOptions,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  localizations.customizeRecitationBehavior,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildAudioDownloadOptionsSection(
                        context: context,
                        currentAyahDownloading: currentAyahDownloading,
                        onDownloadSurah: () => unawaited(downloadSurahAudio()),
                        onToggleCurrentAyah: () =>
                            unawaited(toggleCurrentAyahAudio()),
                        downloadProgressNotifier:
                            _surahDownloadProgressNotifier,
                      ),
                      const SizedBox(height: 10),
                      _buildPlaybackOptionsSection(
                        context: context,
                        title: localizations.recitation,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(
                              Icons.record_voice_over_rounded,
                            ),
                            title: Text(localizations.reciter),
                            subtitle: Text(
                              _localizedReciterName(
                                QuranAudioService().selectedReciter,
                                localizations,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: selectReciter,
                          ),
                          _buildSliderOption(
                            context: context,
                            title: localizations.playbackSpeed,
                            subtitle: '${rate.toStringAsFixed(2)}x',
                            value: rate,
                            min: 0.5,
                            max: 2.0,
                            divisions: 6,
                            label: '${rate.toStringAsFixed(2)}x',
                            onChanged: (value) async {
                              final double normalized = _normalizePlaybackRate(
                                value,
                              );
                              await _setPlaybackRate(normalized);
                              if (mounted) setState(() {});
                              if (sheetContext.mounted) setSheetState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPlaybackOptionsSection(
                        context: context,
                        title: localizations.timing,
                        children: <Widget>[
                          _buildSliderOption(
                            context: context,
                            title: localizations.ayahDelay,
                            subtitle: _delayLabel(_ayahDelaySeconds),
                            value: _delaySteps
                                .indexOf(_ayahDelaySeconds)
                                .clamp(0, 11)
                                .toDouble(),
                            min: 0,
                            max: 11,
                            divisions: 11,
                            label: _delayLabel(_ayahDelaySeconds),
                            onChanged: (value) {
                              setState(() {
                                final int idx = value.round().clamp(
                                  0,
                                  _delaySteps.length - 1,
                                );
                                _ayahDelaySeconds = _delaySteps[idx];
                              });
                              setSheetState(() {});
                              unawaited(_persistPlaybackOptions());
                            },
                            onChangeEnd: (value) {
                              if (_playerMounted ||
                                  _isVersePlaying ||
                                  _isVerseLoading) {
                                final QuranPosition position = _playingPosition;
                                unawaited(
                                  _playVerse(
                                    position.surah,
                                    position.ayah,
                                    continuous: _continuousPlayback,
                                    smoothScroll: false,
                                    preservePlayerPresentationState: true,
                                    preserveRefreshState: true,
                                    resetPlaybackCounters: false,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPlaybackOptionsSection(
                        context: context,
                        title: localizations.intervalOption,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.segment_rounded),
                            title: Text(localizations.intervalOption),
                            subtitle: Text(
                              _formatIntervalSummary(_playbackInterval),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () async {
                              await _showIntervalSelectionSheet();
                              if (sheetContext.mounted) setSheetState(() {});
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.repeat_rounded),
                            title: Text(localizations.intervalRepeatOption),
                            subtitle: Text(
                              _intervalRepeatChoice.localizedLabel(
                                localizations,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: selectIntervalRepeat,
                          ),
                          ListTile(
                            leading: const Icon(Icons.repeat_one_rounded),
                            title: Text(localizations.repeatEachAyahOption),
                            subtitle: Text(
                              _repeatAyahChoice.localizedLabel(localizations),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: selectRepeatAyah,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPlaybackOptionsSection(
                        context: context,
                        title: localizations.sleepTimerOption,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.bedtime_outlined),
                            title: Text(localizations.sleepTimerOption),
                            subtitle: Text(_sleepTimerOptionsSubtitle()),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () async {
                              await _showUpgradedSleepTimerSheet();
                              if (sheetContext.mounted) {
                                setSheetState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: resetOptions,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(localizations.resetPlaybackOptions),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    });
  }

  double _readCardHorizontalInset(double width) {
    if (width > 1200) return 120;
    if (width > 700) return 40;
    return 6;
  }

  Widget _buildFixedPlayerBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: RepaintBoundary(child: _buildVersePlayerBar()),
    );
  }

  Widget _buildNavigationButtons({bool fixed = false}) {
    final EquranColors colors = context.equranColors;
    final double width = MediaQuery.sizeOf(context).width;
    final double horizontalInset = _viewMode
        ? _readCardHorizontalInset(width)
        : (width > 700 ? 16 : 8);
    final Widget buttons = Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton.tonal(
              onPressed: () => _decrease(),
              style: FilledButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.border),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                minimumSize: const Size(58, 44),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.arrow_back_rounded, size: 22),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _increase(),
              style: FilledButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.border),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                minimumSize: const Size(58, 44),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.arrow_forward_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget insetButtons = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: buttons,
    );

    if (!fixed) return insetButtons;
    return Align(alignment: Alignment.bottomCenter, child: insetButtons);
  }

  Widget _buildCardViewBottomBars() {
    return RepaintBoundary(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildVersePlayerBar(),
            const SizedBox(height: 0),
            _buildNavigationButtons(fixed: true),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCurrentAyahImage() async {
    if (_isPreparingShareImage) return;

    final _ShareImageMode? mode = await _chooseShareImageMode();
    if (mode == null) return;
    if (!mounted) return;
    _shareImageMode = mode;

    final RenderObject? pageRenderObject = context.findRenderObject();
    final Rect? shareOrigin = pageRenderObject is RenderBox
        ? pageRenderObject.localToGlobal(Offset.zero) & pageRenderObject.size
        : null;
    String shareStep = 'preparing';

    try {
      await _pauseReadingAudioForShare();
      await _loadChapterTransliterations();
      if (SettingsDB().quranScriptStyle == 'qpc-v4') {
        final int currentPage = EquranTextStyles.getPageNumber(
          _currentChapter,
          _currentVerse,
        );
        await QpcV4FontService.instance.ensureFontLoadedForPage(currentPage);
      }
      if (!mounted) return;

      _isPreparingShareImage = true;

      shareStep = 'rendering';
      final Uint8List pngBytes = await _renderShareImagePng();
      shareStep = 'writing';
      final Directory tempDirectory = await getTemporaryDirectory();
      final File shareFile = File(
        '${tempDirectory.path}/equran_${mode.name}_${_currentChapter}_${_currentVerse}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await shareFile.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;
      _isPreparingShareImage = false;

      shareStep = 'opening share sheet';
      await SharePlus.instance.share(
        ShareParams(
          title: 'eQuran ayah',
          subject: '${quran.getSurahName(_currentChapter)} ayah $_currentVerse',
          files: <XFile>[XFile(shareFile.path, mimeType: 'image/png')],
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to share ayah image while $shareStep: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'equran share image',
          context: ErrorDescription('while $shareStep'),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode
                ? 'Unable to share ayah image while $shareStep: $error'
                : 'Unable to share ayah image.',
          ),
        ),
      );
    } finally {
      _isPreparingShareImage = false;
    }
  }

  Future<_ShareImageMode?> _chooseShareImageMode() {
    return showModalBottomSheet<_ShareImageMode>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        final EquranColors colors = context.equranColors;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Share image format',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final _ShareImageMode mode in _ShareImageMode.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                        side: BorderSide(color: colors.border),
                      ),
                      tileColor: mode == _shareImageMode
                          ? colors.mint
                          : colors.surface,
                      leading: Icon(
                        mode == _ShareImageMode.story
                            ? Icons.stay_current_portrait_rounded
                            : mode == _ShareImageMode.square
                            ? Icons.crop_square_rounded
                            : Icons.image_outlined,
                        color: colors.primary,
                      ),
                      title: Text(
                        mode.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${mode.size.width.toInt()} x ${mode.size.height.toInt()}',
                      ),
                      onTap: () => Navigator.of(context).pop(mode),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pauseReadingAudioForShare() async {
    if (!_playerMounted && !_isVerseLoading) return;

    _playbackRequestId++;
    _visibleProgressRequestId = _playbackRequestId;
    _activeProgressSource = null;
    _visibleProgressSource = null;
    _isPreparingReadingAudioSource = false;
    setState(() {
      _resetPlaybackCounters();
      _isVersePlaying = false;
      _isVerseLoading = false;
      _continuousPlayback = false;
      _repeatIntervalEnabled = false;
    });
    await _pauseCurrentVerseAudio();
    await AndroidAudioDisplayMode.setAudioPlaybackActive(false);
    await _setKeepScreenOn(false);
  }

  Future<Uint8List> _renderShareImagePng() async {
    final Size shareImageSize = _shareImageMode.size;
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
    final RenderView renderView = RenderView(
      view: View.of(context),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(shareImageSize),
        physicalConstraints: BoxConstraints.tight(shareImageSize),
        devicePixelRatio: 1,
      ),
      child: repaintBoundary,
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
          container: repaintBoundary,
          child: _buildShareImageWidget(),
        ).attachToRenderTree(buildOwner);

    try {
      return await _captureShareImagePng(
        repaintBoundary,
        pipelineOwner: pipelineOwner,
        buildOwner: buildOwner,
        rootElement: rootElement,
      );
    } finally {
      pipelineOwner.rootNode = null;
    }
  }

  Future<Uint8List> _captureShareImagePng(
    RenderRepaintBoundary repaintBoundary, {
    required PipelineOwner pipelineOwner,
    required BuildOwner buildOwner,
    required RenderObjectToWidgetElement<RenderBox> rootElement,
  }) async {
    Object? lastError;

    for (int attempt = 0; attempt < 12; attempt++) {
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      try {
        final image = await repaintBoundary.toImage(pixelRatio: 1);
        try {
          final ByteData? byteData = await image.toByteData(
            format: ImageByteFormat.png,
          );
          if (byteData == null) {
            throw StateError('Unable to encode share image.');
          }
          return byteData.buffer.asUint8List();
        } finally {
          image.dispose();
        }
      } catch (error) {
        lastError = error;
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }

    throw StateError('Unable to render share image: $lastError');
  }

  Widget _buildShareImageWidget() {
    final ThemeData theme = Theme.of(context);
    final Size shareImageSize = _shareImageMode.size;
    final bool showTransliteration =
        SettingsDB().get("showTransliteration", defaultValue: false) == true;
    final bool showTranslation =
        SettingsDB().get("enableTranslation", defaultValue: true) == true;
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final String verseText = quranVerseText(_currentChapter, _currentVerse);
    final String translation = quran.cleanTranslationText(
      quran.getVerseTranslation(
        _currentChapter,
        _currentVerse,
        translation: quran
            .Translation
            .values[SettingsDB().get("translation", defaultValue: 0)],
      ),
    );
    final String transliteration = _transliterationForVerse(_currentVerse);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: shareImageSize,
          devicePixelRatio: 1,
          textScaler: TextScaler.noScaling,
        ),
        child: Theme(
          data: theme,
          child: SizedBox(
            width: shareImageSize.width,
            height: shareImageSize.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color.alphaBlend(
                      theme.colorScheme.primary.withAlpha(18),
                      backgroundColor,
                    ),
                    backgroundColor,
                    Color.alphaBlend(
                      theme.colorScheme.tertiary.withAlpha(14),
                      backgroundColor,
                    ),
                  ],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Size canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final layout = _shareImageContentLayout(
                    theme: theme,
                    canvasSize: canvasSize,
                    mode: _shareImageMode,
                    verseText: verseText,
                    translation: translation,
                    transliteration: transliteration,
                    showTranslation: showTranslation,
                    showTransliteration: showTransliteration,
                    reference:
                        'eQuran • ${quran.getSurahName(_currentChapter)} $_currentVerse',
                  );

                  return Padding(
                    padding: layout.canvasPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: layout.headerWidth,
                          child: _ShareImageHeader(
                            chapter: _currentChapter,
                            verse: _currentVerse,
                            mode: _shareImageMode,
                            compact: layout.compactHeader,
                          ),
                        ),
                        SizedBox(height: layout.headerGap),
                        SizedBox(
                          width: layout.cardWidth,
                          height: layout.cardHeight,
                          child: _ShareImageAyahContent(
                            chapter: _currentChapter,
                            verse: _currentVerse,
                            verseText: verseText,
                            translation: translation,
                            transliteration: transliteration,
                            showTranslation: showTranslation,
                            showTransliteration: showTransliteration,
                            reference:
                                'eQuran • ${quran.getSurahName(_currentChapter)} $_currentVerse',
                            layout: layout,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ShareImageContentLayout _shareImageContentLayout({
    required ThemeData theme,
    required Size canvasSize,
    required _ShareImageMode mode,
    required String verseText,
    required String translation,
    required String transliteration,
    required bool showTranslation,
    required bool showTransliteration,
    required String reference,
  }) {
    final double baseCanvasInset = switch (mode) {
      _ShareImageMode.square => 48,
      _ShareImageMode.classic => 58,
      _ShareImageMode.story => 52,
    };
    final double analysisWidth = max(1, canvasSize.width - baseCanvasInset * 2);
    final double baseArabicFontSize = shareArabicFontSizeForText(verseText);
    final double baseTranslationFontSize = min(
      shareTranslationFontSizeForText(verseText),
      shareTranslationFontSizeForText(translation),
    );
    final int textWeight =
        verseText.runes.length +
        (showTranslation ? (translation.runes.length * 0.45).round() : 0) +
        (showTransliteration
            ? (transliteration.runes.length * 0.35).round()
            : 0);
    final int estimatedLines =
        _measureShareTextLineCount(
          verseText,
          _shareArabicTextStyle(baseArabicFontSize),
          analysisWidth * 0.86,
          TextDirection.rtl,
        ) +
        (showTranslation
            ? _measureShareTextLineCount(
                translation,
                _shareTranslationTextStyle(theme, baseTranslationFontSize),
                analysisWidth * 0.86,
                TextDirection.ltr,
              )
            : 0) +
        (showTransliteration && transliteration.trim().isNotEmpty
            ? _measureShareTextLineCount(
                transliteration,
                _shareTransliterationTextStyle(theme, 22),
                analysisWidth * 0.86,
                TextDirection.ltr,
              )
            : 0);
    final _ShareImageContentTier tier = _shareImageTierFor(
      textWeight: textWeight,
      lineCount: estimatedLines,
    );

    final double edgeInset = (baseCanvasInset * _tierCanvasInsetFactor(tier))
        .clamp(28.0, baseCanvasInset)
        .toDouble();
    final EdgeInsets canvasPadding = EdgeInsets.fromLTRB(
      edgeInset,
      edgeInset,
      edgeInset,
      edgeInset * 0.78,
    );
    final double safeWidth = max(
      1,
      canvasSize.width - canvasPadding.horizontal,
    );
    final double safeHeight = max(
      1,
      canvasSize.height - canvasPadding.vertical,
    );
    final bool compactHeader =
        tier == _ShareImageContentTier.long ||
        tier == _ShareImageContentTier.veryLong ||
        mode == _ShareImageMode.square;
    final double headerHeight = compactHeader ? 96 : 118;
    final double headerGap = switch (tier) {
      _ShareImageContentTier.compact =>
        mode == _ShareImageMode.square ? 12 : 18,
      _ShareImageContentTier.medium => mode == _ShareImageMode.square ? 10 : 16,
      _ShareImageContentTier.long => 12,
      _ShareImageContentTier.veryLong => 8,
    };
    final double maxCardHeight = max(1, safeHeight - headerHeight - headerGap);
    final double initialCardWidth = _shareCardWidthForTier(
      safeWidth: safeWidth,
      tier: tier,
    );

    double cardWidth = initialCardWidth;
    double horizontalPadding = _tierHorizontalPadding(tier);
    double verticalPadding = _tierVerticalPadding(tier);
    double arabicFontSize = baseArabicFontSize
        .clamp(_tierMinArabicFontSize(tier), _tierMaxArabicFontSize(tier))
        .toDouble();
    double translationFontSize = baseTranslationFontSize
        .clamp(
          _tierMinTranslationFontSize(tier),
          _tierMaxTranslationFontSize(tier),
        )
        .toDouble();
    double transliterationFontSize = _tierTransliterationFontSize(tier);
    double arabicGap = _tierArabicGap(tier);
    double translationDividerTopGap = _tierTranslationDividerTopGap(tier);
    double translationDividerBottomGap = _tierTranslationDividerBottomGap(tier);
    double footerDividerTopGap = _tierFooterDividerTopGap(tier);
    double footerDividerBottomGap = _tierFooterDividerBottomGap(tier);

    double requiredHeight = 0;
    for (int attempt = 0; attempt < 5; attempt++) {
      final double textWidth = max(1, cardWidth - horizontalPadding * 2);
      requiredHeight =
          _measureShareContentHeight(
            theme: theme,
            textWidth: textWidth,
            verseText: verseText,
            translation: translation,
            transliteration: transliteration,
            showTranslation: showTranslation,
            showTransliteration: showTransliteration,
            reference: reference,
            arabicFontSize: arabicFontSize,
            translationFontSize: translationFontSize,
            transliterationFontSize: transliterationFontSize,
            footerFontSize: _tierFooterFontSize(tier),
            arabicGap: arabicGap,
            translationDividerTopGap: translationDividerTopGap,
            translationDividerBottomGap: translationDividerBottomGap,
            footerDividerTopGap: footerDividerTopGap,
            footerDividerBottomGap: footerDividerBottomGap,
          ) +
          verticalPadding * 2;
      if (requiredHeight <= maxCardHeight) {
        break;
      }
      cardWidth = min(safeWidth, cardWidth + safeWidth * 0.05);
      horizontalPadding = max(
        _tierMinHorizontalPadding(tier),
        horizontalPadding - 4,
      );
      verticalPadding = max(_tierMinVerticalPadding(tier), verticalPadding - 4);
      arabicFontSize = max(_tierMinArabicFontSize(tier), arabicFontSize - 2);
      translationFontSize = max(
        _tierMinTranslationFontSize(tier),
        translationFontSize - 1,
      );
      transliterationFontSize = max(16, transliterationFontSize - 1);
      arabicGap = max(10, arabicGap - 2);
      translationDividerTopGap = max(10, translationDividerTopGap - 2);
      translationDividerBottomGap = max(10, translationDividerBottomGap - 2);
      footerDividerTopGap = max(8, footerDividerTopGap - 2);
      footerDividerBottomGap = max(6, footerDividerBottomGap - 1);
    }

    final double minCardHeight = min(maxCardHeight, _tierMinCardHeight(tier));
    final double breathingRoom = requiredHeight <= maxCardHeight
        ? _tierBreathingRoom(tier)
        : 0;
    final double cardHeight = (requiredHeight + breathingRoom)
        .clamp(minCardHeight, maxCardHeight)
        .toDouble();

    return _ShareImageContentLayout(
      tier: tier,
      canvasPadding: canvasPadding,
      headerWidth: min(cardWidth, safeWidth),
      headerGap: headerGap,
      compactHeader: compactHeader,
      cardWidth: min(cardWidth, safeWidth),
      cardHeight: cardHeight,
      cardPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      arabicFontSize: arabicFontSize,
      translationFontSize: translationFontSize,
      transliterationFontSize: transliterationFontSize,
      footerFontSize: _tierFooterFontSize(tier),
      arabicGap: arabicGap,
      translationDividerTopGap: translationDividerTopGap,
      translationDividerBottomGap: translationDividerBottomGap,
      footerDividerTopGap: footerDividerTopGap,
      footerDividerBottomGap: footerDividerBottomGap,
      scaleContentDown: requiredHeight > maxCardHeight,
    );
  }

  _ShareImageContentTier _shareImageTierFor({
    required int textWeight,
    required int lineCount,
  }) {
    if (textWeight <= 130 && lineCount <= 5) {
      return _ShareImageContentTier.compact;
    }
    if (textWeight <= 340 && lineCount <= 10) {
      return _ShareImageContentTier.medium;
    }
    if (textWeight <= 760 && lineCount <= 18) {
      return _ShareImageContentTier.long;
    }
    return _ShareImageContentTier.veryLong;
  }

  double _shareCardWidthForTier({
    required double safeWidth,
    required _ShareImageContentTier tier,
  }) {
    final double widthFactor = switch (tier) {
      _ShareImageContentTier.compact => 0.68,
      _ShareImageContentTier.medium => 0.80,
      _ShareImageContentTier.long => 0.94,
      _ShareImageContentTier.veryLong => 1.0,
    };
    final double minWidth = switch (tier) {
      _ShareImageContentTier.compact => min(safeWidth, 560),
      _ShareImageContentTier.medium => min(safeWidth, 680),
      _ShareImageContentTier.long => min(safeWidth, 820),
      _ShareImageContentTier.veryLong => min(safeWidth, 920),
    };
    return max(
      minWidth,
      safeWidth * widthFactor,
    ).clamp(1.0, safeWidth).toDouble();
  }

  double _tierCanvasInsetFactor(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 1.0,
    _ShareImageContentTier.medium => 0.92,
    _ShareImageContentTier.long => 0.78,
    _ShareImageContentTier.veryLong => 0.58,
  };

  double _tierHorizontalPadding(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 36,
    _ShareImageContentTier.medium => 38,
    _ShareImageContentTier.long => 32,
    _ShareImageContentTier.veryLong => 26,
  };

  double _tierVerticalPadding(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 32,
    _ShareImageContentTier.medium => 36,
    _ShareImageContentTier.long => 30,
    _ShareImageContentTier.veryLong => 24,
  };

  double _tierMinHorizontalPadding(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 28,
        _ShareImageContentTier.medium => 28,
        _ShareImageContentTier.long => 24,
        _ShareImageContentTier.veryLong => 20,
      };

  double _tierMinVerticalPadding(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 26,
    _ShareImageContentTier.medium => 26,
    _ShareImageContentTier.long => 22,
    _ShareImageContentTier.veryLong => 18,
  };

  double _tierMinArabicFontSize(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 62,
    _ShareImageContentTier.medium => 48,
    _ShareImageContentTier.long => 34,
    _ShareImageContentTier.veryLong => 28,
  };

  double _tierMaxArabicFontSize(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 86,
    _ShareImageContentTier.medium => 74,
    _ShareImageContentTier.long => 58,
    _ShareImageContentTier.veryLong => 42,
  };

  double _tierMinTranslationFontSize(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 23,
        _ShareImageContentTier.medium => 20,
        _ShareImageContentTier.long => 17,
        _ShareImageContentTier.veryLong => 16,
      };

  double _tierMaxTranslationFontSize(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 28,
        _ShareImageContentTier.medium => 25,
        _ShareImageContentTier.long => 22,
        _ShareImageContentTier.veryLong => 20,
      };

  double _tierTransliterationFontSize(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 24,
        _ShareImageContentTier.medium => 22,
        _ShareImageContentTier.long => 19,
        _ShareImageContentTier.veryLong => 17,
      };

  double _tierFooterFontSize(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 17,
    _ShareImageContentTier.medium => 16,
    _ShareImageContentTier.long => 15,
    _ShareImageContentTier.veryLong => 14,
  };

  double _tierArabicGap(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 22,
    _ShareImageContentTier.medium => 22,
    _ShareImageContentTier.long => 16,
    _ShareImageContentTier.veryLong => 12,
  };

  double _tierTranslationDividerTopGap(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 24,
        _ShareImageContentTier.medium => 22,
        _ShareImageContentTier.long => 16,
        _ShareImageContentTier.veryLong => 12,
      };

  double _tierTranslationDividerBottomGap(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 22,
        _ShareImageContentTier.medium => 20,
        _ShareImageContentTier.long => 15,
        _ShareImageContentTier.veryLong => 12,
      };

  double _tierFooterDividerTopGap(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 24,
        _ShareImageContentTier.medium => 20,
        _ShareImageContentTier.long => 14,
        _ShareImageContentTier.veryLong => 10,
      };

  double _tierFooterDividerBottomGap(_ShareImageContentTier tier) =>
      switch (tier) {
        _ShareImageContentTier.compact => 12,
        _ShareImageContentTier.medium => 10,
        _ShareImageContentTier.long => 8,
        _ShareImageContentTier.veryLong => 7,
      };

  double _tierMinCardHeight(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 240,
    _ShareImageContentTier.medium => 330,
    _ShareImageContentTier.long => 500,
    _ShareImageContentTier.veryLong => 620,
  };

  double _tierBreathingRoom(_ShareImageContentTier tier) => switch (tier) {
    _ShareImageContentTier.compact => 10,
    _ShareImageContentTier.medium => 16,
    _ShareImageContentTier.long => 10,
    _ShareImageContentTier.veryLong => 0,
  };

  TextStyle _shareArabicTextStyle(double fontSize) {
    return TextStyle(
      fontFamily: EquranTextStyles.fontFamilyForVerse(
        _currentChapter,
        _currentVerse,
      ),
      fontFamilyFallback: const <String>['UthmanicHafs'],
      fontSize: fontSize,
      height: 1.82,
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle _shareTranslationTextStyle(ThemeData theme, double fontSize) {
    return (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      height: 1.52,
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle _shareTransliterationTextStyle(ThemeData theme, double fontSize) {
    return (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      height: 1.42,
      fontWeight: FontWeight.w600,
    );
  }

  double _measureShareContentHeight({
    required ThemeData theme,
    required double textWidth,
    required String verseText,
    required String translation,
    required String transliteration,
    required bool showTranslation,
    required bool showTransliteration,
    required String reference,
    required double arabicFontSize,
    required double translationFontSize,
    required double transliterationFontSize,
    required double footerFontSize,
    required double arabicGap,
    required double translationDividerTopGap,
    required double translationDividerBottomGap,
    required double footerDividerTopGap,
    required double footerDividerBottomGap,
  }) {
    double height = _measureShareTextHeight(
      verseText,
      _shareArabicTextStyle(arabicFontSize),
      textWidth,
      TextDirection.rtl,
    );

    if (showTransliteration && transliteration.trim().isNotEmpty) {
      height += arabicGap;
      height += _measureShareTextHeight(
        transliteration,
        _shareTransliterationTextStyle(theme, transliterationFontSize),
        textWidth,
        TextDirection.ltr,
      );
    }

    if (showTranslation) {
      height += translationDividerTopGap + 1 + translationDividerBottomGap;
      height += _measureShareTextHeight(
        translation,
        _shareTranslationTextStyle(theme, translationFontSize),
        textWidth,
        TextDirection.ltr,
      );
    }

    height += footerDividerTopGap + 1 + footerDividerBottomGap;
    height += _measureShareTextHeight(
      reference,
      (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
        fontSize: footerFontSize,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      textWidth,
      TextDirection.ltr,
    );
    return height;
  }

  double _measureShareTextHeight(
    String text,
    TextStyle style,
    double maxWidth,
    TextDirection textDirection,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: max(1, maxWidth));
    return painter.height;
  }

  int _measureShareTextLineCount(
    String text,
    TextStyle style,
    double maxWidth,
    TextDirection textDirection,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: max(1, maxWidth));
    return painter.computeLineMetrics().length;
  }

  Widget _buildSurahIntroCard({required double marginValue}) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool arabicMode = isArabicLocalizations(localizations);
    final String surahName = quran.getSurahNameArabic(_currentChapter);
    final String englishName = quran.getSurahNameEnglish(_currentChapter);
    final int verseCount = quran.getVerseCount(_currentChapter);
    final String revelation = _localizedRevelationPlace(localizations);
    final int juzNumber = quran.getJuzNumber(_currentChapter, 1);
    final bool showBasmala = _currentChapter != 1 && _currentChapter != 9;
    final BorderRadius radius = BorderRadius.circular(20);

    return Padding(
      padding: EdgeInsets.fromLTRB(marginValue, 8, marginValue, 10),
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  colors.primaryGradientStart,
                  colors.primaryGradientEnd,
                ],
              ),
              border: Border.all(color: colors.accentGold.withAlpha(115)),
            ),
            child: CustomPaint(
              painter: _SurahIntroOrnamentPainter(
                color: colors.accentGold.withAlpha(153),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EquranSpacing.pagePadding,
                  20,
                  EquranSpacing.pagePadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        surahName,
                        maxLines: 1,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          textStyle: theme.textTheme.displaySmall,
                          color: colors.onPrimary,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          height: 1.08,
                        ),
                      ),
                    ),
                    if (!arabicMode) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimaryMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 100,
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.accentGold.withAlpha(89),
                      ),
                    ),
                    if (showBasmala) ...<Widget>[
                      const SizedBox(height: 20),
                      Text(
                        SettingsDB().quranScriptStyle == 'indopak'
                            ? 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'
                            : SettingsDB().quranScriptStyle == 'qpc-hafs'
                            ? 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ'
                            : SettingsDB().quranScriptStyle == 'qpc-v4'
                            ? 'ﱁ ﱂ ﱃ ﱄ'
                            : quranBasmalaText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: SettingsDB().quranScriptStyle == 'qpc-v4'
                              ? EquranTextStyles.fontFamilyForPage(1)
                              : EquranTextStyles.activeFontFamily,
                          fontFamilyFallback: const <String>['UthmanicHafs'],
                          color: colors.onPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          height: 2.0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      localizations.surahIntroMeta(
                        juzNumber,
                        revelation,
                        verseCount,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.accentGold.withAlpha(191),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _localizedRevelationPlace(AppLocalizations localizations) {
    final String place = quran.getPlaceOfRevelation(_currentChapter);
    if (!isArabicLocalizations(localizations)) return place.toUpperCase();
    return place.toLowerCase() == 'makkah'
        ? localizations.makkah
        : localizations.madinah;
  }

  Widget cardView({required double marginValue}) {
    final bool compactPlayerLayout = MediaQuery.sizeOf(context).width < 700;
    final double quranCardMargin = readQuranCardHorizontalMarginForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final double expandedSpacer = compactPlayerLayout ? 392 : 304;
    final double bottomSpacer = _playerMounted
        ? lerpDouble(expandedSpacer, 132, _playerCollapseProgress)!
        : 180;

    return SafeArea(
      child: GestureDetector(
        onHorizontalDragStart: _handleCardSwipeStart,
        onHorizontalDragUpdate: _handleCardSwipeUpdate,
        onHorizontalDragEnd: _handleCardSwipeEnd,
        onHorizontalDragCancel: _resetCardSwipeGesture,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (_) {
                _notifyAudioUserActivity();
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildProgressBar(marginValue),
                    if (_currentVerse == 1)
                      _buildSurahIntroCard(marginValue: quranCardMargin),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: RepaintBoundary(
                        child: ColoredBox(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: ReadQuranCard(
                            currentChapter: _currentChapter,
                            currentVerse: _currentVerse,
                            totalVerses: _totalVerses,
                            juzNumber: quran.getJuzNumber(
                              _currentChapter,
                              _currentVerse,
                            ),
                            basmala: null,
                            verse: _cardVerseText(
                              _currentChapter,
                              _currentVerse,
                            ),
                            translation: quran.cleanTranslationText(
                              quran.getVerseTranslation(
                                _currentChapter,
                                _currentVerse,
                                translation:
                                    quran.Translation.values[SettingsDB().get(
                                      "translation",
                                      defaultValue: 0,
                                    )],
                              ),
                            ),
                            transliteration: _cardTransliterationForVerse(
                              _currentVerse,
                            ),
                            showTransliteration:
                                SettingsDB().get(
                                  "showTransliteration",
                                  defaultValue: false,
                                ) ==
                                true,
                            showTranslation:
                                SettingsDB().get(
                                  "enableTranslation",
                                  defaultValue: true,
                                ) ==
                                true,
                            fontSize: SettingsDB().get(
                              "fontSize",
                              defaultValue: 31.0,
                            ),
                            fontSizeTranslation: SettingsDB().get(
                              "fontSizeTranslation",
                              defaultValue: 12.0,
                            ),
                            onPlay: _togglePageViewPlayback,
                            onVisualOverlayChanged:
                                _handleCardVisualOverlayChanged,
                            onTafsir: () => _showTafsirSheet(_currentVerse),
                            onPrevious: _currentVerse > 1
                                ? () {
                                    _setVerse(_currentVerse - 1);
                                    _scrollUp();
                                    _updateDB();
                                  }
                                : null,
                            onNext: _currentVerse < _totalVerses
                                ? () {
                                    unawaited(_markCurrentRoutineAyahRead());
                                    _setVerse(_currentVerse + 1);
                                    _scrollUp();
                                    _updateDB();
                                  }
                                : null,
                            isPlaying:
                                _isVersePlaying &&
                                _playingVerse == _currentVerse,
                            isDownloading: _downloadingAyahKeys.contains(
                              '$_currentChapter-$_currentVerse',
                            ),
                            isDownloaded: _hasDownloadedCurrentAyah,
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      height: bottomSpacer,
                    ),
                  ],
                ),
              ),
            ),
            _buildCardViewBottomBars(),
          ],
        ),
      ),
    );
  }

  Widget listView({required double marginValue}) {
    final double fontSize = SettingsDB().get("fontSize", defaultValue: 31.0);
    final double pageMargin = marginValue > 8 ? 16 : 8;
    final bool compactPlayerLayout = MediaQuery.sizeOf(context).width < 700;
    final double playerBottomPadding = lerpDouble(
      compactPlayerLayout ? 260 : 190,
      76,
      _playerCollapseProgress,
    )!;

    return SafeArea(
      key: _pageViewViewportKey,
      child: Stack(
        children: <Widget>[
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _notifyAudioUserActivity();
              if (notification is ScrollEndNotification) {
                _syncPageProgressFromScroll();
              } else if (notification is UserScrollNotification &&
                  notification.direction == ScrollDirection.idle) {
                _syncPageProgressFromScroll();
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: 2,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: _playerMounted ? playerBottomPadding : 24,
              ),
              itemBuilder: (context, index) {
                if (index == 1) {
                  return _buildNavigationButtons();
                }

                return _buildPageViewSurahCard(
                  fontSize: fontSize,
                  pageMargin: pageMargin,
                );
              },
            ),
          ),
          _buildFixedPlayerBar(),
        ],
      ),
    );
  }

  Widget _buildPageViewSurahCard({
    required double fontSize,
    required double pageMargin,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color pageCardColor =
        theme.cardTheme.color ?? colorScheme.surfaceContainerLow;

    return Column(
      children: <Widget>[
        _buildSurahIntroCard(marginValue: pageMargin),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pageMargin, vertical: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pageCardColor,
              borderRadius: BorderRadius.circular(AppRadii.large),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(
                  (0.45 * 255).round(),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 16),
                  _buildInlineSurahText(fontSize),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineSurahText(double fontSize) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _handleInlineSurahLongPressStart,
      child: RichText(
        key: _inlineSurahTextKey,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        text: _buildInlineSurahTextSpan(fontSize, colorScheme),
      ),
    );
  }

  TextSpan _buildInlineSurahTextSpan(double fontSize, ColorScheme colorScheme) {
    if (SettingsDB().quranScriptStyle == 'qpc-v4') {
      final List<InlineSpan> children = <InlineSpan>[];
      final int? highlightedVerse = _selectedInlineVerse ?? _playingVerse;
      for (int verse = 1; verse <= _totalVerses; verse++) {
        final int page = EquranTextStyles.getPageNumber(_currentChapter, verse);
        final TextStyle style = TextStyle(
          fontFamily: EquranTextStyles.fontFamilyForPage(page),
          fontFamilyFallback: const <String>['UthmanicHafs'],
          height: 1.8,
          fontSize: fontSize,
          color: highlightedVerse == verse
              ? colorScheme.primary
              : colorScheme.onSurface,
        );
        children.add(
          TextSpan(text: _inlineVerseTextSegment(verse), style: style),
        );
      }
      return TextSpan(children: children);
    }

    final TextStyle baseStyle = TextStyle(
      fontFamily: EquranTextStyles.activeFontFamily,
      fontFamilyFallback: const <String>['UthmanicHafs'],
      height: 1.8,
      fontSize: fontSize,
      color: colorScheme.onSurface,
    );
    final String surahText = _inlineSurahText();
    final int? highlightedVerse = _selectedInlineVerse ?? _playingVerse;

    if (highlightedVerse == null ||
        highlightedVerse < 1 ||
        highlightedVerse > _totalVerses) {
      return TextSpan(text: surahText, style: baseStyle);
    }

    _ensureVerseTextMetrics();
    final List<int> lengths = _verseTextCumulativeLengths ?? <int>[0];
    if (lengths.length <= highlightedVerse) {
      return TextSpan(text: surahText, style: baseStyle);
    }

    final int start = lengths[highlightedVerse - 1];
    final int end = lengths[highlightedVerse]
        .clamp(start, surahText.length)
        .toInt();
    final TextStyle highlightStyle = baseStyle.copyWith(
      color: colorScheme.primary,
    );

    return TextSpan(
      style: baseStyle,
      children: <InlineSpan>[
        if (start > 0) TextSpan(text: surahText.substring(0, start)),
        TextSpan(text: surahText.substring(start, end), style: highlightStyle),
        if (end < surahText.length) TextSpan(text: surahText.substring(end)),
      ],
    );
  }

  void _handleInlineSurahLongPressStart(LongPressStartDetails details) {
    final RenderObject? renderObject = _inlineSurahTextKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderParagraph) return;

    final Offset localPosition = renderObject.globalToLocal(
      details.globalPosition,
    );
    final TextPosition textPosition = renderObject.getPositionForOffset(
      localPosition,
    );
    final int verse = _verseForTextOffset(textPosition.offset);
    _showAyahActions(verse);
  }

  Future<void> _showAyahActions(int verse) async {
    _inlineVerseHighlightTimer?.cancel();
    setState(() {
      _selectedInlineVerse = verse;
      _currentVerse = verse;
    });
    _updateDB();

    await _withLowFpsSuppressed(() {
      return showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          final AppLocalizations localizations = AppLocalizations.of(context)!;
          bool isFavourite = const QuranBookmarkService().isFavourite(
            _currentChapter,
            verse,
          );
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        localizedSurahAyahLabel(
                          localizations,
                          _currentChapter,
                          verse,
                        ),
                      ),
                      subtitle: Text(localizations.chooseAnAction),
                      trailing: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: LikeButton(
                            size: 28,
                            isLiked: isFavourite,
                            circleColor: CircleColor(
                              start: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(180),
                              end: Theme.of(context).colorScheme.primary,
                            ),
                            bubblesColor: BubblesColor(
                              dotPrimaryColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              dotSecondaryColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                            ),
                            likeBuilder: (bool liked) {
                              return Icon(
                                liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: liked
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                size: 28,
                              );
                            },
                            onTap: (bool liked) async {
                              if (liked) {
                                _toggleFavourite(verse, isFavourite: true);
                                if (!mounted) return false;

                                setSheetState(() {
                                  isFavourite = false;
                                });

                                return false;
                              }

                              await _showFavouriteNotePrompt(verse);
                              if (!mounted) return liked;

                              setSheetState(() {
                                isFavourite = true;
                              });

                              return true;
                            },
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.play_circle_outline_rounded),
                      title: Text(localizations.playThisAyah),
                      onTap: () {
                        Navigator.of(context).pop();
                        _playVerse(_currentChapter, verse, continuous: false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.ios_share_outlined),
                      title: Text(localizations.shareImage),
                      onTap: () {
                        Navigator.of(context).pop();
                        _shareCurrentAyahImage();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chrome_reader_mode_rounded),
                      title: Text(localizations.showTafsir),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showTafsirSheet(verse);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_note_rounded),
                      title: Text(localizations.saveToLibrary),
                      subtitle: Text(localizations.folderTagsAndNote),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showFavouriteNotePrompt(verse);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notes_rounded),
                      title: Text(localizations.ayahDetails),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showAyahDetailsSheet(verse);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
    if (!mounted) return;
    setState(() {
      _selectedInlineVerse = null;
    });
  }

  Widget _buildPlaybackOptionsSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAudioDownloadOptionsSection({
    required BuildContext context,
    required bool currentAyahDownloading,
    required VoidCallback onDownloadSurah,
    required VoidCallback onToggleCurrentAyah,
    required ValueNotifier<double?> downloadProgressNotifier,
  }) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return _buildPlaybackOptionsSection(
      context: context,
      title: localizations.audioDownloads,
      children: <Widget>[
        ValueListenableBuilder<double?>(
          valueListenable: downloadProgressNotifier,
          builder: (context, progressFraction, _) {
            final bool isCurrentlyDownloading =
                _isDownloadingSurahAyahs || progressFraction != null;
            return ListTile(
              leading: isCurrentlyDownloading
                  ? SizedBox.square(
                      dimension: 30,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            value:
                                (progressFraction == 0.0 ||
                                    progressFraction == null)
                                ? null
                                : progressFraction,
                            color: Theme.of(context).colorScheme.primary,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.outlineVariant,
                          ),
                          if (progressFraction != null &&
                              progressFraction > 0.0)
                            Text(
                              '${(progressFraction * 100).round()}%',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                        ],
                      ),
                    )
                  : Icon(
                      _hasDownloadedSurahAyahs
                          ? Icons.offline_pin_rounded
                          : Icons.download_for_offline_rounded,
                    ),
              title: Text(
                _hasDownloadedSurahAyahs
                    ? localizations.surahAudioDownloaded
                    : localizations.downloadSurahAudio,
              ),
              subtitle: Text(
                _hasDownloadedSurahAyahs
                    ? localizations.allAyahsAvailableOffline
                    : localizations.downloadEveryAyahInSurah,
              ),
              enabled: !isCurrentlyDownloading && !_hasDownloadedSurahAyahs,
              onTap: !isCurrentlyDownloading && !_hasDownloadedSurahAyahs
                  ? onDownloadSurah
                  : null,
            );
          },
        ),
        if (!_hasDownloadedSurahAyahs)
          ListTile(
            leading: Icon(
              currentAyahDownloading
                  ? Icons.downloading_rounded
                  : _hasDownloadedCurrentAyah
                  ? Icons.delete_outline_rounded
                  : Icons.download_rounded,
            ),
            title: Text(
              currentAyahDownloading
                  ? localizations.downloadingCurrentAyah
                  : _hasDownloadedCurrentAyah
                  ? localizations.deleteCurrentAyahAudio
                  : localizations.downloadCurrentAyah,
            ),
            subtitle: Text(
              localizations.surahLabel(
                localizedSurahName(localizations, _currentChapter),
                _currentVerse,
              ),
            ),
            enabled: !currentAyahDownloading,
            onTap: currentAyahDownloading ? null : onToggleCurrentAyah,
          ),
      ],
    );
  }

  Widget _buildSliderOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(subtitle),
          Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value.clamp(min, max).toDouble(),
            label: label,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }

  Future<AppReciter?> _showReciterPickerDialog() async {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final List<AppReciter> reciters = AppReciter.values.toList()
      ..sort(
        (a, b) =>
            a.englishName.toLowerCase().compareTo(b.englishName.toLowerCase()),
      );

    // Pre-fetch download status for all reciters in parallel
    final Map<String, bool> reciterDownloadedMap = {};
    await Future.wait(
      reciters.map((reciter) async {
        final bool downloaded = await _isSurahDownloadedForReciter(
          _currentChapter,
          reciter.code,
        );
        reciterDownloadedMap[reciter.code] = downloaded;
      }),
    );

    final AppReciter currentReciter = QuranAudioService().selectedReciter;

    if (!mounted) return null;

    bool groupByDownloaded = false;

    return showDialog<AppReciter>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<AppReciter> displayReciters = List.from(reciters);
            if (groupByDownloaded) {
              displayReciters.sort((a, b) {
                final bool aDownloaded = reciterDownloadedMap[a.code] ?? false;
                final bool bDownloaded = reciterDownloadedMap[b.code] ?? false;
                if (aDownloaded && !bDownloaded) return -1;
                if (!aDownloaded && bDownloaded) return 1;
                return a.englishName.toLowerCase().compareTo(
                  b.englishName.toLowerCase(),
                );
              });
            } else {
              displayReciters.sort(
                (a, b) => a.englishName.toLowerCase().compareTo(
                  b.englishName.toLowerCase(),
                ),
              );
            }

            final ThemeData theme = Theme.of(context);
            final ColorScheme colorScheme = theme.colorScheme;
            final BorderRadius borderRadius = BorderRadius.circular(
              AppRadii.large,
            );

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              backgroundColor: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                  maxHeight: 560,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ColoredBox(
                      color: colorScheme.surfaceContainer,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.record_voice_over_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localizations.reciter,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: groupByDownloaded
                                  ? 'Show Alphabetical'
                                  : 'Group Downloaded',
                              onPressed: () {
                                setDialogState(() {
                                  groupByDownloaded = !groupByDownloaded;
                                });
                              },
                              icon: Icon(
                                groupByDownloaded
                                    ? Icons.offline_pin_rounded
                                    : Icons.offline_pin_outlined,
                                color: groupByDownloaded
                                    ? Colors.green
                                    : colorScheme.onSurfaceVariant.withAlpha(
                                        160,
                                      ),
                              ),
                            ),
                            IconButton(
                              tooltip: localizations.close,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ClipRect(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: displayReciters.length,
                          itemBuilder: (context, index) {
                            final AppReciter reciter = displayReciters[index];
                            final bool isSelected = reciter == currentReciter;
                            final bool isDownloaded =
                                reciterDownloadedMap[reciter.code] ?? false;

                            Widget? leadingWidget;
                            if (isDownloaded) {
                              leadingWidget = const Icon(
                                Icons.offline_pin_rounded,
                                color: Colors.green,
                                size: 20,
                              );
                            } else {
                              leadingWidget = Icon(
                                Icons.record_voice_over_rounded,
                                color: colorScheme.onSurfaceVariant.withAlpha(
                                  60,
                                ),
                                size: 20,
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Material(
                                color: isSelected
                                    ? colorScheme.primaryContainer.withValues(
                                        alpha: 0.42,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.medium,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  leading: leadingWidget,
                                  title: Text(
                                    _localizedReciterName(
                                      reciter,
                                      localizations,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () =>
                                      Navigator.of(context).pop(reciter),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<RepeatChoice?> _showRepeatChoiceDialog({
    required String title,
    required IconData icon,
    required RepeatChoice selectedValue,
  }) {
    return showDialog<RepeatChoice>(
      context: context,
      builder: (context) => AppSelectionDialog<RepeatChoice>(
        title: title,
        icon: icon,
        selectedValue: selectedValue,
        options: RepeatChoice.values
            .map(
              (choice) => AppSelectionOption<RepeatChoice>(
                value: choice,
                title: choice.localizedLabel(AppLocalizations.of(context)!),
              ),
            )
            .toList(),
      ),
    );
  }

  String _localizedReciterName(
    AppReciter reciter,
    AppLocalizations localizations,
  ) {
    return reciter.displayName(arabic: isArabicLocalizations(localizations));
  }

  Future<int?> _showNumberChoiceDialog({
    required String title,
    required IconData icon,
    required int selectedValue,
    required int min,
    required int max,
    required String Function(int value) titleBuilder,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => AppSelectionDialog<int>(
        title: title,
        icon: icon,
        selectedValue: selectedValue,
        maxHeight: 560,
        options: List<AppSelectionOption<int>>.generate(max - min + 1, (index) {
          final int value = min + index;
          return AppSelectionOption<int>(
            value: value,
            title: titleBuilder(value),
          );
        }),
      ),
    );
  }

  String _delayLabel(double seconds) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    if (seconds <= 0) return localizations.noDelay;
    if (seconds == 0.5) return '0.5 seconds';
    return localizations.secondsCount(seconds.toInt());
  }

  Future<void> _showAyahDetailsSheet(int verse) async {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String transliteration = _transliterationForVerse(verse).trim();
    int selectedTranslationIndex = _selectedTranslationIndex();

    await _withLowFpsSuppressed(() {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) {
          final AppLocalizations localizations = AppLocalizations.of(context)!;
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final String translation = quran.cleanTranslationText(
                quran.getVerseTranslation(
                  _currentChapter,
                  verse,
                  translation:
                      quran.Translation.values[selectedTranslationIndex],
                ),
              );

              Future<void> switchLanguage() async {
                final int? value = await _showTranslationPickerDialog(
                  selectedTranslationIndex,
                );
                if (value == null || !context.mounted) return;
                final bool ready = await _saveSelectedTranslationIndex(value);
                if (!ready || !context.mounted) return;
                setSheetState(() {
                  selectedTranslationIndex = value;
                });
                if (mounted) setState(() {});
              }

              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.52,
                minChildSize: 0.36,
                maxChildSize: 0.86,
                builder: (context, controller) {
                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              localizedSurahAyahLabel(
                                localizations,
                                _currentChapter,
                                verse,
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: localizations.translationLanguage,
                            onPressed: switchLanguage,
                            icon: const Icon(Icons.language_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        quranVerseText(_currentChapter, verse),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontFamily: EquranTextStyles.activeFontFamily,
                          fontFamilyFallback: const <String>['UthmanicHafs'],
                          fontSize: _ayahDetailsArabicFontSize,
                          height: 1.7,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (transliteration.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 18),
                        Text(
                          transliteration,
                          textAlign: TextAlign.justify,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        translation,
                        textAlign: TextAlign.justify,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.55,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    });
  }

  Future<int?> _showTranslationPickerDialog(int selectedTranslation) async {
    final ResourceManifest manifest = await ResourceRepository.instance
        .loadManifest();
    if (!mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (context) => AppSelectionDialog<int>(
        title: AppLocalizations.of(context)!.translationLanguage,
        icon: Icons.translate_rounded,
        selectedValue: selectedTranslation,
        maxWidth: 420,
        maxHeight: 520,
        options:
            quran.Translation.values
                .asMap()
                .entries
                .map(
                  (entry) => AppSelectionOption<int>(
                    value: entry.key,
                    title:
                        '${translationDisplayName(entry.value)} • '
                        '${QuranTranslationService.instance.availabilityLabel(entry.value, manifest)}',
                  ),
                )
                .toList()
              ..sort((a, b) => a.title.compareTo(b.title)),
      ),
    );
  }

  Future<void> _openCardTranslationLanguagePicker() async {
    final int? value = await _withLowFpsSuppressed(
      () => _showTranslationPickerDialog(_selectedTranslationIndex()),
    );
    if (value == null || !mounted) return;
    final bool ready = await _saveSelectedTranslationIndex(value);
    if (!ready || !mounted) return;
    setState(() {});
  }

  Future<bool> _saveSelectedTranslationIndex(int value) async {
    if (value < 0 || value >= quran.Translation.values.length) return false;
    final quran.Translation translation = quran.Translation.values[value];
    final bool ready = await _ensureTranslationReady(translation);
    if (!ready) return false;
    await SettingsDB().put("translation", value);
    await QuranTranslationService.instance.loadInstalledTranslation(
      translation,
    );
    return true;
  }

  Future<bool> _ensureTranslationReady(quran.Translation translation) async {
    if (translation.isBundled) return true;
    final ResourceManifest manifest = await ResourceRepository.instance
        .loadManifest();
    final DownloadableResource? resource = QuranTranslationService.instance
        .resourceForTranslation(translation, manifest);
    if (resource == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translationNotInManifest,
            ),
          ),
        );
      }
      return false;
    }
    if (ResourceInstallStore.instance.isInstalled(resource)) return true;
    if (!mounted) return false;

    final bool? download = await showDialog<bool>(
      context: context,
      builder: (context) {
        final AppLocalizations localizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(
            localizations.downloadTranslationQuestion(
              translationDisplayName(translation),
            ),
          ),
          content: Text(
            localizations.translationNotInstalled(
              prettyBytes(getResourceSize(resource)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.download_rounded),
              label: Text(localizations.download),
            ),
          ],
        );
      },
    );
    if (download != true) return false;
    return _downloadDownloadableResource(resource);
  }

  int _selectedTranslationIndex() {
    final dynamic savedTranslation = SettingsDB().get(
      "translation",
      defaultValue: 0,
    );
    if (savedTranslation is int &&
        savedTranslation >= 0 &&
        savedTranslation < quran.Translation.values.length) {
      return savedTranslation;
    }
    return 0;
  }

  Future<void> _showTafsirSheet(int verse) async {
    Future<List<TafsirVerseResult>> loadTafsirs() {
      return TafsirService.instance.selectedVerseTafsirs(
        surah: _currentChapter,
        ayah: verse,
      );
    }

    Future<List<TafsirVerseResult>> tafsirFuture = loadTafsirs();

    await _withLowFpsSuppressed(() {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return ValueListenableBuilder<
                Map<String, ResourceDownloadProgress>
              >(
                valueListenable: ResourceDownloadService.instance.downloads,
                builder: (context, downloads, _) {
                  return FutureBuilder<List<TafsirVerseResult>>(
                    future: tafsirFuture,
                    builder: (context, tafsirSnapshot) {
                      final List<TafsirVerseResult> results =
                          tafsirSnapshot.data ?? const <TafsirVerseResult>[];
                      final bool loading =
                          tafsirSnapshot.connectionState !=
                          ConnectionState.done;

                      return DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.62,
                        minChildSize: 0.32,
                        maxChildSize: 0.92,
                        builder: (context, scrollController) {
                          final ThemeData theme = Theme.of(context);
                          final AppLocalizations localizations =
                              AppLocalizations.of(context)!;
                          return ListView(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            children: <Widget>[
                              Text(
                                localizedSurahAyahLabel(
                                  localizations,
                                  _currentChapter,
                                  verse,
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (loading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 36),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (results.isEmpty)
                                _buildNoTafsirSourcesMessage(context)
                              else
                                for (final TafsirVerseResult result
                                    in results) ...<Widget>[
                                  _buildTafsirResultCard(
                                    context: context,
                                    result: result,
                                    progress: downloads[result.resource.id],
                                    onCancel: () =>
                                        Navigator.of(context).maybePop(),
                                    onDownload: () async {
                                      final bool installed =
                                          await _downloadDownloadableResource(
                                            result.resource,
                                          );
                                      if (!installed || !context.mounted) {
                                        return;
                                      }
                                      TafsirService.instance.clearCache();
                                      setSheetState(() {
                                        tafsirFuture = loadTafsirs();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    });
  }

  Widget _buildNoTafsirSourcesMessage(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.auto_stories_outlined),
      title: Text(localizations.noTafsirSourcesSelected),
      subtitle: Text(localizations.chooseTafsirSourcesFirst),
      trailing: TextButton(
        onPressed: () async {
          await Navigator.of(context).maybePop();
          await _showTafsirSourceSelectorSheet();
        },
        child: Text(localizations.choose),
      ),
    );
  }

  Widget _buildTafsirResultCard({
    required BuildContext context,
    required TafsirVerseResult result,
    required ResourceDownloadProgress? progress,
    required VoidCallback onCancel,
    required Future<void> Function() onDownload,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ResourceInstallState state = _resourceStateFor(
      result.resource,
      progress,
    );
    final bool downloading = state == ResourceInstallState.downloading;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              result.resource.name,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (!result.installed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    localizations.tafsirNeedsDownload(
                      prettyBytes(getResourceSize(result.resource)),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: onCancel,
                        child: Text(localizations.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: downloading ? null : onDownload,
                        icon: downloading
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          downloading
                              ? progress?.phase.label ??
                                    localizations.downloading
                              : localizations.download,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (result.error != null)
              Text(result.error!, style: theme.textTheme.bodyLarge)
            else
              Text(
                result.text.isEmpty
                    ? localizations.noTafsirTextForAyah
                    : result.text,
                textAlign: TextAlign.start,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTafsirSourceSelectorSheet() async {
    final ResourceManifest manifest = await ResourceRepository.instance
        .loadManifest();
    final List<DownloadableResource> tafsirResources = manifest.resourcesOfType(
      ResourceType.tafsir,
    );

    await _withLowFpsSuppressed(() {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
        builder: (context) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.32,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return ValueListenableBuilder<int>(
                valueListenable: ResourceInstallStore.instance.changes,
                builder: (context, _, _) {
                  return ValueListenableBuilder<
                    Map<String, ResourceDownloadProgress>
                  >(
                    valueListenable: ResourceDownloadService.instance.downloads,
                    builder: (context, downloads, _) {
                      final AppLocalizations localizations =
                          AppLocalizations.of(context)!;
                      final Set<String> selectedIds = ResourceInstallStore
                          .instance
                          .selectedTafsirResourceIds(manifest)
                          .toSet();
                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: <Widget>[
                          Text(
                            localizations.tafsirSources,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          if (tafsirResources.isEmpty)
                            ListTile(
                              leading: const Icon(Icons.error_outline_rounded),
                              title: Text(
                                localizations.noTafsirResourcesAvailable,
                              ),
                            )
                          else
                            for (final DownloadableResource resource
                                in tafsirResources)
                              _buildTafsirSourceRow(
                                manifest: manifest,
                                resource: resource,
                                selected: selectedIds.contains(resource.id),
                                progress: downloads[resource.id],
                              ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    });
  }

  Widget _buildTafsirSourceRow({
    required ResourceManifest manifest,
    required DownloadableResource resource,
    required bool selected,
    required ResourceDownloadProgress? progress,
  }) {
    final ResourceInstallState state = _resourceStateFor(resource, progress);
    final bool downloading = state == ResourceInstallState.downloading;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: selected,
        onChanged: (value) => _setTafsirSourceSelected(
          manifest: manifest,
          resource: resource,
          selected: value == true,
        ),
      ),
      title: Text(resource.name),
      subtitle: Text(
        '${resource.language?.toUpperCase() ?? resource.typeLabel} • ${state.label} • ${prettyBytes(getResourceSize(resource))}',
      ),
      trailing: state == ResourceInstallState.installed
          ? const Icon(Icons.check_circle_rounded)
          : IconButton(
              tooltip: downloading
                  ? progress?.phase.label
                  : localizations.download,
              onPressed: downloading
                  ? null
                  : () => _downloadDownloadableResource(resource),
              icon: downloading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
            ),
      onTap: () => _setTafsirSourceSelected(
        manifest: manifest,
        resource: resource,
        selected: !selected,
      ),
    );
  }

  Future<void> _setTafsirSourceSelected({
    required ResourceManifest manifest,
    required DownloadableResource resource,
    required bool selected,
  }) async {
    final Set<String> selectedIds = ResourceInstallStore.instance
        .selectedTafsirResourceIds(manifest)
        .toSet();
    if (selected) {
      selectedIds.add(resource.id);
    } else {
      selectedIds.remove(resource.id);
    }
    await ResourceInstallStore.instance.saveSelectedTafsirResourceIds(
      selectedIds.toList(growable: false),
    );
    if (mounted) setState(() {});
  }

  ResourceInstallState _resourceStateFor(
    DownloadableResource resource,
    ResourceDownloadProgress? progress,
  ) {
    if (progress != null &&
        progress.phase != ResourceDownloadPhase.complete &&
        progress.phase != ResourceDownloadPhase.failed) {
      return ResourceInstallState.downloading;
    }
    return ResourceInstallStore.instance.installStateFor(resource);
  }

  Future<bool> _downloadDownloadableResource(
    DownloadableResource resource,
  ) async {
    try {
      await ResourceDownloadService.instance.downloadAndInstall(resource);
      await QuranTranslationService.instance
          .loadInstalledTranslationForResource(resource);
      if (!mounted) return true;
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.installedResource(resource.name))),
      );
      setState(() {});
      return true;
    } on ResourceInstallException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.unableInstallResource)),
        );
      }
    }
    return false;
  }

  Future<void> _showFavouriteNotePrompt(int verse) async {
    final String key = favouriteAyahKey(_currentChapter, verse);
    final dynamic existing = QuranBookmarksDB().get(key);
    final QuranBookmarkEntry? bookmark = existing is QuranBookmarkEntry
        ? existing
        : null;
    final TextEditingController noteController = TextEditingController(
      text:
          bookmark?.note ??
          FavouritesDB().get(key, defaultValue: '').toString(),
    );
    final TextEditingController folderController = TextEditingController(
      text: bookmark == null || bookmark.folder == 'Default'
          ? ''
          : bookmark.folder,
    );
    final TextEditingController tagsController = TextEditingController(
      text: bookmark?.tags.join(', ') ?? '',
    );
    bool isFavourite =
        bookmark?.isFavourite ??
        const QuranBookmarkService().isFavourite(_currentChapter, verse);
    String selectedFolder =
        bookmark?.folder ?? QuranBookmarkService.defaultFolder;
    try {
      await _withLowFpsSuppressed(() {
        return showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final ThemeData theme = Theme.of(context);
                final EquranColors colors = context.equranColors;
                final AppLocalizations localizations = AppLocalizations.of(
                  context,
                )!;
                final List<String> folders = const QuranBookmarkService()
                    .folders();
                if (!folders.contains(selectedFolder)) {
                  selectedFolder = QuranBookmarkService.defaultFolder;
                }
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    20 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          localizedSurahAyahLabel(
                            localizations,
                            _currentChapter,
                            verse,
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(
                              AppRadii.medium,
                            ),
                            border: Border.all(color: colors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              quranVerseText(_currentChapter, verse),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: EquranTextStyles.activeFontFamily,
                                fontFamilyFallback: const <String>[
                                  'UthmanicHafs',
                                ],
                                color: colors.textPrimary,
                                fontSize: 22,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(localizations.favourites),
                          value: isFavourite,
                          onChanged: (value) => setSheetState(() {
                            isFavourite = value;
                          }),
                        ),
                        TextField(
                          controller: noteController,
                          maxLines: 4,
                          minLines: 2,
                          decoration: InputDecoration(
                            labelText: localizations.privateNote,
                            hintText: localizations.writeReflectionHint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedFolder,
                                decoration: InputDecoration(
                                  labelText: localizations.folders,
                                ),
                                items: <DropdownMenuItem<String>>[
                                  for (final String folder in folders)
                                    DropdownMenuItem<String>(
                                      value: folder,
                                      child: Text(
                                        folder ==
                                                QuranBookmarkService
                                                    .defaultFolder
                                            ? localizations.unsorted
                                            : folder,
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    selectedFolder = value;
                                    folderController.text = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: localizations.createFolder,
                              style: IconButton.styleFrom(
                                backgroundColor: colors.mint,
                                foregroundColor: colors.primary,
                              ),
                              onPressed: () async {
                                final String? folder =
                                    await _showBookmarkFolderNameDialog();
                                if (folder == null) return;
                                final String created =
                                    await const QuranBookmarkService()
                                        .createFolder(folder);
                                setSheetState(() {
                                  selectedFolder = created;
                                  folderController.text = created;
                                });
                              },
                              icon: const Icon(
                                Icons.create_new_folder_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            localizations.savedAyahsOrganizedHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: tagsController,
                          decoration: InputDecoration(
                            labelText: localizations.tags,
                            hintText: localizations.tagsHint,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: () {
                                unawaited(
                                  const QuranBookmarkService().deleteBookmark(
                                    _currentChapter,
                                    verse,
                                  ),
                                );
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: Text(localizations.delete),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () {
                                unawaited(
                                  const QuranBookmarkService()
                                      .saveBookmarkDetails(
                                        _currentChapter,
                                        verse,
                                        isFavourite: isFavourite,
                                        note: noteController.text,
                                        folder: selectedFolder,
                                        tags: _parseBookmarkTags(
                                          tagsController.text,
                                        ),
                                      ),
                                );
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: Text(localizations.save),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      });
    } finally {
      await WidgetsBinding.instance.endOfFrame;
      noteController.dispose();
      folderController.dispose();
      tagsController.dispose();
    }
  }

  List<String> _parseBookmarkTags(String value) {
    final Set<String> tags = <String>{};
    for (final String tag in value.split(',')) {
      final String cleanTag = tag.trim();
      if (cleanTag.isNotEmpty) tags.add(cleanTag);
    }
    return tags.toList(growable: false)..sort();
  }

  Future<String?> _showBookmarkFolderNameDialog() async {
    final TextEditingController controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) {
          final AppLocalizations localizations = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(localizations.newFolder),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: localizations.folderName,
                hintText: localizations.folderNameHint,
              ),
              onSubmitted: (_) {
                final String value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final String value = controller.text.trim();
                  if (value.isEmpty) return;
                  Navigator.of(context).pop(value);
                },
                child: Text(localizations.create),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  void _toggleFavourite(int verse, {required bool isFavourite}) {
    if (isFavourite) {
      unawaited(
        const QuranBookmarkService().removeFavourite(_currentChapter, verse),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.removedFromFavourites),
          ),
        );
      }
      return;
    }
    unawaited(
      const QuranBookmarkService().saveFavourite(_currentChapter, verse),
    );
  }
}

class _ReadingOptionsSection extends StatelessWidget {
  const _ReadingOptionsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ReadingOptionTile extends StatelessWidget {
  const _ReadingOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color iconColor = colorScheme.primary;
    final Color textColor = colorScheme.onSurface;

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(18),
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _NumberStepperTile extends StatelessWidget {
  const _NumberStepperTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.helper,
    required this.onTap,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String helper;
  final VoidCallback onTap;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool canDecrease = value > min;
    final bool canIncrease = value < max;
    final localizations = AppLocalizations.of(context)!;
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadii.small),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    tooltip: localizations.decreaseLabel(label),
                    onPressed: canDecrease ? () => onChanged(value - 1) : null,
                    icon: const Icon(Icons.remove_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 38),
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: localizations.increaseLabel(label),
                    onPressed: canIncrease ? () => onChanged(value + 1) : null,
                    icon: const Icon(Icons.add_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                helper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareImageHeader extends StatelessWidget {
  const _ShareImageHeader({
    required this.chapter,
    required this.verse,
    required this.mode,
    required this.compact,
  });

  final int chapter;
  final int verse;
  final _ShareImageMode mode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 28,
        vertical: compact ? 16 : 22,
      ),
      decoration: BoxDecoration(
        gradient: colors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: colors.onPrimary.withAlpha(34)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  quran.getSurahName(chapter),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary,
                    fontSize: compact
                        ? 30
                        : mode == _ShareImageMode.square
                        ? 33
                        : 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ayah $verse - ${mode.label}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryMuted,
                    fontSize: compact ? 15 : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            quran.getSurahNameArabic(chapter),
            textDirection: TextDirection.rtl,
            style: EquranTextStyles.arabicSmall(
              context,
              color: colors.onPrimary,
            ).copyWith(fontSize: compact ? 25 : 30),
          ),
        ],
      ),
    );
  }
}

class _ShareImageAyahContent extends StatelessWidget {
  const _ShareImageAyahContent({
    required this.chapter,
    required this.verse,
    required this.verseText,
    required this.translation,
    required this.transliteration,
    required this.showTranslation,
    required this.showTransliteration,
    required this.reference,
    required this.layout,
  });

  final int chapter;
  final int verse;
  final String verseText;
  final String translation;
  final String transliteration;
  final bool showTranslation;
  final bool showTransliteration;
  final String reference;
  final _ShareImageContentLayout layout;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        gradient: colors.softSurfaceGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: colors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withAlpha(38),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: layout.cardPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Widget content = SizedBox(
              width: constraints.maxWidth,
              child: _ShareImageAyahTextColumn(
                chapter: chapter,
                verse: verse,
                verseText: verseText,
                translation: translation,
                transliteration: transliteration,
                showTranslation: showTranslation,
                showTransliteration: showTransliteration,
                reference: reference,
                layout: layout,
              ),
            );

            return Center(
              child: layout.scaleContentDown
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: content,
                    )
                  : content,
            );
          },
        ),
      ),
    );
  }
}

class _ShareImageAyahTextColumn extends StatelessWidget {
  const _ShareImageAyahTextColumn({
    required this.chapter,
    required this.verse,
    required this.verseText,
    required this.translation,
    required this.transliteration,
    required this.showTranslation,
    required this.showTransliteration,
    required this.reference,
    required this.layout,
  });

  final int chapter;
  final int verse;
  final String verseText;
  final String translation;
  final String transliteration;
  final bool showTranslation;
  final bool showTransliteration;
  final String reference;
  final _ShareImageContentLayout layout;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          verseText,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: EquranTextStyles.fontFamilyForVerse(chapter, verse),
            fontFamilyFallback: const <String>['UthmanicHafs'],
            fontSize: layout.arabicFontSize,
            height: 1.82,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (showTransliteration && transliteration.isNotEmpty) ...<Widget>[
          SizedBox(height: layout.arabicGap),
          Text(
            transliteration,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontSize: layout.transliterationFontSize,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (showTranslation) ...<Widget>[
          SizedBox(height: layout.translationDividerTopGap),
          Divider(height: 1, color: colors.divider),
          SizedBox(height: layout.translationDividerBottomGap),
          Text(
            translation,
            textAlign: TextAlign.justify,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
              fontSize: layout.translationFontSize,
              height: 1.52,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        SizedBox(height: layout.footerDividerTopGap),
        Divider(height: 1, color: colors.divider),
        SizedBox(height: layout.footerDividerBottomGap),
        Text(
          reference,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontSize: layout.footerFontSize,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _readingDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int _estimatedArabicLetters(int surah, int verse) {
  return quranVerseArabicLetterCount(surah, verse);
}

int _readingStreakIncluding(String todayKey) {
  final Set<String> activeDays = QuranActivityDB().box.values
      .whereType<QuranActivityDay>()
      .where(hasQuranReadingActivity)
      .map((day) => day.dateKey)
      .toSet();
  activeDays.add(todayKey);

  DateTime cursor = DateTime.now();
  int streak = 0;
  while (activeDays.contains(_readingDateKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int _globalAyahIndex(int surah, int verse) {
  int index = verse.clamp(1, quran.getVerseCount(surah)).toInt();
  for (int currentSurah = 1; currentSurah < surah; currentSurah++) {
    index += quran.getVerseCount(currentSurah);
  }
  return index.clamp(1, quran.totalVerseCount).toInt();
}

class _SurahIntroOrnamentPainter extends CustomPainter {
  const _SurahIntroOrnamentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 10;
    const double arm = 20;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    void drawCorner({required bool right, required bool bottom}) {
      final double x = right ? size.width - inset : inset;
      final double y = bottom ? size.height - inset : inset;
      final double dx = right ? -1 : 1;
      final double dy = bottom ? -1 : 1;

      final Path path = Path()
        ..moveTo(x, y + (dy * arm))
        ..lineTo(x, y)
        ..lineTo(x + (dx * arm), y)
        ..moveTo(x, y)
        ..lineTo(x, y + (dy * arm));
      canvas.drawPath(path, paint);
    }

    drawCorner(right: false, bottom: false);
    drawCorner(right: true, bottom: false);
    drawCorner(right: true, bottom: true);
    drawCorner(right: false, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _SurahIntroOrnamentPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
