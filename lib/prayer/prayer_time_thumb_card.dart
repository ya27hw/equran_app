import 'package:equran/widgets/common/equran_asset_image.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

const String _appAssetBase = 'assets/media/images/app';

class PrayerTimeThumbCard extends StatelessWidget {
  const PrayerTimeThumbCard({
    super.key,
    required this.entry,
    required this.isActive,
    required this.use24HourFormat,
    this.onTap,
    this.width,
  });

  final PrayerTimeEntry entry;
  final bool isActive;
  final bool use24HourFormat;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool isLight = theme.brightness == Brightness.light;
    final BorderRadius radius = BorderRadius.circular(AppRadii.large);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: width,
          decoration: BoxDecoration(
            color: isActive ? colors.surfaceAlt : colors.surface,
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color.alphaBlend(
                        colors.primary.withAlpha(isLight ? 34 : 42),
                        colors.surfaceAlt,
                      ),
                      colors.surfaceAlt,
                    ],
                  )
                : null,
            borderRadius: radius,
            border: Border.all(
              color: isActive ? colors.primary.withAlpha(190) : colors.border,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isActive
                    ? colors.primaryStrong.withAlpha(isLight ? 38 : 58)
                    : colors.shadow.withAlpha(isLight ? 12 : 26),
                blurRadius: isActive ? 20 : 14,
                offset: Offset(0, isActive ? 9 : 5),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double imageWidth = (constraints.maxWidth * 0.74)
                  .clamp(88.0, 132.0)
                  .toDouble();
              final double imageHeight = (constraints.maxHeight * 0.52)
                  .clamp(58.0, 90.0)
                  .toDouble();
              final Color primaryText = isActive
                  ? colors.primarySoft
                  : colors.textPrimary;

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            localizedPrayerName(localizations, entry.kind),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: EquranAssetImage(
                          _prayerThumbAsset(entry.kind),
                          fit: BoxFit.contain,
                          width: imageWidth,
                          height: imageHeight,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _iconFor(entry.kind),
                              color: colors.primary,
                              size: imageHeight * 0.78,
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _formatPrayerTime(
                            entry.time,
                            use24HourFormat,
                            AppLocalizations.of(context)!,
                          ),
                          maxLines: 1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(PrayerTimeKind kind) {
  return switch (kind) {
    PrayerTimeKind.fajr => Icons.nights_stay_rounded,
    PrayerTimeKind.sunrise => Icons.wb_twilight_rounded,
    PrayerTimeKind.dhuhr => Icons.wb_sunny_outlined,
    PrayerTimeKind.asr => Icons.light_mode_outlined,
    PrayerTimeKind.maghrib => Icons.wb_twilight_outlined,
    PrayerTimeKind.isha => Icons.dark_mode_outlined,
  };
}

String _prayerThumbAsset(PrayerTimeKind kind) {
  return switch (kind) {
    PrayerTimeKind.fajr => '$_appAssetBase/fajr.webp',
    PrayerTimeKind.sunrise => '$_appAssetBase/sunrise.webp',
    PrayerTimeKind.dhuhr => '$_appAssetBase/dhuhr.webp',
    PrayerTimeKind.asr => '$_appAssetBase/asr.webp',
    PrayerTimeKind.maghrib => '$_appAssetBase/maghrib.webp',
    PrayerTimeKind.isha => '$_appAssetBase/isha.webp',
  };
}

String _formatPrayerTime(
  DateTime time,
  bool use24HourFormat,
  AppLocalizations localizations,
) {
  final int hour = time.hour;
  final int minute = time.minute;
  if (use24HourFormat) {
    return '${_two(hour)}:${_two(minute)}';
  }

  final bool arabic = isArabicLocalizations(localizations);
  final String period = arabic
      ? (hour >= 12 ? 'م' : 'ص')
      : (hour >= 12 ? 'PM' : 'AM');
  final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${_two(minute)} $period';
}

String _two(int value) => value.toString().padLeft(2, '0');
