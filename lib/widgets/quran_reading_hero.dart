import 'package:equran/backend/reading_model.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/common/pressable_scale.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/material.dart';

/// Quran-tab reading entry point. The layered horizon suggests open pages.
class QuranReadingHero extends StatelessWidget {
  const QuranReadingHero({super.key, this.entry, required this.onTap});

  final ReadingEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstRead = entry == null;
    final title = firstRead
        ? l10n.beginQuranReading
        : localizedSurahName(l10n, entry!.surah);
    final subtitle = firstRead
        ? l10n.startWithSurah(localizedSurahName(l10n, 1))
        : l10n.ayahLabel(entry!.verse);
    final action = firstRead ? l10n.startReading : l10n.continueReading;
    const foreground = Color(0xFFF8F6EC);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EquranRadii.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 200),
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: QuranReadingLandscapePainter(
                        isDark: isDark,
                        decorativeEffects: DeviceCapabilityService
                            .instance
                            .profile
                            .allowsDecorativeEffects,
                        textDirection: Directionality.of(context),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('quran-reading-hero'),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 52),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RedesignEyebrow(
                            firstRead ? l10n.yourQuran : l10n.lastRead,
                            color: foreground,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: redesignDisplayStyle(
                              context,
                              size: firstRead ? 34 : 37,
                              height: 1.13,
                              color: foreground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: foreground,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  action,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        fontSize: 12,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                        color: foreground,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 15,
                                color: foreground,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static vector artwork: no downloaded images, timers, blur or saveLayer.
class QuranReadingLandscapePainter extends CustomPainter {
  const QuranReadingLandscapePainter({
    required this.isDark,
    required this.decorativeEffects,
    required this.textDirection,
  });

  final bool isDark;
  final bool decorativeEffects;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF203B42), Color(0xFF3B6465), Color(0xFF8B9D8D)]
              : const [Color(0xFF254E53), Color(0xFF527D77), Color(0xFFBDC5A7)],
          stops: const [0, .65, 1],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.scale(size.width / 382, size.height / 200);
    if (textDirection == TextDirection.rtl) {
      canvas.translate(382, 0);
      canvas.scale(-1, 1);
    }
    if (decorativeEffects) {
      canvas.drawCircle(
        const Offset(317, 32),
        28,
        Paint()..color = const Color(0xFFF1E6BF).withValues(alpha: .055),
      );
      final stars = Paint()
        ..color = const Color(0xFFF8F4D8).withValues(alpha: isDark ? .65 : .25);
      for (final point in const [
        Offset(35, 22),
        Offset(81, 38),
        Offset(286, 20),
        Offset(337, 57),
      ]) {
        canvas.drawCircle(point, .6, stars);
      }
    }
    final far = Path()
      ..moveTo(0, 148)
      ..quadraticBezierTo(63, 130, 121, 151)
      ..quadraticBezierTo(167, 163, 191, 181)
      ..quadraticBezierTo(235, 149, 278, 145)
      ..quadraticBezierTo(336, 141, 382, 156);
    final middle = Path()
      ..moveTo(0, 164)
      ..quadraticBezierTo(61, 148, 125, 167)
      ..quadraticBezierTo(168, 181, 191, 188)
      ..quadraticBezierTo(230, 168, 287, 158)
      ..quadraticBezierTo(335, 153, 382, 170);
    final near = Path()
      ..moveTo(0, 182)
      ..quadraticBezierTo(63, 167, 131, 182)
      ..quadraticBezierTo(169, 194, 191, 197)
      ..quadraticBezierTo(240, 185, 294, 174)
      ..quadraticBezierTo(345, 171, 382, 188);
    for (final (edge, color) in [
      (
        far,
        (isDark ? const Color(0xFFBDC9B0) : const Color(0xFFD9DAC0)).withValues(
          alpha: .4,
        ),
      ),
      (
        middle,
        (isDark ? const Color(0xFF76958B) : const Color(0xFF91AC97)).withValues(
          alpha: .85,
        ),
      ),
      (near, isDark ? const Color(0xFF32544C) : const Color(0xFF456E5C)),
    ]) {
      final fill = Path.from(edge)
        ..lineTo(382, 200)
        ..lineTo(0, 200)
        ..close();
      canvas.drawPath(fill, Paint()..color = color);
      canvas.drawPath(
        edge,
        Paint()
          ..color = const Color(0xFFE4E1BF).withValues(alpha: .23)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
    canvas.drawLine(
      const Offset(191, 181),
      const Offset(191, 200),
      Paint()
        ..color = const Color(0xFFDCE3BD).withValues(alpha: .2)
        ..strokeWidth = .6,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(QuranReadingLandscapePainter oldDelegate) =>
      isDark != oldDelegate.isDark ||
      decorativeEffects != oldDelegate.decorativeEffects ||
      textDirection != oldDelegate.textDirection;
}
