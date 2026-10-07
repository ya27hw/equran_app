import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Presentational bodies for the reader's sheets and dialogs. None of them
/// owns state: values and controllers come in, callbacks go out, and the
/// reading page keeps persistence, audio and navigation.

/// The reading page's top bar: back, the surah name in the display face, and
/// the play and options actions. Same slots as the old bar, so the page and
/// its snackbars keep working with a plain [Scaffold].
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderAppBar({
    super.key,
    required this.toolbarHeight,
    required this.title,
    required this.showPlayButton,
    required this.isPlaying,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.onPlayPause,
    required this.optionsTooltip,
    required this.onOptions,
  });

  final double toolbarHeight;
  final String title;
  final bool showPlayButton;
  final bool isPlaying;
  final String playTooltip;
  final String pauseTooltip;
  final VoidCallback onPlayPause;
  final String optionsTooltip;
  final VoidCallback onOptions;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: Center(
        child: IconButton44(
          designIcon: 'back',
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: redesignDisplayStyle(
          context,
          size: 24,
          color: colors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: <Widget>[
        if (showPlayButton)
          IconButton44(
            tooltip: isPlaying ? pauseTooltip : playTooltip,
            onPressed: onPlayPause,
            ghost: true,
            // The design set has a play glyph but no pause, so both states
            // use the Material pair to stay one icon family.
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
        IconButton44(
          tooltip: optionsTooltip,
          onPressed: onOptions,
          designIcon: 'dots',
          ghost: true,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

/// The prev/next pill under the verse.
class ReaderNavButton extends StatelessWidget {
  const ReaderNavButton({
    super.key,
    required this.designIcon,
    required this.tooltip,
    required this.onPressed,
  });

  final String designIcon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: context.equranColors.surface,
          shape: StadiumBorder(side: BorderSide(color: tokens.hair)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
              child: Center(
                child: DesignIcon(
                  designIcon,
                  size: 22,
                  strokeWidth: 1.8,
                  color: tokens.emText,
                  mirrorInRtl: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The reading options hub.
class ReadingOptionsSheet extends StatelessWidget {
  const ReadingOptionsSheet({
    super.key,
    required this.scrollController,
    required this.surahName,
    required this.verse,
    required this.translationEnabled,
    required this.transliterationEnabled,
    required this.cardViewEnabled,
    required this.onTranslationChanged,
    required this.onTransliterationChanged,
    required this.onCardViewChanged,
    required this.onGoToAyah,
    required this.onTranslationLanguage,
    required this.onTafsirSources,
    required this.onShare,
  });

  final ScrollController scrollController;
  final String surahName;
  final int verse;
  final bool translationEnabled;
  final bool transliterationEnabled;
  final bool cardViewEnabled;
  final ValueChanged<bool> onTranslationChanged;
  final ValueChanged<bool> onTransliterationChanged;
  final ValueChanged<bool> onCardViewChanged;
  final VoidCallback onGoToAyah;
  final VoidCallback onTranslationLanguage;
  final VoidCallback onTafsirSources;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ReaderSheetFrame(
      scrollController: scrollController,
      title: l.readingOptions,
      subtitle: l.surahLabel(surahName, verse),
      children: <Widget>[
        ReaderSheetGroup(
          title: l.navigation,
          children: <Widget>[
            ReaderOptionRow(
              leading: const DesignIcon('pin'),
              title: l.goToAyah,
              subtitle: l.jumpToAyahIn(surahName),
              onTap: onGoToAyah,
            ),
          ],
        ),
        ReaderSheetGroup(
          title: l.displayAndSharing,
          children: <Widget>[
            ReaderSwitchRow(
              leading: const DesignIcon('chat'),
              title: l.translation,
              subtitle: l.showAyahTranslation,
              value: translationEnabled,
              onChanged: onTranslationChanged,
            ),
            ReaderSwitchRow(
              leading: const Icon(Icons.text_fields_rounded),
              title: l.transliterationOption,
              subtitle: l.showLatinTransliteration,
              value: transliterationEnabled,
              onChanged: onTransliterationChanged,
            ),
            ReaderSwitchRow(
              leading: const DesignIcon('book'),
              title: l.cardViewOption,
              subtitle: l.readOneAyahPerCard,
              value: cardViewEnabled,
              onChanged: onCardViewChanged,
            ),
            if (translationEnabled)
              ReaderOptionRow(
                leading: const Icon(Icons.language_rounded),
                title: l.translationLanguage,
                subtitle: l.chooseTranslationShownOnCards,
                onTap: onTranslationLanguage,
              ),
            ReaderOptionRow(
              leading: const DesignIcon('quran'),
              title: l.tafsirSources,
              subtitle: l.chooseDownloadedExplanations,
              onTap: onTafsirSources,
            ),
            ReaderOptionRow(
              leading: const DesignIcon('share'),
              title: l.shareCurrentAyah,
              subtitle: l.createImageForThisAyah,
              onTap: onShare,
            ),
          ],
        ),
      ],
    );
  }
}

/// Go to ayah: one numeric field, Go and Cancel.
class GoToAyahSheet extends StatelessWidget {
  const GoToAyahSheet({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.totalVerses,
    required this.errorText,
    required this.onChanged,
    required this.onSubmit,
    required this.onCancel,
    this.bottomInset = 0,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int totalVerses;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    return ReaderSheetFrame(
      title: l.goToAyah,
      subtitle: l.enterAyahRange(totalVerses),
      bottomInset: bottomInset,
      children: <Widget>[
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.go,
          textAlign: TextAlign.center,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: EquranTextStyles.displayNumeral(
            context,
            size: 28,
            color: colors.textPrimary,
          ),
          decoration: readerInputDecoration(
            context,
            hint: l.ayahNumberHint,
            errorText: errorText,
          ),
          onChanged: onChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: readerFilledButtonStyle(context),
          onPressed: onSubmit,
          child: Text(l.go),
        ),
        const SizedBox(height: 4),
        TextButton(
          style: readerTextButtonStyle(context),
          onPressed: onCancel,
          child: Text(l.cancel),
        ),
      ],
    );
  }
}

/// Sleep timer: minutes stepper, end-of-surah switch, Turn off and Set timer.
class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({
    super.key,
    required this.minutesController,
    required this.unitLabel,
    required this.endOfSurah,
    required this.hasActiveTimer,
    required this.onStep,
    required this.onMinutesChanged,
    required this.onEndOfSurahChanged,
    required this.onTurnOff,
    required this.onSet,
    this.bottomInset = 0,
  });

  final TextEditingController minutesController;

  /// The unit shown after the number, such as "min".
  final String unitLabel;
  final bool endOfSurah;
  final bool hasActiveTimer;
  final ValueChanged<int> onStep;
  final ValueChanged<String> onMinutesChanged;
  final ValueChanged<bool> onEndOfSurahChanged;
  final VoidCallback onTurnOff;
  final VoidCallback onSet;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return ReaderSheetFrame(
      title: l.sleepTimerSettings,
      bottomInset: bottomInset,
      children: <Widget>[
        ReaderSheetGroup(
          title: l.numericMinutesDuration,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: <Widget>[
                  IconButton44(
                    icon: Icons.remove_rounded,
                    tooltip: l.decreaseLabel(unitLabel),
                    onPressed: endOfSurah ? null : () => onStep(-5),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: minutesController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: !endOfSurah,
                        style: EquranTextStyles.displayNumeral(
                          context,
                          size: 32,
                          color: endOfSurah ? tokens.muted : colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          suffixText: unitLabel,
                          suffixStyle: TextStyle(
                            fontSize: 14,
                            color: tokens.muted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: onMinutesChanged,
                      ),
                    ),
                  ),
                  IconButton44(
                    designIcon: 'plus',
                    tooltip: l.increaseLabel(unitLabel),
                    onPressed: endOfSurah ? null : () => onStep(5),
                  ),
                ],
              ),
            ),
          ],
        ),
        ReaderSheetGroup(
          bottomPadding: 8,
          children: <Widget>[
            ReaderSwitchRow(
              leading: const Icon(Icons.queue_music_rounded),
              title: l.endOfSurah,
              subtitle: l.endOfSurahSubtitle,
              value: endOfSurah,
              onChanged: onEndOfSurahChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            if (hasActiveTimer) ...<Widget>[
              Expanded(
                child: OutlinedButton(
                  style: readerOutlinedButtonStyle(context),
                  onPressed: onTurnOff,
                  child: Text(l.turnOff),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                style: readerFilledButtonStyle(context),
                onPressed: onSet,
                child: Text(l.setTimer),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One choice in a [ReaderChoiceSheet].
class ReaderChoiceItem {
  const ReaderChoiceItem({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
}

/// A short list of choices on one card, such as the share image formats.
class ReaderChoiceSheet extends StatelessWidget {
  const ReaderChoiceSheet({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<ReaderChoiceItem> items;

  @override
  Widget build(BuildContext context) {
    return ReaderSheetFrame(
      title: title,
      subtitle: subtitle,
      children: <Widget>[
        ReaderSheetGroup(
          bottomPadding: 0,
          children: <Widget>[
            for (final ReaderChoiceItem item in items)
              ReaderOptionRow(
                leading: item.leading,
                title: item.title,
                subtitle: item.subtitle,
                selected: item.selected,
                showChevron: false,
                onTap: item.onTap,
              ),
          ],
        ),
      ],
    );
  }
}

/// One action in [AyahActionsSheet].
class ReaderActionItem {
  const ReaderActionItem({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

/// The long-press menu for an ayah: its label, a favourite control in
/// [favourite] and a list of actions.
class AyahActionsSheet extends StatelessWidget {
  const AyahActionsSheet({
    super.key,
    required this.title,
    required this.favourite,
    required this.actions,
  });

  final String title;
  final Widget favourite;
  final List<ReaderActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ReaderSheetFrame(
      title: title,
      subtitle: l.chooseAnAction,
      trailing: SizedBox(
        width: 48,
        height: 48,
        child: Center(child: favourite),
      ),
      children: <Widget>[
        ReaderSheetGroup(
          bottomPadding: 0,
          children: <Widget>[
            for (final ReaderActionItem action in actions)
              ReaderOptionRow(
                leading: action.leading,
                title: action.title,
                subtitle: action.subtitle,
                showChevron: false,
                onTap: action.onTap,
              ),
          ],
        ),
      ],
    );
  }
}

/// One reciter in [ReciterPickerDialog].
class ReciterPickerItem {
  const ReciterPickerItem({
    required this.name,
    required this.downloaded,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool downloaded;
  final bool selected;
  final VoidCallback onTap;
}

class ReciterPickerDialog extends StatelessWidget {
  const ReciterPickerDialog({
    super.key,
    required this.items,
    required this.groupByDownloaded,
    required this.groupTooltip,
    required this.onToggleGroup,
  });

  final List<ReciterPickerItem> items;
  final bool groupByDownloaded;
  final String groupTooltip;
  final VoidCallback onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    return ReaderDialog(
      title: l.reciter,
      icon: const DesignIcon('headphones'),
      scrollableContent: true,
      titleTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton44(
            icon: groupByDownloaded
                ? Icons.offline_pin_rounded
                : Icons.offline_pin_outlined,
            tooltip: groupTooltip,
            ghost: !groupByDownloaded,
            onPressed: onToggleGroup,
          ),
          IconButton44(
            designIcon: 'x',
            tooltip: l.close,
            ghost: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final ReciterPickerItem item = items[index];
          return ReaderChoiceTile(
            title: item.name,
            selected: item.selected,
            leading: item.downloaded
                ? Icon(
                    Icons.offline_pin_rounded,
                    size: 20,
                    color: tokens.emText,
                  )
                : DesignIcon('headphones', size: 20, color: tokens.muted),
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}

/// The reader's note editor for an ayah. It mirrors the Saved tab's editor:
/// favourite, note, folder chips, tags, delete and save.
class BookmarkNoteSheet extends StatelessWidget {
  const BookmarkNoteSheet({
    super.key,
    required this.title,
    required this.verse,
    required this.isFavourite,
    required this.onFavouriteChanged,
    required this.noteController,
    required this.folders,
    required this.selectedFolder,
    required this.onFolderSelected,
    required this.onCreateFolder,
    required this.tagsController,
    required this.onTagsChanged,
    required this.onDelete,
    required this.onSave,
    this.bottomInset = 0,
  });

  final String title;

  /// The ayah text, already styled by the reading page.
  final Widget verse;
  final bool isFavourite;
  final ValueChanged<bool> onFavouriteChanged;
  final TextEditingController noteController;

  /// Folder id and its display label.
  final List<(String, String)> folders;
  final String selectedFolder;
  final ValueChanged<String> onFolderSelected;
  final VoidCallback onCreateFolder;
  final TextEditingController tagsController;
  final ValueChanged<String> onTagsChanged;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return ReaderSheetFrame(
      title: title,
      bottomInset: bottomInset,
      trailing: IconButton44(
        designIcon: 'x',
        tooltip: l.close,
        ghost: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(EquranRadii.large),
            border: Border.all(color: tokens.hair),
          ),
          child: verse,
        ),
        const SizedBox(height: 12),
        ReaderSheetGroup(
          bottomPadding: 16,
          children: <Widget>[
            ReaderSwitchRow(
              leading: DesignIcon('heart', filled: isFavourite),
              title: l.favourites,
              value: isFavourite,
              onChanged: onFavouriteChanged,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 9),
          child: RedesignEyebrow(l.note),
        ),
        TextField(
          key: const Key('reader-note-editor'),
          controller: noteController,
          maxLines: 4,
          minLines: 3,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: colors.textPrimary,
          ),
          decoration: readerInputDecoration(
            context,
            hint: l.writeReflectionHint,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
          child: RedesignEyebrow(l.folders),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final (String id, String label) in folders)
              ChipButton(
                label,
                selected: selectedFolder == id,
                icon: selectedFolder == id ? Icons.check_rounded : null,
                onPressed: () => onFolderSelected(id),
              ),
            ChipButton(
              l.addNewFolder,
              icon: Icons.add_rounded,
              onPressed: onCreateFolder,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l.savedAyahsOrganizedHint,
          style: TextStyle(fontSize: 12.5, height: 1.4, color: tokens.muted),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 9),
          child: RedesignEyebrow(l.tags),
        ),
        TextField(
          key: const Key('reader-tags-editor'),
          controller: tagsController,
          onChanged: onTagsChanged,
          style: TextStyle(fontSize: 14.5, color: colors.textPrimary),
          decoration: readerInputDecoration(context, hint: l.tagsHint),
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            TextButton.icon(
              style: readerTextButtonStyle(context, color: tokens.danger),
              onPressed: onDelete,
              icon: const DesignIcon('trash', size: 20),
              label: Text(l.delete),
            ),
            const Spacer(),
            FilledButton.icon(
              style: readerFilledButtonStyle(context),
              onPressed: onSave,
              icon: const DesignIcon('check', size: 20, strokeWidth: 2),
              label: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}

/// New folder: one name field with Cancel and Create.
class ReaderFolderNameDialog extends StatelessWidget {
  const ReaderFolderNameDialog({super.key, required this.controller});

  final TextEditingController controller;

  void _submit(BuildContext context) {
    final String value = controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ReaderDialog(
      title: l.newFolder,
      icon: const DesignIcon('folder'),
      content: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: TextStyle(
            fontSize: 15,
            color: context.equranColors.textPrimary,
          ),
          decoration: readerInputDecoration(
            context,
            hint: l.folderNameHint,
            label: l.folderName,
          ),
          onSubmitted: (_) => _submit(context),
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: readerTextButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: readerFilledButtonStyle(context),
          onPressed: () => _submit(context),
          child: Text(l.create),
        ),
      ],
    );
  }
}
