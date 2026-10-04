import 'package:equran/backend/library.dart';
import 'package:equran/debug/saved_preview_main.dart';
import 'package:equran/home/read.dart';
import 'package:equran/home/main_page.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/widgets/quran_card_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/quran_text.dart';
import 'package:equran/widgets/favourites_list.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran/quran.dart' as quran;
import 'gallery_test_support.dart' show loadGalleryFonts;

class _RouteObserver extends NavigatorObserver {
  Route<dynamic>? pushed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed = route;
  }
}

void main() {
  setUpAll(() async {
    registerCompanionStorageAdapters();
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SurahAdapter());
    await Hive.openBox<HifzEntry>(HifzDB.entriesBoxName, bytes: Uint8List(0));
    await Hive.openBox<HifzUnit>(HifzDB.unitsBoxName, bytes: Uint8List(0));
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final db in [
      SettingsDB(),
      QuranBookmarksDB(),
      FavouritesDB(),
      QuranBookmarkFoldersDB(),
      BookmarkDB(),
      SurahDB(),
    ]) {
      await Hive.openBox(db.boxName, bytes: Uint8List(0));
      await db.initBox();
    }
    await initializeDateFormatting();
    await quran.initializeQuran();
    await loadGalleryFonts();
    final arabicLoader = FontLoader('NotoNaskhArabic')
      ..addFont(
        rootBundle.load(
          'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
        ),
      );
    await arabicLoader.load();
    final loader = FontLoader('UthmanicHafs')
      ..addFont(rootBundle.load('assets/media/fonts/UthmanicHafs_V22.ttf'));
    await loader.load();
  });
  setUp(() => seedSavedPreview());
  tearDownAll(() async {
    await Hive.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    VoidCallback? browse,
    List<NavigatorObserver> observers = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      SavedPreviewApp(
        colors: colors,
        textScale: scale,
        locale: locale,
        onBrowseSurahs: browse,
        navigatorObservers: observers,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Finder tile(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;
  Future<void> openEditor(WidgetTester tester, String action) async {
    await tester.tap(find.byKey(const ValueKey('saved-menu-94-005')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text(action)));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'collections and tags keep the original independent filter rules',
    (tester) async {
      await pump(tester);
      expect(find.text('ALL SAVED · 3'), findsOneWidget);
      await tester.tap(tile('Favourites'));
      await tester.pumpAndSettle();
      expect(find.text('ALL SAVED · 2'), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-150, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(tile('Notes'));
      await tester.pumpAndSettle();
      expect(find.text('ALL SAVED · 2'), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-260, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(tile('Duas'));
      await tester.pumpAndSettle();
      expect(find.text('ALL SAVED · 1'), findsOneWidget);
      await tester.tap(tile('Duas'));
      await tester.pumpAndSettle();
      expect(find.text('ALL SAVED · 3'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChipButton, '#patience'));
      await tester.pumpAndSettle();
      expect(find.text('ALL SAVED · 2'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChipButton, '#patience'));
      await tester.pumpAndSettle();
      expect(find.text('ALL SAVED · 3'), findsOneWidget);
    },
  );
  testWidgets(
    'search matches note, folder, tag, surah and number; clear restores all',
    (tester) async {
      await pump(tester);
      for (final (query, count) in [
        ('hard days', 1),
        ('Duas', 1),
        ('hope', 1),
        ('Ash Sharh', 1),
        ('94', 1),
        ('missing', 0),
      ]) {
        await tester.enterText(find.byKey(const Key('saved-search')), query);
        await tester.pumpAndSettle();
        expect(find.text('ALL SAVED · $count'), findsOneWidget, reason: query);
      }
      expect(find.text('No matching saved ayahs.'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('ALL SAVED · 3'), findsOneWidget);
    },
  );
  testWidgets(
    'favourite toggle preserves notes and metadata and targets are 44px',
    (tester) async {
      await pump(tester);
      final fav = find.byKey(const ValueKey('saved-favourite-94-005'));
      expect(tester.getSize(fav), const Size(44, 44));
      expect(
        tester.getSize(find.byKey(const ValueKey('saved-menu-94-005'))),
        const Size(44, 44),
      );
      await tester.runAsync(() async {
        await tester.tap(fav);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      var entry = QuranBookmarksDB().get('94-005') as QuranBookmarkEntry;
      expect(entry.isFavourite, isFalse);
      expect(entry.note, contains('hard days'));
      expect(entry.folder, 'Gratitude');
      expect(entry.tags, ['hope', 'patience']);
      await tester.runAsync(() async {
        await tester.tap(fav);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      entry = QuranBookmarksDB().get('94-005') as QuranBookmarkEntry;
      expect(entry.isFavourite, isTrue);
    },
  );
  testWidgets(
    'all edit menu actions open the same editor; save uses existing service',
    (tester) async {
      await pump(tester);
      for (final action in ['Move to folder', 'Edit tags']) {
        await openEditor(tester, action);
        expect(find.byKey(const Key('saved-note-editor')), findsOneWidget);
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
      }
      await openEditor(tester, 'Edit note');
      await tester.enterText(
        find.byKey(const Key('saved-note-editor')),
        'Changed reflection',
      );
      await tester.enterText(
        find.byKey(const Key('saved-tags-editor')),
        'hope, new, new',
      );
      await tester.ensureVisible(find.widgetWithText(ChipButton, 'Duas'));
      await tester.tap(find.widgetWithText(ChipButton, 'Duas'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Save'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      final entry = QuranBookmarksDB().get('94-005') as QuranBookmarkEntry;
      expect(entry.note, 'Changed reflection');
      expect(entry.folder, 'Duas');
      expect(entry.tags, ['hope', 'new']);
      expect(entry.createdAt, DateTime(2026, 5, 12));
    },
  );
  testWidgets(
    'overflow delete cancels or removes through existing confirmation',
    (tester) async {
      await pump(tester);
      await openEditor(tester, 'Delete');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(QuranBookmarksDB().contains('94-005'), isTrue);
      await openEditor(tester, 'Delete');
      await tester.runAsync(() async {
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(QuranBookmarksDB().contains('94-005'), isFalse);
      expect(FavouritesDB().contains('94-005'), isFalse);
    },
  );
  testWidgets('empty state retains copy and browse action', (tester) async {
    await seedSavedPreview(empty: true);
    var browsed = false;
    await pump(tester, browse: () => browsed = true);
    expect(
      find.text('Save ayahs, notes, and reflections here.'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Browse surahs'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse surahs'));
    expect(browsed, isTrue);
    // Nothing saved yet: no search, no sort row, no folder manager.
    expect(find.byKey(const Key('saved-search')), findsNothing);
    expect(find.text('Newest first'), findsNothing);
    expect(find.byTooltip('Manage folders'), findsNothing);
  });
  testWidgets('a long ayah is capped with Show more / Show less', (
    tester,
  ) async {
    final id = favouriteAyahKey(2, 282);
    final date = DateTime(2026, 5, 13);
    await QuranBookmarksDB().put(
      id,
      QuranBookmarkEntry(
        id: id,
        surah: 2,
        verse: 282,
        isFavourite: false,
        note: '',
        folder: 'Gratitude',
        tags: const [],
        createdAt: date,
        updatedAt: date,
        legacyKey: id,
      ),
    );
    await pump(tester);
    final more = find.text('Show more');
    await tester.scrollUntilVisible(
      more,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(more, findsWidgets); // long ayahs only
    expect(find.text('Show less'), findsNothing);
    await tester.ensureVisible(more.first);
    await tester.pumpAndSettle();
    await tester.tap(more.first);
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
    await tester.ensureVisible(find.text('Show less'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsNothing);
  });
  testWidgets('verse tap retains reader chapter and starting ayah', (
    tester,
  ) async {
    final observer = _RouteObserver();
    await pump(tester, observers: [observer]);
    await tester.tap(find.text('Ash Sharh'));
    final route = observer.pushed as MaterialPageRoute<void>;
    final page =
        route.builder(tester.element(find.byType(FavouritesList))) as ReadPage;
    expect(page.chapter, 94);
    expect(page.startVerse, 5);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('production Saved search focuses and Browse switches to Surahs', (
    tester,
  ) async {
    // Search only exists once something is saved; 'test' then matches nothing.
    await seedSavedPreview();
    await SettingsDB().put('showLastRead', false);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: savedPreviewTheme(EquranColors.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedQuranHeader), findsOneWidget);
    await tester.tap(find.byTooltip('Search Quran'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('saved-search')),
    );
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.enterText(find.byKey(const Key('saved-search')), 'test');
    await tester.pump(const Duration(milliseconds: 450));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Browse surahs'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse surahs'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedQuranHeader), findsNothing);
    expect(
      tester.widget<QuranCardList>(find.byType(QuranCardList)).searchQuery,
      '',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'editor favourite, removable tags and direct delete retain service behavior',
    (tester) async {
      await pump(tester);
      await openEditor(tester, 'Edit tags');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final tag = find.widgetWithText(Chip, '#hope');
      await tester.ensureVisible(tag);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove #hope'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Chip, '#hope'), findsNothing);
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final entry = QuranBookmarksDB().get('94-005') as QuranBookmarkEntry;
      expect(entry.isFavourite, isFalse);
      expect(entry.tags, ['patience']);
      await openEditor(tester, 'Edit note');
      await tester.ensureVisible(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(QuranBookmarksDB().contains('94-005'), isFalse);
      expect(FavouritesDB().contains('94-005'), isFalse);
    },
  );
  testWidgets(
    'create, rename and delete folder keep saved ayahs and existing manager',
    (tester) async {
      await pump(tester);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-900, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(tile('New Folder'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Reflections',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(const QuranBookmarkService().folders(), contains('Reflections'));
      await tester.tap(find.byTooltip('Manage'));
      await tester.pumpAndSettle();
      final gratitude = find.widgetWithText(ListTile, 'Gratitude');
      await tester.tap(
        find
            .descendant(
              of: gratitude,
              matching: find.byWidgetPredicate(
                (widget) => widget is PopupMenuButton,
              ),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Thankfulness',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        (QuranBookmarksDB().get('94-005') as QuranBookmarkEntry).folder,
        'Thankfulness',
      );
      final renamed = find.widgetWithText(ListTile, 'Thankfulness');
      await tester.tap(
        find
            .descendant(
              of: renamed,
              matching: find.byWidgetPredicate(
                (widget) => widget is PopupMenuButton,
              ),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        (QuranBookmarksDB().get('94-005') as QuranBookmarkEntry).folder,
        QuranBookmarkService.defaultFolder,
      );
      expect(QuranBookmarksDB().length, 3);
      expect(tester.takeException(), isNull);
    },
  );
  final variants = [
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
    ('arabic-text-1.3', EquranColors.dark, 1.3, const Locale('ar')),
  ];
  for (final (name, colors, scale, locale) in variants) {
    testWidgets('Saved library, editor and empty golden $name', (tester) async {
      await pump(tester, colors: colors, scale: scale, locale: locale);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/saved/$name-library.png'),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(FavouritesList)),
      )!;
      await openEditor(tester, l.editNote);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/saved/$name-sheet.png'),
      );
      await tester.tap(find.byTooltip(l.close));
      await tester.pumpAndSettle();
      await seedSavedPreview(empty: true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/saved/$name-empty.png'),
      );
    });
  }
}
