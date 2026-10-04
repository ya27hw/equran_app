import 'package:equran/widgets/redesign/redesign_widgets.dart'
    show RedesignSubpage;
import 'package:flutter/material.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/l10n/app_localizations.dart';

class NavigationSettingsPage extends StatelessWidget {
  const NavigationSettingsPage({super.key});

  IconData _getModuleIcon(NavItem item) {
    return switch (item) {
      NavItem.home => Icons.home_rounded,
      NavItem.quran => Icons.menu_book_rounded,
      NavItem.prayer => Icons.schedule_rounded,
      NavItem.duas => Icons.auto_stories_rounded,
      NavItem.statistics => Icons.bar_chart_rounded,
      NavItem.qibla => Icons.explore_rounded,
      NavItem.downloads => Icons.download_rounded,
      NavItem.readingPlans => Icons.route_rounded,
      NavItem.hifz => Icons.bookmark_added_rounded,
      NavItem.tasbih => Icons.auto_awesome_rounded,
      NavItem.asmaUlHusna => Icons.diamond_rounded,
      NavItem.settings => Icons.settings_rounded,
      NavItem.zakat => Icons.calculate_rounded,
      NavItem.calendar => Icons.calendar_month_rounded,
      NavItem.more => Icons.grid_view_rounded,
    };
  }

  String _getModuleLabel(NavItem item, AppLocalizations l10n) {
    return switch (item) {
      NavItem.home => l10n.home,
      NavItem.quran => l10n.quran,
      NavItem.prayer => l10n.prayer,
      NavItem.duas => l10n.duas,
      NavItem.statistics => l10n.statistics,
      NavItem.qibla => l10n.qibla,
      NavItem.downloads => l10n.downloads,
      NavItem.readingPlans => l10n.readingRoutine,
      NavItem.hifz => l10n.hifz,
      NavItem.tasbih => l10n.tasbih,
      NavItem.asmaUlHusna => l10n.asmaUlHusna,
      NavItem.settings => l10n.settings,
      NavItem.zakat => l10n.zakatCalculator,
      NavItem.calendar => l10n.islamicCalendar,
      NavItem.more => l10n.more,
    };
  }

