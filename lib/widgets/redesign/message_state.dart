import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/material.dart';

/// A centred empty, error or unavailable state: an emerald-wash icon well, a
/// serif title and a quiet hint. It only draws.
class RedesignMessageState extends StatelessWidget {
  const RedesignMessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  /// A `DesignIcon` or an `Icon`; it is tinted and sized by the icon well.
  final Widget icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ReaderIconWell(icon: icon, size: 64),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: redesignDisplayStyle(context, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: tokens.text2),
            ),
          ],
        ),
      ),
    );
  }
}
