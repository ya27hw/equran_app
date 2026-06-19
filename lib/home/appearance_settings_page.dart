import 'dart:async' show unawaited;
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/library.dart' show SettingsDB;
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final List<_AccentOption> _accents = [
    _AccentOption(
      id: AppTheme.defaultScheme,
      name: 'Emerald Green',
      color: const Color(0xFF1E7A61),
      description: 'Classic emerald representation',
    ),
    _AccentOption(
      id: AppTheme.fancyBlueScheme,
      name: 'Sapphire Blue',
      color: const Color(0xFF3B8DD6),
      description: 'Premium sapphire aesthetics',
    ),
    _AccentOption(
      id: AppTheme.sepiaScheme,
      name: 'Premium Golden',
      color: const Color(0xFFC08A4C),
      description: 'Rich warm traditional tones',
    ),
    _AccentOption(
      id: AppTheme.fancyPurpleScheme,
      name: 'Royal Purple',
      color: const Color(0xFF9368D0),
      description: 'Elegant regal representation',
    ),
    _AccentOption(
      id: AppTheme.redScheme,
      name: 'Ruby Red',
      color: const Color(0xFFC8475D),
      description: 'Vibrant and modern styling',
    ),
    _AccentOption(
      id: AppTheme.blackScheme,
      name: 'AMOLED',
      color: const Color(0xFF18A28D),
      description: 'Ultra dark high-contrast cyan',
    ),
  ];

  String _selectedScheme = AppTheme.defaultScheme;

  @override
  void initState() {
    super.initState();
    _loadScheme();
  }

  void _loadScheme() {
    final dynamic saved = SettingsDB().get("themeScheme");
    setState(() {
      _selectedScheme = switch (saved) {
        AppTheme.fancyBlueScheme => AppTheme.fancyBlueScheme,
        AppTheme.fancyPurpleScheme => AppTheme.fancyPurpleScheme,
        AppTheme.sepiaScheme => AppTheme.sepiaScheme,
        AppTheme.blackScheme => AppTheme.blackScheme,
        AppTheme.redScheme => AppTheme.redScheme,
        _ => AppTheme.defaultScheme,
      };
    });
  }

  Future<void> _changeScheme(String schemeId) async {
    await SettingsDB().put("themeScheme", schemeId);
    setState(() {
      _selectedScheme = schemeId;
    });

    if (mounted) {
      AdaptiveTheme.of(context).setTheme(
        light: AppTheme.buildLightTheme(Colors.cyan, schemeId: schemeId),
        dark: AppTheme.buildDarkTheme(Colors.cyan, schemeId: schemeId),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(PrayerWidgetService.refreshWidget(context: context));
        }
      });
    }
  }

  String _themeModeSettingValue(AdaptiveThemeMode themeMode) {
    if (themeMode.isDark) return "dark";
    if (themeMode.isSystem) return "auto";
    return "light";
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AdaptiveThemeMode currentMode = AdaptiveTheme.of(context).mode;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.appearance), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: <Widget>[
          // Section: Theme Mode
          Text(
            'THEME MODE',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: <Widget>[
              Expanded(
                child: _buildThemeModeCard(
                  context: context,
                  mode: AdaptiveThemeMode.light,
                  title: 'Light',
                  icon: Icons.light_mode_rounded,
                  isActive: currentMode.isLight,
                  colors: colors,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeModeCard(
                  context: context,
                  mode: AdaptiveThemeMode.dark,
                  title: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isActive: currentMode.isDark,
                  colors: colors,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeModeCard(
                  context: context,
                  mode: AdaptiveThemeMode.system,
                  title: 'Auto',
                  icon: Icons.brightness_auto_rounded,
                  isActive: currentMode.isSystem,
                  colors: colors,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Section: Custom Accent Color Palettes
          Text(
            'ACCENT COLOR PALETTES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.32,
            ),
            itemCount: _accents.length,
            itemBuilder: (context, index) {
              final accent = _accents[index];
              final bool isSelected = accent.id == _selectedScheme;

              return Card(
                margin: EdgeInsets.zero,
                color: isSelected
                    ? colors.primary.withAlpha(14)
                    : colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.border,
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: InkWell(
                  onTap: () => _changeScheme(accent.id),
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: accent.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.border),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          accent.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          accent.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeCard({
    required BuildContext context,
    required AdaptiveThemeMode mode,
    required String title,
    required IconData icon,
    required bool isActive,
    required EquranColors colors,
    required ThemeData theme,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: isActive ? colors.primary.withAlpha(14) : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(
          color: isActive ? colors.primary : colors.border,
          width: isActive ? 1.6 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () async {
          await SettingsDB().put("themeMode", _themeModeSettingValue(mode));
          if (context.mounted) {
            AdaptiveTheme.of(context).setThemeMode(mode);
            setState(() {});
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                unawaited(PrayerWidgetService.refreshWidget(context: context));
              }
            });
          }
        },
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                color: isActive ? colors.primary : colors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isActive ? colors.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentOption {
  const _AccentOption({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
  });

  final String id;
  final String name;
  final Color color;
  final String description;
}
