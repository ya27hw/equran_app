import 'package:equran/backend/library.dart';
import 'package:equran/duas/duas_category_page.dart';
import 'package:equran/duas/duas_favourites_page.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/duas/hisn_al_muslim_repository.dart';
import 'package:equran/duas/tasbih_page.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/duas/widgets/dua_browser_widgets.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';

class DuasPage extends StatefulWidget {
  DuasPage({super.key, HisnAlMuslimRepository? repository, this.now})
    : repository = repository ?? HisnAlMuslimRepository();

  final HisnAlMuslimRepository repository;
  final DateTime Function()? now;

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

            return DuaBrowserTypography(
              child: DuaSuggestionScope(
                categories: categoryIndex,
                now: widget.now,
                builder: (context, suggestion) => _DuasContent(
                  suggestion: suggestion,
                  now: widget.now,
                  categoryIndex: categoryIndex,
                  query: _query,
                  searchController: _searchController,
                  repository: widget.repository,
                  scrollController: _scrollController,
                ),
              ),
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
    required this.suggestion,
    this.now,
  });
  final List<DuaCategoryIndex> categoryIndex;
  final String query;
  final TextEditingController searchController;
  final HisnAlMuslimRepository repository;
  final ScrollController scrollController;
  final DuaSuggestion? suggestion;
  final DateTime Function()? now;

  void _openCategory(BuildContext context, DuaCategoryIndex category) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              DuasCategoryPage(categoryIndex: category, repository: repository),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.equranTokens;
    final visible = categoryIndex
        .where((c) => duaCategoryMatches(c, query, context))
        .toList();
    final total = categoryIndex.fold<int>(0, (sum, c) => sum + c.duaCount);
    final groups = DuaCategoryGroupMapper.orderedGroups;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.duas, style: duaDisplayStyle(context)),
                const SizedBox(height: 8),
                Text(
                  '${l.hisnAlMuslim} · ${l.duasCount(total)}, ${l.availableOffline.toLowerCase()}',
                  style: TextStyle(fontSize: 14, color: tokens.muted),
                ),
                const SizedBox(height: 20),
                DuaSearchField(
                  key: const Key('duas-search'),
                  controller: searchController,
                  hint: l.searchCategoryCount(categoryIndex.length),
                ),
                if (query.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  if (visible.isEmpty)
                    _DuasMessageState(
                      icon: Icons.search_off,
                      title: l.noMatchingCategories,
                      message: l.trySearchingArabicWord,
                    ),
                  for (final category in visible)
                    DuaCategoryRow(
                      key: ValueKey('dua-search-${category.id}'),
                      category: category,
                      position: category.index + 1,
                      suggestion: suggestion,
                      onTap: () => _openCategory(context, category),
                    ),
                ] else ...[
                  if (suggestion != null) ...[
                    const SizedBox(height: 20),
                    DuaSuggestionHero(
                      suggestion: suggestion!,
                      onBegin: () =>
                          _openCategory(context, suggestion!.category),
                    ),
                  ],
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<Box<dynamic>>(
                            valueListenable: DuaFavouritesDB().listener,
                            builder: (context, box, _) => _QuickTile(
                              key: const Key('duas-favourites'),
                              label: l.favouriteDuas,
                              subtitle: l.saveDuasHere,
                              count: box.length,
                              icon: 'heart',
                              filledIcon: true,
                              gold: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DuasFavouritesPage(
                                    categoryIndex: categoryIndex,
                                    repository: repository,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ValueListenableBuilder<Box<dynamic>>(
                            valueListenable: DhikrSessionsDB().listener,
                            builder: (context, box, _) {
                              final today = now?.call() ?? DateTime.now();
                              final count = box.values
                                  .whereType<DhikrSessionEntry>()
                                  .where(
                                    (s) =>
                                        s.startedAt.year == today.year &&
                                        s.startedAt.month == today.month &&
                                        s.startedAt.day == today.day,
                                  )
                                  .fold<int>(0, (sum, s) => sum + s.count);
                              return _QuickTile(
                                key: const Key('duas-tasbih'),
                                label: l.tasbihAndDhikr,
                                subtitle: l.loggedToday,
                                count: count,
                                icon: 'sparkle',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const TasbihPage(showAppBar: true),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        l.browseByTheme,
                        style: duaDisplayStyle(context, size: 24, height: 1.15),
                      ),
                      Text(
                        l.themesCount(groups.length),
                        style: TextStyle(fontSize: 13, color: tokens.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < groups.length; i += 2) ...[
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _theme(context, groups[i])),
                          if (i + 1 < groups.length) ...[
                            const SizedBox(width: 12),
                            Expanded(child: _theme(context, groups[i + 1])),
                          ],
                        ],
                      ),
                    ),
                    if (i + 2 < groups.length) const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _theme(BuildContext context, DuaGroup group) {
    final categories = categoryIndex.where((c) => c.group == group).toList();
    final l = AppLocalizations.of(context)!;
    return _DuaTile(
      key: ValueKey('dua-theme-${group.name}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DuasThemePage(
            group: group,
            categoryIndex: categoryIndex,
            repository: repository,
            now: now,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DuaGroupDisc(group: group),
          const SizedBox(height: 14),
          Text(
            duaGroupName(l, group),
            style: const TextStyle(
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            l.categoriesCount(categories.length),
            style: TextStyle(fontSize: 12.5, color: context.equranTokens.muted),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    super.key,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.icon,
    this.filledIcon = false,
    required this.onTap,
    this.gold = false,
  });
  final String label;
  final String subtitle;
  final int count;
  final String icon;
  final bool filledIcon;
  final VoidCallback onTap;
  final bool gold;
  @override
  Widget build(BuildContext context) => _DuaTile(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DesignIcon(
              icon,
              size: 22,
              filled: filledIcon,
              color: gold
                  ? context.equranTokens.gold
                  : context.equranTokens.emText,
            ),
            Flexible(child: DisplayNumeral('$count', size: 26, height: 1)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12.5, color: context.equranTokens.muted),
        ),
      ],
    ),
  );
}

class _DuaTile extends StatelessWidget {
  const _DuaTile({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: HairlineCard(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
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
