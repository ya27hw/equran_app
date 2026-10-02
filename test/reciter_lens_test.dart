import 'package:equran/features/reciter_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ReciterLensSynchronizer synchronizer = ReciterLensSynchronizer();

  test('aligns the same ayah by normalized progress', () {
    final ReciterLensPosition aligned = synchronizer.alignByAyah(
      source: const ReciterLensPosition(
        surah: 2,
        ayah: 255,
        position: Duration(seconds: 5),
        duration: Duration(seconds: 10),
      ),
      targetAyahDuration: const Duration(seconds: 20),
    );

    expect(aligned.surah, 2);
    expect(aligned.ayah, 255);
    expect(aligned.position, const Duration(seconds: 10));
    expect(aligned.duration, const Duration(seconds: 20));
  });

  test('clamps malformed progress to the target ayah', () {
    final ReciterLensPosition aligned = synchronizer.alignByAyah(
      source: const ReciterLensPosition(
        surah: 1,
        ayah: 1,
        position: Duration(seconds: 30),
        duration: Duration(seconds: 10),
      ),
      targetAyahDuration: const Duration(seconds: 4),
    );

    expect(aligned.position, const Duration(seconds: 4));
  });
}
