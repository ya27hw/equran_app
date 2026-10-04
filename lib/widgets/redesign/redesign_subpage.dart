import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

/// The redesign's page frame: background, safe area, optional back button and
/// a serif title, with [child] filling the rest. Use it instead of a
/// [Scaffold] plus [AppBar] so every page shares one header.
class RedesignSubpage extends StatelessWidget {
  const RedesignSubpage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.showBack,
    this.backTooltip,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  /// Defaults to whether the route can pop.
  final bool? showBack;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) {
    final bool back = showBack ?? Navigator.of(context).canPop();
    final ThemeData base = Theme.of(context);
    final EquranTokens tokens = context.equranTokens;
    // Cards and dividers inside the page pick up the hairline look.
    final ThemeData themed = base.copyWith(
      cardTheme: CardThemeData(
        color: context.equranColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.xl),
          side: BorderSide(color: tokens.hair),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.hair, thickness: 1),
    );
    return Theme(
      data: themed,
      child: Material(
        color: context.equranColors.background,
        child: RedesignPageTypography(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Row(
                    children: <Widget>[
                      if (back) ...<Widget>[
                        IconButton44(
                          designIcon: 'back',
                          tooltip:
                              backTooltip ??
                              MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: redesignDisplayStyle(context, size: 32),
                        ),
                      ),
                      for (final Widget action in actions) action,
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
