import 'dart:async' show unawaited;

import 'package:equran/backend/android_audio_display_mode.dart';
import 'package:equran/backend/library.dart'
    show FavouritesDB, QuranBookmarkService;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart' show EquranTextStyles;
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';

const int _favouriteNoteMaxLength = 80;

double readQuranCardHorizontalMarginForWidth(double width) {
  if (width > 1200) return 120.0;
  if (width > 700) return 40.0;
  return 6.0;
}

class ReadQuranCard extends StatelessWidget {
  final int currentChapter;
  final int currentVerse;
  final int totalVerses;
  final int juzNumber;

  final String translation;
  final String transliteration;
  final String verse;
  final String? basmala;

  final double fontSize;
  final double fontSizeTranslation;
  final bool showActions;
  final bool showTransliteration;
  final bool showTranslation;
  final bool shareImageMode;

  final VoidCallback? onPlay;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onDownload;
  final VoidCallback? onDeleteDownload;
  final VoidCallback? onShare;
  final VoidCallback? onTafsir;
  final VoidCallback? onSwitchTranslation;
  final ValueChanged<bool>? onVisualOverlayChanged;
  final bool isPlaying;
  final bool isDownloading;
  final bool isDownloaded;

  const ReadQuranCard({
    super.key,
    required this.currentChapter,
    required this.currentVerse,
    required this.totalVerses,
    required this.fontSize,
    required this.fontSizeTranslation,
    required this.juzNumber,
    required this.translation,
    this.transliteration = '',
    this.basmala,
    required this.verse,
    this.showActions = true,
    this.showTransliteration = false,
    this.showTranslation = true,
    this.shareImageMode = false,
    this.onPlay,
    this.onPrevious,
    this.onNext,
    this.onDownload,
    this.onDeleteDownload,
    this.onShare,
    this.onTafsir,
    this.onSwitchTranslation,
    this.onVisualOverlayChanged,
    this.isPlaying = false,
    this.isDownloading = false,
    this.isDownloaded = false,
  });

