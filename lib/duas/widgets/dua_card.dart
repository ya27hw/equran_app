import 'package:equran/backend/dua_favourites_db.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:like_button/like_button.dart';
import 'package:share_plus/share_plus.dart';

enum _DuaOverflowAction { copy, share }

class DuaCard extends StatelessWidget {
  const DuaCard({
    super.key,
    required this.dua,
    this.number,
    this.categoryTitle,
    this.onTap,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 16, 20, 18),
  });

  final DuaEntry dua;
  final int? number;
  final String? categoryTitle;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool isLight = theme.brightness == Brightness.light;
    final List<String> metadata = <String>[
      if (dua.count != null && dua.count! > 1)
        '${localizations.repeat} ${dua.count}x',
      if (dua.reference != null) dua.reference!,
      if (dua.source != null) dua.source!,
      if (dua.notes != null) dua.notes!,
    ];

    return ValueListenableBuilder<Box<dynamic>>(
      valueListenable: SettingsDB().listener,
      builder: (BuildContext context, Box<dynamic> settingsBox, Widget? child) {
        final double translationFontSize =
            (settingsBox.get('fontSizeTranslation', defaultValue: 12.0) as num)
                .toDouble();
        final bool showTranslation =
            settingsBox.get('duaShowTranslation', defaultValue: true) as bool;
        final bool showTransliteration =
            settingsBox.get('duaShowTransliteration', defaultValue: true)
                as bool;
        final String defaultLang = Localizations.localeOf(context).languageCode;
        final String translationLang =
            settingsBox.get('duaTranslationLanguage', defaultValue: defaultLang)
                as String;

        return ValueListenableBuilder<Box<dynamic>>(
          valueListenable: DuaFavouritesDB().listener,
          builder: (BuildContext context, Box<dynamic> box, Widget? child) {
            final bool isFavourite =
                DuaFavouritesDB().contains(dua.id) ||
                DuaFavouritesDB().contains(dua.legacyFavouriteId);

            return Card(
              elevation: isLight ? 3 : 0,
              color: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                side: BorderSide(
                  color: isLight
                      ? colors.primary.withAlpha(26)
                      : colors.outlineVariant.withAlpha(86),
                ),
              ),
              child: InkWell(
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color.alphaBlend(
                          colors.primary.withAlpha(isLight ? 10 : 16),
                          theme.cardTheme.color ?? colors.surfaceContainerLow,
                        ),
                        Color.alphaBlend(
                          colors.tertiary.withAlpha(isLight ? 8 : 12),
                          theme.cardTheme.color ?? colors.surfaceContainerLow,
                        ),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withAlpha(isLight ? 10 : 20),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _DuaCardHeader(
                          dua: dua,
                          number: number,
                          categoryTitle: categoryTitle,
                          isFavourite: isFavourite,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          dua.text,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontFamily: EquranTextStyles.activeFontFamily,
                            fontFamilyFallback: const <String>['Hafs'],
                            height: 1.95,
                            fontSize:
                                settingsBox.get("fontSize", defaultValue: 31.0)
                                    as double,
                            letterSpacing: 0,
                            color: colors.onSurface,
                          ),
                        ),
                        if (showTransliteration &&
                            dua.transliteration != null) ...<Widget>[
                          const SizedBox(height: 14),
                          Text(
                            dua.transliteration!,
                            textAlign: TextAlign.justify,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: (translationFontSize - 2)
                                  .clamp(12.0, 18.0)
                                  .toDouble(),
                              color: colors.onSurfaceVariant.withAlpha(190),
                              height: 1.45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (showTranslation &&
                            dua.localizedTranslation(translationLang) !=
                                null) ...<Widget>[
                          const SizedBox(height: 14),
                          Divider(
                            height: 1,
                            color: colors.outlineVariant.withAlpha(118),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            dua.localizedTranslation(translationLang)!,
                            textAlign: TextAlign.justify,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: translationFontSize,
                              color: colors.onSurfaceVariant,
                              height: 1.55,
                            ),
                          ),
                        ],
                        if (metadata.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: metadata
                                .map(
                                  (String item) => _DuaMetadataPill(text: item),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DuaCardHeader extends StatelessWidget {
  const _DuaCardHeader({
    required this.dua,
    required this.number,
    required this.categoryTitle,
    required this.isFavourite,
  });

  final DuaEntry dua;
  final int? number;
  final String? categoryTitle;
  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Row(
      children: <Widget>[
        if (number != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(14),
              borderRadius: BorderRadius.circular(AppRadii.medium),
              border: Border.all(color: colors.primary.withAlpha(24)),
            ),
            child: Text(
              '${localizations.dua} $number',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant.withAlpha(205),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (categoryTitle != null) ...<Widget>[
          if (number != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              categoryTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant.withAlpha(190),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ] else
          const Spacer(),
        const SizedBox(width: 10),
        _DuaFavouriteButton(dua: dua, isFavourite: isFavourite),
        const SizedBox(width: 6),
        _DuaMoreMenu(dua: dua),
      ],
    );
  }
}

class _DuaFavouriteButton extends StatelessWidget {
  const _DuaFavouriteButton({required this.dua, required this.isFavourite});

  final DuaEntry dua;
  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Tooltip(
      message: isFavourite
          ? localizations.removeFavourite
          : localizations.favourite,
      child: SizedBox(
        height: 34,
        width: 34,
        child: Center(
          child: LikeButton(
            size: 22,
            isLiked: isFavourite,
            circleColor: CircleColor(
              start: colors.primary.withAlpha(180),
              end: colors.primary,
            ),
            bubblesColor: BubblesColor(
              dotPrimaryColor: colors.primary,
              dotSecondaryColor: colors.secondary,
            ),
            likeBuilder: (bool liked) {
              return Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? colors.primary : colors.onSurface.withAlpha(168),
                size: 21,
              );
            },
            onTap: (bool liked) async {
              try {
                if (liked) {
                  await DuaFavouritesDB().delete(dua.id);
                  await DuaFavouritesDB().delete(dua.legacyFavouriteId);
                  return false;
                }

                await DuaFavouritesDB().put(dua.id, dua.toFavouriteSnapshot());
                return true;
              } catch (error) {
                if (!context.mounted) return liked;
                final AppLocalizations localizations = AppLocalizations.of(
                  context,
                )!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.couldNotUpdateDua)),
                );
                return liked;
              }
            },
          ),
        ),
      ),
    );
  }
}

class _DuaMoreMenu extends StatelessWidget {
  const _DuaMoreMenu({required this.dua});

  final DuaEntry dua;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return SizedBox(
      height: 34,
      width: 34,
      child: PopupMenuButton<_DuaOverflowAction>(
        tooltip: localizations.moreActions,
        position: PopupMenuPosition.under,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(10),
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 19,
          color: colors.onSurface.withAlpha(168),
        ),
        onSelected: (action) async {
          switch (action) {
            case _DuaOverflowAction.copy:
              await Clipboard.setData(ClipboardData(text: dua.shareText));
              if (!context.mounted) return;
              final AppLocalizations localizations = AppLocalizations.of(
                context,
              )!;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(localizations.duaCopied)));
              break;
            case _DuaOverflowAction.share:
              await SharePlus.instance.share(
                ShareParams(
                  title: localizations.hisnAlMuslimDua,
                  subject: dua.categoryTitle,
                  text: dua.shareText,
                ),
              );
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<_DuaOverflowAction>>[
            PopupMenuItem<_DuaOverflowAction>(
              value: _DuaOverflowAction.copy,
              child: _OverflowMenuItem(
                icon: Icons.copy_rounded,
                label: localizations.copyText,
              ),
            ),
            PopupMenuItem<_DuaOverflowAction>(
              value: _DuaOverflowAction.share,
              child: _OverflowMenuItem(
                icon: Icons.ios_share_outlined,
                label: localizations.shareText,
              ),
            ),
          ];
        },
      ),
    );
  }
}

class _DuaMetadataPill extends StatelessWidget {
  const _DuaMetadataPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          text,
          textDirection: _looksArabic(text)
              ? TextDirection.rtl
              : TextDirection.ltr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.25,
          ),
        ),
      ),
    );
  }

  bool _looksArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }
}

class _OverflowMenuItem extends StatelessWidget {
  const _OverflowMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Icon(icon, size: 19, color: colors.onSurface.withAlpha(190)),
        const SizedBox(width: 12),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
