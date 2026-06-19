import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/library.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:equran/duas/asma_ul_husna_page.dart';
import 'package:equran/duas/duas_page.dart';
import 'package:equran/duas/tasbih_page.dart';
import 'package:equran/home/downloads.dart';
import 'package:equran/home/main_page.dart';
import 'package:equran/home/more_page.dart';
import 'package:equran/home/quran_stats_page.dart';
import 'package:equran/home/settings.dart';
import 'package:equran/home_dashboard/home_dashboard_page.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/prayer/prayer_times_page.dart';
import 'package:equran/prayer/prayer_times_settings_page.dart';
import 'package:equran/prayer/qibla_page.dart';
import 'package:equran/reading_plans/reading_plans_page.dart';
import 'package:equran/services/frame_rate_policy_manager.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/responsive_nav.dart';
import 'package:equran/zakat/zakat_page.dart';
import 'package:equran/prayer/islamic_calendar_page.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

const String _homePointerRefreshBlocker = 'home.userPointerActive';
const String _routeTransitionRefreshBlocker = 'home.routeTransitionActive';
const String _secondaryRouteRefreshBlocker = 'home.settingsOrDownloadsActive';
const String _homePointerPolicySource = 'home_pointer';

class Destinations {
  const Destinations(
    this.label,
    this.icon,
    this.selectedIcon,
    this.destination,
  );

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final Widget destination;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<QuranSearchRequest?> _quranSearchRequest =
      ValueNotifier<QuranSearchRequest?>(null);

  void _selectTabByWidgetType<T>(Widget Function() fallbackBuilder) {
    final state = NavigationBloc.instance.value;
    final List<Destinations> destinations = _getDestinationsFromState(
      context,
      state,
    );
    final int idx = destinations.indexWhere((d) => d.destination is T);
    if (idx != -1) {
      _onItemTapped(idx);
    } else {
      final localizations = AppLocalizations.of(context)!;
      String label = '';
      bool showAppBar = true;
      if (T == MorePage) {
        label = localizations.more;
      } else if (T == MainPage) {
        label = localizations.quran;
      } else if (T == PrayerTimesPage) {
        label = localizations.prayer;
      } else if (T == DuasPage) {
        label = localizations.duas;
      } else if (T == DownloadsPage) {
        label = localizations.downloads;
      } else if (T == SettingsPage) {
        label = localizations.settings;
      } else if (T == StatisticsPage) {
        label = localizations.statistics;
      } else if (T == ReadingPlansPage) {
        label = localizations.readingRoutine;
      } else if (T == TasbihPage) {
        label = localizations.tasbih;
      } else if (T == AsmaUlHusnaPage) {
        label = localizations.asmaUlHusna;
      } else if (T == QiblaPage) {
        label = localizations.qibla;
        showAppBar = false;
      } else if (T == ZakatCalculatorPage) {
        label = 'Zakat';
      } else if (T == IslamicCalendarPage) {
        label = 'Calendar';
      }

      _pushSecondaryPage(
        label: label,
        page: fallbackBuilder(),
        reason: '${T.toString().toLowerCase()}_fallback_route',
        showAppBar: showAppBar,
      );
    }
  }

