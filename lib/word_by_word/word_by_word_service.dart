import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equran/backend/resource_install_store.dart';
import 'package:equran/backend/resource_models.dart';
import 'package:equran/word_by_word/word_by_word_pack.dart';
import 'package:flutter/foundation.dart';

/// Gives the reader access to the installed word-by-word pack.
///
/// The pack is optional and downloaded on demand, so everything here degrades
/// to "no glosses" (never an error) when it is missing, unreviewed, malformed
/// or the platform has no file system (web). One surah is held in memory at a
/// time; callers read it synchronously after [prepare] completes and listen to
/// this notifier to learn when a pack is installed or removed.
class WordByWordService extends ChangeNotifier {
  WordByWordService._() : _directoryResolver = _installedDirectory {
    ResourceInstallStore.instance.changes.addListener(_onInstallChanged);
  }

  /// Test seam: supply the pack directory instead of the install store.
  @visibleForTesting
  WordByWordService.forTesting(Directory? Function() directoryResolver)
    : _directoryResolver = directoryResolver;

  static final WordByWordService instance = WordByWordService._();

  /// Manifest id of the English pack.
  static const String resourceId = 'word_by_word_en';

  final Directory? Function() _directoryResolver;

  WordByWordPackMeta? _meta;
  bool _metaLoaded = false;
  int? _preparedSurah;
  Map<int, List<WordGloss>> _surahGlosses = const <int, List<WordGloss>>{};
  Future<void>? _pendingPrepare;
  int? _pendingSurah;
  int _generation = 0;

  /// Provenance of the usable installed pack, if any (cached; see [refresh]).
  WordByWordPackMeta? get meta => _meta;

  /// True once the pack's provenance has been read and is usable.
  bool get isAvailable => _metaLoaded && _meta != null;

  /// Reads the pack provenance. Safe to call repeatedly.
  Future<void> ensureMeta() async {
    if (_metaLoaded) return;
    _meta = await _readMeta();
    _metaLoaded = true;
  }

  /// Whether [surah] has been loaded (even if the pack had nothing for it).
  bool isPrepared(int surah) => _preparedSurah == surah;

  /// Loads [surah]'s glosses so [glossesFor] can answer synchronously.
  Future<void> prepare(int surah) {
    if (isPrepared(surah)) return Future<void>.value();
    if (_pendingSurah == surah && _pendingPrepare != null) {
      return _pendingPrepare!;
    }
    _pendingSurah = surah;
    final Future<void> task = _load(surah).whenComplete(() {
      if (_pendingSurah == surah) {
        _pendingSurah = null;
        _pendingPrepare = null;
      }
    });
    _pendingPrepare = task;
    return task;
  }

  /// Glosses for one ayah of the prepared surah, or `null`.
  List<WordGloss>? glossesFor(int surah, int ayah) {
    if (!isPrepared(surah)) return null;
    return _surahGlosses[ayah];
  }

  /// Forgets cached data and re-reads the install state.
  void refresh() {
    _generation++;
    _meta = null;
    _metaLoaded = false;
    _preparedSurah = null;
    _surahGlosses = const <int, List<WordGloss>>{};
    _pendingPrepare = null;
    _pendingSurah = null;
    notifyListeners();
  }

  void _onInstallChanged() => refresh();

  Future<void> _load(int surah) async {
    final int generation = _generation;
    await ensureMeta();
    Map<int, List<WordGloss>> glosses = const <int, List<WordGloss>>{};
    final Directory? directory = _directoryResolver();
    if (isAvailable && directory != null) {
      try {
        final File file = File(
          '${directory.path}${Platform.pathSeparator}$surah.json',
        );
        glosses = parseWordByWordSurah(
          jsonDecode(await file.readAsString()),
          surah,
        );
      } catch (_) {
        // A damaged file leaves this surah unglossed; reading must not break.
        glosses = const <int, List<WordGloss>>{};
      }
    }
    // An install/uninstall during the read invalidates this result.
    if (generation != _generation) return;
    _surahGlosses = glosses;
    _preparedSurah = surah;
    notifyListeners();
  }

  Future<WordByWordPackMeta?> _readMeta() async {
    final Directory? directory = _directoryResolver();
    if (directory == null) return null;
    try {
      final File file = File(
        '${directory.path}${Platform.pathSeparator}meta.json',
      );
      final WordByWordPackMeta meta = WordByWordPackMeta.fromJson(
        jsonDecode(await file.readAsString()),
      );
      return meta.isUsable ? meta : null;
    } catch (_) {
      return null;
    }
  }

  static Directory? _installedDirectory() {
    if (kIsWeb) return null;
    final InstalledResource? installed =
        ResourceInstallStore.instance
            .installedResources()[ResourceInstallStore.metadataKey(
          ResourceType.wordByWord.value,
          resourceId,
        )];
    if (installed == null || installed.status != 'installed') return null;
    final Directory directory = Directory(installed.localPath);
    return directory.existsSync() ? directory : null;
  }
}
