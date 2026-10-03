import 'package:equran/backend/dua_favourites_db.dart';
import 'package:equran/duas/duas_category_page.dart';
import 'package:equran/duas/duas_favourites_page.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/duas/tasbih_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/widgets/common/geometric_pattern.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';

class DuasPage extends StatefulWidget {
  DuasPage({super.key, HisnAlMuslimRepository? repository})
    : repository = repository ?? HisnAlMuslimRepository();

  final HisnAlMuslimRepository repository;

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  Future<List<DuaCategoryIndex>>? _categoryIndexFuture;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCategoryIndex();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final String nextQuery = _searchController.text.trim();
    if (nextQuery == _query) return;
    setState(() {
      _query = nextQuery;
    });
  }

  void _loadCategoryIndex() {
    setState(() {
      _categoryIndexFuture = _loadCategoryIndexAfterLoadingFrame();
    });
  }

  Future<List<DuaCategoryIndex>> _loadCategoryIndexAfterLoadingFrame() async {
    await SchedulerBinding.instance.endOfFrame;
    return widget.repository.loadCategoryIndex();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final Future<List<DuaCategoryIndex>>? categoryIndexFuture =
        _categoryIndexFuture;
    if (categoryIndexFuture == null) {
      return const _DuasLoadingState();
    }

    return FutureBuilder<List<DuaCategoryIndex>>(
      future: categoryIndexFuture,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<DuaCategoryIndex>> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _DuasLoadingState();
            }

            if (snapshot.hasError) {
              return _DuasMessageState(
                icon: Icons.error_outline_rounded,
                title: localizations.duasUnavailable,
                message: localizations.hisnAlMuslimNotLoaded,
                actionLabel: localizations.retry,
                onActionPressed: _loadCategoryIndex,
              );
            }

            final List<DuaCategoryIndex> categoryIndex =
                snapshot.data ?? const <DuaCategoryIndex>[];
            if (categoryIndex.isEmpty) {
              return _DuasMessageState(
                icon: Icons.menu_book_outlined,
                title: localizations.noDuasFound,
                message: localizations.offlineHisnAlMuslimEmpty,
              );
            }

            return _DuasContent(
              categoryIndex: categoryIndex,
              query: _query,
              searchController: _searchController,
              repository: widget.repository,
              scrollController: _scrollController,
            );
          },
    );
  }
}

class _DuasContent extends StatelessWidget {
  const _DuasContent({
    required this.categoryIndex,
    required this.query,
    required this.searchController,
    required this.repository,
    required this.scrollController,
  });

  final List<DuaCategoryIndex> categoryIndex;
  final String query;
  final TextEditingController searchController;
  final HisnAlMuslimRepository repository;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ColorScheme colors = theme.colorScheme;
    final List<DuaCategoryIndex> visibleCategories = _visibleCategories(
      context,
    );
    final int duaCount = categoryIndex.fold<int>(
      0,
      (int total, DuaCategoryIndex category) => total + category.duaCount,
    );

    return RawScrollbar(
      controller: scrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(8),
      minThumbLength: 48,
      child: ListView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _DuasHero(
                    categoryCount: categoryIndex.length,
                    duaCount: duaCount,
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<Box<dynamic>>(
                    valueListenable: DuaFavouritesDB().listener,
                    builder:
                        (
                          BuildContext context,
                          Box<dynamic> box,
                          Widget? child,
                        ) {
                          return _FavouritesEntryCard(
                            count: box.length,
                            onTap: () => _openFavourites(context),
                          );
                        },
                  ),
                  const SizedBox(height: 12),
                  _TasbihEntryCard(onTap: () => _openTasbih(context)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.surfaceContainerLow,
                      hintText: localizations.searchCategories,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: localizations.clearSearch,
                              onPressed: searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    localizations.categories,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (visibleCategories.isEmpty)
                    _DuasMessageState(
                      icon: Icons.search_off_rounded,
                      title: localizations.noMatchingCategories,
                      message: localizations.trySearchingArabicWord,
                    )
                  else if (query.isEmpty)
                    _GroupedCategoriesList(
                      categoryIndex: categoryIndex,
                      repository: repository,
                      onCategoryTap: (context, category) =>
                          _openCategory(context, category),
                    )
                  else
                    for (final DuaCategoryIndex category in visibleCategories)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DuaCategoryCard(
                          category: category,
                          onTap: () => _openCategory(context, category),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DuaCategoryIndex> _visibleCategories(BuildContext context) {
    final String normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return categoryIndex;
    return categoryIndex
        .where(
          (DuaCategoryIndex category) =>
              category.matches(normalizedQuery, context),
        )
        .toList(growable: false);
  }

  void _openCategory(BuildContext context, DuaCategoryIndex category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return DuasCategoryPage(
            categoryIndex: category,
            repository: repository,
          );
        },
      ),
    );
  }

  void _openFavourites(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return DuasFavouritesPage(
            categoryIndex: categoryIndex,
            repository: repository,
          );
        },
      ),
    );
  }

  void _openTasbih(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const TasbihPage(showAppBar: true);
        },
      ),
    );
  }
}