  Destinations _getDestination(BuildContext context, NavItem item) {
    final localizations = AppLocalizations.of(context)!;

    switch (item) {
      case NavItem.home:
        return Destinations(
          localizations.home,
          const Icon(Icons.home_outlined),
          const Icon(Icons.home_rounded),
          HomeDashboardPage(
            onOpenMore: () => _selectTabByWidgetType<MorePage>(
              () => MorePage(
                onOpenQibla: _openQiblaPage,
                onOpenDownloads: _openDownloadsPage,
                onOpenSearch: _openQuranTextSearch,
                onOpenReadingPlans: _openReadingPlansPage,
                onOpenTasbih: _openTasbihPage,
                onOpenAsmaUlHusna: _openAsmaUlHusnaPage,
                onOpenSettings: _openSettingsPage,
                onOpenStats: _openStatisticsPage,
                onOpenZakat: _openZakatPage,
                onOpenCalendar: _openCalendarPage,
                onToggleTheme: _toggleQuickTheme,
              ),
            ),
            onOpenQuran: () => _selectTabByWidgetType<MainPage>(
              () => MainPage(searchRequestListenable: _quranSearchRequest),
            ),
            onOpenZakat: _openZakatPage,
            onOpenPrayerTimes: () => _selectTabByWidgetType<PrayerTimesPage>(
              () => const PrayerTimesPage(),
            ),
            onOpenQibla: _openQiblaPage,
            onOpenDuas: () =>
                _selectTabByWidgetType<DuasPage>(() => DuasPage()),
            onOpenTasbih: _openTasbihPage,
            onOpenReadingPlans: _openReadingPlansPage,
            onOpenDownloads: _openDownloadsPage,
            onOpenSearch: _openQuranTextSearch,
            onOpenStats: _openStatisticsPage,
          ),
        );
      case NavItem.quran:
        return Destinations(
          localizations.quran,
          const Icon(Icons.menu_book_outlined),
          const Icon(Icons.menu_book_rounded),
          MainPage(searchRequestListenable: _quranSearchRequest),
        );
      case NavItem.prayer:
        return Destinations(
          localizations.prayer,
          const Icon(Icons.access_time_outlined),
          const Icon(Icons.schedule_rounded),
          const PrayerTimesPage(),
        );
      case NavItem.duas:
        return Destinations(
          localizations.duas,
          const Icon(Icons.auto_stories_outlined),
          const Icon(Icons.auto_stories_rounded),
          DuasPage(),
        );
      case NavItem.statistics:
        return Destinations(
          localizations.statistics,
          const Icon(Icons.bar_chart_outlined),
          const Icon(Icons.bar_chart_rounded),
          const StatisticsPage(),
        );
      case NavItem.qibla:
        return Destinations(
          localizations.qibla,
          const Icon(Icons.explore_outlined),
          const Icon(Icons.explore_rounded),
          const QiblaPage(),
        );
      case NavItem.downloads:
        return Destinations(
          localizations.downloads,
          const Icon(Icons.download_outlined),
          const Icon(Icons.download_rounded),
          const DownloadsPage(),
        );
      case NavItem.readingPlans:
        return Destinations(
          localizations.readingRoutine,
          const Icon(Icons.route_outlined),
          const Icon(Icons.route_rounded),
          const ReadingPlansPage(showAppBar: false),
        );
      case NavItem.hifz:
        return Destinations(
          localizations.hifz,
          const Icon(Icons.menu_book_rounded),
          const Icon(Icons.menu_book_rounded),
          HifzHomePage(),
        );
      case NavItem.tasbih:
        return Destinations(
          localizations.tasbih,
          const Icon(Icons.auto_awesome_outlined),
          const Icon(Icons.auto_awesome_rounded),
          const TasbihPage(showAppBar: false),
        );
      case NavItem.asmaUlHusna:
        return Destinations(
          localizations.asmaUlHusna,
          const Icon(Icons.diamond_outlined),
          const Icon(Icons.diamond_rounded),
          const AsmaUlHusnaPage(showAppBar: false),
        );
      case NavItem.settings:
        return Destinations(
          localizations.settings,
          const Icon(Icons.settings_outlined),
          const Icon(Icons.settings_rounded),
          const SettingsPage(),
        );
      case NavItem.zakat:
        return Destinations(
          'Zakat',
          const Icon(Icons.calculate_outlined),
          const Icon(Icons.calculate_rounded),
          const ZakatCalculatorPage(showAppBar: false),
        );
      case NavItem.calendar:
        return Destinations(
          'Calendar',
          const Icon(Icons.calendar_month_outlined),
          const Icon(Icons.calendar_month_rounded),
          const IslamicCalendarPage(),
        );
      case NavItem.more:
        return Destinations(
          localizations.more,
          const Icon(Icons.grid_view_outlined),
          const Icon(Icons.grid_view_rounded),
          MorePage(
            onOpenQibla: _openQiblaPage,
            onOpenDownloads: _openDownloadsPage,
            onOpenSearch: _openQuranTextSearch,
            onOpenReadingPlans: _openReadingPlansPage,
            onOpenTasbih: _openTasbihPage,
            onOpenAsmaUlHusna: _openAsmaUlHusnaPage,
            onOpenSettings: _openSettingsPage,
            onOpenStats: _openStatisticsPage,
            onOpenZakat: _openZakatPage,
            onOpenCalendar: _openCalendarPage,
            onToggleTheme: () => unawaited(_toggleQuickTheme()),
          ),
        );
    }
  }

  List<Destinations> _getDestinationsFromState(
    BuildContext context,
    NavigationState state,
  ) {
    return state.activeNavbarItems
        .map((item) => _getDestination(context, item))
        .toList();
  }

