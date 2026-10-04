part of 'quran_stats_page.dart';

class _StatsText extends StatelessWidget {
  const _StatsText(
    this.text, {
    this.size = 12.5,
    this.color,
    this.weight = FontWeight.w400,
    this.align,
    this.direction,
  });
  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;
  final TextAlign? align;
  final TextDirection? direction;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    textDirection: direction,
    style: TextStyle(
      fontSize: size,
      height: 1.4,
      color: color ?? context.equranTokens.text2,
      fontWeight: weight,
    ),
  );
}

class _FlowSectionHeader extends StatelessWidget {
  const _FlowSectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => _PageContentSliver(
    topPadding: 36,
    bottomPadding: 14,
    child: Text(label, style: redesignDisplayStyle(context, size: 24)),
  );
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.rangeListenable});
  final ValueNotifier<StatRange> rangeListenable;
  @override
  Widget build(BuildContext context) {
    final t = context.equranTokens;
    final l = AppLocalizations.of(context)!;
    return ValueListenableBuilder<StatRange>(
      valueListenable: rangeListenable,
      builder: (context, selected, _) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.equranColors.surface,
          border: Border.all(color: t.hair),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            for (final range in StatRange.values) ...[
              if (range.index > 0) const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  selected: range == selected,
                  child: TextButton(
                    key: ValueKey('statistics-range-${range.name}'),
                    onPressed: () => rangeListenable.value = range,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 9,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: range == selected ? t.emText : t.text2,
                      backgroundColor: range == selected
                          ? t.emWash
                          : Colors.transparent,
                      side: BorderSide(
                        color: range == selected ? t.hair2 : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      switch (range) {
                        StatRange.week => l.weekRange,
                        StatRange.month => l.monthRange,
                        StatRange.year => l.yearRange,
                        StatRange.allTime => l.allTime,
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatisticsToday extends StatelessWidget {
  const _StatisticsToday({
    required this.data,
    required this.mastered,
    required this.onLogSaved,
    this.now,
  });
  final OverviewStats data;
  final int? mastered;
  final VoidCallback onLogSaved;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = context.equranTokens;
    final salahData = SalahSectionData.disabled(
      todayEntry: data.todaySalahEntry,
    );
    final log = _SalahSection(data: salahData, onLogSaved: onLogSaved);
    return Container(
      key: const ValueKey('statistics-today'),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.hair),
        gradient: LinearGradient(
          begin: const Alignment(-.174, -.985),
          end: const Alignment(.174, .985),
          colors: [
            context.equranColors.surface,
            context.equranColors.surfaceAlt,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              RedesignEyebrow(l.todaysWorship),
              PillTag(
                l.dayStreakCount(data.highestStreak),
                gold: true,
                designIcon: 'flame',
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final ring = SizedBox.square(
                dimension: 150,
                child: Center(
                  child: ProgressRing(
                    size: 138.75,
                    strokeWidth: 11.25,
                    ringGap: 5.625,
                    value: data.quranGoalProgress,
                    color: t.gold,
                    trackColor: t.hair2,
                    innerValue: data.prayerTrackingEnabled
                        ? data.salahPrayersToday / 5
                        : 0,
                    innerColor: t.emText,
                    innerTrackColor: t.hair2,
                  ),
                ),
              );
              final metrics = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RingMetric(
                    label: l.quranLabel,
                    count: data.quranAyahs,
                    unit: l.ayahsCount(_dailyGoal()),
                    color: t.gold,
                  ),
                  const SizedBox(height: 14),
                  _RingMetric(
                    label: l.salah,
                    count: data.salahPrayersToday,
                    unit: l.prayersCount(5),
                    color: t.emText,
                  ),
                ],
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.1) {
                return Column(
                  children: [ring, const SizedBox(height: 16), metrics],
                );
              }
              return Row(
                children: [
                  ring,
                  const SizedBox(width: 18),
                  Expanded(child: metrics),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: t.hair),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CountLabel(
                  '${data.tasbihCount}',
                  l.dhikrLabel,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CountLabel(
                  '${data.duasViewed}',
                  l.duasViewed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CountLabel(
                  mastered?.toString() ?? '—',
                  '${l.hifzMemorized} · ${l.ayahsLabel}',
                  size: 22,
                ),
              ),
            ],
          ),
          if (data.prayerTrackingEnabled) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: t.hair),
            const SizedBox(height: 14),
            _StatisticsPrayerRow(
              entry: data.todaySalahEntry,
              now: now,
              onPrayerTap: (prayer) => log._openLogSheet(context, prayer),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingMetric extends StatelessWidget {
  const _RingMetric({
    required this.label,
    required this.count,
    required this.unit,
    required this.color,
  });
  final String unit;
  final String label;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: _StatsText(label)),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 5,
        children: [
          DisplayNumeral('$count', size: 28, height: 1),
          _StatsText('/ $unit', size: 13, direction: TextDirection.ltr),
        ],
      ),
    ],
  );
}

class _CountLabel extends StatelessWidget {
  const _CountLabel(this.value, this.label, {this.size = 28, this.color});
  final String value, label;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DisplayNumeral(value, size: size, height: 1, color: color),
      const SizedBox(height: 5),
      _StatsText(label, size: 12),
    ],
  );
}

SalahGlyphState _statisticsGlyph(SalahStatus status, {bool available = true}) =>
    !available
    ? SalahGlyphState.notYet
    : switch (status) {
        SalahStatus.onTime => SalahGlyphState.onTime,
        SalahStatus.late => SalahGlyphState.late,
        SalahStatus.notPrayed => SalahGlyphState.missed,
        SalahStatus.unlogged => SalahGlyphState.notLogged,
      };
String _statisticsGlyphLabel(AppLocalizations l, SalahGlyphState state) =>
    switch (state) {
      SalahGlyphState.onTime => l.onTime,
      SalahGlyphState.late => l.late,
      SalahGlyphState.missed => l.missed,
      SalahGlyphState.notLogged => l.notLogged,
      SalahGlyphState.notYet => l.notYet,
    };

class _StatisticsPrayerRow extends StatelessWidget {
  const _StatisticsPrayerRow({
    required this.entry,
    required this.onPrayerTap,
    this.now,
  });
  final SalahLogEntry entry;
  final ValueChanged<SalahPrayer> onPrayerTap;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final availability = _salahLogAvailabilityForNow(now: now);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final prayer in SalahPrayer.values)
          Expanded(
            child: Column(
              children: [
                _StatsText(
                  _salahPrayerLabel(l, prayer),
                  size: 11,
                  align: TextAlign.center,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 7),
                IconButton(
                  key: ValueKey('statistics-log-${prayer.key}'),
                  tooltip: '${l.log}: ${_salahPrayerLabel(l, prayer)}',
                  onPressed: () => onPrayerTap(prayer),
                  icon: SalahGlyph(
                    size: 28,
                    state: _statisticsGlyph(
                      prayer.statusFor(entry),
                      available: availability.isLoggable(prayer),
                    ),
                    semanticLabel: _statisticsGlyphLabel(
                      l,
                      _statisticsGlyph(
                        prayer.statusFor(entry),
                        available: availability.isLoggable(prayer),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatisticsPrayer extends StatelessWidget {
  const _StatisticsPrayer({
    required this.data,
    required this.onPrayerTap,
    this.now,
  });
  final SalahSectionData data;
  final ValueChanged<SalahPrayer> onPrayerTap;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = context.equranTokens;
    final total = data.prayerStats.fold<int>(
      0,
      (sum, p) => sum + p.loggedCount,
    );
    final onTime = data.prayerStats.fold<int>(
      0,
      (sum, p) => sum + p.onTimeCount,
    );
    final rate = total == 0 ? 0.0 : onTime / total;
    final clock = now ?? _getShiftedNow();
    final today = DateTime(clock.year, clock.month, clock.day);
    final days = [
      for (int i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final logs = {
      for (final entry
          in SalahLogDB().box.values
              .map(SalahLogEntry.fromStored)
              .whereType<SalahLogEntry>())
        entry.date: entry,
    };
    final availability = _salahLogAvailabilityForNow(now: now);
    return HairlineCard(
      key: const ValueKey('statistics-prayer'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 92,
                child: Center(
                  child: ProgressRing(
                    value: rate,
                    trackColor: t.hair2,
                    color: t.emText,
                    size: 85,
                    strokeWidth: 9,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DisplayNumeral(
                          '${(rate * 100).round()}%',
                          size: 24,
                          height: 1,
                        ),
                        const SizedBox(height: 5),
                        _StatsText(l.onTime, size: 10.5),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CountLabel(
                            '${data.onTimeThisWeek}',
                            l.onTimeThisWeek,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CountLabel(
                            '${data.lateThisWeek}',
                            l.lateThisWeek,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.bestPrayer == null
                                    ? '—'
                                    : _salahPrayerLabel(l, data.bestPrayer!),
                                style: redesignDisplayStyle(
                                  context,
                                  size: 22,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              _StatsText(l.bestPrayer, size: 12),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CountLabel(
                            '${data.fajrStreak}',
                            l.currentFajrStreak,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: t.hair),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 62),
              for (final day in days)
                Expanded(
                  child: _StatsText(
                    _weekdayInitials(l)[(day.weekday - 1) % 7],
                    size: 11,
                    align: TextAlign.center,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final prayer in SalahPrayer.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: _StatsText(_salahPrayerLabel(l, prayer)),
                  ),
                  for (final day in days)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final isToday = day == today;
                          final entry =
                              logs[_dateKey(day)] ??
                              SalahLogEntry(date: _dateKey(day));
                          final state = _statisticsGlyph(
                            prayer.statusFor(entry),
                            available:
                                !isToday || availability.isLoggable(prayer),
                          );
                          final label =
                              '${_dateChipLabel(day, l)} · ${_salahPrayerLabel(l, prayer)} · ${_statisticsGlyphLabel(l, state)}';
                          return Tooltip(
                            message: label,
                            child: isToday
                                ? InkResponse(
                                    onTap: () => onPrayerTap(prayer),
                                    child: SizedBox(
                                      height: 24,
                                      child: Center(
                                        child: SalahGlyph(
                                          state: state,
                                          semanticLabel: label,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: SalahGlyph(
                                      state: state,
                                      semanticLabel: label,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final state in SalahGlyphState.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SalahGlyph(
                      state: state,
                      size: 14,
                      semanticLabel: _statisticsGlyphLabel(l, state),
                    ),
                    const SizedBox(width: 6),
                    _StatsText(_statisticsGlyphLabel(l, state), size: 11.5),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _StatisticsFajr(data: data),
        ],
      ),
    );
  }
}

class _StatisticsFajr extends StatelessWidget {
  const _StatisticsFajr({required this.data});
  final SalahSectionData data;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rate = data.perPrayerOnTimePct[SalahPrayer.fajr.key];
    final body = rate == null || rate <= 0
        ? l.startLoggingFajr
        : rate >= .8
        ? l.fajrVeryConsistent
        : rate >= .5
        ? l.fajrGettingStronger
        : l.fajrEveryAttemptCounts;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      decoration: BoxDecoration(
        color: context.equranTokens.emWash,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_twilight_rounded,
            color: context.equranTokens.emText,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsText(
                  l.fajrConsistency,
                  size: 14,
                  weight: FontWeight.w600,
                ),
                const SizedBox(height: 1),
                _StatsText(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsQuran extends StatelessWidget {
  const _StatisticsQuran({
    required this.data,
    required this.sectionKey,
    required this.range,
    required this.expanded,
    required this.onOpenSurah,
    required this.onToggle,
  });
  final QuranStatsData data;
  final StatRange range;
  final GlobalKey sectionKey;
  final bool expanded;
  final ValueChanged<int> onOpenSurah;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = context.equranTokens;
    final read = _readAyahsBySurah(
      QuranActivityDB().box.values.whereType<QuranActivityDay>().toList(),
    );
    final unique = read.values.fold<int>(
      0,
      (sum, verses) => sum + verses.length,
    );
    return Column(
      key: const ValueKey('statistics-quran'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatisticsChart(
          buckets: data.buckets,
          showDailyGoal: range == StatRange.week,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _StatisticsTile('${data.totalAyahs}', l.ayahsRead)),
            const SizedBox(width: 12),
            Expanded(
              child: _StatisticsTile(
                _compactNumber(data.totalLetters),
                l.lettersRead,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatisticsTile('${data.activeDays}', l.activeDays),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatisticsTile(
                data.mostActiveWeekday == null
                    ? '—'
                    : _shortWeekdayLabel(data.mostActiveWeekday!, l),
                l.mostActiveDay,
                numeral: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('statistics-most-read'),
            borderRadius: BorderRadius.circular(24),
            onTap: data.mostReadSurah == null
                ? null
                : () => onOpenSurah(data.mostReadSurah!),
            child: HairlineCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: t.goldWash,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: 22,
                      color: t.goldText,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatsText(l.mostReadSurah),
                        const SizedBox(height: 4),
                        _StatsText(
                          data.mostReadSurah == null
                              ? l.noSurahYet
                              : localizedSurahName(l, data.mostReadSurah!),
                          size: 16,
                          weight: FontWeight.w600,
                          color: context.equranColors.textPrimary,
                        ),
                        if (data.mostReadSurah != null)
                          _StatsText(
                            l.ayahsReadCount(data.mostReadSurahAyahs),
                            size: 11.5,
                          ),
                      ],
                    ),
                  ),
                  if (data.mostReadSurah != null)
                    Text(
                      quran.getSurahNameArabic(data.mostReadSurah!),
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 24,
                        color: t.goldText,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        HairlineCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatsText(
                      l.khatmProgress,
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  ),
                  DisplayNumeral(
                    '${(unique / 6236 * 100).round()}%',
                    size: 22,
                    height: 1,
                    color: t.emText,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Semantics(
                  value: '${(unique / 6236 * 100).round()}%',
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: t.hair2),
                        FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: (unique / 6236).clamp(0, 1),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: AlignmentDirectional.centerStart,
                                end: AlignmentDirectional.centerEnd,
                                colors: [t.filled, t.emText],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _StatsText('${l.ayahsReadCount(unique)} / 6236'),
              const SizedBox(height: 10),
              _StatsText(
                '${l.fullCompletions}: ${data.khatmCompletionDates.length}',
              ),
              if (data.khatmCompletionDates.isEmpty)
                _StatsText(l.completeAllSurahsForFirstKhatm(114), size: 11.5),
              for (final date in data.khatmCompletionDates.asMap().entries)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _StatsText(
                    l.khatmDateLabel(
                      date.key + 1,
                      _dateChipLabel(date.value, l),
                    ),
                    size: 11.5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StatisticsSurahMap(
          key: sectionKey,
          title: l.surahMap,
          summary: l.surahsComplete(data.completedSurahs.length, 114),
          counts: {
            for (final entry in read.entries) entry.key: entry.value.length,
          },
          expanded: expanded,
          onToggle: onToggle,
          onTap: onOpenSurah,
        ),
        if (data.insights.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InsightsRow(insights: data.insights),
        ],
      ],
    );
  }
}

class _StatisticsTile extends StatelessWidget {
  const _StatisticsTile(this.value, this.label, {this.numeral = true});
  final String value, label;
  final bool numeral;
  @override
  Widget build(BuildContext context) => HairlineCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (numeral)
          DisplayNumeral(value, size: 28, height: 1)
        else
          Text(
            value,
            style: redesignDisplayStyle(context, size: 28, height: 1),
          ),
        const SizedBox(height: 6),
        _StatsText(label),
      ],
    ),
  );
}

class _StatisticsChart extends StatelessWidget {
  const _StatisticsChart({required this.buckets, required this.showDailyGoal});
  final List<ActivityBucket> buckets;
  final bool showDailyGoal;
  @override
  Widget build(BuildContext context) {
    final t = context.equranTokens;
    final l = AppLocalizations.of(context)!;
    final total = buckets.fold<int>(0, (sum, b) => sum + b.count);
    final goal = _dailyGoal();
    final maximum = buckets.fold<int>(
      goal,
      (maximum, b) => math.max(maximum, b.count),
    );
    return HairlineCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsText(l.ayahsRead),
                  const SizedBox(height: 6),
                  DisplayNumeral('$total', size: 40, height: 1),
                ],
              ),
              PillTag(l.dailyQuranGoalSubtitle(goal), gold: true),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 148,
            child: Stack(
              children: [
                if (showDailyGoal)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 120 * (1 - goal / maximum),
                    child: CustomPaint(
                      size: const Size(0, 1),
                      painter: _StatisticsGoalPainter(
                        t.gold.withValues(alpha: .55),
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final bucket in buckets)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                triggerMode: TooltipTriggerMode.tap,
                                message:
                                    '${bucket.detailLabel}\n${l.ayahsCount(bucket.count)}',
                                child: Semantics(
                                  label:
                                      '${bucket.detailLabel}: ${l.ayahsCount(bucket.count)}',
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 30,
                                    ),
                                    height: math.max(
                                      4,
                                      120 * bucket.count / maximum,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bucket.isCurrent
                                          ? t.gold
                                          : bucket.count == 0
                                          ? t.hair
                                          : t.filled.withValues(alpha: .62),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(9),
                                        bottom: Radius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 20,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _StatsText(bucket.label, size: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsGoalPainter extends CustomPainter {
  const _StatisticsGoalPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + 4, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StatisticsGoalPainter old) => color != old.color;
}

class _StatisticsSurahMap extends StatelessWidget {
  const _StatisticsSurahMap({
    super.key,
    required this.title,
    required this.counts,
    required this.expanded,
    required this.onToggle,
    this.onTap,
    this.summary,
  });
  final String title;
  final String? summary;
  final Map<int, int> counts;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<int>? onTap;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = context.equranTokens;
    Color level(double progress) => progress <= 0
        ? t.hair
        : progress < .5
        ? t.filled.withValues(alpha: .32)
        : progress < 1
        ? t.filled.withValues(alpha: .62)
        : t.filled;
    return HairlineCard(
      key: ValueKey('statistics-map-${onTap == null ? 'hifz' : 'quran'}'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 5,
            children: [
              _StatsText(title, size: 15, weight: FontWeight.w600),
              if (onTap != null) _StatsText(l.tapCellToOpen),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 6),
            _StatsText(summary!, size: 11.5),
          ],
          const SizedBox(height: 14),
          GridView.builder(
            key: ValueKey(
              'statistics-surah-map-${onTap == null ? 'hifz' : 'quran'}',
            ),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 114,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: expanded ? 6 : 19,
              crossAxisSpacing: expanded ? 6 : 3,
              mainAxisSpacing: expanded ? 6 : 3,
            ),
            itemBuilder: (context, index) {
              final surah = index + 1;
              final count = counts[surah] ?? 0;
              final total = quran.getVerseCount(surah);
              final label =
                  '${localizedSurahName(l, surah)} · ${l.ayahsCount(count)} / $total';
              return Semantics(
                label: label,
                button: onTap != null,
                child: Tooltip(
                  message: label,
                  child: Material(
                    color: level(count / total),
                    borderRadius: BorderRadius.circular(expanded ? 8 : 3),
                    child: InkWell(
                      key: ValueKey(
                        'statistics-surah-${onTap == null ? 'hifz' : 'quran'}-$surah',
                      ),
                      onTap: onTap == null ? null : () => onTap!(surah),
                      child: expanded
                          ? Center(
                              child: Text(
                                '$surah',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: count == total
                                      ? Colors.white
                                      : context.equranColors.textPrimary,
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatsText(l.less, size: 11.5),
              const SizedBox(width: 6),
              for (final value in [0.0, .25, .75, 1.0])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: level(value),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              _StatsText(l.more, size: 11.5),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: ValueKey(
                'statistics-map-toggle-${onTap == null ? 'hifz' : 'quran'}',
              ),
              onPressed: onToggle,
              child: Text(expanded ? l.showLess : l.showAllSurahs(114)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsHifz extends StatelessWidget {
  const _StatisticsHifz({
    required this.data,
    required this.expanded,
    required this.onToggle,
    this.now,
  });
  final HifzSectionData data;
  final bool expanded;
  final VoidCallback onToggle;
  final DateTime? now;
  void _open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HifzHomePage()));
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = context.equranTokens;
    final entry = data.nextDueEntry;
    final clock = now ?? _getShiftedNow();
    final today = DateTime(clock.year, clock.month, clock.day);
    final due = entry == null
        ? null
        : DateTime(entry.dueDate.year, entry.dueDate.month, entry.dueDate.day);
    final date = due == today
        ? l.hifzNextReviewToday
        : due == today.add(const Duration(days: 1))
        ? l.hifzNextReviewTomorrow
        : entry == null
        ? ''
        : '${entry.dueDate.day}/${entry.dueDate.month}/${entry.dueDate.year}';
    return Column(
      key: const ValueKey('statistics-hifz'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HairlineCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatsText(l.hifzStatsTotalMemorized),
              const SizedBox(height: 6),
              DisplayNumeral('${data.totalMemorized}', size: 40, height: 1),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (int i = 0; i < 10; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: i < (data.retentionRate * 10).round()
                              ? t.filled
                              : t.hair,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              _StatsText(
                '${l.hifzStatsRetentionRate}: ${(data.retentionRate * 100).round()}%',
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CountLabel(
                      '${data.currentStreak}',
                      l.hifzStatsDailyStreak,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountLabel(
                      '${data.totalReviews}',
                      l.hifzStatsTotalReviews,
                      size: 22,
                    ),
                  ),
                ],
              ),
              if (entry != null) ...[
                const SizedBox(height: 16),
                Material(
                  color: t.goldWash,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    key: const ValueKey('statistics-next-review'),
                    onTap: () => _open(context),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatsText(
                                  l.hifzStatsNextDue,
                                  size: 11.5,
                                  color: t.goldText,
                                ),
                                const SizedBox(height: 4),
                                _StatsText(
                                  l.hifzStatsNextDueValue(
                                    localizedSurahName(l, entry.surah),
                                    entry.ayah,
                                  ),
                                  size: 16,
                                  weight: FontWeight.w600,
                                ),
                                const SizedBox(height: 4),
                                _StatsText(
                                  l.hifzStatsNextDueDate(date),
                                  size: 11.5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _open(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: t.filled,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l.hifzReminderReview,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (data.totalMemorized == 0 && data.totalReviews == 0) ...[
                const SizedBox(height: 16),
                _StatsText(l.hifzStatsNoEntries),
                TextButton(
                  onPressed: () => _open(context),
                  child: Text(l.hifzTitle),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StatisticsSurahMap(
          title: l.hifzStatsSurahProgress,
          summary: l.hifzSurahsMastered(
            data.masteredPerSurah.entries
                .where((entry) => entry.value >= quran.getVerseCount(entry.key))
                .length,
          ),
          counts: data.masteredPerSurah,
          expanded: expanded,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

class _StatisticsTasbih extends StatelessWidget {
  const _StatisticsTasbih({required this.data});
  final TasbihStatsData data;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return HairlineCard(
      key: const ValueKey('statistics-tasbih'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RedesignEyebrow(l.dhikrLabel),
          const SizedBox(height: 14),
          DisplayNumeral('${data.totalDhikr}', size: 30, height: 1),
          const SizedBox(height: 5),
          _StatsText(l.totalDhikr),
          const SizedBox(height: 12),
          if (!data.hasData)
            _StatsText(l.startFirstTasbihSession)
          else ...[
            _StatsText(
              '${l.dailyAverage}: ${_averageLabel(data.dailyAverage)}',
            ),
            const SizedBox(height: 8),
            _StatsText(l.activeDaysCount(data.activeDays)),
            const SizedBox(height: 12),
            _StatsText(
              data.mostRecitedName.isEmpty
                  ? l.dhikrLabel
                  : _localizedDhikrStatsLabel(data.mostRecitedName, l),
              weight: FontWeight.w600,
            ),
            _StatsText(l.recitationsCount(data.mostRecitedCount), size: 11.5),
          ],
        ],
      ),
    );
  }
}

class _StatisticsDuas extends StatelessWidget {
  const _StatisticsDuas({required this.data});
  final DuasStatsData data;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return HairlineCard(
      key: const ValueKey('statistics-duas'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RedesignEyebrow(l.duas),
          const SizedBox(height: 14),
          DisplayNumeral('${data.viewedCount}', size: 30, height: 1),
          const SizedBox(height: 5),
          _StatsText(l.duasViewed),
          const SizedBox(height: 12),
          if (!data.hasData)
            _StatsText(l.openDuaToBeginHistory)
          else ...[
            _StatsText('${l.favouriteDuas}: ${data.favouriteCount}'),
            const SizedBox(height: 12),
            _StatsText(
              data.mostViewedCategoryCount == 0
                  ? l.noCategoryYet
                  : data.mostViewedCategoryId == null
                  ? data.mostViewedCategory
                  : getLocalizedCategoryTitle(
                      context,
                      data.mostViewedCategoryId!,
                      data.mostViewedCategory,
                    ),
              weight: FontWeight.w600,
            ),
            _StatsText(l.viewsCount(data.mostViewedCategoryCount), size: 11.5),
          ],
        ],
      ),
    );
  }
}

class _StatisticsStreaks extends StatelessWidget {
  const _StatisticsStreaks({required this.data});
  final StreakStats data;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = context.equranTokens;
    return Column(
      key: const ValueKey('statistics-streaks'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: t.goldWash,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.gold.withValues(alpha: .35)),
          ),
          child: _CountLabel(
            '${data.overall}',
            l.overallStreak,
            size: 40,
            color: t.goldText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HairlineCard(
                padding: const EdgeInsets.all(18),
                child: _CountLabel('${data.quran}', l.quranStreak, size: 40),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HairlineCard(
                padding: const EdgeInsets.all(18),
                child: _CountLabel('${data.tasbih}', l.tasbihStreak, size: 40),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
