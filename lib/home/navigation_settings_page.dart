import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/nav_item_icon.dart';
import 'package:equran/widgets/redesign/page_typography.dart'
    show RedesignEyebrow;
import 'package:equran/widgets/redesign/redesign_widgets.dart'
    show IconButton44, RedesignSubpage;
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:flutter/material.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/l10n/app_localizations.dart';

class NavigationSettingsPage extends StatelessWidget {
  const NavigationSettingsPage({super.key});

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
    final EquranTokens tokens = context.equranTokens;

    return RedesignSubpage(
      title: l10n.customizeNavigation,
      child: ValueListenableBuilder<NavigationState>(
        valueListenable: NavigationBloc.instance,
        builder: (context, state, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              const ReaderNotice(
                icon: DesignIcon('info'),
                text:
                    'Drag tiles to rearrange. Drag an available item and drop it on an active tile to swap, or tap an item below to pin it (displaces least recently used).',
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
                child: RedesignEyebrow(
                  'ACTIVE NAVBAR SLOTS (${state.activeNavbarItems.length}/5)',
                ),
              ),
              // Reorderable list of active slots
              Theme(
                data: Theme.of(context).copyWith(
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
                        return _NavSlotCard(
                          hovered: isHovered,
                          muted: isMore,
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              DesignIcon('dots', size: 18, color: tokens.muted),
                              const SizedBox(width: 10),
                              ReaderIconWell(
                                icon: DesignIcon(navItemDesignIcon(item)),
                              ),
                            ],
                          ),
                          title: _getModuleLabel(item, l10n),
                          subtitle: isMore
                              ? 'Slot ${index + 1} (Locked Hub)'
                              : 'Slot ${index + 1}',
                          trailing: isMore
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: tokens.muted,
                                    size: 18,
                                  ),
                                )
                              : (state.activeNavbarItems.length > 2
                                    ? IconButton44(
                                        designIcon: 'x',
                                        tooltip: l10n.remove,
                                        ghost: true,
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
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
                child: RedesignEyebrow(
                  'AVAILABLE UNPINNED ITEMS',
                  color: tokens.goldText,
                ),
              ),
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
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width - 40,
                        child: _NavSlotCard(
                          hovered: true,
                          leading: ReaderIconWell(
                            icon: DesignIcon(navItemDesignIcon(item)),
                          ),
                          title: _getModuleLabel(item, l10n),
                          subtitle: _getModuleSubtitle(item, l10n),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _NavSlotCard(
                        muted: true,
                        leading: ReaderIconWell(
                          icon: DesignIcon(navItemDesignIcon(item)),
                        ),
                        title: _getModuleLabel(item, l10n),
                        subtitle: _getModuleSubtitle(item, l10n),
                      ),
                    ),
                    child: _NavSlotCard(
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
                      leading: ReaderIconWell(
                        icon: DesignIcon(navItemDesignIcon(item)),
                      ),
                      title: _getModuleLabel(item, l10n),
                      subtitle: _getModuleSubtitle(item, l10n),
                      trailing: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DesignIcon(
                          'plus',
                          size: 20,
                          strokeWidth: 1.8,
                          color: tokens.emText,
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

/// One slot or available item: a hairline card with an icon well, a title and
/// a caption. A hovered card (a drop target) takes the emerald wash.
class _NavSlotCard extends StatelessWidget {
  const _NavSlotCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.hovered = false,
    this.muted = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool hovered;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: hovered
            ? tokens.emWash
            : muted
            ? colors.surfaceAlt
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.xl),
          side: BorderSide(color: hovered ? tokens.emText : tokens.hair),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
              child: Row(
                children: <Widget>[
                  leading,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontVariations: const [FontVariation('opsz', 15)],
                            fontWeight: FontWeight.w600,
                            color: muted ? tokens.muted : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: tokens.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
