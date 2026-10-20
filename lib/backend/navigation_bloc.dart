import 'package:flutter/material.dart';
import 'package:equran/backend/library.dart' show SettingsDB;

enum NavItem {
  home,
  quran,
  prayer,
  duas,
  statistics,
  qibla,
  downloads,
  readingPlans,
  hifz,
  tasbih,
  asmaUlHusna,
  settings,
  zakat,
  calendar,
  more,
}

class NavigationState {
  const NavigationState({
    required this.activeNavbarItems,
    required this.availableMoreItems,
    required this.selectedIndex,
  });

  final List<NavItem> activeNavbarItems;
  final List<NavItem> availableMoreItems;
  final int selectedIndex;

  NavigationState copyWith({
    List<NavItem>? activeNavbarItems,
    List<NavItem>? availableMoreItems,
    int? selectedIndex,
  }) {
    return NavigationState(
      activeNavbarItems: activeNavbarItems ?? this.activeNavbarItems,
      availableMoreItems: availableMoreItems ?? this.availableMoreItems,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

class NavigationBloc extends ValueNotifier<NavigationState> {
  NavigationBloc._() : super(_initialState()) {
    _loadUsageHistory();
  }

  static final NavigationBloc instance = NavigationBloc._();

  // LRU Queue tracking usage order of active items.
  final List<NavItem> _usageHistory = <NavItem>[];

  List<NavItem> get usageHistory => List<NavItem>.unmodifiable(_usageHistory);

  static NavigationState _initialState() {
    final SettingsDB settings = SettingsDB();
    final dynamic savedActive = settings.get("navigation_active_items");
    final dynamic savedAvailable = settings.get("navigation_available_items");

    List<NavItem> active = <NavItem>[];
    List<NavItem> available = <NavItem>[];

    if (savedActive is List) {
      active = savedActive
          .map((dynamic e) => _parseNavItem(e.toString()))
          .toList();
    }

    if (savedAvailable is List) {
      available = savedAvailable
          .map((dynamic e) => _parseNavItem(e.toString()))
          .toList();
    }

    // Default configuration if cache is empty or invalid
    if (active.length < 2 ||
        active.length > 5 ||
        !active.contains(NavItem.more)) {
      active = <NavItem>[
        NavItem.home,
        NavItem.quran,
        NavItem.prayer,
        NavItem.duas,
        NavItem.more,
      ];
      // Available items are the remaining ones
      available = NavItem.values
          .where((NavItem e) => !active.contains(e))
          .toList();
    }

    return NavigationState(
      activeNavbarItems: active,
      availableMoreItems: available,
      selectedIndex: 0,
    );
  }

  static NavItem _parseNavItem(String name) {
    return NavItem.values.firstWhere(
      (e) => e.name == name,
      orElse: () => NavItem.home,
    );
  }

  void _loadUsageHistory() {
    _usageHistory.clear();
    // Initialize history with current active items, home being the most recently used
    _usageHistory.addAll(value.activeNavbarItems);
    // Bring home and quran to the end (most recently used)
    _recordUsage(NavItem.more);
    _recordUsage(NavItem.home);
  }

  void _recordUsage(NavItem item) {
    if (value.activeNavbarItems.contains(item)) {
      _usageHistory.remove(item);
      _usageHistory.add(item);
    }
  }

  // --- EVENTS ---

  /// Sets the active index and records usage of the selected tab
  void selectTab(int index) {
    if (index < 0 || index >= value.activeNavbarItems.length) return;
    final NavItem item = value.activeNavbarItems[index];
    _recordUsage(item);
    value = value.copyWith(selectedIndex: index);
  }

  Future<void> reorderActiveItems(int oldIndex, int newIndex) async {
    final List<NavItem> items = List<NavItem>.from(value.activeNavbarItems);
    final NavItem item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Validate active items constraints before mutation
    if (items.length >= 2 &&
        items.length <= 5 &&
        items.contains(NavItem.more)) {
      // Find the index of the previously selected item to adjust the selectedIndex
      final NavItem selectedItem = value.activeNavbarItems[value.selectedIndex];
      final int newSelectedIdx = items
          .indexOf(selectedItem)
          .clamp(0, items.length - 1);

      value = value.copyWith(
        activeNavbarItems: items,
        selectedIndex: newSelectedIdx,
      );
      await _persistState();
    }
  }

  /// Promotes an item from availableMoreItems to activeNavbarItems.
  /// If navbar is full (length == 5), it displaces the least recently used unlocked item.
  Future<void> promoteToActive(NavItem item, {int? targetIndex}) async {
    if (!value.availableMoreItems.contains(item)) return;

    final List<NavItem> active = List<NavItem>.from(value.activeNavbarItems);
    final List<NavItem> available = List<NavItem>.from(
      value.availableMoreItems,
    );

    if (active.length < 5) {
      if (targetIndex != null &&
          targetIndex >= 0 &&
          targetIndex <= active.length) {
        active.insert(targetIndex, item);
      } else {
        active.add(item);
      }
      available.remove(item);
      _usageHistory.remove(item);
      _usageHistory.add(item);

      final NavItem currentSelected =
          value.activeNavbarItems[value.selectedIndex.clamp(
            0,
            value.activeNavbarItems.length - 1,
          )];
      int newSelectedIdx = active.indexOf(currentSelected);
      if (newSelectedIdx == -1) {
        newSelectedIdx = active.length - 1;
      }

      value = value.copyWith(
        activeNavbarItems: active,
        availableMoreItems: available,
        selectedIndex: newSelectedIdx.clamp(0, active.length - 1),
      );
      await _persistState();
      return;
    }

    // Find candidate to displace: least recently used in active items that is NOT NavItem.more
    NavItem? displaceCandidate;
    for (final NavItem historic in _usageHistory) {
      if (historic != NavItem.more && active.contains(historic)) {
        displaceCandidate = historic;
        break;
      }
    }

    // Fallback: first item that is not 'more'
    displaceCandidate ??= active.firstWhere((e) => e != NavItem.more);

    final int replaceIdx = targetIndex ?? active.indexOf(displaceCandidate);

    if (replaceIdx != -1 && replaceIdx < active.length) {
      final NavItem replacedItem = active[replaceIdx];
      if (replacedItem == NavItem.more) {
        // Cannot displace 'more' tab
        return;
      }

      // Perform swap
      active[replaceIdx] = item;
      available.remove(item);
      available.add(replacedItem);

      // Maintain selection index or adjust it if the currently selected item was displaced
      final NavItem currentSelected =
          value.activeNavbarItems[value.selectedIndex.clamp(
            0,
            value.activeNavbarItems.length - 1,
          )];
      int newSelectedIdx = active.indexOf(currentSelected);
      if (newSelectedIdx == -1) {
        newSelectedIdx = replaceIdx; // default to the new active item
      }

      _usageHistory.remove(replacedItem);
      _usageHistory.remove(item);
      _usageHistory.add(item);

      value = value.copyWith(
        activeNavbarItems: active,
        availableMoreItems: available,
        selectedIndex: newSelectedIdx.clamp(0, active.length - 1),
      );
      await _persistState();
    }
  }

  /// Swaps an active item at a specific index with an available item
  Future<void> swapItems(NavItem activeItem, NavItem availableItem) async {
    if (!value.activeNavbarItems.contains(activeItem) ||
        activeItem == NavItem.more) {
      return;
    }
    if (!value.availableMoreItems.contains(availableItem)) return;

    final List<NavItem> active = List<NavItem>.from(value.activeNavbarItems);
    final List<NavItem> available = List<NavItem>.from(
      value.availableMoreItems,
    );

    final int idx = active.indexOf(activeItem);
    if (idx != -1) {
      active[idx] = availableItem;
      available.remove(availableItem);
      available.add(activeItem);

      _usageHistory.remove(activeItem);
      _usageHistory.remove(availableItem);
      _usageHistory.add(availableItem);

      final NavItem currentSelected =
          value.activeNavbarItems[value.selectedIndex.clamp(
            0,
            value.activeNavbarItems.length - 1,
          )];
      int newSelectedIdx = active.indexOf(currentSelected);
      if (newSelectedIdx == -1) {
        newSelectedIdx = idx;
      }

      value = value.copyWith(
        activeNavbarItems: active,
        availableMoreItems: available,
        selectedIndex: newSelectedIdx.clamp(0, active.length - 1),
      );
      await _persistState();
    }
  }

  /// Demotes an active item back to the available pool, reducing the active navbar
  /// length directly (down to a minimum of 2 items) without replacing it.
  Future<void> demoteToAvailable(NavItem item) async {
    if (!value.activeNavbarItems.contains(item) || item == NavItem.more) return;
    final List<NavItem> active = List<NavItem>.from(value.activeNavbarItems);
    if (active.length <= 2) return; // Cannot demote below 2 slots

    final List<NavItem> available = List<NavItem>.from(
      value.availableMoreItems,
    );

    active.remove(item);
    available.add(item);

    _usageHistory.remove(item);

    final NavItem currentSelected =
        value.activeNavbarItems[value.selectedIndex.clamp(
          0,
          value.activeNavbarItems.length - 1,
        )];
    int newSelectedIdx = active.indexOf(currentSelected);
    if (newSelectedIdx == -1) {
      newSelectedIdx = active.length - 1;
    }

    value = value.copyWith(
      activeNavbarItems: active,
      availableMoreItems: available,
      selectedIndex: newSelectedIdx.clamp(0, active.length - 1),
    );
    await _persistState();
  }

  /// Helper validation before saving to persistent storage
  bool _validateState(List<NavItem> active) {
    return active.length >= 2 &&
        active.length <= 5 &&
        active.contains(NavItem.more);
  }

  Future<void> _persistState() async {
    if (_validateState(value.activeNavbarItems)) {
      final SettingsDB settings = SettingsDB();
      final List<String> activeKeys = value.activeNavbarItems
          .map((e) => e.name)
          .toList();
      final List<String> availableKeys = value.availableMoreItems
          .map((e) => e.name)
          .toList();
      await settings.put("navigation_active_items", activeKeys);
      await settings.put("navigation_available_items", availableKeys);
    }
  }
}
