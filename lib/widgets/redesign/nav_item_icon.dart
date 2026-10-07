import 'package:equran/backend/library.dart' show NavItem;

/// The [DesignIcon] name for a navigation destination, shared by the dock and
/// the Navigation settings page.
String navItemDesignIcon(NavItem item) => switch (item) {
  NavItem.home => 'home',
  NavItem.quran => 'quran',
  NavItem.prayer => 'clock',
  NavItem.duas => 'arch',
  NavItem.more => 'grid',
  NavItem.statistics => 'trophy',
  NavItem.qibla => 'compass',
  NavItem.downloads => 'folder',
  NavItem.readingPlans => 'calendar',
  NavItem.hifz => 'book',
  NavItem.tasbih => 'dotsgrid',
  NavItem.asmaUlHusna => 'sparkle',
  NavItem.settings => 'sliders',
  NavItem.zakat => 'grid',
  NavItem.calendar => 'calendar',
};
