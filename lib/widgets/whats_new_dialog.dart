import 'package:equran/backend/whats_new_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:flutter/material.dart';

/// Modal dialog that presents highlights of the latest app release in simple,
/// non-technical language for everyday users.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, this.release, this.onDismiss});

  final AppRelease? release;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context, {
    AppRelease? release,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) =>
          WhatsNewDialog(release: release, onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppRelease currentRelease =
        release ?? WhatsNewService.instance.latestRelease;
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;

    return ReaderDialog(
      title: currentRelease.title,
      icon: Icon(Icons.auto_awesome_rounded, color: tokens.emText, size: 22),
      titleTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: tokens.emWash,
          borderRadius: BorderRadius.circular(EquranRadii.pill),
          border: Border.all(color: tokens.hair2),
        ),
        child: Text(
          'v${currentRelease.version}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tokens.emText,
          ),
        ),
      ),
      maxWidth: 480,
      scrollableContent: true,
      content: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final highlight in currentRelease.highlights) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tokens.emWash,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.hair),
                      ),
                      child: Center(
                        child: Icon(
                          highlight.icon,
                          size: 20,
                          color: tokens.emText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            highlight.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            highlight.description,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: tokens.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        FilledButton(
          style: readerFilledButtonStyle(context),
          onPressed: () {
            WhatsNewService.instance.markWhatsNewSeen(currentRelease.version);
            onDismiss?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
