import 'dart:async' show unawaited;

import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/word_by_word/word_alignment.dart';
import 'package:equran/word_by_word/word_by_word_pack.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Arabic ayah text whose words can be tapped to see their gloss.
///
/// Renders exactly the same string, style and alignment as a plain [Text]; only
/// the word substrings gain a tap recognizer, so line breaking is unchanged.
/// [ranges] and [glosses] must be the same length (see [alignWordRanges]).
class WordByWordText extends StatefulWidget {
  const WordByWordText({
    super.key,
    required this.text,
    required this.ranges,
    required this.glosses,
    required this.style,
    required this.meta,
    this.textAlign = TextAlign.justify,
    this.onWordTap,
    this.wrapSheet,
  });

  final String text;
  final List<WordRange> ranges;
  final List<WordGloss> glosses;
  final TextStyle style;
  final WordByWordPackMeta meta;
  final TextAlign textAlign;

  /// Overrides the default bottom sheet (used by tests).
  final void Function(int index)? onWordTap;

  /// Lets the host bracket the sheet's lifetime (the reader pauses its live
  /// progress animation while an overlay is open). Must await [open].
  final Future<void> Function(Future<void> Function() open)? wrapSheet;

  @override
  State<WordByWordText> createState() => _WordByWordTextState();
}

class _WordByWordTextState extends State<WordByWordText> {
  List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _buildRecognizers();
  }

  @override
  void didUpdateWidget(covariant WordByWordText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        !listEquals(oldWidget.ranges, widget.ranges)) {
      _disposeRecognizers();
      _buildRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _buildRecognizers() {
    _recognizers = <TapGestureRecognizer>[
      for (int i = 0; i < widget.ranges.length; i++)
        TapGestureRecognizer()..onTap = () => _onTap(i),
    ];
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers = <TapGestureRecognizer>[];
  }

  void _onTap(int index) {
    final void Function(int index)? override = widget.onWordTap;
    if (override != null) {
      override(index);
      return;
    }
    Future<void> open() => showWordMeaningSheet(
      context,
      arabic: widget.text.substring(
        widget.ranges[index].start,
        widget.ranges[index].end,
      ),
      gloss: widget.glosses[index],
      meta: widget.meta,
      arabicStyle: widget.style,
    );
    final Future<void> Function(Future<void> Function() open)? wrap =
        widget.wrapSheet;
    unawaited(wrap == null ? open() : wrap(open));
  }

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    for (int i = 0; i < widget.ranges.length; i++) {
      final WordRange range = widget.ranges[i];
      if (range.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: widget.text.substring(range.start, range.end),
          recognizer: _recognizers[i],
        ),
      );
      cursor = range.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }
    // Per-word recognizers would split the ayah into several screen-reader
    // nodes. Keep it one node, exactly as a plain Text is, so assistive
    // technology reads the ayah as before; word meanings are a touch feature.
    return Semantics(
      label: widget.text,
      textDirection: TextDirection.rtl,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(style: widget.style, children: spans),
        textDirection: TextDirection.rtl,
        textAlign: widget.textAlign,
      ),
    );
  }
}

/// Shows a word's meaning and transliteration with its provenance.
Future<void> showWordMeaningSheet(
  BuildContext context, {
  required String arabic,
  required WordGloss gloss,
  required WordByWordPackMeta meta,
  required TextStyle arabicStyle,
}) {
  final AppLocalizations localizations = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);
      final ColorScheme colors = theme.colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: arabicStyle.copyWith(
                  fontSize: (arabicStyle.fontSize ?? 28).clamp(30.0, 44.0),
                  height: 1.6,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _SheetField(
                label: localizations.wordMeaning,
                value: gloss.meaning,
                valueStyle: theme.textTheme.titleLarge,
              ),
              if (gloss.transliteration.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _SheetField(
                  label: localizations.wordTransliteration,
                  value: gloss.transliteration,
                  valueStyle: theme.textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 18),
              Text(
                localizations.wordByWordProvenance(meta.source, meta.license),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: valueStyle),
      ],
    );
  }
}