  Future<bool> _showInputPrompt(BuildContext context) async {
    final TextEditingController textController = TextEditingController();
    bool saved = false;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    AndroidAudioDisplayMode.notifyUserActivity();
    onVisualOverlayChanged?.call(true);
    unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(true));
    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(localizations.savedAyah),
            content: TextField(
              maxLength: _favouriteNoteMaxLength,
              maxLines: null,
              controller: textController,
              decoration: InputDecoration(hintText: localizations.optionalNote),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final NavigatorState navigator = Navigator.of(context);
                  try {
                    await const QuranBookmarkService().saveFavourite(
                      currentChapter,
                      currentVerse,
                      note: textController.text,
                    );
                    saved = true;
                  } catch (_) {
                    saved = false;
                  }
                  navigator.pop();
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(localizations.save),
              ),
            ],
          );
        },
      );
    } finally {
      onVisualOverlayChanged?.call(false);
      unawaited(AndroidAudioDisplayMode.setLowFpsSuppressed(false));
      await WidgetsBinding.instance.endOfFrame;
      textController.dispose();
    }
    return saved;
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final TextStyle? mutedStyle =
        (shareImageMode
                ? theme.textTheme.labelLarge
                : theme.textTheme.labelMedium)
            ?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(205),
              fontSize: shareImageMode ? 24 : null,
              fontWeight: FontWeight.w600,
            );
    final String ayahLabel = shareImageMode
        ? localizations.ayahNumber(currentVerse)
        : localizations.ayahOfTotal(currentVerse, totalVerses);

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.mint,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  localizedJuzLabel(localizations, juzNumber),
                  style: mutedStyle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ayahLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(190),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showActions && !shareImageMode) ...<Widget>[
          const SizedBox(width: 12),
          _buildHeaderActions(context),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required Widget child,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool wideActions = MediaQuery.sizeOf(context).width >= 700;
    final double actionSize = wideActions ? 38 : 34;
    final BorderRadius radius = BorderRadius.circular(10);

    return Material(
      color: isPrimary ? colorScheme.primary.withAlpha(10) : Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            height: actionSize,
            width: actionSize,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: FavouritesDB().listener,
      builder: (context, favouritesBox, child) {
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final AppLocalizations localizations = AppLocalizations.of(context)!;
        final bool isFavourite = const QuranBookmarkService().isFavourite(
          currentChapter,
          currentVerse,
        );
        final bool wideActions = MediaQuery.sizeOf(context).width >= 700;
        final double actionGap = wideActions ? 10 : 6;
        final double playIconSize = wideActions ? 23 : 21;
        final double actionIconSize = wideActions ? 20 : 18;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildActionButton(
              context: context,
              tooltip: isPlaying ? localizations.pause : localizations.play,
              onPressed: onPlay,
              isPrimary: true,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: playIconSize,
                color: colorScheme.primary,
              ),
            ),
            if (onTafsir != null) ...<Widget>[
              SizedBox(width: actionGap),
              _buildActionButton(
                context: context,
                tooltip: localizations.tafsir,
                onPressed: onTafsir,
                child: Icon(
                  Icons.chrome_reader_mode_rounded,
                  size: actionIconSize,
                  color: colorScheme.onSurface.withAlpha(168),
                ),
              ),
            ],
            SizedBox(width: actionGap),
            _buildFavouriteButton(context, isFavourite: isFavourite),
          ],
        );
      },
    );
  }

  Widget _buildFavouriteButton(
    BuildContext context, {
    required bool isFavourite,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool wideActions = MediaQuery.sizeOf(context).width >= 700;
    final double buttonSize = wideActions ? 38 : 34;
    final double iconSize = wideActions ? 22 : 20;

    return Tooltip(
      message: isFavourite ? localizations.remove : localizations.favourites,
      child: SizedBox(
        height: buttonSize,
        width: buttonSize,
        child: Center(
          child: LikeButton(
            size: iconSize,
            isLiked: isFavourite,
            circleColor: CircleColor(
              start: colorScheme.primary.withAlpha(180),
              end: colorScheme.primary,
            ),
            bubblesColor: BubblesColor(
              dotPrimaryColor: colorScheme.primary,
              dotSecondaryColor: colorScheme.secondary,
            ),
            likeBuilder: (bool liked) {
              return Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked
                    ? colorScheme.primary
                    : colorScheme.onSurface.withAlpha(168),
                size: iconSize,
              );
            },
            onTap: (bool liked) async {
              AndroidAudioDisplayMode.notifyUserActivity();
              try {
                if (liked) {
                  await const QuranBookmarkService().removeFavourite(
                    currentChapter,
                    currentVerse,
                  );
                  return false;
                }
                return await _showInputPrompt(context);
              } catch (_) {
                return liked;
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final EquranColors colors = context.equranColors;
    final bool isLight = theme.brightness == Brightness.light;
    final Color resolvedCardColor =
        theme.cardTheme.color ??
        (isLight
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainer);
    final String trimmedTransliteration = transliteration.trim();
    final bool hasTransliteration =
        showTransliteration && trimmedTransliteration.isNotEmpty;
    final bool hasTranslation =
        showTranslation && translation.trim().isNotEmpty;
    final bool hasVerse = verse.trim().isNotEmpty;
    final bool compactShareContent =
        shareImageMode && verse.runes.length <= 140;

    final double marginValue = readQuranCardHorizontalMarginForWidth(
      screenSize.width,
    );

    final BorderRadius radius = BorderRadius.circular(AppRadii.large);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: marginValue, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: isLight ? colors.border : colors.border.withAlpha(160),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: resolvedCardColor,
          gradient: shareImageMode
              ? colors.softSurfaceGradient
              : isLight
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[colors.paleGreen, colors.surface],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color.alphaBlend(
                      colorScheme.primary.withAlpha(14),
                      resolvedCardColor,
                    ),
                    Color.alphaBlend(
                      colorScheme.secondary.withAlpha(8),
                      resolvedCardColor,
                    ),
                  ],
                ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.shadow.withAlpha(isLight ? 14 : 36),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            EquranSpacing.pagePadding,
            compactShareContent ? 14 : 16,
            EquranSpacing.pagePadding,
            shareImageMode ? (compactShareContent ? 14 : 16) : 20,
          ),
          child: Column(
            mainAxisSize: shareImageMode ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(context),
              SizedBox(height: compactShareContent ? 16 : 20),
              if (basmala != null)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: compactShareContent ? 14 : 16,
                  ),
                  child: Text(
                    basmala!,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: EquranTextStyles.fontFamilyForVerse(
                        currentChapter,
                        currentVerse,
                      ),
                      fontFamilyFallback: const <String>['UthmanicHafs'],
                      fontSize: fontSize,
                      height: 1.7,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              if (hasVerse)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    verse,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontFamily: EquranTextStyles.fontFamilyForVerse(
                        currentChapter,
                        currentVerse,
                      ),
                      fontFamilyFallback: const <String>['UthmanicHafs'],
                      height: 1.78,
                      fontSize: fontSize,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              if (hasTransliteration)
                Padding(
                  padding: EdgeInsets.only(top: compactShareContent ? 12 : 14),
                  child: Text(
                    trimmedTransliteration,
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: (fontSizeTranslation - 2)
                          .clamp(12.0, 18.0)
                          .toDouble(),
                      color: colorScheme.onSurfaceVariant.withAlpha(178),
                      height: 1.45,

                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              if (hasTranslation) ...[
                Padding(
                  padding: EdgeInsets.only(
                    top: hasTransliteration
                        ? (compactShareContent ? 14 : 16)
                        : (compactShareContent ? 16 : 18),
                  ),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withAlpha(118),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: compactShareContent ? 14 : 16),
                  child: Text(
                    translation,
                    textAlign: TextAlign.justify,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: fontSizeTranslation,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
              if (shareImageMode) ...<Widget>[
                SizedBox(height: compactShareContent ? 14 : 18),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(90),
                ),
                SizedBox(height: compactShareContent ? 8 : 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'eQuran',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$currentChapter:$currentVerse',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(140),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
