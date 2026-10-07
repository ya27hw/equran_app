import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:flutter/material.dart';

/// The daily Quran goal dialog. It validates the same 1 to 1000 range as
/// before and pops the number, or nothing on cancel.
class DailyGoalDialog extends StatefulWidget {
  const DailyGoalDialog({super.key, required this.initialGoal});

  final int initialGoal;

  @override
  State<DailyGoalDialog> createState() => _DailyGoalDialogState();
}

class _DailyGoalDialogState extends State<DailyGoalDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialGoal.toString(),
  );
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(AppLocalizations l) {
    final int? value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 || value > 1000) {
      setState(() => _errorText = l.enterGoalRange);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ReaderDialog(
      title: l.dailyQuranGoal,
      icon: const Icon(Icons.flag_rounded),
      content: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: readerInputDecoration(
            context,
            label: l.ayahsPerDay,
            hint: '20',
            errorText: _errorText,
          ),
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
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

/// A destructive yes or no. [onConfirm] runs to completion before the dialog
/// closes, exactly as the old dialog did.
class ClearDataDialog extends StatelessWidget {
  const ClearDataDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranTokens tokens = context.equranTokens;
    return ReaderDialog(
      title: title,
      icon: const DesignIcon('trash'),
      content: Text(
        message,
        style: TextStyle(fontSize: 14.5, height: 1.45, color: tokens.text2),
      ),
      actions: <Widget>[
        TextButton(
          style: readerTextButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          style: readerTextButtonStyle(context, color: tokens.danger),
          onPressed: () async {
            await onConfirm();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(l.clear),
        ),
      ],
    );
  }
}
