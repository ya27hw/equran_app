import 'dart:math' as math;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;

String prayerDisplayTime(DateTime time, bool use24Hour, AppLocalizations l) {
  if (use24Hour) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final suffix = l.localeName.startsWith('ar')
      ? (time.hour >= 12 ? 'م' : 'ص')
      : (time.hour >= 12 ? 'PM' : 'AM');
  return '$hour:${time.minute.toString().padLeft(2, '0')} $suffix';
}

/// Geometry from the design SVG, independent of the prayer calculation service.
double prayerArcFraction(DateTime now, DateTime start, DateTime end) {
  final span = end.difference(start).inMicroseconds;
  if (span <= 0) return 0;
  return (now.difference(start).inMicroseconds / span).clamp(0.0, 1.0);
}

Offset prayerArcPoint(double fraction, {bool rtl = false}) {
  final t = fraction.clamp(0.0, 1.0);
  final angle = math.pi * (1 - t);
  final x = 171 + 140 * math.cos(angle);
  return Offset(rtl ? 342 - x : x, 150 - 140 * math.sin(angle));
}

class PrayerArcHero extends StatelessWidget {
  const PrayerArcHero({
    super.key,
    required this.day,
    required this.nextPrayer,
    required this.now,
    required this.onTap,
    required this.followingDay,
    this.currentPrayer,
    this.titleOverride,
    this.subtitleOverride,
    this.periodEndsAt,
    this.isViewingToday = true,
  });
  final PrayerDay day;
  final NextPrayer nextPrayer;
  final PrayerDay followingDay;
  final DateTime now;
  final VoidCallback onTap;
  final PrayerTimeEntry? currentPrayer;
  final DateTime? periodEndsAt;
  final String? titleOverride;
  final String? subtitleOverride;
  final bool isViewingToday;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.equranTokens;
    final foreground = EquranColors.dark.textPrimary;
    final gold = EquranTokens.ensure(
      tokens.gold,
      against: [tokens.featA, tokens.featB],
      target: 4.5,
      toward: foreground,
    );
    final sunrise = day.entryFor(PrayerTimeKind.sunrise).time;
    // PrayerDay begins at the previous evening's Maghrib. Daylight ends
    // at the following Islamic day's Maghrib on this sunrise's civil date.
    final maghrib = followingDay.entryFor(PrayerTimeKind.maghrib).time;
    final night = isViewingToday && now.isBefore(sunrise);
    final arcStart = night
        ? day.entryFor(PrayerTimeKind.maghrib).time
        : sunrise;
    final arcEnd = night ? day.entryFor(PrayerTimeKind.fajr).time : maghrib;
    final fraction = prayerArcFraction(now, arcStart, arcEnd);
    final current = currentPrayer ?? nextPrayer.entry;
    final title = titleOverride ?? localizedPrayerName(l, current.kind);
    final countdown = nextPrayer.countdown.isNegative
        ? Duration.zero
        : nextPrayer.countdown;
    final subtitle =
        subtitleOverride ??
        l.prayerBeginsIn(
          localizedPrayerName(l, nextPrayer.entry.kind),
          countdown.inHours > 0
              ? l.hoursMinutesShort(
                  countdown.inHours,
                  countdown.inMinutes.remainder(60),
                )
              : l.minutesShort(countdown.inMinutes),
        );
    String time(DateTime value) =>
        prayerDisplayTime(value, day.settings.use24HourFormat, l);
    final ends = periodEndsAt ?? nextPrayer.entry.time;
    final periodFraction = isViewingToday
        ? prayerArcFraction(now, current.time, ends)
        : 0.0;
    return Semantics(
      button: true,
      child: HeroPanel(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const Key('prayer-arc-hero'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = MediaQuery.textScalerOf(context).scale(1);
                      final arcHeight = 176 + (scale - 1).clamp(0.0, 2.0) * 100;
                      return SizedBox(
                        height: arcHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ExcludeSemantics(
                                child: CustomPaint(
                                  painter: PrayerArcPainter(
                                    fraction: fraction,
                                    night: night,
                                    gold: tokens.gold,
                                    background: tokens.featB,
                                    markers: night
                                        ? const []
                                        : [
                                            prayerArcFraction(
                                              day
                                                  .entryFor(
                                                    PrayerTimeKind.dhuhr,
                                                  )
                                                  .time,
                                              sunrise,
                                              maghrib,
                                            ),
                                            prayerArcFraction(
                                              day
                                                  .entryFor(PrayerTimeKind.asr)
                                                  .time,
                                              sunrise,
                                              maghrib,
                                            ),
                                          ],
                                    showProgress: isViewingToday,
                                    rtl:
                                        Directionality.of(context) ==
                                        TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 38,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  RedesignEyebrow(
                                    isViewingToday
                                        ? l.countdownNow
                                        : l.prayerTimes,
                                    color: gold,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: redesignDisplayStyle(
                                      context,
                                      size: 46,
                                      color: foreground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: tokens.featText2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _ArcEndpoint(
                                    label: night
                                        ? l.prayerNameMaghrib
                                        : l.prayerNameSunrise,
                                    time: time(arcStart),
                                    color: tokens.featText2,
                                  ),
                                  _ArcEndpoint(
                                    label: night
                                        ? l.prayerNameFajr
                                        : l.prayerNameMaghrib,
                                    time: time(arcEnd),
                                    color: tokens.featText2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (isViewingToday) ...[
                    const SizedBox(height: 20),
                    Divider(
                      height: 1,
                      color: tokens.gold.withValues(alpha: .22),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        if (currentPrayer != null)
                          Text(
                            l.prayerBeganAt(time(current.time)),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.featText2,
                            ),
                          ),
                        Text(
                          l.prayerEndsAt(time(ends)),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.featText2,
                          ),
                        ),
                      ],
                    ),
                    if (currentPrayer != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 5,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: foreground.withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              PositionedDirectional(
                                start: 0,
                                top: 0,
                                bottom: 0,
                                width: constraints.maxWidth * periodFraction,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: tokens.gold,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcEndpoint extends StatelessWidget {
  const _ArcEndpoint({
    required this.label,
    required this.time,
    required this.color,
  });
  final String label;
  final String time;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11.5, height: 1.35, color: color)),
      Text(
        time,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    ],
  );
}

class PrayerArcPainter extends CustomPainter {
  const PrayerArcPainter({
    required this.fraction,
    required this.gold,
    required this.background,
    required this.markers,
    this.rtl = false,
    this.showProgress = true,
    this.night = false,
  });
  final bool night;
  final double fraction;
  final Color gold;
  final Color background;
  final List<double> markers;
  final bool rtl;
  final bool showProgress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 342, size.height / 176);
    if (rtl) {
      canvas.translate(342, 0);
      canvas.scale(-1, 1);
    }
    final paint = Paint()
      ..color = gold.withValues(alpha: .3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(31, 150), const Offset(311, 150), paint);
    final circle = Rect.fromCircle(center: const Offset(171, 150), radius: 140);
    paint
      ..color = gold.withValues(alpha: .28)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var t = 0.0; t < math.pi; t += 8 / 140) {
      canvas.drawArc(
        circle,
        math.pi + t,
        math.min(2 / 140, math.pi - t),
        false,
        paint,
      );
    }
    if (showProgress) {
      paint
        ..color = gold
        ..strokeWidth = 2.4;
      canvas.drawArc(circle, math.pi, math.pi * fraction, false, paint);
    }
    for (final marker in markers) {
      final point = prayerArcPoint(marker);
      paint
        ..style = PaintingStyle.fill
        ..color = marker <= fraction && showProgress ? gold : background;
      canvas.drawCircle(point, 3.2, paint);
      paint
        ..style = PaintingStyle.stroke
        ..color = gold.withValues(alpha: .7)
        ..strokeWidth = 1.4;
      canvas.drawCircle(point, 3.2, paint);
    }
    if (showProgress) {
      final point = prayerArcPoint(fraction);
      paint
        ..style = PaintingStyle.fill
        ..color = gold.withValues(alpha: .16);
      canvas.drawCircle(point, 19, paint);
      paint.color = EquranTokens.mix(gold, EquranColors.dark.textPrimary, .2);
      if (night) {
        final moon = Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: point, radius: 10)),
          Path()..addOval(
            Rect.fromCircle(center: point + const Offset(5, -4), radius: 9),
          ),
        );
        canvas.drawPath(moon, paint);
      } else {
        canvas.drawCircle(point, 10, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PrayerArcPainter old) =>
      old.fraction != fraction ||
      old.night != night ||
      old.gold != gold ||
      old.background != background ||
      old.rtl != rtl ||
      old.showProgress != showProgress ||
      !listEquals(old.markers, markers);
}
