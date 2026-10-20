import 'package:equran/backend/base_db.dart';
import 'package:equran/hifz/memory_twin.dart';
import 'package:equran/hifz/models/hifz_entry.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

enum MemoryPageState {
  unstarted,
  learning,
  reviewing,
  strong,
  fragile,
  urgent,
  mastered,
  mixed,
}

class MemoryAyahSummary {
  const MemoryAyahSummary({
    required this.surah,
    required this.ayah,
    required this.state,
    this.prediction,
  });

  final int surah;
  final int ayah;
  final MemoryPageState state;
  final MemoryTwinPrediction? prediction;

  Map<String, Object?> toMap() => <String, Object?>{
    'surah': surah,
    'ayah': ayah,
    'state': state.name,
    'prediction': prediction?.toMap(),
  };
}

class MemoryPageSummary {
  const MemoryPageSummary({
    required this.page,
    required this.ayahs,
    required this.state,
    required this.memorizedProportion,
    required this.fragileProportion,
    required this.dueReviews,
    this.lastReview,
  });

  final int page;
  final List<MemoryAyahSummary> ayahs;
  final MemoryPageState state;
  final double memorizedProportion;
  final double fragileProportion;
  final int dueReviews;
  final DateTime? lastReview;

  Map<String, Object?> toMap() => <String, Object?>{
    'page': page,
    'state': state.name,
    'memorizedProportion': memorizedProportion,
    'fragileProportion': fragileProportion,
    'dueReviews': dueReviews,
    'lastReview': lastReview?.toUtc().toIso8601String(),
    'ayahs': ayahs.map((MemoryAyahSummary ayah) => ayah.toMap()).toList(),
  };
}

/// Stores only derived map metadata and user-owned map preferences. Quran and
/// Hifz records remain the source of truth and can rebuild this cache.
class MemoryMapStateDB extends BaseDB {
  MemoryMapStateDB._() : super('memory_map_state');

  static final MemoryMapStateDB instance = MemoryMapStateDB._();

  Future<void> savePage(MemoryPageSummary summary) =>
      put('page:${summary.page}', summary.toMap());

  Future<void> reset() => clear();
}

/// Derives pages from the quran package's verified 604-page metadata. It never
/// guesses page boundaries from verse counts.
class MemoryMapRepository {
  MemoryMapRepository({MemoryTwinModel? model})
    : _model = model ?? const MemoryTwinModel();

  final MemoryTwinModel _model;
  final Map<int, MemoryPageSummary> _cache = <int, MemoryPageSummary>{};

  MemoryPageSummary pageSummary(
    int page,
    Iterable<HifzEntry> entries, {
    DateTime Function()? now,
  }) {
    if (page < 1 || page > 604) {
      throw RangeError.range(page, 1, 604, 'page');
    }
    final Map<String, HifzEntry> byAyah = <String, HifzEntry>{
      for (final HifzEntry entry in entries) entry.key: entry,
    };
    final List<MemoryAyahSummary> ayahs = <MemoryAyahSummary>[];
    for (final dynamic row in quran.getPageData(page)) {
      final int surah = row['surah'] as int;
      final int start = row['start'] as int;
      final int end = row['end'] as int;
      for (int ayah = start; ayah <= end; ayah++) {
        final HifzEntry? entry = byAyah['$surah:$ayah'];
        final MemoryTwinPrediction? prediction = entry == null
            ? null
            : _model.predict(
                MemoryTwinSignal(
                  surah: surah,
                  ayah: ayah,
                  intervalDays: entry.interval,
                  lapses: entry.lapses,
                  repetitions: entry.repetitions,
                  lastReviewedAt: entry.lastReviewed,
                ),
                now: now,
              );
        ayahs.add(
          MemoryAyahSummary(
            surah: surah,
            ayah: ayah,
            state: _ayahState(entry, prediction),
            prediction: prediction,
          ),
        );
      }
    }
    final int memorized = ayahs.where((MemoryAyahSummary ayah) {
      return ayah.state == MemoryPageState.strong ||
          ayah.state == MemoryPageState.mastered;
    }).length;
    final int fragile = ayahs.where((MemoryAyahSummary ayah) {
      return ayah.state == MemoryPageState.fragile ||
          ayah.state == MemoryPageState.urgent;
    }).length;
    final int due = ayahs.where((MemoryAyahSummary ayah) {
      return ayah.prediction?.band == MemoryRiskBand.urgent ||
          ayah.prediction?.band == MemoryRiskBand.fragile;
    }).length;
    final MemoryPageSummary summary = MemoryPageSummary(
      page: page,
      ayahs: List<MemoryAyahSummary>.unmodifiable(ayahs),
      state: _pageState(ayahs),
      memorizedProportion: ayahs.isEmpty ? 0 : memorized / ayahs.length,
      fragileProportion: ayahs.isEmpty ? 0 : fragile / ayahs.length,
      dueReviews: due,
      lastReview: _lastReview(entries, ayahs),
    );
    _cache[page] = summary;
    return summary;
  }

