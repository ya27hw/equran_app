import 'package:equran/debug/saved_preview_main.dart' show savedPreviewTheme;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/widgets/app_selection_dialog.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/reader_sheets.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gallery_test_support.dart' show loadGalleryFonts;

/// The reader's restyled chrome: top bar, prev/next pills and the sheets and
/// dialogs that moved onto the redesign system. `ReadPage` itself is not
/// pumped (it needs Hive, just_audio and the Quran data), so every sheet is a
/// presentational widget and is tested here with the same inputs the page
/// passes. There is no design preview for these sheets; the look follows the
/// finished playback options sheet and the Saved tab's editor.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadGalleryFonts();
    await (FontLoader('NotoNaskhArabic')..addFont(
          rootBundle.load(
            'assets/media/fonts/noto-naskh-arabic/NotoNaskhArabic.ttf',
          ),
        ))
        .load();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget Function(BuildContext context) builder, {
    EquranColors colors = EquranColors.dark,
    double scale = 1,
    Locale locale = const Locale('en'),
    double height = 900,
    bool asSheet = true,
    bool fixedHeight = false,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(390 * 2, height * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: savedPreviewTheme(colors),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: asSheet ? Colors.black54 : colors.background,
            body: asSheet
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: height * 0.9,
                        minHeight: fixedHeight ? height * 0.9 : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        child: ColoredBox(
                          color: colors.background,
                          child: builder(context),
                        ),
                      ),
                    ),
                  )
                : builder(context),
          ),
        ),
      ),
    );
    // A running download shows a spinner that never settles.
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 1),
      );
    } on FlutterError {
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  Widget readingOptions(
    List<String> log, {
    bool translation = true,
    bool transliteration = false,
    bool cardView = true,
  }) => ReadingOptionsSheet(
    scrollController: ScrollController(),
    surahName: 'Al-Baqarah',
    verse: 142,
    translationEnabled: translation,
    transliterationEnabled: transliteration,
    cardViewEnabled: cardView,
    onTranslationChanged: (v) => log.add('translation:$v'),
    onTransliterationChanged: (v) => log.add('transliteration:$v'),
    onCardViewChanged: (v) => log.add('cardView:$v'),
    onGoToAyah: () => log.add('goTo'),
    onTranslationLanguage: () => log.add('language'),
    onTafsirSources: () => log.add('tafsir'),
    onShare: () => log.add('share'),
  );

  Widget goTo({
    String? error,
    List<String>? log,
    TextEditingController? controller,
  }) => GoToAyahSheet(
    controller: controller ?? TextEditingController(text: '142'),
    focusNode: FocusNode(),
    totalVerses: 286,
    errorText: error,
    onChanged: (v) => log?.add('changed:$v'),
    onSubmit: () => log?.add('submit'),
    onCancel: () => log?.add('cancel'),
  );

  Widget sleep({
    bool endOfSurah = false,
    bool active = false,
    List<String>? log,
    TextEditingController? controller,
  }) => SleepTimerSheet(
    minutesController: controller ?? TextEditingController(text: '15'),
    unitLabel: 'min',
    endOfSurah: endOfSurah,
    hasActiveTimer: active,
    onStep: (d) => log?.add('step:$d'),
    onMinutesChanged: (v) => log?.add('minutes:$v'),
    onEndOfSurahChanged: (v) => log?.add('endOfSurah:$v'),
    onTurnOff: () => log?.add('off'),
    onSet: () => log?.add('set'),
  );

  Widget shareFormats(List<String> log) => ReaderChoiceSheet(
    title: 'Share image format',
    items: <ReaderChoiceItem>[
      ReaderChoiceItem(
        leading: const Icon(Icons.stay_current_portrait_rounded),
        title: 'Story 9:16',
        subtitle: '1080 x 1920',
        selected: true,
        onTap: () => log.add('story'),
      ),
      ReaderChoiceItem(
        leading: const Icon(Icons.crop_square_rounded),
        title: 'Square 1:1',
        subtitle: '1080 x 1080',
        onTap: () => log.add('square'),
      ),
      ReaderChoiceItem(
        leading: const Icon(Icons.image_outlined),
        title: 'Classic',
        subtitle: '1080 x 1350',
        onTap: () => log.add('classic'),
      ),
    ],
  );

  Widget ayahActions(List<String> log) => AyahActionsSheet(
    title: 'Al-Baqarah 142',
    favourite: IconButton(
      onPressed: () => log.add('favourite'),
      icon: const Icon(Icons.favorite_border_rounded),
    ),
    actions: <ReaderActionItem>[
      ReaderActionItem(
        leading: const Icon(Icons.play_arrow_rounded),
        title: 'Play this ayah',
        onTap: () => log.add('play'),
      ),
      ReaderActionItem(
        leading: const Icon(Icons.share_rounded),
        title: 'Share image',
        onTap: () => log.add('share'),
      ),
      ReaderActionItem(
        leading: const Icon(Icons.bookmark_border_rounded),
        title: 'Save to library',
        subtitle: 'Folder, tags and note',
        onTap: () => log.add('save'),
      ),
    ],
  );

  Widget reciters(List<String> log, {bool grouped = false}) =>
      ReciterPickerDialog(
        groupByDownloaded: grouped,
        groupTooltip: grouped ? 'Show Alphabetical' : 'Group Downloaded',
        onToggleGroup: () => log.add('group'),
        items: <ReciterPickerItem>[
          ReciterPickerItem(
            name: 'Mishary Rashid Alafasy',
            downloaded: true,
            selected: true,
            onTap: () => log.add('alafasy'),
          ),
          ReciterPickerItem(
            name: 'Abdul Basit Abdus Samad',
            downloaded: false,
            selected: false,
            onTap: () => log.add('basit'),
          ),
          ReciterPickerItem(
            name: 'Saud Al-Shuraim',
            downloaded: true,
            selected: false,
            onTap: () => log.add('shuraim'),
          ),
          ReciterPickerItem(
            name: 'Maher Al Muaiqly',
            downloaded: false,
            selected: false,
            onTap: () => log.add('maher'),
          ),
        ],
      );

  Widget noteEditor(
    List<String> log, {
    bool favourite = true,
    String folder = 'Default',
    TextEditingController? note,
    TextEditingController? tags,
  }) => BookmarkNoteSheet(
    title: 'Al-Baqarah 142',
    verse: const Text(
      'سَيَقُولُ السُّفَهَاءُ مِنَ النَّاسِ مَا وَلَّاهُمْ عَن قِبْلَتِهِمُ',
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'NotoNaskhArabic',
        fontSize: 22,
        height: 1.6,
      ),
    ),
    isFavourite: favourite,
    onFavouriteChanged: (v) => log.add('favourite:$v'),
    noteController:
        note ?? TextEditingController(text: 'Direction of prayer, revisit.'),
    folders: const <(String, String)>[
      ('Default', 'Unsorted'),
      ('Reflections', 'Reflections'),
      ('Hifz', 'Hifz'),
    ],
    selectedFolder: folder,
    onFolderSelected: (v) => log.add('folder:$v'),
    onCreateFolder: () => log.add('newFolder'),
    tagsController: tags ?? TextEditingController(text: 'qibla, change'),
    onTagsChanged: (v) => log.add('tags:$v'),
    onDelete: () => log.add('delete'),
    onSave: () => log.add('save'),
  );

  Widget topBar(List<String> log, {bool playing = false, bool play = true}) =>
      Column(
        children: <Widget>[
          ReaderAppBar(
            toolbarHeight: 64,
            title: 'Al-Baqarah',
            showPlayButton: play,
            isPlaying: playing,
            playTooltip: 'Play this ayah',
            pauseTooltip: 'Pause',
            onPlayPause: () => log.add('play'),
            optionsTooltip: 'Reading options',
            onOptions: () => log.add('options'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ReaderNavButton(
                  designIcon: 'back',
                  tooltip: 'Previous',
                  onPressed: () => log.add('previous'),
                ),
                ReaderNavButton(
                  designIcon: 'chev',
                  tooltip: 'Next',
                  onPressed: () => log.add('next'),
                ),
              ],
            ),
          ),
        ],
      );

  Widget interval(List<String> log, {String? error, int startAyah = 142}) =>
      ReaderIntervalSheet(
        groups: <Widget>[
          ReaderSheetGroup(
            title: 'Start',
            bottomPadding: 12,
            children: <Widget>[
              ReaderStepperRow(
                label: 'Surah',
                value: 2,
                min: 1,
                max: 114,
                helper: 'Al-Baqarah',
                onTap: () => log.add('pickStartSurah'),
                onChanged: (v) => log.add('startSurah:$v'),
              ),
              ReaderStepperRow(
                label: 'Ayah',
                value: startAyah,
                min: 1,
                max: 286,
                helper: '1-286',
                onTap: () => log.add('pickStartAyah'),
                onChanged: (v) => log.add('startAyah:$v'),
              ),
            ],
          ),
          ReaderSheetGroup(
            title: 'End',
            bottomPadding: 12,
            children: <Widget>[
              ReaderStepperRow(
                label: 'Surah',
                value: 2,
                min: 1,
                max: 114,
                helper: 'Al-Baqarah',
                onTap: () {},
                onChanged: (v) => log.add('endSurah:$v'),
              ),
              ReaderStepperRow(
                label: 'Ayah',
                value: 286,
                min: 1,
                max: 286,
                helper: '1-286',
                onTap: () {},
                onChanged: (v) => log.add('endAyah:$v'),
              ),
            ],
          ),
        ],
        summary: 'Al-Baqarah 142 to Al-Baqarah 286',
        errorText: error,
        onCancel: () => log.add('cancel'),
        onApply: () => log.add('apply'),
      );

  Widget details() => AyahDetailsSheet(
    scrollController: ScrollController(),
    title: 'Al-Baqarah 142',
    languageTooltip: 'Translation language',
    onLanguage: () {},
    arabic: const Text(
      'سَيَقُولُ السُّفَهَاءُ مِنَ النَّاسِ مَا وَلَّاهُمْ عَن قِبْلَتِهِمُ',
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      style: TextStyle(
        fontFamily: 'NotoNaskhArabic',
        fontSize: 26,
        height: 1.7,
      ),
    ),
    transliteration: 'Sayaqoolu alssufahao mina alnnasi ma wallahum',
    translation:
        'The foolish among the people will say, what has turned them away '
        'from the direction they used to face in prayer?',
  );

  Widget tafsir(List<String> log) => ReaderSheetFrame(
    title: 'Al-Baqarah 142',
    scrollController: ScrollController(),
    children: <Widget>[
      const ReaderTafsirCard(
        name: 'Tafsir Ibn Kathir',
        text:
            'Allah informs that some of the foolish would object to the change '
            'of the qiblah, and tells His Prophet how to answer them.',
      ),
      const SizedBox(height: 12),
      ReaderTafsirCard(
        name: 'Tafsir al-Jalalayn',
        text: '',
        needsDownloadText: 'Needs a download of 4.2 MB.',
        cancelLabel: 'Cancel',
        onCancel: () => log.add('cancel'),
        downloadLabel: 'Download',
        onDownload: () => log.add('download'),
      ),
      const SizedBox(height: 12),
      const ReaderTafsirCard(
        name: 'Tafsir al-Sa\'di',
        text: '',
        needsDownloadText: 'Needs a download of 2 MB.',
        cancelLabel: 'Cancel',
        downloadLabel: 'Downloading',
        downloading: true,
      ),
      const SizedBox(height: 12),
      ReaderNotice(
        icon: const DesignIcon('quran'),
        title: 'No tafsir sources selected',
        subtitle: 'Choose sources first',
        actionLabel: 'Choose',
        onAction: () => log.add('choose'),
      ),
    ],
  );

  Widget sources(List<String> log) => ReaderSheetFrame(
    title: 'Tafsir Sources',
    scrollController: ScrollController(),
    children: <Widget>[
      ReaderSheetGroup(
        bottomPadding: 0,
        children: <Widget>[
          ReaderSourceRow(
            title: 'Tafsir Ibn Kathir',
            subtitle: 'EN • Installed • 14 MB',
            selected: true,
            installed: true,
            downloading: false,
            downloadTooltip: 'Download',
            onDownload: () => log.add('download:kathir'),
            onToggle: () => log.add('toggle:kathir'),
          ),
          ReaderSourceRow(
            title: 'Tafsir al-Jalalayn',
            subtitle: 'EN • Not installed • 4 MB',
            selected: false,
            installed: false,
            downloading: false,
            downloadTooltip: 'Download',
            onDownload: () => log.add('download:jalalayn'),
            onToggle: () => log.add('toggle:jalalayn'),
          ),
          ReaderSourceRow(
            title: 'Tafsir al-Sa\'di',
            subtitle: 'AR • Downloading • 2 MB',
            selected: true,
            installed: false,
            downloading: true,
            downloadTooltip: 'Downloading',
            onDownload: () => log.add('download:sadi'),
            onToggle: () => log.add('toggle:sadi'),
          ),
        ],
      ),
    ],
  );

  Widget noteDialog(List<String> log) => ReaderNoteDialog(
    controller: TextEditingController(text: 'Revisit this one'),
    title: 'Saved ayah',
    hint: 'Optional note',
    maxLength: 280,
    cancelLabel: 'Cancel',
    saveLabel: 'Save',
    onSave: () => log.add('save'),
  );

  group('behaviour', () {
    testWidgets('reading options reach their callbacks', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => readingOptions(log), height: 1100);
      final l = l10n(tester);
      Future<void> tap(String text) async {
        final f = find.text(text);
        await tester.ensureVisible(f);
        await tester.tap(f);
      }

      await tap(l.goToAyah);
      await tap(l.translation);
      await tap(l.transliterationOption);
      await tap(l.cardViewOption);
      await tap(l.translationLanguage);
      await tap(l.tafsirSources);
      await tap(l.shareCurrentAyah);
      expect(log, <String>[
        'goTo',
        'translation:false',
        'transliteration:true',
        'cardView:false',
        'language',
        'tafsir',
        'share',
      ]);
    });

    testWidgets('translation language is hidden when translation is off', (
      tester,
    ) async {
      await pump(tester, (_) => readingOptions([], translation: false));
      expect(find.text(l10n(tester).translationLanguage), findsNothing);
    });

    testWidgets('switches are reachable as switches', (tester) async {
      await pump(tester, (_) => readingOptions([]), height: 1100);
      expect(find.byType(Switch), findsNWidgets(3));
    });

    testWidgets('go to ayah submits from the button and the keyboard', (
      tester,
    ) async {
      final log = <String>[];
      await pump(tester, (_) => goTo(log: log));
      final l = l10n(tester);
      expect(find.text(l.enterAyahRange(286)), findsOneWidget);
      await tester.tap(find.text(l.go));
      await tester.tap(find.text(l.cancel));
      await tester.enterText(find.byType(TextField), '7');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      expect(log, <String>['submit', 'cancel', 'changed:7', 'submit']);
    });

    testWidgets('go to ayah shows the error text', (tester) async {
      await pump(tester, (_) => goTo(error: 'Enter 1 to 286'));
      expect(find.text('Enter 1 to 286'), findsOneWidget);
    });

    testWidgets('go to ayah only accepts digits', (tester) async {
      final controller = TextEditingController();
      await pump(tester, (_) => goTo(controller: controller));
      await tester.enterText(find.byType(TextField), '1a2-3');
      expect(controller.text, '123');
    });

    testWidgets('sleep timer steps, toggles and applies', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => sleep(active: true, log: log));
      final l = l10n(tester);
      await tester.tap(find.byTooltip(l.decreaseLabel('min')));
      await tester.tap(find.byTooltip(l.increaseLabel('min')));
      await tester.tap(find.text(l.endOfSurah));
      await tester.tap(find.text(l.turnOff));
      await tester.tap(find.text(l.setTimer));
      expect(log, <String>[
        'step:-5',
        'step:5',
        'endOfSurah:true',
        'off',
        'set',
      ]);
    });

    testWidgets('sleep timer hides Turn off without a timer and locks the '
        'stepper for end of surah', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => sleep(endOfSurah: true, log: log));
      final l = l10n(tester);
      expect(find.text(l.turnOff), findsNothing);
      await tester.tap(find.byTooltip(l.increaseLabel('min')));
      expect(log, isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('share formats mark the current one and report taps', (
      tester,
    ) async {
      final log = <String>[];
      await pump(tester, (_) => shareFormats(log));
      expect(find.byType(Switch), findsNothing);
      await tester.tap(find.text('Square 1:1'));
      await tester.tap(find.text('Classic'));
      expect(log, <String>['square', 'classic']);
    });

    testWidgets('ayah actions report taps and keep the favourite slot', (
      tester,
    ) async {
      final log = <String>[];
      await pump(tester, (_) => ayahActions(log));
      final l = l10n(tester);
      expect(find.text(l.chooseAnAction), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.tap(find.text('Play this ayah'));
      await tester.tap(find.text('Save to library'));
      expect(log, <String>['favourite', 'play', 'save']);
    });

    testWidgets('reciter picker selects, groups and closes', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => reciters(log), asSheet: false);
      await tester.tap(find.text('Abdul Basit Abdus Samad'));
      await tester.tap(find.byTooltip('Group Downloaded'));
      expect(log, <String>['basit', 'group']);
      expect(find.byTooltip(l10n(tester).close), findsOneWidget);
    });

    testWidgets('choice dialog pops the tapped value', (tester) async {
      int? result;
      await pump(
        tester,
        (context) => Center(
          child: TextButton(
            onPressed: () async {
              result = await showReaderDialog<int>(
                context: context,
                builder: (_) => ReaderChoiceDialog<int>(
                  title: 'Repeat',
                  icon: const Icon(Icons.repeat_rounded),
                  selectedValue: 2,
                  options: const <AppSelectionOption<int>>[
                    AppSelectionOption<int>(value: 1, title: 'Once'),
                    AppSelectionOption<int>(value: 2, title: 'Twice'),
                    AppSelectionOption<int>(value: 3, title: 'Thrice'),
                  ],
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
        asSheet: false,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thrice'));
      await tester.pumpAndSettle();
      expect(result, 3);
    });

    testWidgets('choice dialog closes with null from the close button', (
      tester,
    ) async {
      int? result = 99;
      await pump(
        tester,
        (context) => Center(
          child: TextButton(
            onPressed: () async {
              result = await showReaderDialog<int>(
                context: context,
                builder: (_) => ReaderChoiceDialog<int>(
                  title: 'Repeat',
                  icon: const Icon(Icons.repeat_rounded),
                  selectedValue: 1,
                  options: const <AppSelectionOption<int>>[
                    AppSelectionOption<int>(value: 1, title: 'Once'),
                  ],
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
        asSheet: false,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n(tester).close));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    for (final destructive in <bool>[false, true]) {
      testWidgets('confirm dialog returns true on confirm '
          '(destructive: $destructive)', (tester) async {
        bool? result;
        await pump(
          tester,
          (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await showReaderDialog<bool>(
                  context: context,
                  builder: (_) => ReaderConfirmDialog(
                    title: 'Delete',
                    body: 'Remove it?',
                    cancelLabel: 'Cancel',
                    confirmLabel: 'Yes',
                    destructive: destructive,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
          asSheet: false,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();
        expect(result, isTrue);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(result, isFalse);
      });
    }

    testWidgets('note editor reports every control', (tester) async {
      final log = <String>[];
      final note = TextEditingController(text: 'x');
      await pump(
        tester,
        (_) => noteEditor(log, note: note),
        height: 1200,
        fixedHeight: true,
      );
      final l = l10n(tester);
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.tap(f);
      }

      await tap(find.text(l.favourites));
      await tap(find.text('Reflections'));
      await tap(find.text(l.addNewFolder));
      await tester.enterText(find.byKey(const Key('reader-tags-editor')), 'a');
      await tap(find.text(l.delete));
      await tap(find.text(l.save));
      expect(log, <String>[
        'favourite:false',
        'folder:Reflections',
        'newFolder',
        'tags:a',
        'delete',
        'save',
      ]);
      await tester.enterText(find.byKey(const Key('reader-note-editor')), 'y');
      expect(note.text, 'y');
    });

    testWidgets('folder dialog trims, ignores blanks and returns the name', (
      tester,
    ) async {
      String? result;
      final controller = TextEditingController();
      await pump(
        tester,
        (context) => Center(
          child: TextButton(
            onPressed: () async {
              result = await showReaderDialog<String>(
                context: context,
                builder: (_) => ReaderFolderNameDialog(controller: controller),
              );
            },
            child: const Text('open'),
          ),
        ),
        asSheet: false,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l = l10n(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(l.create));
      await tester.pumpAndSettle();
      expect(
        find.text(l.newFolder),
        findsOneWidget,
        reason: 'blank stays open',
      );
      await tester.enterText(find.byType(TextField), '  Hifz  ');
      await tester.tap(find.text(l.create));
      await tester.pumpAndSettle();
      expect(result, 'Hifz');
    });

    testWidgets('top bar: play only in list view, pause while playing', (
      tester,
    ) async {
      final log = <String>[];
      await pump(tester, (_) => topBar(log), asSheet: false);
      await tester.tap(find.byTooltip('Play this ayah'));
      await tester.tap(find.byTooltip('Reading options'));
      await tester.tap(find.byTooltip('Previous'));
      await tester.tap(find.byTooltip('Next'));
      expect(log, <String>['play', 'options', 'previous', 'next']);

      await pump(tester, (_) => topBar(log, playing: true), asSheet: false);
      expect(find.byTooltip('Pause'), findsOneWidget);
      await pump(tester, (_) => topBar(log, play: false), asSheet: false);
      expect(find.byTooltip('Play this ayah'), findsNothing);
    });

    testWidgets('top bar and nav targets are at least 44 px', (tester) async {
      await pump(tester, (_) => topBar([]), asSheet: false, scale: 1.3);
      for (final tip in <String>[
        'Play this ayah',
        'Reading options',
        'Previous',
        'Next',
      ]) {
        final size = tester.getSize(find.byTooltip(tip));
        expect(size.width, greaterThanOrEqualTo(44), reason: tip);
        expect(size.height, greaterThanOrEqualTo(44), reason: tip);
      }
    });

    testWidgets('back button pops the route', (tester) async {
      await pump(tester, (_) => topBar([]), asSheet: false);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      // The only route cannot pop; the tap must simply not throw.
      expect(tester.takeException(), isNull);
    });
    testWidgets('interval steppers clamp and report', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => interval(log), height: 1100);
      final l = l10n(tester);
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.tap(f);
      }

      await tap(find.byTooltip(l.decreaseLabel('Ayah')).first);
      await tap(find.byTooltip(l.increaseLabel('Ayah')).first);
      await tap(find.byTooltip(l.increaseLabel('Surah')).first);
      await tap(find.text('Al-Baqarah').first);
      await tap(find.text(l.apply));
      await tap(find.text(l.cancel));
      // End ayah is already at its maximum, so plus is disabled.
      await tap(find.byTooltip(l.increaseLabel('Ayah')).last);
      expect(log, <String>[
        'startAyah:141',
        'startAyah:143',
        'startSurah:3',
        'pickStartSurah',
        'apply',
        'cancel',
      ]);
    });

    testWidgets('interval sheet shows the error instead of the summary', (
      tester,
    ) async {
      await pump(tester, (_) => interval([], error: 'End is before start'));
      expect(find.text('End is before start'), findsOneWidget);
      expect(find.text('Al-Baqarah 142 to Al-Baqarah 286'), findsNothing);
    });

    testWidgets('tafsir cards report download and cancel', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => tafsir(log), height: 1400, fixedHeight: true);
      await tester.tap(find.text('Download'));
      await tester.tap(find.text('Cancel').first);
      await tester.tap(find.text('Choose'));
      expect(log, <String>['download', 'cancel', 'choose']);
      expect(find.textContaining('qiblah'), findsOneWidget);
    });

    testWidgets('tafsir sources toggle and download', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => sources(log), height: 900);
      await tester.tap(find.text('Tafsir Ibn Kathir'));
      await tester.tap(find.text('Tafsir al-Jalalayn'));
      await tester.tap(find.byTooltip('Download'));
      expect(log, <String>[
        'toggle:kathir',
        'toggle:jalalayn',
        'download:jalalayn',
      ]);
      // An installed source has no download button; a running one shows a
      // spinner, not a button.
      expect(find.byTooltip('Download'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('note dialog saves and cancels', (tester) async {
      final log = <String>[];
      await pump(tester, (_) => noteDialog(log), asSheet: false);
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Cancel'));
      expect(log, <String>['save']);
      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 280);
    });

    testWidgets('ayah details shows all three texts', (tester) async {
      await pump(tester, (_) => details(), height: 900);
      expect(find.textContaining('Sayaqoolu'), findsOneWidget);
      expect(find.textContaining('foolish'), findsOneWidget);
      expect(find.byTooltip('Translation language'), findsOneWidget);
    });
  });

  // Goldens. Every widget is captured in emerald dark; the four busiest are
  // repeated in emerald light, AMOLED black, red dark, at text scale 1.3 and
  // in Arabic (RTL).
  Future<void> shot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/reader/$name.png'),
  );

  final variants = <(String, EquranColors, double, Locale)>[
    ('emerald-dark', EquranColors.dark, 1.0, const Locale('en')),
    ('emerald-light', EquranColors.light, 1.0, const Locale('en')),
    ('black-dark', EquranColors.blackDark, 1.0, const Locale('en')),
    ('red-dark', EquranColors.redDark, 1.0, const Locale('en')),
    ('text-1.3', EquranColors.dark, 1.3, const Locale('en')),
    ('arabic-rtl', EquranColors.dark, 1.0, const Locale('ar')),
  ];

  for (final (name, colors, scale, locale) in variants) {
    final tall = scale > 1 ? 1250.0 : 900.0;
    testWidgets('golden reading options $name', (tester) async {
      await pump(
        tester,
        (_) => readingOptions([]),
        colors: colors,
        scale: scale,
        locale: locale,
        height: tall,
        fixedHeight: true,
      );
      await shot(tester, 'reading-options-$name');
    });
    testWidgets('golden note editor $name', (tester) async {
      await pump(
        tester,
        (_) => noteEditor([]),
        colors: colors,
        scale: scale,
        locale: locale,
        height: scale > 1 ? 1700 : 1300,
      );
      await shot(tester, 'note-editor-$name');
    });
    testWidgets('golden reciter dialog $name', (tester) async {
      await pump(
        tester,
        (_) => reciters([]),
        colors: colors,
        scale: scale,
        locale: locale,
        height: 800,
        asSheet: false,
      );
      await shot(tester, 'reciter-$name');
    });
    testWidgets('golden top bar and nav $name', (tester) async {
      await pump(
        tester,
        (_) => topBar([]),
        colors: colors,
        scale: scale,
        locale: locale,
        height: 300,
        asSheet: false,
      );
      await shot(tester, 'top-bar-$name');
    });
  }

  // Every other sheet and dialog, in emerald dark, emerald light, text scale
  // 1.3 and Arabic (RTL). AMOLED black and red are covered by the busiest
  // widgets above, which share the same chrome.
  final cases = <(String, Widget Function(), double, bool)>[
    ('go-to-ayah', () => goTo(), 520, true),
    (
      'go-to-ayah-error',
      () => goTo(error: 'Enter a number from 1 to 286'),
      520,
      true,
    ),
    ('sleep-timer', () => sleep(), 760, true),
    (
      'sleep-timer-active',
      () => sleep(endOfSurah: true, active: true),
      760,
      true,
    ),
    ('share-formats', () => shareFormats([]), 640, true),
    ('ayah-actions', () => ayahActions([]), 760, true),
    ('interval', () => interval([]), 1000, true),
    (
      'interval-error',
      () => interval([], error: 'End is before start'),
      1000,
      true,
    ),
    ('ayah-details', () => details(), 900, true),
    ('tafsir', () => tafsir([]), 1300, true),
    ('tafsir-sources', () => sources([]), 760, true),
    ('reciter-grouped', () => reciters([], grouped: true), 800, false),
    (
      'folder-dialog',
      () => ReaderFolderNameDialog(controller: TextEditingController()),
      500,
      false,
    ),
    ('note-dialog', () => noteDialog([]), 560, false),
    (
      'confirm-dialogs',
      () => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ReaderConfirmDialog(
            icon: DesignIcon('trash'),
            title: 'Delete downloaded ayah?',
            body: 'This removes ayah 2:142 from offline storage.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
            destructive: true,
          ),
          ReaderConfirmDialog(
            icon: DesignIcon('download'),
            title: 'Download all ayahs?',
            body: 'Download every ayah of Al-Baqarah for offline listening.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Download',
          ),
        ],
      ),
      900,
      false,
    ),
    (
      'choice-dialog',
      () => const ReaderChoiceDialog<int>(
        title: 'Repeat each ayah',
        icon: Icon(Icons.repeat_one_rounded),
        selectedValue: 2,
        options: <AppSelectionOption<int>>[
          AppSelectionOption<int>(value: 1, title: '1 time'),
          AppSelectionOption<int>(value: 2, title: '2 times'),
          AppSelectionOption<int>(value: 3, title: '3 times'),
          AppSelectionOption<int>(value: 4, title: 'Infinite'),
        ],
      ),
      700,
      false,
    ),
  ];
  final caseVariants = <(String, EquranColors, double, Locale)>[
    variants[0],
    variants[1],
    variants[4],
    variants[5],
  ];
  for (final (id, build, height, sheet) in cases) {
    for (final (name, colors, scale, locale) in caseVariants) {
      testWidgets('golden $id $name', (tester) async {
        await pump(
          tester,
          (_) => build(),
          colors: colors,
          scale: scale,
          locale: locale,
          height: scale > 1 ? height * 1.35 : height,
          asSheet: sheet,
          fixedHeight:
              id == 'tafsir' || id == 'tafsir-sources' || id == 'ayah-details',
        );
        await shot(tester, '$id-$name');
      });
    }
  }
}
