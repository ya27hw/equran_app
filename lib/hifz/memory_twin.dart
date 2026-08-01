import 'dart:math' as math;

import 'package:equran/backend/base_db.dart';

enum MemoryRiskBand { strong, stable, drifting, fragile, urgent }

class MemoryTwinSignal {
  const MemoryTwinSignal({
    required this.surah,
    required this.ayah,
    required this.intervalDays,
    required this.lapses,
    required this.repetitions,
    required this.lastReviewedAt,
    this.cueUses = 0,
    this.reviewCount = 0,
    this.successCount = 0,
    this.confusionCount = 0,
    this.responseLatencyMs = 0,
  });

  final int surah;
  final int ayah;
  final int intervalDays;
  final int lapses;
  final int repetitions;
  final DateTime? lastReviewedAt;
  final int cueUses;
  final int reviewCount;
  final int successCount;
  final int confusionCount;
  final int responseLatencyMs;

  String get id => '$surah:$ayah';

  Map<String, Object?> toMap() => <String, Object?>{
    'surah': surah,
    'ayah': ayah,
    'intervalDays': intervalDays,
    'lapses': lapses,
    'repetitions': repetitions,
    'lastReviewedAt': lastReviewedAt?.toUtc().toIso8601String(),
    'cueUses': cueUses,
    'reviewCount': reviewCount,
    'successCount': successCount,
    'confusionCount': confusionCount,
    'responseLatencyMs': responseLatencyMs,
  };

  static MemoryTwinSignal? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final int? parsedSurah = _intValue(raw['surah']);
    final int? parsedAyah = _intValue(raw['ayah']);
    if (parsedSurah == null ||
        parsedAyah == null ||
        parsedSurah < 1 ||
        parsedSurah > 114 ||
        parsedAyah < 1) {
      return null;
    }
    return MemoryTwinSignal(
      surah: parsedSurah,
      ayah: parsedAyah,
      intervalDays: _intValue(raw['intervalDays'])?.clamp(0, 36500) ?? 0,
      lapses: _intValue(raw['lapses'])?.clamp(0, 10000) ?? 0,
      repetitions: _intValue(raw['repetitions'])?.clamp(0, 100000) ?? 0,
      lastReviewedAt: _date(raw['lastReviewedAt']),
      cueUses: _intValue(raw['cueUses'])?.clamp(0, 100000) ?? 0,
      reviewCount: _intValue(raw['reviewCount'])?.clamp(0, 100000) ?? 0,
      successCount: _intValue(raw['successCount'])?.clamp(0, 100000) ?? 0,
      confusionCount: _intValue(raw['confusionCount'])?.clamp(0, 100000) ?? 0,
      responseLatencyMs:
          _intValue(raw['responseLatencyMs'])?.clamp(0, 3600000) ?? 0,
    );
  }

  static int? _intValue(Object? value) => value is num ? value.toInt() : null;

  static DateTime? _date(Object? value) {
    if (value is DateTime) return value.toUtc();
    return value is String ? DateTime.tryParse(value)?.toUtc() : null;
  }
}

class MemoryTwinPrediction {
  const MemoryTwinPrediction({
    required this.id,
    required this.riskScore,
    required this.band,
    required this.predictedFor,
    required this.modelVersion,
    required this.featureSchemaVersion,
    required this.explanationSignals,
  });

  final String id;
  final double riskScore;
  final MemoryRiskBand band;
  final DateTime predictedFor;
  final String modelVersion;
  final String featureSchemaVersion;
  final List<String> explanationSignals;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'riskScore': riskScore,
    'band': band.name,
    'predictedFor': predictedFor.toUtc().toIso8601String(),
    'modelVersion': modelVersion,
    'featureSchemaVersion': featureSchemaVersion,
    'explanationSignals': explanationSignals,
  };

  static MemoryTwinPrediction? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final String? id = raw['id'] is String ? raw['id'] as String : null;
    final double? score = raw['riskScore'] is num
        ? (raw['riskScore'] as num).toDouble()
        : null;
    final MemoryRiskBand? band = raw['band'] is String
        ? MemoryRiskBand.values.cast<MemoryRiskBand?>().firstWhere(
            (MemoryRiskBand? value) => value?.name == raw['band'],
            orElse: () => null,
          )
        : null;
    final DateTime? predictedFor = raw['predictedFor'] is String
        ? DateTime.tryParse(raw['predictedFor'] as String)
        : null;
    if (id == null ||
        id.isEmpty ||
        score == null ||
        !score.isFinite ||
        score < 0 ||
        score > 1 ||
        band == null ||
        predictedFor == null) {
      return null;
    }
    return MemoryTwinPrediction(
      id: id,
      riskScore: score,
      band: band,
      predictedFor: predictedFor.toUtc(),
      modelVersion: raw['modelVersion']?.toString() ?? 'unknown',
      featureSchemaVersion:
          raw['featureSchemaVersion']?.toString() ?? 'unknown',
      explanationSignals:
          (raw['explanationSignals'] as List?)
              ?.whereType<String>()
              .take(32)
              .toList(growable: false) ??
          const <String>[],
    );
  }
}

