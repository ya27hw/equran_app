import 'package:equran/utils/text_direction.dart';
import 'package:equran/backend/dua_favourites_db.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
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
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
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

            return Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EquranRadii.xl),
                side: BorderSide(color: tokens.hair),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
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
                          color: colors.textPrimary,
                        ),
                      ),
                      if (showTransliteration &&
                          dua.transliteration != null) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          dua.transliteration!,
                          textDirection: scriptDirectionIn(
                            context,
                            dua.transliteration!,
                          ),
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: (translationFontSize - 2)
                                .clamp(12.0, 18.0)
                                .toDouble(),
                            color: tokens.muted,
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (showTranslation &&
                          dua.localizedTranslation(translationLang) !=
                              null) ...<Widget>[
                        const SizedBox(height: 14),
                        Divider(height: 1, thickness: 1, color: tokens.hair),
                        const SizedBox(height: 14),
                        Text(
                          dua.localizedTranslation(translationLang)!,
                          textDirection: scriptDirectionIn(
                            context,
                            dua.localizedTranslation(translationLang)!,
                          ),
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: translationFontSize,
                            color: tokens.text2,
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
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Row(
      children: <Widget>[
        if (number != null)
          PillTag('${localizations.dua} $number', selected: true),
        if (categoryTitle != null) ...<Widget>[
          if (number != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              categoryTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              textDirection: scriptDirectionIn(context, categoryTitle!),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: tokens.text2,
              ),
            ),
          ),
        ] else
          const Spacer(),
        const SizedBox(width: 10),
        _DuaFavouriteButton(dua: dua, isFavourite: isFavourite),
        const SizedBox(width: 2),
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
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Tooltip(
      message: isFavourite
          ? localizations.removeFavourite
          : localizations.favourite,
      child: SizedBox(
        height: 44,
        width: 44,
        child: Center(
          child: LikeButton(
            size: 22,
            isLiked: isFavourite,
            circleColor: CircleColor(
              start: tokens.emText.withAlpha(180),
              end: tokens.emText,
            ),
            bubblesColor: BubblesColor(
              dotPrimaryColor: tokens.emText,
              dotSecondaryColor: tokens.gold,
            ),
            likeBuilder: (bool liked) {
              return DesignIcon(
                'heart',
                filled: liked,
                color: liked ? tokens.emText : tokens.text2,
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
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return SizedBox(
      height: 44,
      width: 44,
      child: PopupMenuButton<_DuaOverflowAction>(
        tooltip: localizations.moreActions,
        position: PopupMenuPosition.under,
        padding: EdgeInsets.zero,
        color: context.equranColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
          side: BorderSide(color: tokens.hair2),
        ),
        icon: DesignIcon('dots', size: 20, color: tokens.text2),
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
                icon: 'copy',
                label: localizations.copyText,
              ),
            ),
            PopupMenuItem<_DuaOverflowAction>(
              value: _DuaOverflowAction.share,
              child: _OverflowMenuItem(
                icon: 'share',
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
    final EquranTokens tokens = context.equranTokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(color: tokens.hair),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          textDirection: _looksArabic(text)
              ? TextDirection.rtl
              : TextDirection.ltr,
          style: TextStyle(fontSize: 12, height: 1.3, color: tokens.text2),
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

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;

    return Row(
      children: <Widget>[
        DesignIcon(icon, size: 19, color: tokens.text2),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              color: context.equranColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