  void invalidatePage(int page) => _cache.remove(page);
  void invalidateAll() => _cache.clear();
  MemoryPageSummary? cachedPage(int page) => _cache[page];

  Future<void> persistPageSummary(MemoryPageSummary summary) {
    return MemoryMapStateDB.instance.savePage(summary);
  }

  static MemoryPageState _ayahState(
    HifzEntry? entry,
    MemoryTwinPrediction? prediction,
  ) {
    if (entry == null || entry.status == 'unseen' || entry.status == 'new') {
      return MemoryPageState.unstarted;
    }
    if (prediction?.band == MemoryRiskBand.urgent) {
      return MemoryPageState.urgent;
    }
    if (prediction?.band == MemoryRiskBand.fragile) {
      return MemoryPageState.fragile;
    }
    if (entry.status == 'mastered') return MemoryPageState.mastered;
    if (entry.status == 'learning') return MemoryPageState.learning;
    if (entry.status == 'review') return MemoryPageState.reviewing;
    return MemoryPageState.mixed;
  }

  static MemoryPageState _pageState(List<MemoryAyahSummary> ayahs) {
    if (ayahs.isEmpty) return MemoryPageState.unstarted;
    final Set<MemoryPageState> states = ayahs
        .map((MemoryAyahSummary ayah) => ayah.state)
        .toSet();
    if (states.length == 1) return states.first;
    if (states.contains(MemoryPageState.urgent)) return MemoryPageState.urgent;
    if (states.contains(MemoryPageState.fragile)) {
      return MemoryPageState.fragile;
    }
    return MemoryPageState.mixed;
  }

  static DateTime? _lastReview(
    Iterable<HifzEntry> entries,
    List<MemoryAyahSummary> ayahs,
  ) {
    final Set<String> ids = ayahs.map((MemoryAyahSummary value) {
      return '${value.surah}:${value.ayah}';
    }).toSet();
    DateTime? latest;
    for (final HifzEntry entry in entries) {
      if (!ids.contains(entry.key) || entry.lastReviewed == null) continue;
      if (latest == null || entry.lastReviewed!.isAfter(latest)) {
        latest = entry.lastReviewed;
      }
    }
    return latest;
  }
}

/// Virtualized, accessible overview. Callers provide localized labels so no
/// raw user-facing strings are introduced by this feature module.
class MemoryMapPage extends StatelessWidget {
  const MemoryMapPage({
    super.key,
    required this.summaries,
    required this.title,
    required this.statusLabel,
    this.onPageSelected,
  });

  final List<MemoryPageSummary> summaries;
  final String title;
  final String Function(MemoryPageState state) statusLabel;
  final ValueChanged<MemoryPageSummary>? onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: 108,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: summaries.length,
        itemBuilder: (BuildContext context, int index) {
          final MemoryPageSummary summary = summaries[index];
          final String state = statusLabel(summary.state);
          return Semantics(
            button: onPageSelected != null,
            label: '$title ${summary.page}: $state',
            child: Card(
              child: InkWell(
                onTap: onPageSelected == null
                    ? null
                    : () => onPageSelected!(summary),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        summary.page.toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(state, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${(summary.memorizedProportion * 100).round()}%'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