/// Compact, interpretable local retention model. It is a forecast, never a
/// religious or medical conclusion, and every explanation token maps to an
/// observed input signal.
class MemoryTwinModel {
  const MemoryTwinModel({
    this.modelVersion = 'memory-twin-logistic-1',
    this.featureSchemaVersion = 'memory-twin-features-1',
  });

  final String modelVersion;
  final String featureSchemaVersion;

  MemoryTwinPrediction predict(
    MemoryTwinSignal signal, {
    DateTime Function()? now,
  }) {
    final DateTime at = (now ?? DateTime.now)();
    final int elapsedDays = signal.lastReviewedAt == null
        ? signal.intervalDays + 1
        : math.max(0, at.difference(signal.lastReviewedAt!).inDays);
    final double overdueRatio =
        elapsedDays / math.max(1, signal.intervalDays).toDouble();
    final double failureRate = signal.reviewCount == 0
        ? 0
        : 1 - (signal.successCount / signal.reviewCount).clamp(0.0, 1.0);
    final double cueRate = signal.reviewCount == 0
        ? 0
        : (signal.cueUses / signal.reviewCount).clamp(0.0, 1.0);
    final double latencyPenalty = (signal.responseLatencyMs / 12000).clamp(
      0.0,
      1.0,
    );
    final double logit =
        -2.1 +
        (overdueRatio - 1).clamp(-1.0, 4.0) * 0.85 +
        failureRate * 1.45 +
        cueRate * 0.8 +
        latencyPenalty * 0.55 +
        signal.confusionCount.clamp(0, 6) * 0.18 -
        signal.repetitions.clamp(0, 20) * 0.035;
    final double score = (1 / (1 + math.exp(-logit))).clamp(0.01, 0.99);
    final List<String> explanations = <String>[
      if (overdueRatio > 1.2) 'overdue_interval',
      if (signal.lapses > 0) 'lapses:${signal.lapses}',
      if (cueRate >= 0.34) 'cue_usage',
      if (signal.confusionCount > 0) 'confusion:${signal.confusionCount}',
      if (latencyPenalty >= 0.34) 'response_latency',
    ];
    return MemoryTwinPrediction(
      id: signal.id,
      riskScore: score,
      band: _band(score),
      predictedFor: at.toUtc(),
      modelVersion: modelVersion,
      featureSchemaVersion: featureSchemaVersion,
      explanationSignals: List<String>.unmodifiable(explanations),
    );
  }

  static MemoryRiskBand _band(double score) {
    if (score >= 0.8) return MemoryRiskBand.urgent;
    if (score >= 0.6) return MemoryRiskBand.fragile;
    if (score >= 0.4) return MemoryRiskBand.drifting;
    if (score >= 0.2) return MemoryRiskBand.stable;
    return MemoryRiskBand.strong;
  }
}

/// Local storage for prediction metadata. The core Hifz scheduler remains
/// independent if this store is unavailable or reset.
class MemoryTwinDB extends BaseDB {
  MemoryTwinDB._() : super('memory_twin_predictions');

  static final MemoryTwinDB instance = MemoryTwinDB._();

  Future<void> save(MemoryTwinPrediction prediction) =>
      put(prediction.id, prediction.toMap());

  MemoryTwinPrediction? find(String id) =>
      MemoryTwinPrediction.fromMap(get(id));

  List<MemoryTwinPrediction> all() {
    return box.values
        .map(MemoryTwinPrediction.fromMap)
        .whereType<MemoryTwinPrediction>()
        .toList(growable: false);
  }

  Future<void> deletePrediction(String id) => delete(id);

  Future<void> reset() => clear();
}
