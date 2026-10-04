import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/app_slider_theme.dart';
import 'package:equran/widgets/common/pressable_scale.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Playback speeds offered as chips. They match the 0.25 steps the player
/// normalises to, so a tap always lands on a supported rate.
const List<double> playbackSpeedSteps = <double>[
  0.5,
  0.75,
  1.0,
  1.25,
  1.5,
  1.75,
  2.0,
];

String playbackSpeedLabel(double rate) {
  final String text = rate == rate.roundToDouble()
      ? rate.toStringAsFixed(0)
      : (rate * 100) % 10 == 0
      ? rate.toStringAsFixed(1)
      : rate.toStringAsFixed(2);
  return '$text×';
}

/// The reading player's options, as a presentational sheet. It owns no
/// playback state: every value comes in and every change goes out, so the
/// reading page keeps all of its audio logic.
class PlaybackOptionsSheet extends StatelessWidget {
  const PlaybackOptionsSheet({
    super.key,
    required this.scrollController,
    required this.reciterName,
    required this.onReciter,
    required this.rate,
    required this.onRateSelected,
    required this.delayLabels,
    required this.delayIndex,
    required this.onDelayChanged,
    required this.onDelayChangeEnd,
    required this.intervalSummary,
    required this.onInterval,
    required this.intervalRepeatLabel,
    required this.onIntervalRepeat,
    required this.repeatAyahLabel,
    required this.onRepeatAyah,
    required this.sleepSummary,
    required this.onSleepTimer,
    required this.surahDownloadProgress,
    required this.surahDownloading,
    required this.surahDownloaded,
    required this.onDownloadSurah,
    required this.ayahDownloading,
    required this.ayahDownloaded,
    required this.ayahSubtitle,
    required this.onToggleAyah,
    required this.onReset,
  });

  final ScrollController scrollController;
  final String reciterName;
  final VoidCallback onReciter;
  final double rate;
  final ValueChanged<double> onRateSelected;
  final List<String> delayLabels;
  final int delayIndex;
  final ValueChanged<int> onDelayChanged;
  final ValueChanged<int> onDelayChangeEnd;
  final String intervalSummary;
  final VoidCallback onInterval;
  final String intervalRepeatLabel;
  final VoidCallback onIntervalRepeat;
  final String repeatAyahLabel;
  final VoidCallback onRepeatAyah;
  final String sleepSummary;
  final VoidCallback onSleepTimer;
  final ValueListenable<double?> surahDownloadProgress;
  final bool surahDownloading;
  final bool surahDownloaded;
  final VoidCallback onDownloadSurah;
  final bool ayahDownloading;
  final bool ayahDownloaded;
  final String ayahSubtitle;
  final VoidCallback onToggleAyah;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final List<Widget> sections = <Widget>[
      _SectionGroup(
        title: l.recitation,
        children: <Widget>[
          _OptionRow(
            leading: const DesignIcon('headphones', size: 20),
            title: l.reciter,
            value: reciterName,
            onTap: onReciter,
          ),
          _SpeedBlock(
            title: l.playbackSpeed,
            rate: rate,
            onSelected: onRateSelected,
          ),
        ],
      ),
      _SectionGroup(
        title: l.timing,
        children: <Widget>[
          _DelayBlock(
            title: l.ayahDelay,
            labels: delayLabels,
            index: delayIndex,
            onChanged: onDelayChanged,
            onChangeEnd: onDelayChangeEnd,
          ),
          _OptionRow(
            leading: const DesignIcon('moon', size: 20),
            title: l.sleepTimerOption,
            value: sleepSummary,
            onTap: onSleepTimer,
          ),
        ],
      ),
      _SectionGroup(
        title: l.intervalOption,
        children: <Widget>[
          _OptionRow(
            leading: const DesignIcon('bars', size: 20),
            title: l.intervalOption,
            value: intervalSummary,
            onTap: onInterval,
          ),
          _OptionRow(
            leading: const Icon(Icons.repeat_rounded, size: 20),
            title: l.intervalRepeatOption,
            value: intervalRepeatLabel,
            onTap: onIntervalRepeat,
          ),
          _OptionRow(
            leading: const Icon(Icons.repeat_one_rounded, size: 20),
            title: l.repeatEachAyahOption,
            value: repeatAyahLabel,
            onTap: onRepeatAyah,
          ),
        ],
      ),
      _SectionGroup(
        title: l.audioDownloads,
        children: <Widget>[
          ValueListenableBuilder<double?>(
            valueListenable: surahDownloadProgress,
            builder: (context, fraction, _) {
              final bool busy = surahDownloading || fraction != null;
              return _OptionRow(
                leading: busy
                    ? _DownloadRing(fraction: fraction)
                    : DesignIcon(surahDownloaded ? 'check' : 'download'),
                title: surahDownloaded
                    ? l.surahAudioDownloaded
                    : l.downloadSurahAudio,
                value: surahDownloaded
                    ? l.allAyahsAvailableOffline
                    : l.downloadEveryAyahInSurah,
                stacked: true,
                showChevron: false,
                onTap: busy || surahDownloaded ? null : onDownloadSurah,
              );
            },
          ),
          if (!surahDownloaded)
            _OptionRow(
              leading: DesignIcon(
                ayahDownloading
                    ? 'download'
                    : ayahDownloaded
                    ? 'trash'
                    : 'plus',
              ),
              title: ayahDownloading
                  ? l.downloadingCurrentAyah
                  : ayahDownloaded
                  ? l.deleteCurrentAyahAudio
                  : l.downloadCurrentAyah,
              value: ayahSubtitle,
              stacked: true,
              showChevron: false,
              onTap: ayahDownloading ? null : onToggleAyah,
            ),
        ],
      ),
    ];