class _DuasHero extends StatelessWidget {
  const _DuasHero({required this.categoryCount, required this.duaCount});

  final int categoryCount;
  final int duaCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large),
        gradient: colors.heroGradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primaryStrong.withAlpha(42),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GeometricPattern(
                color: colors.onPrimary,
                anchor: AlignmentDirectional.bottomEnd,
                maxOpacity: 0.18,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withAlpha(24),
                      borderRadius: BorderRadius.circular(AppRadii.medium),
                    ),
                    child: Icon(
                      Icons.auto_stories_outlined,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          localizations.hisnAlMuslim,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          localizations.arabicCategoriesDuasOffline(
                            categoryCount,
                            duaCount,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouritesEntryCard extends StatelessWidget {
  const _FavouritesEntryCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return _TappablePanel(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withAlpha(190),
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: Icon(
              count > 0
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  localizations.favouriteDuas,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? localizations.saveDuasHere
                      : localizations.savedDuasCount(
                          count,
                          count == 1
                              ? localizations.dua
                              : localizations.duasLabel,
                        ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _TasbihEntryCard extends StatelessWidget {
  const _TasbihEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return _TappablePanel(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.mint,
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: Icon(Icons.auto_awesome_outlined, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  localizations.tasbihAndDhikr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  localizations.calmCounterDailyPresets,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        ],
      ),
    );
  }
}

class _DuaCategoryCard extends StatelessWidget {
  const _DuaCategoryCard({required this.category, required this.onTap});

  final DuaCategoryIndex category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final int visualIndex = category.index % _categoryIcons.length;

    return _TappablePanel(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                _categoryAccentColors[visualIndex].withAlpha(34),
                colors.surfaceContainerHighest,
              ),
              borderRadius: BorderRadius.circular(AppRadii.medium),
              border: Border.all(
                color: _categoryAccentColors[visualIndex].withAlpha(70),
              ),
            ),
            child: Icon(
              _categoryIcons[visualIndex],
              color: _categoryAccentColors[visualIndex],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  category.localizedTitle(context),
                  textDirection: Directionality.of(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  localizations.duaCount(
                    category.duaCount,
                    category.duaCount == 1
                        ? localizations.dua
                        : localizations.duasLabel,
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _TappablePanel extends StatelessWidget {
  const _TappablePanel({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;
    final Color resolvedCardColor =
        theme.cardTheme.color ?? colors.surfaceContainerLow;

    return Card(
      elevation: isLight ? 2 : 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(
          color: isLight
              ? colors.primary.withAlpha(22)
              : colors.outlineVariant.withAlpha(82),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: resolvedCardColor,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(
                  colors.primary.withAlpha(isLight ? 8 : 14),
                  resolvedCardColor,
                ),
                Color.alphaBlend(
                  colors.tertiary.withAlpha(isLight ? 6 : 10),
                  resolvedCardColor,
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DuasLoadingState extends StatelessWidget {
  const _DuasLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 40,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _DuasMessageState extends StatelessWidget {
  const _DuasMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.large),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: colors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  if (actionLabel != null && onActionPressed != null) ...[
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onActionPressed,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupedCategoriesList extends StatefulWidget {
  const _GroupedCategoriesList({
    required this.categoryIndex,
    required this.repository,
    required this.onCategoryTap,
  });

  final List<DuaCategoryIndex> categoryIndex;
  final HisnAlMuslimRepository repository;
  final void Function(BuildContext context, DuaCategoryIndex category)
  onCategoryTap;

  @override
  State<_GroupedCategoriesList> createState() => _GroupedCategoriesListState();
}

class _GroupedCategoriesListState extends State<_GroupedCategoriesList> {
  final Set<DuaGroup> _collapsed = <DuaGroup>{};

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final Map<DuaGroup, List<DuaCategoryIndex>> grouped =
        <DuaGroup, List<DuaCategoryIndex>>{};
    for (final DuaGroup group in DuaCategoryGroupMapper.orderedGroups) {
      grouped[group] = <DuaCategoryIndex>[];
    }
    for (final DuaCategoryIndex category in widget.categoryIndex) {
      grouped[category.group]!.add(category);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final DuaGroup group in DuaCategoryGroupMapper.orderedGroups)
          if (grouped[group]!.isNotEmpty)
            _DuaGroupSection(
              group: group,
              categories: grouped[group]!,
              localizations: localizations,
              isCollapsed: _collapsed.contains(group),
              onToggle: () {
                setState(() {
                  if (_collapsed.contains(group)) {
                    _collapsed.remove(group);
                  } else {
                    _collapsed.add(group);
                  }
                });
              },
              onCategoryTap: widget.onCategoryTap,
            ),
      ],
    );
  }
}

class _DuaGroupSection extends StatelessWidget {
  const _DuaGroupSection({
    required this.group,
    required this.categories,
    required this.localizations,
    required this.isCollapsed,
    required this.onToggle,
    required this.onCategoryTap,
  });

  final DuaGroup group;
  final List<DuaCategoryIndex> categories;
  final AppLocalizations localizations;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final void Function(BuildContext context, DuaCategoryIndex category)
  onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color accentColor) = _groupIconAndColor(group);
    final String groupName = _groupName(localizations, group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        _GroupHeader(
          groupName: groupName,
          categoryCount: categories.length,
          icon: icon,
          accentColor: accentColor,
          isCollapsed: isCollapsed,
          onToggle: onToggle,
        ),
        if (!isCollapsed) ...[
          const SizedBox(height: 10),
          for (final DuaCategoryIndex category in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GroupedCategoryCard(
                category: category,
                icon: icon,
                accentColor: accentColor,
                localizations: localizations,
                onTap: () => onCategoryTap(context, category),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  static (IconData, Color) _groupIconAndColor(DuaGroup group) {
    switch (group) {
      case DuaGroup.dailyAthkar:
        return (Icons.wb_sunny_outlined, const Color(0xFF00A6A6));
      case DuaGroup.prayer:
        return (Icons.front_hand_outlined, const Color(0xFF7C6ADE));
      case DuaGroup.hajjUmrah:
        return (Icons.travel_explore_outlined, const Color(0xFFD08700));
      case DuaGroup.travel:
        return (Icons.flight_outlined, const Color(0xFF2E8B57));
      case DuaGroup.protectionHardship:
        return (Icons.shield_outlined, const Color(0xFF4A8FE7));
      case DuaGroup.healthIllness:
        return (Icons.favorite_outline, const Color(0xFFC6538C));
      case DuaGroup.deathFunerals:
        return (Icons.coffee_outlined, const Color(0xFF505050));
      case DuaGroup.repentance:
        return (Icons.refresh_outlined, const Color(0xFF00A6A6));
      case DuaGroup.natureWeather:
        return (Icons.cloud_outlined, const Color(0xFF4A8FE7));
      case DuaGroup.marriageFamily:
        return (Icons.family_restroom_outlined, const Color(0xFFD08700));
      case DuaGroup.remembrancePraise:
        return (Icons.record_voice_over_outlined, const Color(0xFF7C6ADE));
      case DuaGroup.socialEtiquette:
        return (Icons.emoji_people_outlined, const Color(0xFF2E8B57));
      case DuaGroup.misc:
        return (Icons.more_horiz_outlined, const Color(0xFF505050));
    }
  }

  static String _groupName(AppLocalizations l, DuaGroup group) {
    switch (group) {
      case DuaGroup.dailyAthkar:
        return l.duaGroupDailyAthkar;
      case DuaGroup.prayer:
        return l.duaGroupPrayer;
      case DuaGroup.hajjUmrah:
        return l.duaGroupHajjUmrah;
      case DuaGroup.travel:
        return l.duaGroupTravel;
      case DuaGroup.protectionHardship:
        return l.duaGroupProtectionHardship;
      case DuaGroup.healthIllness:
        return l.duaGroupHealthIllness;
      case DuaGroup.deathFunerals:
        return l.duaGroupDeathFunerals;
      case DuaGroup.repentance:
        return l.duaGroupRepentance;
      case DuaGroup.natureWeather:
        return l.duaGroupNatureWeather;
      case DuaGroup.marriageFamily:
        return l.duaGroupMarriageFamily;
      case DuaGroup.remembrancePraise:
        return l.duaGroupRemembrancePraise;
      case DuaGroup.socialEtiquette:
        return l.duaGroupSocialEtiquette;
      case DuaGroup.misc:
        return l.duaGroupMisc;
    }
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.groupName,
    required this.categoryCount,
    required this.icon,
    required this.accentColor,
    required this.isCollapsed,
    required this.onToggle,
  });

  final String groupName;
  final int categoryCount;
  final IconData icon;
  final Color accentColor;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(26),
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                groupName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              '$categoryCount',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              isCollapsed
                  ? Icons.expand_more_rounded
                  : Icons.expand_less_rounded,
              size: 22,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedCategoryCard extends StatelessWidget {
  const _GroupedCategoryCard({
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.localizations,
    required this.onTap,
  });

  final DuaCategoryIndex category;
  final IconData icon;
  final Color accentColor;
  final AppLocalizations localizations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return _TappablePanel(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accentColor.withAlpha(34),
                colors.surfaceContainerHighest,
              ),
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.localizedTitle(context),
              textDirection: Directionality.of(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            localizations.duaCount(
              category.duaCount,
              category.duaCount == 1
                  ? localizations.dua
                  : localizations.duasLabel,
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

const List<IconData> _categoryIcons = <IconData>[
  Icons.wb_sunny_outlined,
  Icons.nights_stay_outlined,
  Icons.home_outlined,
  Icons.local_florist_outlined,
  Icons.shield_outlined,
  Icons.volunteer_activism_outlined,
];

const List<Color> _categoryAccentColors = <Color>[
  Color(0xFF00A6A6),
  Color(0xFF7C6ADE),
  Color(0xFFD08700),
  Color(0xFF2E8B57),
  Color(0xFF4A8FE7),
  Color(0xFFC6538C),
];
