import 'package:equran/hifz/memory_twin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 1, 10, 12);

  test('local prediction is deterministic and explains observed signals', () {
    const MemoryTwinModel model = MemoryTwinModel();
    final MemoryTwinPrediction strong = model.predict(
      MemoryTwinSignal(
        surah: 1,
        ayah: 1,
        intervalDays: 30,
        lapses: 0,
        repetitions: 12,
        lastReviewedAt: DateTime.utc(2026, 1, 9),
        reviewCount: 12,
        successCount: 12,
      ),
      now: () => now,
    );
    final MemoryTwinPrediction fragile = model.predict(
      MemoryTwinSignal(
        surah: 1,
        ayah: 2,
        intervalDays: 1,
        lapses: 2,
        repetitions: 1,
        lastReviewedAt: DateTime.utc(2025, 12, 20),
        cueUses: 4,
        reviewCount: 4,
        successCount: 1,
        confusionCount: 2,
        responseLatencyMs: 8000,
      ),
      now: () => now,
    );

    expect(strong.id, '1:1');
    expect(strong.riskScore, lessThan(fragile.riskScore));
    expect(fragile.explanationSignals, contains('overdue_interval'));
    expect(fragile.explanationSignals, contains('lapses:2'));
    expect(fragile.explanationSignals, contains('cue_usage'));
    expect(fragile.explanationSignals, contains('confusion:2'));
    expect(fragile.explanationSignals, contains('response_latency'));
  });

  test('prediction metadata is serializable without private text', () {
    final MemoryTwinPrediction prediction = const MemoryTwinModel().predict(
      const MemoryTwinSignal(
        surah: 2,
        ayah: 255,
        intervalDays: 3,
        lapses: 0,
        repetitions: 2,
        lastReviewedAt: null,
      ),
      now: () => now,
    );

    expect(prediction.toMap()['modelVersion'], isNotEmpty);
    expect(prediction.toMap()['featureSchemaVersion'], isNotEmpty);
    expect(prediction.toMap().keys, isNot(contains('text')));
    expect(MemoryTwinPrediction.fromMap(prediction.toMap())?.id, prediction.id);
    expect(
      MemoryTwinSignal.fromMap(<String, Object?>{
        'surah': 1,
        'ayah': 7,
        'intervalDays': -4,
      })?.intervalDays,
      0,
    );
  });
}