    return RedesignPageTypography(
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: <Widget>[
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.hair2,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          _Reveal(
            index: 0,
            reduceMotion: reduceMotion,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.playbackOptions,
                    style: redesignDisplayStyle(context, size: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.customizeRecitationBehavior,
                    style: TextStyle(fontSize: 14, color: tokens.muted),
                  ),
                ],
              ),
            ),
          ),
          for (int i = 0; i < sections.length; i++)
            _Reveal(
              index: i + 1,
              reduceMotion: reduceMotion,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: sections[i],
              ),
            ),
          _Reveal(
            index: sections.length + 1,
            reduceMotion: reduceMotion,
            child: Center(
              // Read the theme from inside the typography scope.
              child: Builder(
                builder: (context) => TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  label: Text(l.resetPlaybackOptions),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    minimumSize: const Size(44, 44),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts a section in once, staggered by its position. Skipped when
/// the platform asks for reduced motion.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.index,
    required this.reduceMotion,
    required this.child,
  });

  final int index;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    final int delay = (index * 55).clamp(0, 440);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay),
      curve: Interval(delay / (380 + delay), 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: EyebrowLabel(title),
        ),
        HairlineCard(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: tokens.hair),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.leading,
    required this.title,
    required this.value,
    required this.onTap,
    this.showChevron = true,
    this.stacked = false,
  });

  final Widget leading;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool showChevron;

  /// Shows [value] as a second line under the title rather than at the end.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final bool enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.emWash,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: IconTheme(
                  data: IconThemeData(color: tokens.emText, size: 20),
                  child: leading,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: enabled
                                  ? colors.textPrimary
                                  : tokens.text2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.3,
                              color: tokens.muted,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
              ),
              if (!stacked) ...<Widget>[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 13.5, color: tokens.muted),
                  ),
                ),
              ],
              if (showChevron) ...<Widget>[
                const SizedBox(width: 6),
                DesignIcon(
                  'chev',
                  size: 18,
                  strokeWidth: 1.8,
                  color: tokens.muted,
                  mirrorInRtl: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadRing extends StatelessWidget {
  const _DownloadRing({required this.fraction});

  final double? fraction;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final bool determinate = fraction != null && fraction! > 0;
    return SizedBox.square(
      dimension: 24,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            strokeWidth: 2.4,
            value: determinate ? fraction : null,
            color: tokens.emText,
            backgroundColor: tokens.hair2,
          ),
          if (determinate)
            Text(
              '${(fraction! * 100).round()}',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: tokens.emText,
              ),
            ),
        ],
      ),
    );
  }
}

class _SpeedBlock extends StatelessWidget {
  const _SpeedBlock({
    required this.title,
    required this.rate,
    required this.onSelected,
  });

  final String title;
  final double rate;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: DisplayNumeral(
                  playbackSpeedLabel(rate),
                  key: ValueKey<double>(rate),
                  size: 24,
                  color: tokens.emText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < playbackSpeedSteps.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _SpeedChip(
                      value: playbackSpeedSteps[i],
                      selected: (playbackSpeedSteps[i] - rate).abs() < 0.01,
                      onTap: () => onSelected(playbackSpeedSteps[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final double value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Semantics(
      button: true,
      selected: selected,
      label: playbackSpeedLabel(value),
      excludeSemantics: true,
      child: PressableScale(
        pressedScale: 0.94,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? tokens.filled : Colors.transparent,
              borderRadius: BorderRadius.circular(EquranRadii.medium),
              border: Border.all(
                color: selected ? tokens.filled : tokens.hair2,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  playbackSpeedLabel(value),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : colors.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DelayBlock extends StatelessWidget {
  const _DelayBlock({
    required this.title,
    required this.labels,
    required this.index,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String title;
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final int last = labels.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Container(
                  key: ValueKey<int>(index),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.emWash,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    labels[index.clamp(0, last)],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.emText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: AppSliderTheme.player(context),
            child: Slider(
              min: 0,
              max: last.toDouble(),
              divisions: last,
              value: index.clamp(0, last).toDouble(),
              label: labels[index.clamp(0, last)],
              onChanged: (double v) => onChanged(v.round()),
              onChangeEnd: (double v) => onChangeEnd(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
