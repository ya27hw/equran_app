import 'dart:math';
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/app_slider_theme.dart';
import 'package:equran/utils/number_formatting.dart';
import 'package:equran/utils/quran_display.dart';
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
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
    final double expandedHeight = _expandedBarHeight(width);
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
        colorScheme: colorScheme,
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
                                  ? _buildMinimizedBody(
                                      context,
                                      theme,
                                      colorScheme,
                                    )
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

  Widget _buildMinimizedBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final int verse = playingVerse ?? currentVerse;
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: isLoading
                ? localizations.unableToReconnect
                : isPlaying
                ? localizations.pause
                : localizations.play,
            onPressed: isLoading ? null : onTogglePlayPause,
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
            color: colorScheme.primary,
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.large),
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
                          localizedSurahAyahLabel(
                            localizations,
                            currentChapter,
                            verse,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isDownloaded) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.offline_pin_rounded,
                          size: 15,
                          color: isPlaying
                              ? Colors.green
                              : colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: localizations.dismissPlayer,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBody(
    BuildContext context, {
    required Duration position,
    required Duration duration,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final double progress = _durationProgress(position, duration);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SliderTheme(
                data: AppSliderTheme.standard(context),
                child: Slider(
                  value: progress,
                  onChanged: duration.inMilliseconds <= 0 ? null : onSeek,
                  onChangeStart: duration.inMilliseconds <= 0
                      ? null
                      : onSeekStart,
                  onChangeEnd: duration.inMilliseconds <= 0 ? null : onSeekEnd,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    formatDurationLabel(position),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatDurationLabel(duration),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSharedControls(context, colorScheme, spacing: 4),
            ],
          ),
        ),
        Positioned(
          top: -8,
          left: 0,
          right: 0,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 40),
              Expanded(
                child: Center(
                  child: Container(
                    width: 34,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withAlpha(140),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.playbackOptions,
                onPressed: onAdvancedOptionsPressed,
                icon: const Icon(Icons.more_horiz_rounded),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
              ),
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final double progress = _durationProgress(position, duration);
    final bool compactWidescreenLayout = width < 1100;
    final double centerGap = compactWidescreenLayout ? 96 : 220;
    final double centerWidth = min(
      compactWidescreenLayout ? 500.0 : 640.0,
      max(compactWidescreenLayout ? 460.0 : 320.0, width - 620),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: width >= 1500 ? 132 : 124),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Expanded(child: SizedBox.shrink()),
              SizedBox(width: centerGap),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: AppLocalizations.of(context)!.playbackOptions,
                        onPressed: onAdvancedOptionsPressed,
                        icon: const Icon(Icons.more_horiz_rounded, size: 28),
                        color: colorScheme.onSurfaceVariant,
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context)!.dismissPlayer,
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close_rounded, size: 28),
                        color: colorScheme.onSurfaceVariant,
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
                  _buildSharedControls(context, colorScheme, spacing: 12),
                  const SizedBox(height: 25),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 64,
                        child: Text(
                          formatDurationLabel(position),
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: AppSliderTheme.standard(context),
                          child: Slider(
                            value: progress,
                            onChanged: duration.inMilliseconds <= 0
                                ? null
                                : onSeek,
                            onChangeStart: duration.inMilliseconds <= 0
                                ? null
                                : onSeekStart,
                            onChangeEnd: duration.inMilliseconds <= 0
                                ? null
                                : onSeekEnd,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          formatDurationLabel(duration),
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedControls(
    BuildContext context,
    ColorScheme colorScheme, {
    required double spacing,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildAutoPlaybackButton(context, colorScheme),
          SizedBox(width: spacing),
          _buildAyahNavButton(
            icon: Icons.skip_previous_rounded,
            tooltip: AppLocalizations.of(context)!.previousAyah,
            onPressed: canPlayPrevious ? onPlayPrevious : null,
          ),
          SizedBox(width: spacing),
          FilledButton.tonal(
            onPressed: onTogglePlayPause,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: isLoading
                ? SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 30,
                  ),
          ),
          SizedBox(width: spacing),
          _buildAyahNavButton(
            icon: Icons.skip_next_rounded,
            tooltip: AppLocalizations.of(context)!.nextAyah,
            onPressed: canPlayNext ? onPlayNext : null,
          ),
          SizedBox(width: spacing),
          _buildRepeatIntervalButton(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildAutoPlaybackButton(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final bool isActive = continuousPlayback && !repeatIntervalEnabled;

    return _buildModeButton(
      tooltip: AppLocalizations.of(context)!.autoPlayback,
      icon: Icons.playlist_play_rounded,
      isActive: isActive,
      colorScheme: colorScheme,
      onPressed: () => onContinuousPlaybackChanged(!isActive),
      underlineOffsetX: -1,
    );
  }

  Widget _buildAyahNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 30,
    );
  }

  Widget _buildRepeatIntervalButton(
    BuildContext context,
    ColorScheme colorScheme, {
    IconData icon = Icons.all_inclusive_rounded,
    double? iconSize,
  }) {
    return _buildModeButton(
      tooltip: AppLocalizations.of(context)!.repeatInterval,
      icon: icon,
      iconSize: iconSize,
      isActive: repeatIntervalEnabled,
      colorScheme: colorScheme,
      onPressed: onRepeatIntervalPressed,
    );
  }

  Widget _buildModeButton({
    required String tooltip,
    required IconData icon,
    required bool isActive,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
    double? iconSize,
    double underlineOffsetX = 0,
  }) {
    final Color activeColor = colorScheme.primary;
    final Color inactiveColor = colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              Transform.translate(
                offset: Offset(underlineOffsetX, 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 18,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedSurface({
    required ColorScheme colorScheme,
    required EdgeInsetsGeometry padding,
    required Widget child,
    double borderRadius = AppRadii.large,
  }) {
    final Widget surface = Container(
      padding: padding,
      decoration: _decoration(
        colorScheme,
      ).copyWith(borderRadius: BorderRadius.circular(borderRadius)),
      child: child,
    );
    // The surface is ~92% opaque, so the blur is subtle but forces an
    // offscreen pass every frame; skip it on low-end devices.
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
  }

  BoxDecoration _decoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: Color.alphaBlend(
        colorScheme.primary.withAlpha(10),
        colorScheme.surfaceContainerLow.withAlpha((0.92 * 255).round()),
      ),
      borderRadius: BorderRadius.circular(AppRadii.large),
      border: Border.all(
        color: colorScheme.outlineVariant.withAlpha((0.52 * 255).round()),
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withAlpha((0.12 * 255).round()),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
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

  double _expandedBarHeight(double width) {
    if (width < 900) return 146;
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
