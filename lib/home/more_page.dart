import 'package:equran/backend/library.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equran/hifz/hifz.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String _appDownloadUrl =
    'https://f-droid.org/en/packages/com.app.equran/';
const String _issueReportUrl = 'https://github.com/ya27hw/equran_app/issues';
const String _contactEmail = 'equran@elbaesy.com';
const String _appAssetBase = 'assets/media/images/app';
const String _qiblaAsset = '$_appAssetBase/qiblah.webp';
const String _downloadAsset = '$_appAssetBase/download.webp';
const String _quranAsset = '$_appAssetBase/quran.webp';
const String _routineAsset = '$_appAssetBase/routine.webp';
const String _tasbihAsset = '$_appAssetBase/tasbih.webp';
const String _duaAsset = '$_appAssetBase/dua.webp';
const String _lastReadAsset = '$_appAssetBase/last_read.webp';
const String _settingsAsset = '$_appAssetBase/settings.webp';
const String _zakatAsset = '$_appAssetBase/zakat.webp';
// const String _designAsset = '$_appAssetBase/design.webp';
const String _appIconAsset = 'assets/media/images/icon.webp';
const String _themeAsset = '$_appAssetBase/theme_mode.webp';
const String _hifzAsset = '$_appAssetBase/hifz.webp';
const String _shareAppAsset = '$_appAssetBase/share_app.webp';
const String _feedbackAsset = '$_appAssetBase/feedback.webp';
const String _bitcoinDonationAddress =
    'bc1qs7jfrkxvpdh96qmfu9srtla38fe30gvdvc22av';
const String _ethereumDonationAddress =
    '0x9d60158D5315Fa46241FC47Bf76eEE6cF7abcAa9';
const String _solanaDonationAddress =
    'Gyy1Ar1Lu5zbyW9WEcisKkcGxBb4GPuUQEJvcQ4oV9va';
const String _usdcDonationAddress =
    '0x9d60158D5315Fa46241FC47Bf76eEE6cF7abcAa9';
