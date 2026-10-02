import 'package:equran/widgets/common/equran_asset_image.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/prayer/prayer_notification_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/common/equran_components.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

const String _appAssetBase = 'assets/media/images/app';
const String _fallbackPrayerAsset = '$_appAssetBase/prayer_time.webp';

class PrayerHeroCard extends StatelessWidget {
  const PrayerHeroCard({
    super.key,
    required this.day,
    required this.nextPrayer,
    required this.onTap,
    this.currentPrayer,
    this.exactAlarmPermission,
    this.titleOverride,
    this.subtitleOverride,
  });

  final PrayerDay? day;
  final NextPrayer? nextPrayer;
  final PrayerTimeEntry? currentPrayer;
  final PrayerExactAlarmPermissionStatus? exactAlarmPermission;
  final String? titleOverride;
  final String? subtitleOverride;
  final VoidCallback onTap;

  String _formatTime(
    DateTime time,
    bool use24HourFormat,
    AppLocalizations localizations,
  ) {
    if (use24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }
    final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final bool arabic = isArabicLocalizations(localizations);
    final String suffix = arabic
        ? (time.hour >= 12 ? 'م' : 'ص')
        : (time.hour >= 12 ? 'PM' : 'AM');
    return '$hour:${time.minute.toString().padLeft(2, '0')} $suffix';
  }

  String _formatCountdown(Duration duration, AppLocalizations localizations) {
    final Duration normalized = duration.isNegative ? Duration.zero : duration;
    final int hours = normalized.inHours;
    final int minutes = normalized.inMinutes.remainder(60);
    if (hours <= 0) return localizations.minutesShort(minutes);
    return localizations.hoursMinutesShort(hours, minutes);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final PrayerDay? prayerDay = day;
    final NextPrayer? next = nextPrayer;

    if (prayerDay == null || next == null) {
      return EquranGradientCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SizedBox(
          height: 176,
          child: Stack(
            children: <Widget>[
              const PositionedDirectional(
                end: -18,
                top: 8,
                bottom: 8,
                width: 190,
                child: _PrayerHeroDecoration(kind: PrayerTimeKind.fajr),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      localizations.prayerTimes,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 230,
                      child: Text(
                        localizations.chooseLocationForNextPrayer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimaryMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      localizations.setUpLocation,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
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

    final PrayerTimeSettings settings = prayerDay.settings;
    final PrayerTimeEntry featuredPrayer = currentPrayer ?? next.entry;
    final String prayerTime = _formatTime(
      featuredPrayer.time,
      settings.use24HourFormat,
      localizations,
    );
    final String countdown = _formatCountdown(next.countdown, localizations);
    final bool exactAlarmDenied =
        exactAlarmPermission == PrayerExactAlarmPermissionStatus.denied;
    final String featuredPrayerName = localizedPrayerName(
      localizations,
      featuredPrayer.kind,
    );
    final String nextPrayerName = localizedPrayerName(
      localizations,
      next.entry.kind,
    );
    final String title =
        titleOverride ??
        (featuredPrayer.kind == PrayerTimeKind.sunrise
            ? localizations.prayerNameSunrise
            : localizations.prayerTimeTitle(featuredPrayerName));
    final String subtitle =
        subtitleOverride ??
        localizations.prayerBeginsIn(nextPrayerName, countdown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 390;
            final bool use12HourTime = !settings.use24HourFormat;
            final double artWidth =
                (constraints.maxWidth * (compact ? 0.72 : 0.76))
                    .clamp(compact ? 220.0 : 270.0, compact ? 280.0 : 380.0)
                    .toDouble();
            final double trailingSpace = (artWidth * 0.72)
                .clamp(compact ? 178.0 : 220.0, compact ? 230.0 : 300.0)
                .toDouble();
            final double timeSize =
                (constraints.maxWidth * (use12HourTime ? 0.105 : 0.13))
                    .clamp(
                      compact
                          ? (use12HourTime ? 30.0 : 34.0)
                          : (use12HourTime ? 34.0 : 40.0),
                      use12HourTime ? 40.0 : 48.0,
                    )
                    .toDouble();
            final double titleSize = (constraints.maxWidth * 0.052)
                .clamp(18.0, 22.0)
                .toDouble();

            return EquranGradientCard(
              onTap: onTap,
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 20,
                compact ? 14 : 16,
                compact ? 12 : 16,
                compact ? 14 : 16,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  PositionedDirectional(
                    end: -20,
                    top: -24,
                    bottom: -12,
                    width: artWidth,
                    child: Transform.scale(
                      scale: compact ? 1.12 : 1.23,
                      alignment: AlignmentDirectional.centerEnd,
                      child: _PrayerHeroDecoration(kind: featuredPrayer.kind),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: compact ? 148.0 : 168.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  prayerTime,
                                  maxLines: 1,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: colors.onPrimary,
                                    fontSize: timeSize,
                                    fontWeight: FontWeight.w900,
                                    height: 0.94,
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 6 : 8),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colors.onPrimary,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 12 : 16,
                                ),
                                child: SizedBox(
                                  width: compact ? 88 : 104,
                                  child: Divider(
                                    height: 1,
                                    color: colors.onPrimary.withAlpha(58),
                                  ),
                                ),
                              ),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.onPrimaryMuted,
                                  fontSize: compact ? 13 : null,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: trailingSpace),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        if (exactAlarmDenied) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: colors.warningSurface,
              borderRadius: BorderRadius.circular(EquranRadii.medium),
              border: Border.all(color: colors.warning.withAlpha(72)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.notifications_paused_outlined,
                  size: 18,
                  color: colors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations.exactAlarmPermissionOff,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PrayerHeroDecoration extends StatelessWidget {
  const _PrayerHeroDecoration({required this.kind});

  final PrayerTimeKind kind;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(EquranRadii.large),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.0, 1.0, 1.0),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 0, 2),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: EquranAssetImage(
                  _prayerBannerAsset(kind),
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  fit: BoxFit.contain,
                  alignment: AlignmentDirectional.centerEnd,
                  errorBuilder: (context, error, stackTrace) {
                    return EquranAssetImage(
                      _fallbackPrayerAsset,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _prayerBannerAsset(PrayerTimeKind kind) {
    return switch (kind) {
      PrayerTimeKind.fajr => '$_appAssetBase/fajr_banner.webp',
      PrayerTimeKind.sunrise => '$_appAssetBase/fajr_banner.webp',
      PrayerTimeKind.dhuhr => '$_appAssetBase/dhuhr_banner.webp',
      PrayerTimeKind.asr => '$_appAssetBase/asr_banner.webp',
      PrayerTimeKind.maghrib => '$_appAssetBase/maghrib_banner.webp',
      PrayerTimeKind.isha => '$_appAssetBase/isha_banner.webp',
    };
  }
}
