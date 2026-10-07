import 'package:equran/backend/dua_favourites_db.dart';
import 'package:equran/duas/duas_category_page.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/duas/hisn_category_translations.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/duas/widgets/dua_card.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/message_state.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DuasFavouritesPage extends StatelessWidget {
  const DuasFavouritesPage({
    super.key,
    required this.categoryIndex,
    required this.repository,
  });

  final List<DuaCategoryIndex> categoryIndex;
  final HisnAlMuslimRepository repository;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return RedesignSubpage(
      title: localizations.favouriteDuasPage,
      child: ValueListenableBuilder<Box<dynamic>>(
        valueListenable: DuaFavouritesDB().listener,
        builder: (BuildContext context, Box<dynamic> box, Widget? child) {
          return FutureBuilder<List<DuaEntry>>(
            future: _favouriteDuas(),
            builder:
                (BuildContext context, AsyncSnapshot<List<DuaEntry>> snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: context.equranTokens.emText,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return RedesignMessageState(
                      icon: const DesignIcon('info'),
                      title: localizations.favouritesUnavailable,
                      message: localizations.savedDuasNotLoaded,
                    );
                  }

                  final List<DuaEntry> favourites =
                      snapshot.data ?? const <DuaEntry>[];

                  if (favourites.isEmpty) {
                    return RedesignMessageState(
                      icon: const DesignIcon('heart'),
                      title: localizations.noFavouriteDuasYet,
                      message: localizations.tapHeartToSave,
                    );
                  }

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      EquranSpacing.pagePadding,
                      8,
                      EquranSpacing.pagePadding,
                      32,
                    ),
                    children: <Widget>[
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              for (final _FavouriteDuaGroup group
                                  in _groupByCategory(favourites)) ...<Widget>[
                                _FavouriteCategoryHeader(group: group),
                                for (final DuaEntry dua in group.duas)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: DuaCard(
                                      dua: dua,
                                      number: dua.index + 1,
                                      categoryTitle: getLocalizedCategoryTitle(
                                        context,
                                        group.categoryId,
                                        group.title,
                                      ),
                                      onTap: () =>
                                          _openCategory(context, group, dua),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
          );
        },
      ),
    );
  }

  Future<List<DuaEntry>> _favouriteDuas() async {
    final List<DuaEntry> favourites = <DuaEntry>[];

    final List<Object?> keys = DuaFavouritesDB().getKeys().toList(
      growable: false,
    );
    for (final Object? key in keys) {
      if (key is! String) continue;

      final Object? value = DuaFavouritesDB().get(key);
      DuaEntry? dua = DuaEntry.fromFavouriteSnapshot(value);
      dua ??= await repository.loadDuaById(key);
      if (dua == null) continue;

      favourites.add(dua);

      if (key != dua.id || value is! Map) {
        await DuaFavouritesDB().put(dua.id, dua.toFavouriteSnapshot());
        if (key != dua.id) {
          await DuaFavouritesDB().delete(key);
        }
      }
    }

    favourites.sort((DuaEntry a, DuaEntry b) {
      final int categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      return a.index.compareTo(b.index);
    });
    return favourites;
  }

  List<_FavouriteDuaGroup> _groupByCategory(List<DuaEntry> duas) {
    final Map<String, _FavouriteDuaGroup> groups =
        <String, _FavouriteDuaGroup>{};

    for (final DuaEntry dua in duas) {
      groups.putIfAbsent(
        dua.categoryId,
        () => _FavouriteDuaGroup(
          categoryId: dua.categoryId,
          title: dua.categoryTitle,
          duas: <DuaEntry>[],
        ),
      );
      groups[dua.categoryId]!.duas.add(dua);
    }

    return groups.values.toList(growable: false);
  }

  void _openCategory(
    BuildContext context,
    _FavouriteDuaGroup group,
    DuaEntry dua,
  ) {
    final DuaCategoryIndex? index = _categoryIndexById(group.categoryId);
    if (index == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return DuasCategoryPage(
            categoryIndex: index,
            repository: repository,
            focusDuaId: dua.id,
          );
        },
      ),
    );
  }

  DuaCategoryIndex? _categoryIndexById(String id) {
    for (final DuaCategoryIndex entry in categoryIndex) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}

class _FavouriteDuaGroup {
  _FavouriteDuaGroup({
    required this.categoryId,
    required this.title,
    required this.duas,
  });

  final String categoryId;
  final String title;
  final List<DuaEntry> duas;
}

class _FavouriteCategoryHeader extends StatelessWidget {
  const _FavouriteCategoryHeader({required this.group});

  final _FavouriteDuaGroup group;

  @override
  Widget build(BuildContext context) {
    final String title = getLocalizedCategoryTitle(
      context,
      group.categoryId,
      group.title,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 14, 4, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              textDirection: Directionality.of(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: redesignDisplayStyle(context, size: 22, height: 1.2),
            ),
          ),
          const SizedBox(width: 12),
          PillTag('${group.duas.length}', selected: true),
        ],
      ),
    );
  }
}
