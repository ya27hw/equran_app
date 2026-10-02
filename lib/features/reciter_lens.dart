class ReciterLensPosition {
  const ReciterLensPosition({
    required this.surah,
    required this.ayah,
    required this.position,
    this.duration,
  });

  final int surah;
  final int ayah;
  final Duration position;
  final Duration? duration;
}

class ReciterLensSynchronizer {
  const ReciterLensSynchronizer();

  ReciterLensPosition alignByAyah({
    required ReciterLensPosition source,
    required Duration targetAyahDuration,
  }) {
    final Duration sourceDuration = source.duration ?? targetAyahDuration;
    final double fraction = sourceDuration.inMicroseconds == 0
        ? 0
        : (source.position.inMicroseconds / sourceDuration.inMicroseconds)
              .clamp(0.0, 1.0);
    return ReciterLensPosition(
      surah: source.surah,
      ayah: source.ayah,
      position: Duration(
        microseconds: (targetAyahDuration.inMicroseconds * fraction).round(),
      ),
      duration: targetAyahDuration,
    );
  }
}