  String _getModuleSubtitle(NavItem item, AppLocalizations l10n) {
    return switch (item) {
      NavItem.home => 'Main Dashboard',
      NavItem.quran => 'Read the Holy Quran',
      NavItem.prayer => 'Prayer Times & Adhan',
      NavItem.duas => 'Dua & Supplications',
      NavItem.statistics => 'Streaks & Worship Trends',
      NavItem.qibla => 'Qibla Direction Compass',
      NavItem.downloads => 'Offline Audio Cache Files',
      NavItem.readingPlans => 'Reading Plans & Routines',
      NavItem.hifz => 'Hifz Memorization Tasks',
      NavItem.tasbih => 'Calm Dhikr Counter',
      NavItem.asmaUlHusna => '99 Beautiful Names',
      NavItem.settings => 'System Preferences',
      NavItem.zakat => 'Advanced Nisab Calculator',
      NavItem.calendar => 'Synchronized Hijri Timeline',
      NavItem.more => 'Immutable Hub Platform',
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return RedesignSubpage(
      title: l10n.customizeNavigation,
      child: ValueListenableBuilder<NavigationState>(
        valueListenable: NavigationBloc.instance,
        builder: (context, state, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              // Header Card Info
              Card(
                color: colors.primary.withAlpha(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  side: BorderSide(color: colors.primary.withAlpha(32)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline_rounded,
                        color: colors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used).',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Active Items Header
              Text(
                'ACTIVE NAVBAR SLOTS (${state.activeNavbarItems.length}/5)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              // Reorderable list of active slots
              Theme(
                data: theme.copyWith(
                  canvasColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.activeNavbarItems.length,
                  onReorderItem: (oldIndex, newIndex) => NavigationBloc.instance
                      .reorderActiveItems(oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final NavItem item = state.activeNavbarItems[index];
                    final bool isMore = item == NavItem.more;

                    // Wrap each active slot in a DragTarget to support explicit swap drop gestures
                    return DragTarget<NavItem>(
                      key: ValueKey<String>('target_${item.name}'),
                      onWillAcceptWithDetails: (details) =>
                          details.data != item && !isMore,
                      onAcceptWithDetails: (details) {
                        final incoming = details.data;
                        NavigationBloc.instance.swapItems(item, incoming);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Swapped ${_getModuleLabel(item, l10n)} with ${_getModuleLabel(incoming, l10n)}',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final bool isHovered = candidateData.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: isHovered
                              ? colors.primary.withAlpha(20)
                              : (isMore ? colors.surfaceSoft : colors.surface),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadii.medium,
                            ),
                            side: BorderSide(
                              color: isHovered
                                  ? colors.primary
                                  : (isMore
                                        ? colors.border.withAlpha(120)
                                        : colors.border),
                              width: isHovered ? 1.8 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.drag_handle_rounded,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _getModuleIcon(item),
                                  color: isMore
                                      ? colors.textMuted
                                      : colors.primary,
                                ),
                              ],
                            ),
                            title: Text(
                              _getModuleLabel(item, l10n),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isMore
                                    ? colors.textMuted
                                    : colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              isMore
                                  ? 'Slot ${index + 1} (Locked Hub)'
                                  : 'Slot ${index + 1}',
                              style: isMore
                                  ? TextStyle(color: colors.textMuted)
                                  : null,
                            ),
                            trailing: isMore
                                ? Icon(
                                    Icons.lock_rounded,
                                    color: colors.textMuted,
                                    size: 18,
                                  )
                                : (state.activeNavbarItems.length > 2
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            NavigationBloc.instance
                                                .demoteToAvailable(item);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Removed ${_getModuleLabel(item, l10n)} from navbar',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : null),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Available Items Header
              Text(
                'AVAILABLE UNPINNED ITEMS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              // Grid/List of available items
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.availableMoreItems.length,
                itemBuilder: (context, index) {
                  final NavItem item = state.availableMoreItems[index];

                  // Wrap each available item in a Draggable to support swap gestures
                  return Draggable<NavItem>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: MediaQuery.sizeOf(context).width - 32,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface.withAlpha(220),
                          borderRadius: BorderRadius.circular(AppRadii.medium),
                          border: Border.all(color: colors.primary),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withAlpha(20),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(_getModuleIcon(item), color: colors.primary),
                            const SizedBox(width: 12),
                            Text(
                              _getModuleLabel(item, l10n),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: colors.surfaceSoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.medium),
                          side: BorderSide(color: colors.border),
                        ),
                        child: ListTile(
                          leading: Icon(
                            _getModuleIcon(item),
                            color: colors.textMuted,
                          ),
                          title: Text(
                            _getModuleLabel(item, l10n),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.textMuted,
                            ),
                          ),
                          subtitle: Text(_getModuleSubtitle(item, l10n)),
                        ),
                      ),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                        side: BorderSide(color: colors.border),
                      ),
                      child: ListTile(
                        onTap: () {
                          final List<NavItem> active = state.activeNavbarItems;
                          final bool willDisplace = active.length == 5;

                          NavItem? displaceCandidate;
                          if (willDisplace) {
                            for (final NavItem historic
                                in NavigationBloc.instance.usageHistory) {
                              if (historic != NavItem.more &&
                                  active.contains(historic)) {
                                displaceCandidate = historic;
                                break;
                              }
                            }
                            displaceCandidate ??= active.firstWhere(
                              (e) => e != NavItem.more,
                            );
                          }

                          NavigationBloc.instance.promoteToActive(item);

                          final String message = willDisplace
                              ? 'Pinned ${_getModuleLabel(item, l10n)} (displaced ${_getModuleLabel(displaceCandidate!, l10n)})'
                              : 'Pinned ${_getModuleLabel(item, l10n)}';

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withAlpha(12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getModuleIcon(item),
                            color: colors.primary,
                          ),
                        ),
                        title: Text(
                          _getModuleLabel(item, l10n),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(_getModuleSubtitle(item, l10n)),
                        trailing: Icon(
                          Icons.add_circle_outline_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
