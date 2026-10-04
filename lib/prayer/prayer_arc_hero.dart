import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_sky_painter.dart';
import 'package:equran/prayer/prayer_sky_scene.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/common/pressable_scale.dart';
import 'package:flutter/material.dart';

/// Prayer-page-only sky hero. Home retains its existing hero and setup state.
class PrayerArcHero extends StatelessWidget {
  const PrayerArcHero({
    super.key,
    required this.day,
    required this.followingDay,
    required this.now,
    required this.nextPrayer,
    required this.onTap,
    this.currentPrayer,
    this.periodEndsAt,
    this.titleOverride,
    this.subtitleOverride,
    this.isViewingToday = true,
  });

  final PrayerDay day;
  final PrayerDay followingDay;
  final DateTime now;
  final NextPrayer nextPrayer;
  final VoidCallback onTap;
  final PrayerTimeEntry? currentPrayer;
  final DateTime? periodEndsAt;
  final String? titleOverride;
  final String? subtitleOverride;
  final bool isViewingToday;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String title =
        titleOverride ??
        localizedPrayerName(l10n, (currentPrayer ?? nextPrayer.entry).kind);
    final Duration remaining = nextPrayer.countdown.isNegative
        ? Duration.zero
        : nextPrayer.countdown;
    final String countdown = remaining.inHours == 0
        ? l10n.minutesShort(remaining.inMinutes)
        : l10n.hoursMinutesShort(
            remaining.inHours,
            twoDigitMinutes(remaining.inMinutes.remainder(60)),
          );
    final InlineSpan subtitle = subtitleOverride != null
        ? TextSpan(text: subtitleOverride)
        : prayerNextInSpan(
            l10n,
            prayer: localizedPrayerName(l10n, nextPrayer.entry.kind),
            duration: countdown,
            numeralStyle: EquranTextStyles.displayNumeral(
              context,
              size: 16,
              fontWeight: FontWeight.w700,
              height: 1,
              color: PrayerSkyScene.foreground,
            ).copyWith(fontFamilyFallback: const ['NotoNaskhArabic']),
          );
    final PrayerSkyScene scene = PrayerSkyScene.forInstant(
      day: day,
      followingDay: followingDay,
      now: isViewingToday ? now : day.entryFor(PrayerTimeKind.dhuhr).time,
    );
    return ValueListenableBuilder(
      valueListenable: DeviceCapabilityService.instance,
      builder: (context, profile, _) {
        final bool animate =
            isViewingToday &&
            profile.allowsDecorativeEffects &&
            !MediaQuery.disableAnimationsOf(context) &&
            TickerMode.valuesOf(context).enabled;
        return LayoutBuilder(
          builder: (context, constraints) {
            final double scale =
                MediaQuery.textScalerOf(context).scale(14) / 14;
            final double height =
                (constraints.maxWidth < 390 ? 176.0 : 200.0) +
                (scale - 1).clamp(0.0, 2.0) * 100;
            return PressableScale(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(EquranRadii.xxl),
                child: SizedBox(
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Positioned.fill(
                        child: ExcludeSemantics(
                          child: RepaintBoundary(
                            child: _AnimatedPrayerSky(
                              scene: scene,
                              animate: animate,
                              decorativeEffects:
                                  profile.allowsDecorativeEffects,
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('prayer-arc-hero'),
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                if (isViewingToday) ...<Widget>[
                                  RedesignEyebrow(
                                    l10n.countdownNow,
                                    color: PrayerSkyScene.foreground,
                                  ),
                                  const SizedBox(height: 5),
                                ],
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    title,
                                    style: redesignDisplayStyle(
                                      context,
                                      size: 36,
                                      height: 1.15,
                                      color: PrayerSkyScene.foreground,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text.rich(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: PrayerSkyScene.foreground,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedPrayerSky extends ImplicitlyAnimatedWidget {
  const _AnimatedPrayerSky({
    required this.scene,
    required bool animate,
    required this.decorativeEffects,
  }) : super(
         duration: animate ? const Duration(milliseconds: 350) : Duration.zero,
         curve: Curves.easeOutCubic,
       );

  final PrayerSkyScene scene;
  final bool decorativeEffects;

  @override
  AnimatedWidgetBaseState<_AnimatedPrayerSky> createState() =>
      _AnimatedPrayerSkyState();
}

class _AnimatedPrayerSkyState
    extends AnimatedWidgetBaseState<_AnimatedPrayerSky> {
  _SkyTween? _scene;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _scene =
        visitor(
              _scene,
              widget.scene,
              (dynamic value) => _SkyTween(begin: value as PrayerSkyScene),
            )
            as _SkyTween?;
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: PrayerSkyPainter(
      scene: _scene!.evaluate(animation),
      textDirection: Directionality.of(context),
      decorativeEffects: widget.decorativeEffects,
    ),
  );
}

class _SkyTween extends Tween<PrayerSkyScene> {
  _SkyTween({required super.begin});

  @override
  PrayerSkyScene lerp(double t) => PrayerSkyScene.lerp(begin!, end!, t);
}