  @override
  void dispose() {
    _quranSearchRequest.dispose();
    FrameRatePolicyManager.instance.setPointerActive(
      false,
      source: _homePointerPolicySource,
      reason: 'home_disposed',
    );
    FrameRatePolicyManager.instance.setDrawerOpen(
      false,
      reason: 'home_disposed',
    );
    FrameRatePolicyManager.instance.setRouteTransitionActive(
      false,
      reason: 'home_disposed',
    );
    FrameRatePolicyManager.instance.setSettingsOrDownloadsVisible(
      false,
      reason: 'home_disposed',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double navIconSize = ResponsiveNav.iconSize(context);
    final EquranColors equranColors = context.equranColors;

    return ValueListenableBuilder<NavigationState>(
      valueListenable: NavigationBloc.instance,
      builder: (context, state, child) {
        final List<Destinations> destinations = _getDestinationsFromState(
          context,
          state,
        );
        final int selectedIdx = state.selectedIndex.clamp(
          0,
          destinations.length - 1,
        );

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _handleGlobalPointerDown(),
          onPointerUp: (_) => _handleGlobalPointerReleased(),
          onPointerCancel: (_) => _handleGlobalPointerReleased(),
          onPointerSignal: (_) => AndroidAudioDisplayMode.notifyUserActivity(),
          child: Scaffold(
            appBar:
                (destinations[selectedIdx].destination is PrayerTimesPage ||
                    destinations[selectedIdx].destination is DuasPage ||
                    destinations[selectedIdx].destination is MorePage)
                ? AppBar(
                    toolbarHeight: ResponsiveNav.toolbarHeight(context),
                    title: Text(destinations[selectedIdx].label),
                    centerTitle: true,
                    backgroundColor:
                        destinations[selectedIdx].destination is PrayerTimesPage
                        ? Colors.transparent
                        : equranColors.background,
                    foregroundColor: equranColors.textPrimary,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    titleTextStyle: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(
                          color: equranColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                    iconTheme: IconThemeData(
                      color: equranColors.textSecondary,
                      size: navIconSize,
                    ),
                    actionsIconTheme: IconThemeData(
                      color: equranColors.textSecondary,
                      size: navIconSize,
                    ),
                    actions: <Widget>[
                      if (destinations[selectedIdx].destination
                          is PrayerTimesPage) ...<Widget>[
                        IconButton(
                          tooltip: AppLocalizations.of(
                            context,
                          )!.prayerTimesSettings,
                          onPressed: _openPrayerSettingsPage,
                          icon: const Icon(Icons.settings_outlined),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: IconButton(
                            tooltip: AppLocalizations.of(context)!.qibla,
                            onPressed: _openQiblaPage,
                            icon: const Icon(Icons.explore_outlined),
                          ),
                        ),
                      ],
                    ],
                  )
                : null,
            body: destinations[selectedIdx].destination,
            bottomNavigationBar: _buildBottomNavigation(state, destinations),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(
    NavigationState state,
    List<Destinations> destinations,
  ) {
    final EquranColors colors = context.equranColors;
    final int selectedIdx = state.selectedIndex.clamp(
      0,
      destinations.length - 1,
    );

    return ColoredBox(
      color: colors.primary,
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 68,
          selectedIndex: selectedIdx,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (int index) {
            _onItemTapped(index);
          },
          destinations: destinations.map((d) {
            return NavigationDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleGlobalPointerDown() {
    FrameRatePolicyManager.instance.setPointerActive(
      true,
      source: _homePointerPolicySource,
      reason: 'home_pointer_down',
    );
    AndroidAudioDisplayMode.notifyUserActivity();
    unawaited(
      AndroidAudioDisplayMode.addLowRefreshBlocker(
        _homePointerRefreshBlocker,
        reason: 'home pointer down',
      ),
    );
  }

  void _handleGlobalPointerReleased() {
    FrameRatePolicyManager.instance.setPointerActive(
      false,
      source: _homePointerPolicySource,
      reason: 'home_pointer_released',
    );
    AndroidAudioDisplayMode.notifyUserActivity();
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        return AndroidAudioDisplayMode.removeLowRefreshBlocker(
          _homePointerRefreshBlocker,
          reason: 'home pointer settled',
        );
      }),
    );
  }

  void _openQuranTextSearch() {
    _selectTabByWidgetType<MainPage>(
      () => MainPage(searchRequestListenable: _quranSearchRequest),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quranSearchRequest.value = QuranSearchRequest(
        mode: QuranSearchMode.quranText,
        nonce: DateTime.now().microsecondsSinceEpoch,
      );
    });
  }

  void _pushSecondaryPage({
    required String label,
    required Widget page,
    required String reason,
    bool showAppBar = true,
  }) {
    FrameRatePolicyManager.instance.setRouteTransitionActive(
      true,
      reason: '${reason}_opening',
    );
    FrameRatePolicyManager.instance.setSettingsOrDownloadsVisible(
      true,
      reason: '${reason}_route',
    );
    unawaited(
      AndroidAudioDisplayMode.addLowRefreshBlocker(
        _routeTransitionRefreshBlocker,
        reason: 'opening $label',
      ),
    );
    unawaited(
      AndroidAudioDisplayMode.addLowRefreshBlocker(
        _secondaryRouteRefreshBlocker,
        reason: '$label route active',
      ),
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        FrameRatePolicyManager.instance.setRouteTransitionActive(
          false,
          reason: '${reason}_push_settled',
        );
        return AndroidAudioDisplayMode.removeLowRefreshBlocker(
          _routeTransitionRefreshBlocker,
          reason: '$label push transition settled',
        );
      }),
    );

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              final EquranColors colors = context.equranColors;
              return Scaffold(
                appBar: showAppBar
                    ? AppBar(
                        toolbarHeight: ResponsiveNav.toolbarHeight(context),
                        title: Text(label),
                        centerTitle: true,
                        backgroundColor: colors.background,
                        foregroundColor: colors.textPrimary,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        surfaceTintColor: Colors.transparent,
                        titleTextStyle: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        iconTheme: IconThemeData(
                          color: colors.textSecondary,
                          size: ResponsiveNav.iconSize(context),
                        ),
                        actionsIconTheme: IconThemeData(
                          color: colors.textSecondary,
                          size: ResponsiveNav.iconSize(context),
                        ),
                      )
                    : null,
                body: page,
              );
            },
          ),
        )
        .whenComplete(() {
          FrameRatePolicyManager.instance.setRouteTransitionActive(
            true,
            reason: '${reason}_pop_transition',
          );
          unawaited(
            AndroidAudioDisplayMode.addLowRefreshBlocker(
              _routeTransitionRefreshBlocker,
              reason: '$label pop transition',
            ),
          );
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 450), () async {
              FrameRatePolicyManager.instance.setSettingsOrDownloadsVisible(
                false,
                reason: '${reason}_route_closed',
              );
              FrameRatePolicyManager.instance.setRouteTransitionActive(
                false,
                reason: '${reason}_pop_settled',
              );
              await AndroidAudioDisplayMode.removeLowRefreshBlocker(
                _secondaryRouteRefreshBlocker,
                reason: '$label route closed',
              );
              await AndroidAudioDisplayMode.removeLowRefreshBlocker(
                _routeTransitionRefreshBlocker,
                reason: '$label pop transition settled',
              );
            }),
          );
        });
  }

  void _onItemTapped(int index) {
    FrameRatePolicyManager.instance.setSettingsOrDownloadsVisible(
      false,
      reason: 'primary_tab_visible',
    );
    NavigationBloc.instance.selectTab(index);
  }

  void _openDownloadsPage() {
    _selectTabByWidgetType<DownloadsPage>(() => const DownloadsPage());
  }

  void _openSettingsPage() {
    _selectTabByWidgetType<SettingsPage>(() => const SettingsPage());
  }

  void _openStatisticsPage() {
    _selectTabByWidgetType<StatisticsPage>(() => const StatisticsPage());
  }

  void _openReadingPlansPage() {
    _selectTabByWidgetType<ReadingPlansPage>(
      () => const ReadingPlansPage(showAppBar: false),
    );
  }

  void _openTasbihPage() {
    _selectTabByWidgetType<TasbihPage>(
      () => const TasbihPage(showAppBar: false),
    );
  }

  void _openAsmaUlHusnaPage() {
    _selectTabByWidgetType<AsmaUlHusnaPage>(
      () => const AsmaUlHusnaPage(showAppBar: false),
    );
  }

  void _openQiblaPage() {
    _selectTabByWidgetType<QiblaPage>(() => const QiblaPage());
  }

  void _openZakatPage() {
    _selectTabByWidgetType<ZakatCalculatorPage>(
      () => const ZakatCalculatorPage(showAppBar: false),
    );
  }

  void _openCalendarPage() {
    _selectTabByWidgetType<IslamicCalendarPage>(
      () => const IslamicCalendarPage(),
    );
  }

  void _openPrayerSettingsPage() {
    FrameRatePolicyManager.instance.setRouteTransitionActive(
      true,
      reason: 'prayer_settings_route_opening',
    );
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const PrayerTimesSettingsPage(),
          ),
        )
        .whenComplete(() {
          FrameRatePolicyManager.instance.setRouteTransitionActive(
            false,
            reason: 'prayer_settings_route_closed',
          );
        });
  }

  Future<void> _toggleQuickTheme() async {
    final ThemeData theme = Theme.of(context);
    final AdaptiveThemeMode mode = AdaptiveTheme.of(context).mode;
    final bool isDark = mode.isSystem
        ? theme.brightness == Brightness.dark
        : mode.isDark;
    final AdaptiveThemeMode nextMode = isDark
        ? AdaptiveThemeMode.light
        : AdaptiveThemeMode.dark;

    await SettingsDB().put('themeMode', nextMode.isDark ? 'dark' : 'light');
    if (!mounted) return;
    AdaptiveTheme.of(context).setThemeMode(nextMode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(PrayerWidgetService.refreshWidget(context: context));
      }
    });
  }
}
