import 'package:equran/prayer/prayer_clock_text.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';

class PrayerTimeThumbCard extends StatelessWidget {
  const PrayerTimeThumbCard({
    super.key,
    required this.entry,
    required this.isActive,
    required this.use24HourFormat,
    this.onTap,
    this.width,
    this.listRow = false,
    this.now,
    this.isViewingToday = true,
    this.periodEndsAt,
  });

  final PrayerTimeEntry entry;
  final bool isActive;
  final bool use24HourFormat;
  final VoidCallback? onTap;
  final double? width;
  final bool listRow;
  final DateTime? now;
  final DateTime? periodEndsAt;
  final bool isViewingToday;

  @override
  Widget build(BuildContext context) {
    if (listRow) {
      return _PrayerTimeRow(
        entry: entry,
        isActive: isActive,
        use24HourFormat: use24HourFormat,
        now: now!,
        isViewingToday: isViewingToday,
        periodEndsAt: periodEndsAt,
        onTap: onTap,
      );
    }
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final BorderRadius radius = BorderRadius.circular(EquranRadii.xl - 4);
    final String time = _formatPrayerTime(
      entry.time,
      use24HourFormat,
      localizations,
    );

    return Semantics(
      button: onTap != null,
      selected: isActive,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: isActive ? tokens.goldWash : colors.surface,
              borderRadius: radius,
              border: Border.all(
                color: isActive
                    ? tokens.gold.withValues(alpha: 0.55)
                    : tokens.hair,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 42,
                  child: Center(
                    child: PrayerArch(
                      kind: entry.kind,
                      semanticLabel: localizedPrayerName(
                        localizations,
                        entry.kind,
                      ),
                      width: entry.kind == PrayerTimeKind.sunrise ? 26 : 30,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizedPrayerName(localizations, entry.kind),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive ? tokens.goldText : tokens.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DisplayNumeral(
                    time,
                    size: 16,
                    color: colors.textPrimary,
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

class _PrayerTimeRow extends StatelessWidget {
  const _PrayerTimeRow({
    required this.entry,
    required this.isActive,
    required this.use24HourFormat,
    required this.now,
    required this.isViewingToday,
    this.periodEndsAt,
    this.onTap,
  });
  final PrayerTimeEntry entry;
  final bool isActive;
  final bool use24HourFormat;
  final DateTime now;
  final bool isViewingToday;
  final DateTime? periodEndsAt;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.equranTokens;
    final passed = isViewingToday && !entry.time.isAfter(now) && !isActive;
    final text = passed ? tokens.text2 : context.equranColors.textPrimary;
    final duration = entry.time.difference(now);
    final String status = !isViewingToday
        ? ''
        : isActive
        ? (periodEndsAt == null
              ? l.countdownNow
              : l.prayerEndsAt(
                  _formatPrayerTime(periodEndsAt!, use24HourFormat, l),
                ))
        : passed
        ? l.prayerPassed
        : duration.inHours > 0
        ? l.countdownInHoursMinutes(
            duration.inHours,
            twoDigitMinutes(duration.inMinutes.remainder(60)),
          )
        : l.countdownInMinutes(duration.inMinutes);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: AlignmentDirectional.centerStart.resolve(
                  Directionality.of(context),
                ),
                end: AlignmentDirectional.centerEnd.resolve(
                  Directionality.of(context),
                ),
                colors: [tokens.emWash, tokens.emWash.withValues(alpha: 0)],
              )
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Center(
                    child: PrayerArch(
                      kind: entry.kind,
                      semanticLabel: localizedPrayerName(l, entry.kind),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            localizedPrayerName(l, entry.kind),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: text,
                            ),
                          ),
                          if (isActive)
                            PillTag(
                              l.countdownNow.toUpperCase(),
                              gold: true,
                              compact: true,
                            ),
                        ],
                      ),
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive ? tokens.emText : tokens.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PrayerClockText(
                  _formatPrayerTime(entry.time, use24HourFormat, l),
                  size: 22,
                  color: text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
