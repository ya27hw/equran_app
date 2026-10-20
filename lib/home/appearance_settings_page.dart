import 'dart:async' show unawaited;
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:equran/backend/library.dart' show SettingsDB;
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/app_theme.dart';
import 'package:equran/widgets/prayer_widget_service.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/page_typography.dart'
    show RedesignEyebrow;
import 'package:equran/widgets/redesign/redesign_widgets.dart'
    show RedesignSubpage;
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  String _selectedScheme = AppTheme.defaultScheme;
  bool _pureBlackBackground = false;

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
        AppTheme.redScheme => AppTheme.redScheme,
        _ => AppTheme.defaultScheme,
      };
      _pureBlackBackground = SettingsDB().pureBlackBackground;
    });
  }

  Future<void> _changeScheme(String schemeId) async {
    // Save the legacy AMOLED preference before replacing its old palette ID.
    await SettingsDB().put('pureBlackBackground', _pureBlackBackground);
    await SettingsDB().put("themeScheme", schemeId);
    if (!mounted) return;
    QpcV4FontService.instance.clearCache();
    setState(() {
      _selectedScheme = schemeId;
    });

    _applyTheme();
  }

  Future<void> _changePureBlackBackground(bool enabled) async {
    await SettingsDB().put('pureBlackBackground', enabled);
    await SettingsDB().put('themeScheme', _selectedScheme);
    if (!mounted) return;
    setState(() => _pureBlackBackground = enabled);
    _applyTheme();
  }

  void _applyTheme() {
    AdaptiveTheme.of(context).setTheme(
      light: AppTheme.buildLightTheme(Colors.cyan, schemeId: _selectedScheme),
      dark: AppTheme.buildDarkTheme(
        Colors.cyan,
        schemeId: _selectedScheme,
        pureBlackBackground: _pureBlackBackground,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(PrayerWidgetService.refreshWidget(context: context));
      }
    });
  }

  String _themeModeSettingValue(AdaptiveThemeMode themeMode) {
    if (themeMode.isDark) return "dark";
    if (themeMode.isSystem) return "auto";
    return "light";
  }

  List<_AccentOption> _accents(AppLocalizations l, bool dark) =>
      <_AccentOption>[
        for (final (String id, String name, String description)
            in <(String, String, String)>[
              (
                AppTheme.defaultScheme,
                l.themeSchemeEmeraldGreen,
                l.themeSchemeEmeraldGreenSubtitle,
              ),
              (
                AppTheme.fancyBlueScheme,
                l.themeSchemeSapphireBlue,
                l.themeSchemeSapphireBlueSubtitle,
              ),
              (
                AppTheme.sepiaScheme,
                l.themeSchemeSepia,
                l.themeSchemeSepiaSubtitle,
              ),
              (
                AppTheme.fancyPurpleScheme,
                l.themeSchemeRoyalPurple,
                l.themeSchemeRoyalPurpleSubtitle,
              ),
              (
                AppTheme.redScheme,
                l.themeSchemeRubyRed,
                l.themeSchemeRubyRedSubtitle,
              ),
            ])
          _AccentOption(
            id: id,
            name: name,
            // The swatch is the scheme's own primary, so it can never drift
            // from the theme it applies.
            color: EquranColors.forScheme(id, dark).primary,
            description: description,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    final AdaptiveThemeMode currentMode = AdaptiveTheme.of(context).mode;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<_AccentOption> accents = _accents(localizations, dark);

    return RedesignSubpage(
      title: localizations.appearance,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
            child: RedesignEyebrow(localizations.themeMode),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _buildThemeModeCard(
                    mode: AdaptiveThemeMode.light,
                    title: localizations.themeModeLight,
                    icon: const DesignIcon('sun'),
                    isActive: currentMode.isLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildThemeModeCard(
                    mode: AdaptiveThemeMode.dark,
                    title: localizations.themeModeDark,
                    icon: const DesignIcon('moon'),
                    isActive: currentMode.isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildThemeModeCard(
                    mode: AdaptiveThemeMode.system,
                    title: localizations.themeModeSystem,
                    icon: const Icon(Icons.brightness_auto_rounded),
                    isActive: currentMode.isSystem,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HairlineCard(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
              child: ReaderSwitchRow(
                key: const Key('pure-black-background-toggle'),
                leading: const DesignIcon('moon'),
                title: localizations.pureBlackBackground,
                subtitle: localizations.pureBlackBackgroundSubtitle,
                value: _pureBlackBackground,
                onChanged: _changePureBlackBackground,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
            child: RedesignEyebrow(localizations.theme, color: tokens.goldText),
          ),
          for (int i = 0; i < accents.length; i += 2) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _buildAccentCard(accents[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < accents.length
                        ? _buildAccentCard(accents[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccentCard(_AccentOption accent) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final bool selected = accent.id == _selectedScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? tokens.emWash : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.xl),
          side: BorderSide(color: selected ? tokens.hair2 : tokens.hair),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _changeScheme(accent.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.hair2),
                      ),
                    ),
                    if (selected)
                      DesignIcon(
                        'check',
                        size: 20,
                        strokeWidth: 2,
                        color: tokens.emText,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  accent.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontVariations: const [FontVariation('opsz', 15)],
                    fontWeight: FontWeight.w600,
                    color: selected ? tokens.emText : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  accent.description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeModeCard({
    required AdaptiveThemeMode mode,
    required String title,
    required Widget icon,
    required bool isActive,
  }) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Semantics(
      button: true,
      selected: isActive,
      child: Material(
        color: isActive ? tokens.emWash : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.xl),
          side: BorderSide(color: isActive ? tokens.hair2 : tokens.hair),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await SettingsDB().put("themeMode", _themeModeSettingValue(mode));
            QpcV4FontService.instance.clearCache();
            if (!mounted) return;
            AdaptiveTheme.of(context).setThemeMode(mode);
            setState(() {});
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                unawaited(PrayerWidgetService.refreshWidget(context: context));
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconTheme(
                  data: IconThemeData(
                    color: isActive ? tokens.emText : tokens.text2,
                    size: 26,
                  ),
                  child: icon is DesignIcon
                      ? DesignIcon(
                          icon.name,
                          size: 26,
                          strokeWidth: 1.6,
                          color: isActive ? tokens.emText : tokens.text2,
                        )
                      : icon,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontVariations: const [FontVariation('opsz', 14.5)],
                    fontWeight: FontWeight.w600,
                    color: isActive ? tokens.emText : colors.textPrimary,
                  ),
                ),
              ],
            ),
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
