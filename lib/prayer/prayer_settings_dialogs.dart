import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A number the user entered, or an empty answer. A cancelled dialog returns
/// null instead, so "cleared" and "dismissed" stay different.
class OptionalNumberResult<T extends num> {
  const OptionalNumberResult(this.value);

  final T? value;
}

/// Free numeric entry for the Prayer settings (angles). Validation is the
/// caller's; an invalid entry shows a snack bar and keeps the dialog open.
class PrayerNumberDialog<T extends num> extends StatefulWidget {
  const PrayerNumberDialog({
    super.key,
    required this.title,
    required this.currentValue,
    required this.helperText,
    required this.parser,
    required this.validator,
    required this.formatter,
    required this.allowEmpty,
  });

  final String title;
  final T? currentValue;
  final String helperText;
  final T? Function(String value) parser;
  final bool Function(T value) validator;
  final String Function(T value) formatter;
  final bool allowEmpty;

  @override
  State<PrayerNumberDialog<T>> createState() => _PrayerNumberDialogState<T>();
}

class _PrayerNumberDialogState<T extends num>
    extends State<PrayerNumberDialog<T>> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentValue == null
        ? ''
        : widget.formatter(widget.currentValue as T),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(AppLocalizations l) {
    final String raw = _controller.text.trim();
    if (widget.allowEmpty && raw.isEmpty) {
      Navigator.of(context).pop(OptionalNumberResult<T>(null));
      return;
    }
    final T? value = widget.parser(raw);
    if (value == null || !widget.validator(value)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.enterValidValue)));
      return;
    }
    Navigator.of(context).pop(OptionalNumberResult<T>(value));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ReaderDialog(
      title: widget.title,
      content: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          decoration: readerInputDecoration(context).copyWith(
            helperText: widget.helperText,
            helperMaxLines: 3,
            helperStyle: TextStyle(
              fontSize: 12.5,
              color: context.equranTokens.muted,
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: readerTextButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: readerFilledButtonStyle(context),
          onPressed: () => _save(l),
          child: Text(l.save),
        ),
      ],
    );
  }
}

/// Whole-number entry with an optional sign toggle, for offsets, intervals and
/// prohibited-time lengths. With [allowNullValue] a Clear button answers with
/// an empty result.
class PrayerSteppedIntDialog extends StatefulWidget {
  const PrayerSteppedIntDialog({
    super.key,
    required this.title,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.helperText,
    required this.allowNullValue,
  });

  final String title;
  final int? currentValue;
  final int min;
  final int max;
  final String helperText;
  final bool allowNullValue;

  @override
  State<PrayerSteppedIntDialog> createState() => _PrayerSteppedIntDialogState();
}

class _PrayerSteppedIntDialogState extends State<PrayerSteppedIntDialog> {
  late int _signedValue = (widget.currentValue ?? 0)
      .clamp(widget.min, widget.max)
      .toInt();
  late bool _isNegative = _signedValue < 0;
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentValue == null ? '' : _signedValue.abs().toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _signedValueFromText() {
    final String raw = _controller.text.trim();
    final int magnitude = raw.isEmpty ? 0 : int.tryParse(raw) ?? -1;
    if (magnitude < 0) return widget.min - 1;
    if (_isNegative && magnitude != 0 && widget.min < 0) return -magnitude;
    return magnitude;
  }

  void _syncValue() {
    final int fromText = _signedValueFromText();
    if (fromText >= widget.min && fromText <= widget.max) {
      _signedValue = fromText;
    }
  }

  void _toggleSign() {
    if (widget.min >= 0) return;
    setState(() {
      _isNegative = !_isNegative;
      _syncValue();
    });
  }

  void _save(AppLocalizations l) {
    final int value = _signedValueFromText();
    if (value < widget.min || value > widget.max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.enterValueFromMinToMax(
              widget.min.toString(),
              widget.max.toString(),
            ),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(OptionalNumberResult<int>(value));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    return ReaderDialog(
      title: widget.title,
      content: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: readerInputDecoration(context).copyWith(
            prefixIcon: widget.min < 0
                ? IconButton(
                    tooltip: _isNegative ? 'Set positive' : 'Set negative',
                    onPressed: _toggleSign,
                    icon: Text(
                      _isNegative ? '−' : '+',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: tokens.emText,
                      ),
                    ),
                  )
                : null,
            helperText: widget.helperText,
            helperMaxLines: 3,
            helperStyle: TextStyle(fontSize: 12.5, color: tokens.muted),
          ),
          onChanged: (_) => setState(_syncValue),
        ),
      ),
      actions: <Widget>[
        if (widget.allowNullValue)
          TextButton(
            style: readerTextButtonStyle(context),
            onPressed: () => Navigator.of(
              context,
            ).pop(const OptionalNumberResult<Never>(null)),
            child: Text(l.clear),
          ),
        TextButton(
          style: readerTextButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: readerFilledButtonStyle(context),
          onPressed: () => _save(l),
          child: Text(l.save),
        ),
      ],
    );
  }
}