const String _litecoinDonationAddress = 'LZW5Jh52Lnni6Zr3FQhimGGkyZPywSAaDX';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.onOpenQibla,
    required this.onOpenDownloads,
    required this.onOpenSearch,
    required this.onOpenReadingPlans,
    required this.onOpenTasbih,
    required this.onOpenAsmaUlHusna,
    required this.onOpenSettings,
    required this.onOpenStats,
    required this.onOpenZakat,
    required this.onOpenCalendar,
    required this.onToggleTheme,
  });

  final VoidCallback onOpenQibla;
  final VoidCallback onOpenDownloads;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenReadingPlans;
  final VoidCallback onOpenTasbih;
  final VoidCallback onOpenAsmaUlHusna;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenZakat;
  final VoidCallback onOpenCalendar;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;

    return ColoredBox(
      color: colors.background,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          EquranSpacing.pagePadding,
          16,
          EquranSpacing.pagePadding,
          32,
        ),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _MoreHero(onOpenReadingPlans: onOpenReadingPlans),
                  const SizedBox(height: 18),
                  _MoreShortcutsGrid(
                    items: <_MoreAction>[
                      _MoreAction(
                        icon: Icons.explore_outlined,
                        assetPath: _qiblaAsset,
                        title: localizations.qibla,
                        subtitle: localizations.compassAndDirection,
                        onTap: onOpenQibla,
                      ),
                      _MoreAction(
                        icon: Icons.download_outlined,
                        assetPath: _downloadAsset,
                        title: localizations.downloads,
                        subtitle: localizations.offlineAudioAndCleanup,
                        onTap: onOpenDownloads,
                      ),
                      _MoreAction(
                        icon: Icons.travel_explore_rounded,
                        assetPath: _quranAsset,
                        title: localizations.quranSearch,
                        subtitle: localizations.searchArabicAndTranslation,
                        onTap: onOpenSearch,
                      ),
                      _MoreAction(
                        icon: Icons.route_outlined,
                        assetPath: _routineAsset,
                        title: localizations.readingRoutine,
                        subtitle: localizations.plansGoalsProgress,
                        onTap: onOpenReadingPlans,
                      ),
                      _MoreAction(
                        icon: Icons.menu_book_rounded,
                        assetPath: _hifzAsset,
                        title: localizations.hifz,
                        subtitle: localizations.hifzSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const HifzHomePage(),
                            ),
                          );
                        },
                      ),
                      _MoreAction(
                        icon: Icons.auto_awesome_outlined,
                        assetPath: _tasbihAsset,
                        title: localizations.tasbih,
                        subtitle: localizations.calmDhikrCounter,
                        onTap: onOpenTasbih,
                      ),
                      _MoreAction(
                        icon: Icons.diamond_outlined,
                        assetPath: _duaAsset,
                        title: localizations.asmaUlHusna,
                        subtitle: localizations.the99BeautifulNames,
                        onTap: onOpenAsmaUlHusna,
                      ),
                      _MoreAction(
                        icon: Icons.insights_outlined,
                        assetPath: _lastReadAsset,
                        title: localizations.statistics,
                        subtitle: localizations.worshipTrendsAndStreaks,
                        onTap: onOpenStats,
                      ),
                      _MoreAction(
                        icon: Icons.calculate_outlined,
                        assetPath: _zakatAsset,
                        title: localizations.zakatCalculator,
                        subtitle: localizations.zakatCalculatorSubtitle,
                        onTap: onOpenZakat,
                      ),
                      _MoreAction(
                        icon: Icons.calendar_month_outlined,
                        assetPath: _routineAsset,
                        title: localizations.islamicCalendar,
                        subtitle: localizations.islamicCalendarSubtitle,
                        onTap: onOpenCalendar,
                      ),
                      _MoreAction(
                        icon: Icons.settings_outlined,
                        assetPath: _settingsAsset,
                        title: localizations.settings,
                        subtitle: localizations.fontsReciterAppBehavior,
                        onTap: onOpenSettings,
                      ),

                      _MoreAction(
                        icon: Icons.brightness_6_outlined,
                        assetPath: _themeAsset,
                        title: localizations.theme,
                        subtitle: localizations.switchLightOrNightMode,
                        onTap: onToggleTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MoreSupportSection(
                    onAbout: () => _showAboutApp(context),
                    onShare: () => _shareApp(context),
                    onFeedback: () => _openFeedbackContactPage(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAboutApp(BuildContext context) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _CustomAboutDialog(
        version: AppLocalizations.of(
          context,
        )!.versionLabel(packageInfo.version),
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'eQuran',
          subject: AppLocalizations.of(context)!.downloadEquran,
          text: AppLocalizations.of(
            context,
          )!.downloadEquranShareText(_appDownloadUrl),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, AppLocalizations.of(context)!.unableOpenShareSheet);
    }
  }

  void _openFeedbackContactPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _FeedbackContactPage(),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MoreHero extends StatelessWidget {
  const _MoreHero({required this.onOpenReadingPlans});

  final VoidCallback onOpenReadingPlans;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;

    return EquranGradientCard(
      onTap: onOpenReadingPlans,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double copyWidth = constraints.maxWidth < 560
              ? (constraints.maxWidth * 0.58).clamp(220.0, 420.0).toDouble()
              : 420;

          return Stack(
            children: <Widget>[
              const Positioned.fill(child: _MoreHeroArtwork()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    localizations.yourIslamicCompanion,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: copyWidth,
                    child: Text(
                      localizations.moreHeroSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryMuted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        localizations.openRoutine,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: colors.onPrimary,
                        size: 19,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoreHeroArtwork extends StatelessWidget {
  const _MoreHeroArtwork();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 340;
        final double artworkEdgePadding = _artworkEdgePadding(
          constraints.maxWidth,
        );
        final double artWidth = (constraints.maxWidth * 0.92)
            .clamp(compact ? 340.0 : 460.0, 820.0)
            .toDouble();
        final double artworkScale = compact ? 1.55 : 1.7;
        final double artworkTransparentRightInset =
            artWidth * artworkScale * 0.26;
        final double artworkOffsetY = compact ? -5.0 : -5.0;
        final bool isRtl = Directionality.of(context) == TextDirection.rtl;

        return IgnorePointer(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: artworkEdgePadding),
              child: OverflowBox(
                alignment: AlignmentDirectional.centerEnd,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Transform.scale(
                  scale: artworkScale,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Transform.translate(
                    offset: Offset(
                      isRtl
                          ? -artworkTransparentRightInset
                          : artworkTransparentRightInset,
                      artworkOffsetY,
                    ),
                    child: Opacity(
                      opacity: 0.18,
                      child: SizedBox(
                        width: artWidth,
                        child: Image.asset(
                          _routineAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _artworkEdgePadding(double width) {
    if (width < 340) return 4;
    if (width < 430) return 6;
    return 8;
  }
}

class _MoreShortcutsGrid extends StatelessWidget {
  const _MoreShortcutsGrid({required this.items});

  final List<_MoreAction> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 670 ? 2 : 1;
        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 4.6 : 3.8,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _MoreActionTile(action: items[index]);
          },
        );
      },
    );
  }
}

class _MoreActionTile extends StatelessWidget {
  const _MoreActionTile({required this.action});

  final _MoreAction action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return EquranSurfaceCard(
      onTap: action.onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: <Widget>[
          _MoreActionArtwork(icon: action.icon, assetPath: action.assetPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _MoreActionArtwork extends StatelessWidget {
  const _MoreActionArtwork({required this.icon, this.assetPath});

  final IconData icon;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;

    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.mint,
        borderRadius: BorderRadius.circular(EquranRadii.medium),
      ),
      child: assetPath == null
          ? Icon(icon, color: colors.primary, size: 23)
          : ClipRRect(
              borderRadius: BorderRadius.circular(EquranRadii.small),
              child: Image.asset(
                assetPath!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(icon, color: colors.primary, size: 23);
                },
              ),
            ),
    );
  }
}

class _MoreSupportSection extends StatelessWidget {
  const _MoreSupportSection({
    required this.onAbout,
    required this.onShare,
    required this.onFeedback,
  });

  final VoidCallback onAbout;
  final VoidCallback onShare;
  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MoreActionTile(
          action: _MoreAction(
            icon: Icons.info_outline_rounded,
            assetPath: _appIconAsset,
            title: localizations.aboutThisApp,
            subtitle: localizations.appDetailsAndVersion,
            onTap: onAbout,
          ),
        ),
        const SizedBox(height: 12),
        _MoreActionTile(
          action: _MoreAction(
            icon: Icons.share_outlined,
            assetPath: _shareAppAsset,
            title: localizations.shareApp,
            subtitle: localizations.shareAppSubtitle,
            onTap: onShare,
          ),
        ),
        const SizedBox(height: 12),
        _MoreActionTile(
          action: _MoreAction(
            icon: Icons.feedback_outlined,
            assetPath: _feedbackAsset,
            title: localizations.feedbackContact,
            subtitle: localizations.feedbackContactSubtitle,
            onTap: onFeedback,
          ),
        ),
      ],
    );
  }
}

class _FeedbackContactPage extends StatelessWidget {
  const _FeedbackContactPage();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.feedbackContact),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colors.textSecondary),
        actionsIconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(localizations.reportIssues),
            subtitle: Text(localizations.reportIssuesSubtitle),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () async {
              final Uri uri = Uri.parse(_issueReportUrl);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
                  context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.unableOpenIssueTracker)),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(localizations.emailSupport),
            subtitle: Text(_contactEmail),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'mailto',
                path: _contactEmail,
                queryParameters: <String, String>{'subject': 'eQuran feedback'},
              );
              if (!await launchUrl(uri) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.unableOpenEmailClient)),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              localizations.feedbackThanks,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreAction {
  const _MoreAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.assetPath,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? assetPath;
}

class _CustomAboutDialog extends StatefulWidget {
  const _CustomAboutDialog({required this.version});

  final String version;

  @override
  State<_CustomAboutDialog> createState() => _CustomAboutDialogState();
}

class _CustomAboutDialogState extends State<_CustomAboutDialog> {
  int _clickCount = 0;

  Future<void> _copyDonationAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!mounted) return;

    final AppLocalizations localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.addressCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _supportDonationTile({
    required _SupportDonation donation,
    required ThemeData theme,
    required EquranColors colors,
    required AppLocalizations localizations,
  }) {
    final BorderRadius borderRadius = BorderRadius.circular(EquranRadii.medium);

    return Material(
      color: colors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => _copyDonationAddress(donation.address),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      donation.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: localizations.copyAddress,
                    child: Icon(
                      Icons.copy_outlined,
                      size: 17,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                donation.address,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return AlertDialog(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(EquranRadii.medium),
            child: Image.asset(
              _appIconAsset,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _clickCount++;
                    });
                    if (_clickCount == 7) {
                      _clickCount = 0;
                      final SettingsDB settings = SettingsDB();
                      final bool currentVal =
                          settings.get(
                                'holographicCardsEnabled',
                                defaultValue: false,
                              )
                              as bool;
                      final bool nextVal = !currentVal;
                      settings.put('holographicCardsEnabled', nextVal);

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            nextVal
                                ? '🌈 Holographic cards enabled!'
                                : '✨ Holographic cards disabled!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'eQuran',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  widget.version,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                localizations.aboutAppBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.supportProject,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                localizations.supportProjectDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final _SupportDonation donation in <_SupportDonation>[
                _SupportDonation(
                  label: localizations.bitcoin,
                  address: _bitcoinDonationAddress,
                ),
                _SupportDonation(
                  label: localizations.ethereum,
                  address: _ethereumDonationAddress,
                ),
                _SupportDonation(
                  label: localizations.solana,
                  address: _solanaDonationAddress,
                ),
                _SupportDonation(
                  label: localizations.usdcErc20,
                  address: _usdcDonationAddress,
                ),
                _SupportDonation(
                  label: localizations.litecoin,
                  address: _litecoinDonationAddress,
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _supportDonationTile(
                    donation: donation,
                    theme: theme,
                    colors: colors,
                    localizations: localizations,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            showLicensePage(
              context: context,
              applicationName: 'eQuran',
              applicationVersion: widget.version,
              applicationIcon: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(EquranRadii.medium),
                  child: Image.asset(
                    _appIconAsset,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
          child: Text(
            localizations.licenses,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            localizations.close,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class _SupportDonation {
  const _SupportDonation({required this.label, required this.address});

  final String label;
  final String address;
}
