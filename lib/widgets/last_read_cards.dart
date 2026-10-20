import 'package:equran/backend/library.dart';
import 'package:equran/home/read.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class LastReadCard extends StatefulWidget {
  const LastReadCard({
    super.key,
    required this.entries,
    required this.cardBuilder,
    this.estimatedCardHeight = 158,
  });

  final List<ReadingEntry> entries;
  final Widget Function(BuildContext, ReadingEntry, VoidCallback) cardBuilder;
  final double estimatedCardHeight;

  static List<ReadingEntry> displayReadingHistory(Iterable<dynamic> values) {
    final rawEntries = values.whereType<ReadingEntry>().toList();

    // Keep one record per surah: latest ayah read only.
    final Map<int, ReadingEntry> latestPerSurah = <int, ReadingEntry>{};
    for (final entry in rawEntries) {
      final ReadingEntry? current = latestPerSurah[entry.surah];
      if (current == null || entry.timestamp.isAfter(current.timestamp)) {
        latestPerSurah[entry.surah] = entry;
      }
    }

    final entries = latestPerSurah.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(7).toList();
  }

  @override
  State<LastReadCard> createState() => _LastReadCardState();
}

class _LastReadCardState extends State<LastReadCard> {
  int _currentPage = 0;
  // Fractional page position while swiping; drives the depth effect without
  // rebuilding the whole carousel on every scroll frame.
  final ValueNotifier<double> _scrollPage = ValueNotifier<double>(0);
  final ExpandableCarouselController _carouselController =
      ExpandableCarouselController();

  @override
  void dispose() {
    _scrollPage.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LastReadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.isEmpty) {
      _currentPage = 0;
      return;
    }

    final int maxPage = widget.entries.length - 1;
    if (_currentPage > maxPage) {
      _currentPage = maxPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ReadingEntry> entries = widget.entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    final int activeIndex = _currentPage.clamp(0, entries.length - 1).toInt();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExpandableCarousel.builder(
          itemCount: entries.length,
          itemBuilder:
              (BuildContext context, int itemIndex, int pageViewIndex) {
                final ReadingEntry entry = entries[itemIndex];
                void openReading() => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        ReadPage(chapter: entry.surah, startVerse: entry.verse),
                  ),
                );
                final Widget card = Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget.cardBuilder(context, entry, openReading),
                );
                // Cards far from the scroll position recede, so the swipe
                // reads as moving through a stack of cards.
                return ValueListenableBuilder<double>(
                  valueListenable: _scrollPage,
                  child: card,
                  builder: (context, page, child) {
                    final double distance = (page - itemIndex)
                        .abs()
                        .clamp(0.0, 1.0)
                        .toDouble();
                    return Opacity(
                      opacity: 1 - 0.35 * distance,
                      child: Transform.scale(
                        scale: 1 - 0.06 * distance,
                        child: child,
                      ),
                    );
                  },
                );
              },
          options: ExpandableCarouselOptions(
            controller: _carouselController,
            showIndicator: false,
            estimatedPageSize: widget.estimatedCardHeight,
            enableInfiniteScroll: false,
            viewportFraction: 1,
            initialPage: 0,
            onScrolled: (double? page) {
              if (page != null) _scrollPage.value = page;
            },
            onPageChanged: (int index, _) {
              if (!mounted) return;
              setState(() {
                _currentPage = index.clamp(0, entries.length - 1).toInt();
              });
            },
          ),
        ),
        if (entries.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _CarouselPillsIndicator(
              itemCount: entries.length,
              activeIndex: activeIndex,
              onTap: _carouselController.animateToPage,
            ),
          ),
      ],
    );
  }
}

class _CarouselPillsIndicator extends StatelessWidget {
  const _CarouselPillsIndicator({
    required this.itemCount,
    required this.activeIndex,
    required this.onTap,
  });

  final int itemCount;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(itemCount, (index) {
        final bool isActive = index == activeIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          // Taller hit area than the 5px pill, so tapping a pill is easy.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive
                    ? colors.accentGold
                    : colors.onPrimaryMuted.withAlpha(150),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      }),
    );
  }
}
