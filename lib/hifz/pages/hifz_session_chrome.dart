import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/material.dart';

/// Presentation for the Hifz review session. The page keeps the queue, the
/// scheduler, the audio player and every rating handler; these widgets only
/// draw. There is no design preview for the session, so the look follows the
/// finished redesign pages (hairline cards, serif title, eyebrow label, the
/// reader sheets' buttons).

/// Which memorisation track a card belongs to.
enum HifzTrackTone { fresh, revision, maintenance }

/// Page frame: page colour, the page glow and the interface font.
class HifzSessionFrame extends StatelessWidget {
  const HifzSessionFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: context.equranColors.background,
    child: RedesignPageTypography(child: SafeArea(bottom: false, child: child)),
  );
}

/// Close button, unit title, then the track pill, the position and a thin
/// progress line.
class HifzSessionTopBar extends StatelessWidget {
  const HifzSessionTopBar({
    super.key,
    required this.title,
    required this.closeTooltip,
    required this.onClose,
    required this.trackLabel,
    required this.trackTone,
    required this.position,
    required this.progress,
  });

  final String title;
  final String closeTooltip;
  final VoidCallback onClose;
  final String trackLabel;
  final HifzTrackTone trackTone;

  /// For example `3/12`, always in Western digits and reading order.
  final String position;

  /// 0 to 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton44(
                designIcon: 'x',
                tooltip: closeTooltip,
                onPressed: onClose,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: redesignDisplayStyle(context, size: 24, height: 1.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              HifzTrackPill(label: trackLabel, tone: trackTone),
              const Spacer(),
              DisplayNumeral(position, size: 17, color: tokens.text2),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(EquranRadii.pill),
            child: SizedBox(
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: tokens.hair2),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: tokens.gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HifzTrackPill extends StatelessWidget {
  const HifzTrackPill({super.key, required this.label, required this.tone});
  final String label;
  final HifzTrackTone tone;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    // Shape and wording carry the track; the colour only supports it.
    switch (tone) {
      case HifzTrackTone.fresh:
        return PillTag(label, selected: true);
      case HifzTrackTone.revision:
        return PillTag(label, gold: true);
      case HifzTrackTone.maintenance:
        return Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 11,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: tokens.hair,
            borderRadius: BorderRadius.circular(EquranRadii.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: tokens.text2,
            ),
          ),
        );
    }
  }
}

/// The card the ayah sits on: surah and ayah as an eyebrow, then [child].
class HifzAyahPanel extends StatelessWidget {
  const HifzAyahPanel({super.key, required this.heading, required this.child});
  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) => HairlineCard(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(child: RedesignEyebrow(heading)),
        const SizedBox(height: 12),
        const OrnamentDivider(),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );
}

/// The few words before the ayah in recall mode.
class HifzCuePanel extends StatelessWidget {
  const HifzCuePanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: context.equranColors.surfaceAlt,
      borderRadius: BorderRadius.circular(EquranRadii.large),
      border: Border.all(color: context.equranTokens.hair),
    ),
    child: child,
  );
}

/// A hidden word: tap to reveal.
class HifzBlankWord extends StatelessWidget {
  const HifzBlankWord({super.key, required this.width, required this.onReveal});
  final double width;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onReveal,
    child: Container(
      width: width,
      height: 38,
      decoration: BoxDecoration(
        color: context.equranColors.surfaceAlt,
        border: Border.all(color: context.equranTokens.hair2),
        borderRadius: BorderRadius.circular(EquranRadii.medium),
      ),
    ),
  );
}

/// Round 44 px toggle for transliteration, translation and audio.
class HifzToggleButton extends StatelessWidget {
  const HifzToggleButton({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
    this.enabled = true,
  });
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  /// When false the button is dimmed and ignores taps.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final Widget button = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? tokens.emWash : context.equranColors.surface,
        border: Border.all(color: active ? tokens.hair2 : tokens.hair),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 21, color: active ? tokens.emText : tokens.text2),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: active,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: enabled ? button : Opacity(opacity: 0.35, child: button),
      ),
    );
  }
}

/// Small A-/A+ pair that resizes the translation text. Shares the stored
/// translation size with Settings and the reader.
class HifzTextSizeControls extends StatelessWidget {
  const HifzTextSizeControls({
    super.key,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onDecrease,
    required this.onIncrease,
    required this.canDecrease,
    required this.canIncrease,
  });
  final String decreaseTooltip;
  final String increaseTooltip;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool canDecrease;
  final bool canIncrease;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Tooltip(
        message: decreaseTooltip,
        child: HifzToggleButton(
          icon: Icons.text_decrease,
          tooltip: decreaseTooltip,
          active: false,
          enabled: canDecrease,
          onTap: onDecrease,
        ),
      ),
      const SizedBox(width: 14),
      Tooltip(
        message: increaseTooltip,
        child: HifzToggleButton(
          icon: Icons.text_increase,
          tooltip: increaseTooltip,
          active: false,
          enabled: canIncrease,
          onTap: onIncrease,
        ),
      ),
    ],
  );
}

/// Primary action under the card ("I'm ready"): filled, 52 px.
class HifzPrimaryButton extends StatelessWidget {
  const HifzPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: readerFilledButtonStyle(context)
          .copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 52))),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

/// Secondary action ("Reveal all"): hairline outline, 52 px.
class HifzSecondaryButton extends StatelessWidget {
  const HifzSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: readerOutlinedButtonStyle(context)
          .copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 52))),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

/// A rating choice. [emphasis] fills it for the positive answer.
class HifzRatingButton extends StatelessWidget {
  const HifzRatingButton({
    super.key,
    required this.label,
    required this.onTap,
    this.interval,
    this.emphasis = false,
  });
  final String label;

  /// The projected next interval, already formatted.
  final String? interval;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final Color labelColor = emphasis ? Colors.white : tokens.text2;
    return Expanded(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: interval == null ? 52 : 58),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: emphasis ? tokens.filled : Colors.transparent,
              border: Border.all(
                color: emphasis ? tokens.filled : tokens.hair2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontFamilyFallback: const <String>['NotoNaskhArabic'],
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                if (interval != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    interval!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontFamilyFallback: const <String>['NotoNaskhArabic'],
                      fontSize: 12,
                      height: 1.2,
                      color: emphasis ? tokens.featText2 : tokens.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The strip under the card that holds the phase's action(s).
class HifzActionBar extends StatelessWidget {
  const HifzActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.equranColors.background,
      border: Border(top: BorderSide(color: context.equranTokens.hair)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: SafeArea(top: false, child: child),
    ),
  );
}

/// The translation shown under the ayah when enabled.
class HifzTranslationPanel extends StatelessWidget {
  const HifzTranslationPanel({
    super.key,
    required this.text,
    required this.fontSize,
  });
  final String text;

  /// The stored translation text size (`fontSizeTranslation`).
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.equranColors.surfaceAlt,
      border: Border.all(color: context.equranTokens.hair),
      borderRadius: BorderRadius.circular(EquranRadii.large),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontVariations: [FontVariation('opsz', fontSize)],
        height: 1.5,
        color: context.equranTokens.text2,
      ),
    ),
  );
}

/// Side inset that keeps session content to a readable column on a wide
/// window. Zero at phone and tablet widths, so the phone layout is unchanged.
double hifzSessionSideInset(double windowWidth) {
  const double maxContentWidth = 760;
  return windowWidth > maxContentWidth
      ? (windowWidth - maxContentWidth) / 2
      : 0;
}
