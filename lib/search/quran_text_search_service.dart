import 'dart:async';

import 'package:equran/backend/library.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:quran/quran.dart' as quran;

class QuranTextSearchResult {
  const QuranTextSearchResult({
    required this.surah,
    required this.verse,
    required this.arabicPreview,
    required this.translationPreview,
    required this.translationMatch,
  });

  final int surah;
  final int verse;
  final String arabicPreview;
  final String translationPreview;
  final bool translationMatch;

  String get id => '$surah:$verse';
}

class QuranTextSearchService {
  const QuranTextSearchService();

  Future<List<QuranTextSearchResult>> search(String query, {int limit = 80}) {
    final String trimmedQuery = query.trim();
    final String normalizedQuery = _normalizeSearchText(trimmedQuery);
    if (normalizedQuery.length < 2) {
      return Future<List<QuranTextSearchResult>>.value(
        const <QuranTextSearchResult>[],
      );
    }

    return _searchIncrementally(normalizedQuery, limit: limit);
  }

  Future<void> storeRecentQuery(String query, int resultCount) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) return;

    final String id = 'quran_text:${trimmed.toLowerCase()}';
    await RecentSearchesDB().put(
      id,
      RecentSearchEntry(
        id: id,
        query: trimmed,
        mode: 'quran_text',
        searchedAt: DateTime.now(),
        resultCount: resultCount,
      ),
    );

    final List<RecentSearchEntry> entries = recentQuranTextSearches();
    for (final RecentSearchEntry entry in entries.skip(8)) {
      unawaited(RecentSearchesDB().delete(entry.id));
    }
  }

  List<RecentSearchEntry> recentQuranTextSearches() {
    final List<RecentSearchEntry> entries = RecentSearchesDB().box.values
        .whereType<RecentSearchEntry>()
        .where((RecentSearchEntry entry) => entry.mode == 'quran_text')
        .toList();
    entries.sort((a, b) => b.searchedAt.compareTo(a.searchedAt));
    return entries;
  }

  Future<List<QuranTextSearchResult>> _searchIncrementally(
    String normalizedQuery, {
    required int limit,
  }) async {
    final quran.Translation translation = _selectedTranslation();
    final Map<String, _SearchHit> hits = <String, _SearchHit>{};

    void addHit(int surah, int verse, {required bool translationMatch}) {
      final String id = '$surah:$verse';
      hits[id] = _SearchHit(
        surah: surah,
        verse: verse,
        translationMatch:
            (hits[id]?.translationMatch ?? false) || translationMatch,
      );
    }

    // Scan in small asynchronous batches. This keeps memory bounded and gives
    // cancellation/rebuilds a chance to run; a microtask would still execute
    // the complete CPU-heavy loop on the UI isolate without yielding.
    int inspected = 0;
    for (int surah = 1; surah <= quran.totalSurahCount; surah++) {
      final int verseCount = quran.getVerseCount(surah);
      for (int verse = 1; verse <= verseCount; verse++) {
        final String normalizedArabic = _normalizeSearchText(
          quranVerseText(surah, verse),
        );
        final String normalizedTranslation = _normalizeSearchText(
          _translationText(surah, verse, translation),
        );
        final bool arabicMatch = normalizedArabic.contains(normalizedQuery);
        final bool translationMatch = normalizedTranslation.contains(
          normalizedQuery,
        );
        if (arabicMatch || translationMatch) {
          addHit(surah, verse, translationMatch: translationMatch);
        }
        inspected++;
        if (inspected % 32 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    }

    final List<_SearchHit> orderedHits = hits.values.toList()
      ..sort((a, b) {
        final int surahCompare = a.surah.compareTo(b.surah);
        if (surahCompare != 0) return surahCompare;
        return a.verse.compareTo(b.verse);
      });

    return orderedHits
        .take(limit)
        .map((_SearchHit hit) {
          return QuranTextSearchResult(
            surah: hit.surah,
            verse: hit.verse,
            arabicPreview: quranVerseText(hit.surah, hit.verse),
            translationPreview: _translationText(
              hit.surah,
              hit.verse,
              translation,
            ),
            translationMatch: hit.translationMatch,
          );
        })
        .toList(growable: false);
  }

  quran.Translation _selectedTranslation() {
    final dynamic saved = SettingsDB().get('translation', defaultValue: 0);
    if (saved is int && saved >= 0 && saved < quran.Translation.values.length) {
      return quran.Translation.values[saved];
    }
    return quran.Translation.enSaheeh;
  }

  String _translationText(int surah, int verse, quran.Translation translation) {
    try {
      return quran.cleanTranslationText(
        quran.getVerseTranslation(surah, verse, translation: translation),
      );
    } catch (_) {
      return '';
    }
  }

  String _normalizeSearchText(String value) {
    final String withoutArabicMarks = _normalizeArabic(value);
    return withoutArabicMarks
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeArabic(String value) {
    return value
        .replaceAll(
          RegExp(r'[\u0610-\u061A\u0640\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        )
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .trim();
  }
}

class _SearchHit {
  const _SearchHit({
    required this.surah,
    required this.verse,
    required this.translationMatch,
  });

  final int surah;
  final int verse;
  final bool translationMatch;
}
