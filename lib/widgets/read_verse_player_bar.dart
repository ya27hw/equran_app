import 'dart:math';
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/app_slider_theme.dart';
import 'package:equran/utils/number_formatting.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/common/pressable_scale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReadVersePlayerBar extends StatelessWidget {
  const ReadVersePlayerBar({
    super.key,
    required this.viewMode,
    required this.isMounted,
    required this.isVisible,
    required this.isMinimized,
    required this.isMinimizedSettled,
    required this.isDragging,
    required this.isPlaying,
    required this.isLoading,
    required this.continuousPlayback,
    required this.repeatIntervalEnabled,
    required this.collapseProgress,
    required this.currentChapter,
    required this.currentVerse,
    required this.totalVerses,
    required this.playingVerse,
    required this.positionListenable,
    required this.durationListenable,
    required this.onHidden,
    required this.onMinimizedSettled,
    required this.onExpand,
    required this.onDismiss,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onVerticalDragCancel,
    required this.onSeekStart,
    required this.onSeek,
    required this.onSeekEnd,
    required this.onTogglePlayPause,
    required this.onContinuousPlaybackChanged,
    required this.onRepeatIntervalPressed,
    required this.onAdvancedOptionsPressed,
    required this.onPlayPrevious,
    required this.onPlayNext,
    this.canPlayPrevious = true,
    this.canPlayNext = true,
    this.isDownloaded = false,
  });

  final bool viewMode;
  final bool isMounted;
  final bool isVisible;
  final bool isMinimized;
  final bool isMinimizedSettled;
  final bool isDragging;
  final bool isPlaying;
  final bool isLoading;
  final bool continuousPlayback;
  final bool repeatIntervalEnabled;
  final double collapseProgress;
  final int currentChapter;
  final int currentVerse;
  final int totalVerses;
  final int? playingVerse;
  final ValueListenable<Duration> positionListenable;
  final ValueListenable<Duration> durationListenable;
  final VoidCallback onHidden;
  final VoidCallback onMinimizedSettled;
  final VoidCallback onExpand;
  final VoidCallback onDismiss;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final VoidCallback onVerticalDragCancel;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSeekEnd;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<bool> onContinuousPlaybackChanged;
  final VoidCallback onRepeatIntervalPressed;
  final VoidCallback onAdvancedOptionsPressed;
  final VoidCallback onPlayPrevious;
  final VoidCallback onPlayNext;
  final bool canPlayPrevious;
  final bool canPlayNext;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    if (!isMounted) return const SizedBox.shrink();

    final double width = MediaQuery.sizeOf(context).width;
    final Widget barBody = isMinimizedSettled
        ? _buildMorphingBar(
            context,
            width,
            collapseProgress: 1,
            position: Duration.zero,
            duration: Duration.zero,
          )
        : ValueListenableBuilder<Duration>(
            valueListenable: positionListenable,
            builder: (context, position, _) {
              return ValueListenableBuilder<Duration>(
                valueListenable: durationListenable,
                builder: (context, duration, _) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: collapseProgress),
                    duration: isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    onEnd: () {
                      if (isMinimized && collapseProgress >= 1) {
                        onMinimizedSettled();
                      }
                    },
                    builder: (context, animatedCollapseProgress, _) {
                      return _buildMorphingBar(
                        context,
                        width,
                        collapseProgress: animatedCollapseProgress,
                        position: position,
                        duration: duration,
                      );
                    },
                  );
                },
              );
            },
          );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: isMinimized ? onExpand : null,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      onVerticalDragCancel: onVerticalDragCancel,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 1.15),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        onEnd: () {
          if (!isVisible) {
            onHidden();
          }
        },
        child: AnimatedOpacity(
          opacity: isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: barBody,
        ),
      ),
    );
  }

  Widget _buildMorphingBar(
    BuildContext context,
    double width, {
    required double collapseProgress,
    required Duration position,
    required Duration duration,
  }) {
    final double expandedInset = width < 900
        ? _compactHorizontalInset(width)
        : _widescreenHorizontalInset(width);
    final double minimizedInset = _minimizedHorizontalInset(width);
    final double horizontalInset = lerpDouble(
      expandedInset,
      minimizedInset,
      collapseProgress,
    )!;
    final double bottomInset = lerpDouble(
      width < 900 ? 10 : 12,
      13,
      collapseProgress,
    )!;
    final double verticalPadding = lerpDouble(
      width < 900 ? 16 : 18,
      10,
      collapseProgress,
    )!;
    final double horizontalPadding = lerpDouble(
      width < 900 ? 14 : 24,
      14,
      collapseProgress,
    )!;
    final double expandedHeight = _expandedBarHeight(
      width,
      MediaQuery.textScalerOf(context).scale(1),
    );
    final double minimizedHeight = _minimizedBarHeight;
    final double barHeight = lerpDouble(
      expandedHeight,
      minimizedHeight,
      collapseProgress,
    )!;
    final double shellHeightFactor = (barHeight / expandedHeight).clamp(
      0.0,
      1.0,
    );
    final bool renderExpandedBody = collapseProgress < 0.995;
    final bool renderMinimizedBody = collapseProgress > 0.005;
    final Widget expandedBody = !renderExpandedBody
        ? const SizedBox.shrink()
        : width < 900
        ? _buildCompactBody(context, position: position, duration: duration)
        : _buildWidescreenBody(
            context,
            width,
            position: position,
            duration: duration,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        bottomInset,
      ),
      child: _buildFrostedSurface(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: SafeArea(
          top: false,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: shellHeightFactor,
              child: SizedBox(
                height: expandedHeight,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: expandedHeight,
                      child: IgnorePointer(
                        ignoring: collapseProgress > 0.12,
                        child: Opacity(
                          opacity: (1 - collapseProgress).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(
                                0,
                                expandedHeight - minimizedHeight,
                                collapseProgress,
                              )!,
                            ),
                            child: Transform.scale(
                              scale: lerpDouble(1, 0.985, collapseProgress)!,
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: double.infinity,
                                height: expandedHeight,
                                child: expandedBody,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: minimizedHeight,
                      child: IgnorePointer(
                        ignoring: collapseProgress < 0.88,
                        child: Opacity(
                          opacity: collapseProgress.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(20, 0, collapseProgress)!,
                            ),
                            child: Transform.scale(
                              scale: lerpDouble(0.985, 1, collapseProgress)!,
                              alignment: Alignment.bottomCenter,
                              child: renderMinimizedBody
                                  ? _buildMinimizedBody(context)
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedBody(BuildContext context) {
    return ReadPlayerMiniContent(
      chapter: currentChapter,
      verse: playingVerse ?? currentVerse,
      isPlaying: isPlaying,
      isLoading: isLoading,
      isDownloaded: isDownloaded,
      onTogglePlayPause: onTogglePlayPause,
      onExpand: onExpand,
      onDismiss: onDismiss,
    );
  }

  Widget _buildCompactBody(
    BuildContext context, {
    required Duration position,
    required Duration duration,
  }) {
    final EquranTokens tokens = context.equranTokens;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _TrackTitle(
                    chapter: currentChapter,
                    verse: playingVerse ?? currentVerse,
                    isDownloaded: isDownloaded,
                  ),
                ),
                _buildOptionsButton(context),
              ],
            ),
            const SizedBox(height: 2),
            _buildSeekRow(context, position: position, duration: duration),
            const SizedBox(height: 4),
            _buildSharedControls(context, playSize: 58, spread: true),
          ],
        ),
        Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.hair2,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsButton(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.playbackOptions,
      onPressed: onAdvancedOptionsPressed,
      icon: const Icon(Icons.tune_rounded),
      iconSize: 22,
      color: context.equranTokens.text2,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        minimumSize: const Size.square(44),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSeekRow(
    BuildContext context, {
    required Duration position,
    required Duration duration,
  }) {
    final EquranTokens tokens = context.equranTokens;
    final double progress = _durationProgress(position, duration);
    final bool seekable = duration.inMilliseconds > 0;
    final TextStyle timeStyle = TextStyle(
      fontFamily: _uiFamily(context),
      fontSize: 12,
      height: 1,
      color: tokens.muted,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SliderTheme(
          data: AppSliderTheme.player(context),
          child: Slider(
            value: progress,
            onChanged: seekable ? onSeek : null,
            onChangeStart: seekable ? onSeekStart : null,
            onChangeEnd: seekable ? onSeekEnd : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(formatDurationLabel(position), style: timeStyle),
              Text(formatDurationLabel(duration), style: timeStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWidescreenBody(
    BuildContext context,
    double width, {
    required Duration position,
    required Duration duration,
  }) {
    final EquranTokens tokens = context.equranTokens;
    final bool compactWidescreenLayout = width < 1100;
    final double centerGap = compactWidescreenLayout ? 96 : 220;
    final double centerWidth = min(
      compactWidescreenLayout ? 500.0 : 640.0,
      max(compactWidescreenLayout ? 460.0 : 320.0, width - 620),
    );
    final double titleWidth = max(80, (width - centerWidth) / 2 - 56);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: width >= 1500 ? 132 : 124),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: titleWidth),
                    child: _TrackTitle(
                      chapter: currentChapter,
                      verse: playingVerse ?? currentVerse,
                      isDownloaded: isDownloaded,
                      large: true,
                    ),
                  ),
                ),
              ),
              SizedBox(width: centerGap),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildOptionsButton(context),
                      IconButton(
                        tooltip: AppLocalizations.of(context)!.dismissPlayer,
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close_rounded),
                        iconSize: 22,
                        color: tokens.text2,
                        style: IconButton.styleFrom(
                          fixedSize: const Size.square(44),
                          minimumSize: const Size.square(44),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: centerWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildSharedControls(context, playSize: 62, gap: 14),
                  const SizedBox(height: 14),
                  _buildSeekRow(
                    context,
                    position: position,
                    duration: duration,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The transport row stays left-to-right in every locale.
  Widget _buildSharedControls(
    BuildContext context, {
    required double playSize,
    bool spread = false,
    double gap = 4,
  }) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool autoActive = continuousPlayback && !repeatIntervalEnabled;
    final List<Widget> children = <Widget>[
      _ModeToggle(
        tooltip: l.autoPlayback,
        icon: Icons.playlist_play_rounded,
        active: autoActive,
        onPressed: () => onContinuousPlaybackChanged(!autoActive),
      ),
      _SkipButton(
        icon: Icons.skip_previous_rounded,
        tooltip: l.previousAyah,
        onPressed: canPlayPrevious ? onPlayPrevious : null,
      ),
      PlayPauseButton(
        size: playSize,
        isPlaying: isPlaying,
        isLoading: isLoading,
        playTooltip: l.play,
        pauseTooltip: l.pause,
        loadingTooltip: l.unableToReconnect,
        onPressed: onTogglePlayPause,
      ),
      _SkipButton(
        icon: Icons.skip_next_rounded,
        tooltip: l.nextAyah,
        onPressed: canPlayNext ? onPlayNext : null,
      ),
      _ModeToggle(
        tooltip: l.repeatInterval,
        icon: Icons.all_inclusive_rounded,
        active: repeatIntervalEnabled,
        onPressed: onRepeatIntervalPressed,
      ),
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: spread
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        mainAxisSize: spread ? MainAxisSize.max : MainAxisSize.min,
        children: spread
            ? children
            : <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0) SizedBox(width: gap),
                  children[i],
                ],
              ],
      ),
    );
  }

  Widget _buildFrostedSurface({
    required EdgeInsetsGeometry padding,
    required Widget child,
    double borderRadius = _barRadius,
  }) {
    // The surface is ~94% opaque, so the blur is subtle but forces an
    // offscreen pass every frame; skip it on low-end devices.
    return Builder(
      builder: (BuildContext context) {
        final Widget surface = Container(
          padding: padding,
          decoration: readPlayerSurfaceDecoration(
            context,
            radius: borderRadius,
          ),
          child: child,
        );
        final bool blur =
            DeviceCapabilityService.instance.profile.allowsDecorativeEffects;
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: blur
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: surface,
                )
              : surface,
        );
      },
    );
  }

  double _compactHorizontalInset(double width) {
    return viewMode ? _readCardHorizontalInset(width) : 9;
  }

  double _widescreenHorizontalInset(double width) {
    return viewMode ? _readCardHorizontalInset(width) : 12;
  }

  double _minimizedHorizontalInset(double width) {
    return viewMode ? _readCardHorizontalInset(width) : (width > 700 ? 16 : 8);
  }

  double _readCardHorizontalInset(double width) {
    if (width > 1200) return 120;
    if (width > 700) return 40;
    return 6;
  }

  /// Grows with text scale; the reading page reserves 260 px above the bar.
  double _expandedBarHeight(double width, double textScale) {
    if (width < 900) return 164 + 40 * (textScale.clamp(1.0, 1.5) - 1);
    return width >= 1500 ? 148 : 142;
  }

  double get _minimizedBarHeight => 45;

  double _durationProgress(Duration position, Duration duration) {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

const double _barRadius = 22;

String _uiFamily(BuildContext context) =>
    const <String>[
      'ar',
      'fa',
      'ur',
    ].contains(Localizations.localeOf(context).languageCode)
    ? 'NotoNaskhArabic'
    : 'Inter';

/// The player's surface, shared by the expanded bar, the morphing minimized
/// bar and the static minimized bar so they never drift apart.
BoxDecoration readPlayerSurfaceDecoration(
  BuildContext context, {
  double radius = _barRadius,
}) {
  final EquranColors colors = context.equranColors;
  final EquranTokens tokens = context.equranTokens;
  return BoxDecoration(
    color: colors.surface.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: tokens.hair2),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: tokens.shadow,
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class _TrackTitle extends StatelessWidget {
  const _TrackTitle({
    required this.chapter,
    required this.verse,
    required this.isDownloaded,
    this.large = false,
  });

  final int chapter;
  final int verse;
  final bool isDownloaded;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final bool arabic = const <String>[
      'ar',
      'fa',
      'ur',
    ].contains(l.localeName.split('_').first);
    final TextStyle title = EquranTextStyles.displayNumeral(
      context,
      size: large ? 24 : 20,
      height: 1.1,
      color: colors.textPrimary,
    ).copyWith(fontFamilyFallback: const <String>['NotoNaskhArabic']);
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            localizedSurahName(l, chapter),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: arabic
                ? title.copyWith(fontFamily: 'NotoNaskhArabic', height: 1.4)
                : title,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  localizedAyahReference(l, verse),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _uiFamily(context),
                    fontSize: 12.5,
                    height: 1.2,
                    color: tokens.muted,
                  ),
                ),
              ),
              if (isDownloaded) ...<Widget>[
                const SizedBox(width: 6),
                Icon(Icons.offline_pin_rounded, size: 14, color: tokens.emText),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A toggle that fills with the emerald wash when on.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Semantics(
      button: true,
      toggled: active,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: PressableScale(
          pressedScale: 0.92,
          child: InkResponse(
            onTap: onPressed,
            radius: 26,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? tokens.emWash : Colors.transparent,
                border: Border.all(
                  color: active
                      ? tokens.emText.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 22,
                color: active ? tokens.emText : tokens.text2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.9,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 32,
        color: context.equranColors.textPrimary,
        disabledColor: context.equranTokens.muted.withValues(alpha: 0.5),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(46),
          minimumSize: const Size.square(46),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// The filled play button. The glyph morphs between play and pause only when
/// the state changes; nothing animates while it sits still.
class PlayPauseButton extends StatefulWidget {
  const PlayPauseButton({
    super.key,
    required this.size,
    required this.isPlaying,
    required this.isLoading,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.loadingTooltip,
    required this.onPressed,
  });

  final double size;
  final bool isPlaying;
  final bool isLoading;
  final String playTooltip;
  final String pauseTooltip;
  final String loadingTooltip;
  final VoidCallback onPressed;

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph;

  @override
  void initState() {
    super.initState();
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.isPlaying ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying == widget.isPlaying) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _morph.value = widget.isPlaying ? 1 : 0;
    } else if (widget.isPlaying) {
      _morph.forward();
    } else {
      _morph.reverse();
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final Color glyph = Colors.white;
    final String tooltip = widget.isLoading
        ? widget.loadingTooltip
        : widget.isPlaying
        ? widget.pauseTooltip
        : widget.playTooltip;
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: PressableScale(
          pressedScale: 0.93,
          child: Material(
            color: tokens.filled,
            shape: const CircleBorder(),
            elevation: 0,
            shadowColor: tokens.filled,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: tokens.filled.withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.size * 0.4,
                        height: widget.size * 0.4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: glyph,
                        ),
                      )
                    : AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: _morph,
                        size: widget.size * 0.5,
                        color: glyph,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything the collapsed bar shows. Stateless and listenable-free, so the
/// settled minimized bar stays as cheap as before.
class ReadPlayerMiniContent extends StatelessWidget {
  const ReadPlayerMiniContent({
    super.key,
    required this.chapter,
    required this.verse,
    required this.isPlaying,
    required this.isLoading,
    required this.isDownloaded,
    required this.onTogglePlayPause,
    required this.onExpand,
    required this.onDismiss,
  });

  final int chapter;
  final int verse;
  final bool isPlaying;
  final bool isLoading;
  final bool isDownloaded;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onExpand;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final String playTooltip = isLoading
        ? l.unableToReconnect
        : isPlaying
        ? l.pause
        : l.play;
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: playTooltip,
          excludeSemantics: true,
          child: Tooltip(
            message: playTooltip,
            child: Material(
              color: tokens.filled,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isLoading ? null : onTogglePlayPause,
                child: SizedBox.square(
                  dimension: 38,
                  child: Center(
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(EquranRadii.large),
            onTap: onExpand,
            child: SizedBox(
              height: double.infinity,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        localizedSurahAyahLabel(l, chapter, verse),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _uiFamily(context),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (isDownloaded) ...<Widget>[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.offline_pin_rounded,
                        size: 15,
                        color: isPlaying
                            ? tokens.emText
                            : tokens.muted.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l.dismissPlayer,
          onPressed: onDismiss,
          icon: const Icon(Icons.close_rounded),
          iconSize: 20,
          color: tokens.text2,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// The settled minimized bar, surface included. [ReadVersePlayerBar] uses the
/// same content while it morphs.
class ReadPlayerMiniBar extends StatelessWidget {
  const ReadPlayerMiniBar({
    super.key,
    required this.horizontalInset,
    required this.content,
  });

  final double horizontalInset;
  final ReadPlayerMiniContent content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, 13),
      child: DecoratedBox(
        decoration: readPlayerSurfaceDecoration(context),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 65,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
