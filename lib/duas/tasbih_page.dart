import 'dart:async';
import 'dart:math' as math;

import 'package:equran/backend/library.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart'
    show IconButton44, RedesignSubpage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:hive/hive.dart';

const String _postPrayerDhikrStorageLabel = 'Post-prayer dhikr';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  static const String _selectedPresetKey = 'tasbih.selectedPreset';
  static const String _currentCountKey = 'tasbih.currentCount';
  static const String _hapticsKey = 'tasbih.hapticsEnabled';
  static const Duration _completionInputLockDuration = Duration(seconds: 1);

  int _selectedPresetIndex = 0;
  int _count = 0;
  bool _hapticsEnabled = true;
  DateTime _sessionStartedAt = DateTime.now();
  DateTime? _postPrayerSequenceStartedAt;
  final List<int> _postPrayerSequenceCounts = <int>[0, 0, 0];
  int _liveUnsavedCountToday = 0;
  int _liveUnsavedRoundsToday = 0;
  String? _completionMessage;
  bool _completionPulse = false;
  bool _completionInputLocked = false;

  _DhikrPreset get _selectedPreset =>
      _DhikrPreset.presets[_selectedPresetIndex];

  @override
  void initState() {
    super.initState();
    final dynamic savedIndex = SettingsDB().get(
      _selectedPresetKey,
      defaultValue: 0,
    );
    final dynamic savedCount = SettingsDB().get(
      _currentCountKey,
      defaultValue: 0,
    );
    _selectedPresetIndex = savedIndex is int
        ? savedIndex.clamp(0, _DhikrPreset.presets.length - 1).toInt()
        : 0;
    _count = savedCount is int ? savedCount.clamp(0, 100000).toInt() : 0;
    _liveUnsavedCountToday = _count;
    _hapticsEnabled = SettingsDB().get(_hapticsKey, defaultValue: true) == true;
  }

  @override
  Widget build(BuildContext context) {
    return RedesignSubpage(
      title: AppLocalizations.of(context)!.tasbih,
      actions: <Widget>[
        IconButton44(
          icon: Icons.refresh_rounded,
          tooltip: AppLocalizations.of(context)!.resetCounter,
          onPressed: _completionInputLocked ? null : _reset,
        ),
      ],
      child: ValueListenableBuilder<Box<dynamic>>(
        valueListenable: DhikrSessionsDB().listener,
        builder: (context, box, child) {
          final List<DhikrSessionEntry> sessions =
              box.values.whereType<DhikrSessionEntry>().toList(growable: false)
                ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          final _TasbihStats stats = _TasbihStats.fromSessions(
            sessions,
            currentCount: 0,
            currentStartedAt: _sessionStartedAt,
            liveUnsavedCount: _liveUnsavedCountToday,
            liveUnsavedRounds: _liveUnsavedRoundsToday,
          );

          final double screenHeight = MediaQuery.sizeOf(context).height;
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              EquranSpacing.pagePadding,
              8,
              EquranSpacing.pagePadding,
              32,
            ),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _TasbihStatsRow(stats: stats),
                      const SizedBox(height: 14),
                      _PresetSelector(
                        selectedIndex: _selectedPresetIndex,
                        onPrevious: _selectPreviousPreset,
                        onNext: _selectNextPreset,
                        enabled: !_completionInputLocked,
                      ),
                      const SizedBox(height: 18),
                      _CircularCounter(
                        preset: _selectedPreset,
                        count: _count,
                        targetHeight: screenHeight * 0.55,
                        pulse: _completionPulse,
                        enabled: !_completionInputLocked,
                        onTap: _increment,
                      ),
                      const SizedBox(height: 14),
                      _DhikrCaption(
                        preset: _selectedPreset,
                        nextPreset: _DhikrPreset
                            .presets[_nextPresetIndex(_selectedPresetIndex)],
                        completionMessage: _completionMessage,
                      ),
                      const SizedBox(height: 32),
                      _HapticsRow(
                        hapticsEnabled: _hapticsEnabled,
                        onHapticsChanged: _setHapticsEnabled,
                      ),
                      const SizedBox(height: 22),
                      TextButton(
                        onPressed: () => _showRecentSessionsSheet(sessions),
                        child: Text(
                          AppLocalizations.of(context)!.recentSessions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _increment() async {
    if (_completionInputLocked || _count >= _selectedPreset.target) return;

    final _DhikrPreset preset = _selectedPreset;
    final int sequenceIndex = _selectedPresetIndex;
    final int nextCount = _count + 1;
    final bool completesPreset = nextCount >= preset.target;
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
    setState(() {
      _count = nextCount;
      _liveUnsavedCountToday += 1;
      if (completesPreset) {
        _completionInputLocked = true;
        _completionPulse = true;
        final AppLocalizations localizations = AppLocalizations.of(context)!;
        _completionMessage = localizations.dhikrComplete(
          preset.localizedLabel(localizations),
        );
      }
    });
    _persistCurrentState();

    if (completesPreset) {
      await _completePreset(preset, nextCount, sequenceIndex: sequenceIndex);
    }
  }

  Future<void> _completePreset(
    _DhikrPreset preset,
    int completedCount, {
    required int sequenceIndex,
  }) async {
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.heavyImpact());
    }
    final bool groupedCompletion = await _recordCompletedPreset(
      preset,
      completedCount,
      sequenceIndex: sequenceIndex,
    );
    if (!mounted) return;

    setState(() {
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      _completionMessage = groupedCompletion
          ? localizations.postPrayerDhikrComplete
          : localizations.dhikrComplete(preset.localizedLabel(localizations));
      _completionPulse = true;
    });

    await Future<void>.delayed(_completionInputLockDuration);
    if (!mounted) return;

    final int nextIndex = _nextPresetIndex(sequenceIndex);
    setState(() {
      _selectedPresetIndex = nextIndex;
      _count = 0;
      _sessionStartedAt = DateTime.now();
      _completionPulse = false;
      _completionInputLocked = false;
    });
    _persistCurrentState();

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _completionMessage = null;
        });
      }),
    );
  }

  int _nextPresetIndex(int currentIndex) {
    if (currentIndex >= 0 && currentIndex < 2) return currentIndex + 1;
    if (currentIndex == 2) return 0;
    return currentIndex;
  }

  void _reset() {
    setState(() {
      _count = 0;
      _sessionStartedAt = DateTime.now();
      _resetPostPrayerSequence();
      _liveUnsavedCountToday = 0;
      _liveUnsavedRoundsToday = 0;
      _completionMessage = null;
      _completionInputLocked = false;
      _completionPulse = false;
    });
    _persistCurrentState();
  }

  void _selectPreviousPreset() {
    final int nextIndex =
        (_selectedPresetIndex - 1 + _DhikrPreset.presets.length) %
        _DhikrPreset.presets.length;
    _selectPreset(nextIndex);
  }

  void _selectNextPreset() {
    final int nextIndex =
        (_selectedPresetIndex + 1) % _DhikrPreset.presets.length;
    _selectPreset(nextIndex);
  }

  void _showRecentSessionsSheet(List<DhikrSessionEntry> sessions) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _RecentDhikrSessionsSheet(
        sessions: sessions.take(12).toList(growable: false),
      ),
    );
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      _count = 0;
      _sessionStartedAt = DateTime.now();
      _liveUnsavedCountToday = 0;
      _liveUnsavedRoundsToday = 0;
      if (index < 0 || index > 2) {
        _resetPostPrayerSequence();
      }
      _completionMessage = null;
      _completionInputLocked = false;
      _completionPulse = false;
    });
    _persistCurrentState();
  }

  Future<void> _setHapticsEnabled(bool enabled) async {
    setState(() {
      _hapticsEnabled = enabled;
    });
    await SettingsDB().put(_hapticsKey, enabled);
  }

  Future<void> _saveSession({required bool manual, int? completedCount}) async {
    final int count = completedCount ?? _count;
    if (count <= 0) {
      if (!manual || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.countSomeDhikrFirst),
        ),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final _DhikrPreset preset = _selectedPreset;
    final bool completed = count >= preset.target;
    final DhikrSessionEntry session = DhikrSessionEntry(
      id: 'dhikr:${now.microsecondsSinceEpoch}',
      label: preset.label,
      targetCount: preset.target,
      count: count,
      startedAt: _sessionStartedAt,
      completedAt: completed ? now : null,
    );
    await DhikrSessionsDB().put(session.id, session);
    if (!manual || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.dhikrSessionSaved)),
    );
  }

  Future<bool> _recordCompletedPreset(
    _DhikrPreset preset,
    int completedCount, {
    required int sequenceIndex,
  }) async {
    if (!_isPostPrayerSequenceIndex(sequenceIndex)) {
      _liveUnsavedCountToday = 0;
      await _saveSession(manual: false, completedCount: completedCount);
      return false;
    }

    _postPrayerSequenceStartedAt ??= _sessionStartedAt;
    _postPrayerSequenceCounts[sequenceIndex] = completedCount
        .clamp(0, preset.target)
        .toInt();

    final bool sequenceComplete =
        _postPrayerSequenceCounts[0] >= 33 &&
        _postPrayerSequenceCounts[1] >= 33 &&
        _postPrayerSequenceCounts[2] >= 34;
    if (!sequenceComplete) {
      _liveUnsavedRoundsToday += 1;
      return false;
    }

    final DateTime now = DateTime.now();
    final DhikrSessionEntry session = DhikrSessionEntry(
      id: 'dhikr:post-prayer:${now.microsecondsSinceEpoch}',
      label: _postPrayerDhikrStorageLabel,
      targetCount: 100,
      count: 100,
      startedAt: _postPrayerSequenceStartedAt ?? _sessionStartedAt,
      completedAt: now,
    );
    _resetPostPrayerSequence();
    _liveUnsavedCountToday = 0;
    _liveUnsavedRoundsToday = 0;
    await DhikrSessionsDB().put(session.id, session);
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.heavyImpact());
    }
    return true;
  }

  void _resetPostPrayerSequence() {
    _postPrayerSequenceStartedAt = null;
    for (int i = 0; i < _postPrayerSequenceCounts.length; i++) {
      _postPrayerSequenceCounts[i] = 0;
    }
  }

  bool _isPostPrayerSequenceIndex(int index) => index >= 0 && index <= 2;

  void _persistCurrentState() {
    unawaited(SettingsDB().put(_selectedPresetKey, _selectedPresetIndex));
    unawaited(SettingsDB().put(_currentCountKey, _count));
  }
}

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({
    required this.selectedIndex,
    required this.onPrevious,
    required this.onNext,
    required this.enabled,
  });

  final int selectedIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final _DhikrPreset selectedPreset = _DhikrPreset.presets[selectedIndex];
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final BorderRadius radius = BorderRadius.circular(16);

    return Material(
      color: colors.background.withAlpha(0),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: radius,
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 11),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: localizations.previousDhikr,
                    onPressed: enabled ? onPrevious : null,
                    color: colors.textSecondary,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      selectedPreset.localizedLabel(localizations),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: localizations.nextDhikr,
                    onPressed: enabled ? onNext : null,
                    color: colors.textSecondary,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Text(
                localizations.counts33To33To34(selectedPreset.target),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularCounter extends StatefulWidget {
  const _CircularCounter({
    required this.preset,
    required this.count,
    required this.targetHeight,
    required this.pulse,
    required this.enabled,
    required this.onTap,
  });

  final _DhikrPreset preset;
  final int count;
  final double targetHeight;
  final bool pulse;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_CircularCounter> createState() => _CircularCounterState();
}

class _CircularCounterState extends State<_CircularCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _bounceController.forward(from: 0).then((_) {
      if (mounted) _bounceController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final double progress = widget.preset.target <= 0
        ? 0
        : (widget.count / widget.preset.target).clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double circleSize = math
            .min(constraints.maxWidth * 0.72, widget.targetHeight)
            .clamp(220.0, 420.0);
        return SizedBox(
          height: widget.targetHeight.clamp(circleSize, 520.0),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? _handleTap : null,
              child: AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  final double scale =
                      1 - (0.04 * math.sin(_bounceController.value * math.pi));
                  return Transform.scale(scale: scale, child: child);
                },
                child: SizedBox.square(
                  dimension: circleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: widget.pulse ? circleSize : circleSize - 18,
                        height: widget.pulse ? circleSize : circleSize - 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: widget.pulse
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: colors.primarySoft.withAlpha(110),
                                    blurRadius: 34,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedProgress, child) {
                          return CustomPaint(
                            painter: _CounterRingPainter(
                              progress: animatedProgress,
                              trackColor: colors.border,
                              progressColor: colors.primary,
                            ),
                            child: child,
                          );
                        },
                        child: SizedBox.square(
                          dimension: circleSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: circleSize * 0.08,
                                ),
                                child: Text(
                                  widget.preset.arabic,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      TextStyle(
                                        fontFamily:
                                            EquranTextStyles.activeFontFamily,
                                        fontFamilyFallback: const <String>[
                                          'UthmanicHafs',
                                        ],
                                        fontSize: circleSize * 0.2,
                                        height: 1.15,
                                        fontWeight: FontWeight.w400,
                                      ).copyWith(
                                        color: colors.textPrimary.withAlpha(20),
                                      ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    '${widget.count}',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          color: colors.textPrimary,
                                          fontSize: 88,
                                          fontWeight: FontWeight.w700,
                                          height: 0.9,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '/ ${widget.preset.target}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colors.textSecondary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DhikrCaption extends StatelessWidget {
  const _DhikrCaption({
    required this.preset,
    required this.nextPreset,
    required this.completionMessage,
  });

  final _DhikrPreset preset;
  final _DhikrPreset nextPreset;
  final String? completionMessage;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Column(
      children: <Widget>[
        Text(
          preset.localizedLabel(localizations),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          completionMessage ??
              localizations.autoAdvancesToNextPreset(
                nextPreset.localizedLabel(localizations),
              ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: completionMessage == null
                ? colors.textSecondary
                : colors.primarySoft,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HapticsRow extends StatelessWidget {
  const _HapticsRow({
    required this.hapticsEnabled,
    required this.onHapticsChanged,
  });

  final bool hapticsEnabled;
  final ValueChanged<bool> onHapticsChanged;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.vibration_rounded, color: colors.textSecondary, size: 19),
        const SizedBox(width: 7),
        Text(
          AppLocalizations.of(context)!.haptics,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: hapticsEnabled,
          activeThumbColor: colors.primary,
          activeTrackColor: colors.primarySoft.withAlpha(90),
          onChanged: onHapticsChanged,
        ),
      ],
    );
  }
}

class _TasbihStatsRow extends StatelessWidget {
  const _TasbihStatsRow({required this.stats});

  final _TasbihStats stats;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bool arabic = isArabicLocalizations(localizations);
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatsMetricCard(
            label: localizations.todayMetric,
            value: '${stats.totalToday}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatsMetricCard(
            label: localizations.rounds,
            value: '${stats.roundsToday}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatsMetricCard(
            label: localizations.streak,
            value: arabic ? '${stats.streak} يوم' : '${stats.streak}d',
          ),
        ),
      ],
    );
  }
}

class _StatsMetricCard extends StatelessWidget {
  const _StatsMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: radius,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Column(
          children: <Widget>[
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDhikrSessionsSheet extends StatelessWidget {
  const _RecentDhikrSessionsSheet({required this.sessions});

  final List<DhikrSessionEntry> sessions;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final ThemeData theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: <Widget>[
        Text(
          localizations.recentSessions,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (sessions.isEmpty)
          Text(
            localizations.savedDhikrSessionsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          )
        else
          for (final DhikrSessionEntry session in sessions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                session.completedAt == null
                    ? Icons.radio_button_checked_rounded
                    : Icons.check_circle_rounded,
                color: session.completedAt == null
                    ? colors.textMuted
                    : colors.primary,
              ),
              title: Text(
                session.label == _postPrayerDhikrStorageLabel
                    ? localizations.postPrayerDhikr
                    : _localizedDhikrSessionLabel(session.label, localizations),
              ),
              subtitle: Text(
                session.label == _postPrayerDhikrStorageLabel
                    ? '${_postPrayerDhikrSummary(localizations)}\n${_sessionTimeLabel(session, localizations)}'
                    : localizations.dhikrSessionCounted(
                        session.count,
                        session.targetCount,
                        _sessionTimeLabel(session, localizations),
                      ),
              ),
            ),
      ],
    );
  }
}

class _CounterRingPainter extends CustomPainter {
  const _CounterRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2 - 8;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final double sweep = (math.pi * 2) * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CounterRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        trackColor != oldDelegate.trackColor ||
        progressColor != oldDelegate.progressColor;
  }
}

class _TasbihStats {
  const _TasbihStats({
    required this.totalToday,
    required this.roundsToday,
    required this.streak,
  });

  final int totalToday;
  final int roundsToday;
  final int streak;

  static _TasbihStats fromSessions(
    List<DhikrSessionEntry> sessions, {
    required int currentCount,
    required DateTime currentStartedAt,
    required int liveUnsavedCount,
    required int liveUnsavedRounds,
  }) {
    final String today = _dateKey(DateTime.now());
    int totalToday = liveUnsavedCount;
    int roundsToday = liveUnsavedRounds;
    final Set<String> completedDates = <String>{};

    for (final DhikrSessionEntry session in sessions) {
      if (_dateKey(session.startedAt) == today) {
        totalToday += session.count;
      }
      final DateTime? completedAt = session.completedAt;
      if (completedAt != null) {
        completedDates.add(_dateKey(completedAt));
        if (_dateKey(completedAt) == today) {
          roundsToday += session.label == _postPrayerDhikrStorageLabel ? 3 : 1;
        }
      }
    }
    if (_dateKey(currentStartedAt) == today) {
      totalToday += currentCount;
    }

    int streak = 0;
    DateTime cursor = DateTime.now();
    while (completedDates.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return _TasbihStats(
      totalToday: totalToday,
      roundsToday: roundsToday,
      streak: streak,
    );
  }
}

class _DhikrPreset {
  const _DhikrPreset({
    required this.label,
    required this.arabic,
    required this.target,
    this.shortLabel,
    this.sequenceHint = '',
  });

  final String label;
  final String arabic;
  final int target;
  final String? shortLabel;
  final String sequenceHint;

  String localizedLabel(AppLocalizations localizations) {
    return switch (label) {
      'SubhanAllah' => localizations.subhanAllah,
      'Alhamdulillah' => localizations.alhamdulillah,
      'Allahu Akbar' => localizations.allahuAkbar,
      'Astaghfirullah' => localizations.astaghfirullah,
      'Custom' => localizations.custom,
      _ => label,
    };
  }

  static const List<_DhikrPreset> presets = <_DhikrPreset>[
    _DhikrPreset(
      label: 'SubhanAllah',
      arabic: 'سُبْحَانَ اللَّه',
      shortLabel: 'Subhan',
      target: 33,
      sequenceHint: 'Auto-advances to Alhamdulillah',
    ),
    _DhikrPreset(
      label: 'Alhamdulillah',
      arabic: 'ٱلْحَمْدُ لِلَّه',
      shortLabel: 'Hamd',
      target: 33,
      sequenceHint: 'Auto-advances to Allahu Akbar',
    ),
    _DhikrPreset(
      label: 'Allahu Akbar',
      arabic: 'اللَّهُ أَكْبَر',
      shortLabel: 'Akbar',
      target: 34,
      sequenceHint: 'Completes the post-prayer sequence',
    ),
    _DhikrPreset(
      label: 'Astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّه',
      shortLabel: 'Istighfar',
      target: 100,
    ),
    _DhikrPreset(label: 'Custom', arabic: 'ذِكْر', target: 100),
  ];
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _localizedDhikrSessionLabel(
  String label,
  AppLocalizations localizations,
) {
  return switch (label) {
    'SubhanAllah' => localizations.subhanAllah,
    'Alhamdulillah' => localizations.alhamdulillah,
    'Allahu Akbar' => localizations.allahuAkbar,
    'Astaghfirullah' => localizations.astaghfirullah,
    'Custom' => localizations.custom,
    _ => label,
  };
}

String _postPrayerDhikrSummary(AppLocalizations localizations) {
  return '${localizations.subhanAllah} 33 • ${localizations.alhamdulillah} 33 • ${localizations.allahuAkbar} 34';
}

String _sessionTimeLabel(
  DhikrSessionEntry session,
  AppLocalizations localizations,
) {
  final DateTime time = session.completedAt ?? session.startedAt;
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final bool arabic = isArabicLocalizations(localizations);
  final String period = arabic
      ? (time.hour >= 12 ? 'م' : 'ص')
      : (time.hour >= 12 ? 'PM' : 'AM');
  return '${time.month}/${time.day} $hour:${time.minute.toString().padLeft(2, '0')} $period';
}
