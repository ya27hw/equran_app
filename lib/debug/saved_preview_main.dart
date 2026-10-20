import 'package:equran/backend/library.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:equran/widgets/favourites_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:quran/quran.dart' as quran;

/// Standalone debug entry point on its own web origin. Never in app navigation.
Future<void> main() async {
  if (!kDebugMode) return;
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init('redesign_saved_preview');
  registerCompanionStorageAdapters();
  for (final db in [
    SettingsDB(),
    QuranBookmarksDB(),
    FavouritesDB(),
    QuranBookmarkFoldersDB(),
  ]) {
    await db.initBox();
  }
  await quran.initializeQuran();
  await seedSavedPreview(empty: Uri.base.queryParameters['empty'] == 'true');
  final params = Uri.base.queryParameters;
  runApp(
    SavedPreviewApp(
      colors: switch (params['palette']) {
        'emerald-light' => EquranColors.light,
        'black-dark' => EquranColors.blackDark,
        'red-dark' => EquranColors.redDark,
        _ => EquranColors.dark,
      },
      locale: Locale(params['locale'] ?? 'en'),
      textScale: double.tryParse(params['scale'] ?? '') ?? 1,
    ),
  );
}

/// Deterministic, clearly isolated sample data for debug previews and tests.
Future<void> seedSavedPreview({bool empty = false}) async {
  await QuranBookmarksDB().clear();
  await FavouritesDB().clear();
  await QuranBookmarkFoldersDB().clear();
  await SettingsDB().put('quranScriptStyle', 'qpc-hafs');
  if (empty) return;
  await const QuranBookmarkService().createFolder('Gratitude');
  await const QuranBookmarkService().createFolder('Duas');
  for (final (surah, verse, favourite, note, folder, tags, day) in [
    (
      94,
      5,
      true,
      'For the hard days. With hardship comes ease.',
      'Gratitude',
      ['hope', 'patience'],
      12,
    ),
    (
      2,
      286,
      false,
      'Nothing is asked of me that I cannot carry.',
      'Gratitude',
      ['patience'],
      11,
    ),
    (18, 10, true, '', 'Duas', ['duas'], 10),
  ]) {
    final id = favouriteAyahKey(surah, verse);
    final date = DateTime(2026, 5, day);
    final entry = QuranBookmarkEntry(
      id: id,
      surah: surah,
      verse: verse,
      isFavourite: favourite,
      note: note,
      folder: folder,
      tags: tags,
      createdAt: date,
      updatedAt: date,
      legacyKey: id,
    );
    await QuranBookmarksDB().put(id, entry);
    if (favourite) await FavouritesDB().put(id, note);
  }
}

ThemeData savedPreviewTheme(EquranColors colors) => ThemeData(
  brightness: colors.background.computeLuminance() < .5
      ? Brightness.dark
      : Brightness.light,
  colorSchemeSeed: colors.primary,
  scaffoldBackgroundColor: colors.background,
  fontFamily: 'Inter',
  extensions: [colors, EquranTokens.fromColors(colors)],
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 1.4,
      color: colors.textPrimary,
    ),
  ),
);

class SavedPreviewApp extends StatelessWidget {
  const SavedPreviewApp({
    super.key,
    this.colors = EquranColors.dark,
    this.locale = const Locale('en'),
    this.textScale = 1,
    this.onBrowseSurahs,
    this.navigatorObservers = const [],
  });
  final EquranColors colors;
  final Locale locale;
  final double textScale;
  final VoidCallback? onBrowseSurahs;
  final List<NavigatorObserver> navigatorObservers;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: savedPreviewTheme(colors),
    locale: locale,
    navigatorObservers: navigatorObservers,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: _SavedPreviewPage(onBrowseSurahs: onBrowseSurahs),
  );
}

class _SavedPreviewPage extends StatefulWidget {
  const _SavedPreviewPage({this.onBrowseSurahs});
  final VoidCallback? onBrowseSurahs;
  @override
  State<_SavedPreviewPage> createState() => _SavedPreviewPageState();
}

class _SavedPreviewPageState extends State<_SavedPreviewPage> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          SavedQuranHeader(
            onSearch: focus.requestFocus,
            onSelectSection: (_) => widget.onBrowseSurahs?.call(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FavouritesList(
                searchQuery: '',
                searchFocusNode: focus,
                onBrowseSurahs: widget.onBrowseSurahs ?? () {},
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
