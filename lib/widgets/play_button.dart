import 'package:audioplayers/audioplayers.dart';
import 'package:eQuran/backend/library.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PlayButton extends StatefulWidget {
  final String url;

  const PlayButton({super.key, required this.url});

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isLoading = false;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPositionChanged.listen((position) {
      if (_audioPlayer.state == PlayerState.playing) {
        _updateProgress(position);
      }
    });

    // When the audio has finished playing this is what to do...
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _progress = 0.0;
      });
    });
  }

  void _updateProgress(Duration position) async {
    Duration duration = await _audioPlayer.getDuration() ?? Duration.zero;
    setState(() {
      _progress = position.inMilliseconds / duration.inMilliseconds;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (widget.url.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer
          .setPlaybackRate(SettingsDB().get("playbackRate", defaultValue: 1.0));
      await _audioPlayer.play(
        UrlSource(widget.url),
      );
    }

    setState(() {
      _isLoading = false;
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _isPlaying
            ? CircularPercentIndicator(
                radius: 20.0,
                progressColor: Theme.of(context).colorScheme.primary,
                lineWidth: 3.5,
                percent: _progress,
              )
            : const SizedBox.shrink(),
        IconButton(
            onPressed: _togglePlayPause,
            icon: _isLoading
                ? const SizedBox(
                    width: 29,
                    height: 29,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                    ),
                  )
                : Icon(
                    !_isPlaying
                        ? Icons.play_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 29,
                  ))
      ],
    );
  }
}
