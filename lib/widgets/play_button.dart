import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:equran/backend/library.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart'
    show ReaderConfirmDialog, showReaderDialog;
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:http/http.dart' as http;

class PlayButton extends StatefulWidget {
  final Future<String> url;
  final int surah;
  final int ayah;
  final Future<void> Function(int surah, int ayah)? onPlayRequested;

  const PlayButton({
    super.key,
    required this.url,
    required this.surah,
    required this.ayah,
    this.onPlayRequested,
  });

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  AppLocalizations get localizations => AppLocalizations.of(context)!;

  static const int _maxCachedAyahs = 10;
  static final LinkedHashMap<String, Uint8List> _audioCache =
      LinkedHashMap<String, Uint8List>();

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _completeSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  Timer? _progressVisualTimer;

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _hasError = false;

  double _progress = 0.0;
  double _latestProgress = 0.0;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (_audioPlayer.state == PlayerState.playing) {
        _updateProgress(position);
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
    });

    // When the audio has finished playing this is what to do...
    _completeSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _safeSetState(() {
        _isPlaying = false;
        _progress = 0.0;
        _latestProgress = 0.0;
      });
      _syncProgressVisuals();
      unawaited(AndroidAudioDisplayMode.setVisualProgressActive(false));
      unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));
    });

    // Listen for errors
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      final bool playing = state == PlayerState.playing;
      unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(playing));
      unawaited(AndroidAudioDisplayMode.setVisualProgressActive(playing));
      if (!playing) {
        _progressVisualTimer?.cancel();
        _progressVisualTimer = null;
      }
      if (state == PlayerState.stopped && _isPlaying) {
        _safeSetState(() {
          _hasError = true;
          _isPlaying = false;
          _isLoading = false;
        });
      }
    });

    unawaited(_refreshDownloadState());
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _updateProgress(Duration position) {
    if (_duration.inMilliseconds > 0) {
      _latestProgress = position.inMilliseconds / _duration.inMilliseconds;
    }
  }

  void _syncProgressVisuals() {
    if (!mounted || !_isPlaying) {
      _progressVisualTimer?.cancel();
      _progressVisualTimer = null;
      return;
    }

    _progressVisualTimer ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _flushProgressVisual(),
    );
    _flushProgressVisual();
  }

  void _flushProgressVisual() {
    if (!mounted || !_isPlaying || _progress == _latestProgress) return;
    setState(() {
      _progress = _latestProgress.clamp(0.0, 1.0).toDouble();
    });
  }

  Uint8List? _getCachedAudio(String url) {
    final Uint8List? cached = _audioCache.remove(url);
    if (cached == null) {
      return null;
    }

    _audioCache[url] = cached;
    return cached;
  }

  void _cacheAudio(String url, Uint8List bytes) {
    _audioCache.remove(url);
    _audioCache[url] = bytes;

    while (_audioCache.length > _maxCachedAyahs) {
      _audioCache.remove(_audioCache.keys.first);
    }
  }

  Future<Uint8List> _downloadAudioBytes(String url) async {
    final http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load audio: ${response.statusCode}');
    }

    return Uint8List.fromList(response.bodyBytes);
  }

  Future<void> _refreshDownloadState() async {
    if (kIsWeb) return;
    final bool isDownloaded = await AudioDownloadService().hasAyah(
      widget.surah,
      widget.ayah,
    );
    _safeSetState(() {
      _isDownloaded = isDownloaded;
    });
  }

  @override
  void dispose() {
    unawaited(AndroidAudioDisplayMode.setVisualProgressActive(false));
    unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));
    _progressVisualTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _stateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    final AudioDownloadService downloads = AudioDownloadService();
    if (!kIsWeb) {
      final File? offlineFile = await downloads.playbackAyahFile(
        widget.surah,
        widget.ayah,
      );
      if (offlineFile != null && offlineFile.existsSync()) {
        await _audioPlayer.play(DeviceFileSource(offlineFile.path));
        return;
      }
    }

    final Uint8List? cachedAudio = _getCachedAudio(url);
    if (cachedAudio != null) {
      await _audioPlayer.play(BytesSource(cachedAudio));
      return;
    }

    try {
      final Uint8List bytes = await _downloadAudioBytes(url);
      _cacheAudio(url, bytes);
      if (!kIsWeb) {
        unawaited(downloads.cacheAyah(widget.surah, widget.ayah));
      }
      await _audioPlayer.play(BytesSource(bytes));
    } catch (_) {
      if (!kIsWeb) {
        rethrow;
      }

      final proxiedUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      await _audioPlayer.play(UrlSource(proxiedUrl));
    }
  }

  Future<void> _handleLongPress() async {
    if (kIsWeb || _isDownloading) return;
    if (_isDownloaded) {
      await _confirmDeleteDownload();
      return;
    }
    await _downloadAyah();
  }

  Future<void> _downloadAyah() async {
    _safeSetState(() {
      _isDownloading = true;
      _hasError = false;
    });

    try {
      final int notificationId = DownloadNotifications.notificationId(
        'ayah-${widget.surah}-${widget.ayah}',
      );
      final String title = localizations.downloadingName(
        'ayah ${widget.surah}:${widget.ayah}',
      );
      await DownloadNotifications.progress(
        id: notificationId,
        title: title,
        progress: null,
      );
      await AudioDownloadService().downloadAyah(
        widget.surah,
        widget.ayah,
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
        title: localizations.downloadedName(
          'ayah ${widget.surah}:${widget.ayah}',
        ),
      );
      await _refreshDownloadState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.downloadedName(
                'ayah ${widget.surah}:${widget.ayah}',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      await DownloadNotifications.fail(
        id: DownloadNotifications.notificationId(
          'ayah-${widget.surah}-${widget.ayah}',
        ),
        title: localizations.failedDownloadName(
          'ayah ${widget.surah}:${widget.ayah}',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.failedDownloadAyahAudio)),
        );
      }
    } finally {
      _safeSetState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _confirmDeleteDownload() async {
    final bool? confirm = await showReaderDialog<bool>(
      context: context,
      builder: (context) {
        return ReaderConfirmDialog(
          icon: const DesignIcon('trash'),
          title: localizations.deleteDownloadedAyah,
          body: localizations.removeSurahFromOffline(
            'ayah ${widget.surah}:${widget.ayah}',
          ),
          cancelLabel: localizations.cancel,
          confirmLabel: localizations.delete,
          destructive: true,
        );
      },
    );

    if (confirm == true) {
      await _deleteDownload();
    }
  }

  Future<void> _deleteDownload() async {
    try {
      await AudioDownloadService().deleteAyah(widget.surah, widget.ayah);
      await _refreshDownloadState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.deletedDownload(
                'ayah ${widget.surah}:${widget.ayah} audio',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.failedDeleteDownloadedAyah)),
        );
      }
    }
  }

  double _playbackRate() {
    final dynamic value = SettingsDB().get("playbackRate", defaultValue: 1.0);
    if (value is num) {
      return value.toDouble().clamp(0.5, 2.0);
    }
    return 1.0;
  }

  void _togglePlayPause() async {
    final Future<void> Function(int surah, int ayah)? playRequested =
        widget.onPlayRequested;
    if (playRequested != null) {
      await playRequested(widget.surah, widget.ayah);
      return;
    }

    _safeSetState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _safeSetState(() {
          _isLoading = false;
          _isPlaying = false;
        });
        _syncProgressVisuals();
        unawaited(AndroidAudioDisplayMode.setVisualProgressActive(false));
        unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));
      } else {
        final String resolvedUrl = await widget.url;
        if (resolvedUrl.isEmpty) {
          throw Exception('Audio URL is empty.');
        }

        final double rate = _playbackRate();
        await _audioPlayer.setPlaybackRate(rate);
        if (_audioPlayer.state == PlayerState.paused) {
          await _audioPlayer.resume();
        } else {
          await _playAudio(resolvedUrl);
        }
        // Re-apply because some platforms reset rate when a source is (re)started.
        await _audioPlayer.setPlaybackRate(rate);

        _safeSetState(() {
          _isLoading = false;
          _isPlaying = true;
        });
        _syncProgressVisuals();
      }
    } catch (_) {
      _safeSetState(() {
        _isLoading = false;
        _isPlaying = false;
        _hasError = true;
      });
      _syncProgressVisuals();
      unawaited(AndroidAudioDisplayMode.setVisualProgressActive(false));
      unawaited(AndroidAudioDisplayMode.setAudioPlaybackActive(false));

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? localizations.unablePlayAudioWeb
                  : localizations.failedPlayAudioConnection,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isPlaying)
          CircularPercentIndicator(
            radius: 20.0,
            progressColor: Theme.of(context).colorScheme.primary,
            lineWidth: 3.5,
            percent: _progress,
          ),
        GestureDetector(
          onLongPress: _handleLongPress,
          child: IconButton(
            onPressed: _togglePlayPause,
            icon: _isLoading || _isDownloading
                ? SizedBox(
                    width: 29,
                    height: 29,
                    child: CircularProgressIndicator(
                      strokeWidth: _isDownloading ? 2 : 1,
                    ),
                  )
                : Icon(
                    _hasError
                        ? Icons.error_outline_rounded
                        : _isPlaying
                        ? Icons.pause_circle_outline_rounded
                        : _isDownloaded
                        ? Icons.offline_pin_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 29,
                    color: _hasError
                        ? Colors.red
                        : _isDownloaded
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
          ),
        ),
      ],
    );
  }
}
