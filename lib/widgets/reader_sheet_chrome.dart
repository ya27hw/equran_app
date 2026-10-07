import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/app_selection_dialog.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/icon_button44.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:flutter/material.dart';

/// Shared chrome for the reader's bottom sheets and dialogs. It follows the
/// playback options sheet: a page-coloured sheet with a 28 px top radius, a
/// serif title, eyebrow-labelled hairline groups and 64 px rows with a round
/// emerald-wash icon. Everything here is presentational; the reading page
/// keeps all state and audio logic.
Future<T?> showReaderSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useSafeArea = true,
  bool? requestFocus,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    showDragHandle: false,
    requestFocus: requestFocus,
    backgroundColor: context.equranColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(EquranRadii.xxl),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
    builder: builder,
  );
}

Future<T?> showReaderDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(context: context, builder: builder);
}

bool _isArabicScript(BuildContext context) => const <String>[
  'ar',
  'fa',
  'ur',
].contains(Localizations.localeOf(context).languageCode);

/// Interface font for dialogs, without the page glow of
/// [RedesignPageTypography].
class ReaderFontScope extends StatelessWidget {
  const ReaderFontScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String family = _isArabicScript(context)
        ? 'NotoNaskhArabic'
        : 'Inter';
    final ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: family,
          fontFamilyFallback: const <String>['NotoNaskhArabic'],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: family,
          fontFamilyFallback: const <String>['NotoNaskhArabic'],
          color: context.equranColors.textPrimary,
        ),
        child: child,
      ),
    );
  }
}

/// The drag handle every reader sheet shares.
class ReaderSheetHandle extends StatelessWidget {
  const ReaderSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 14),
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: context.equranTokens.hair2,
        borderRadius: BorderRadius.circular(EquranRadii.pill),
      ),
    ),
  );
}

/// Handle, serif title, optional subtitle, then [children]. Pass the
/// [scrollController] of a `DraggableScrollableSheet` to make it scroll with
/// the sheet; without one the list shrink-wraps and the sheet hugs its
/// content.
class ReaderSheetFrame extends StatelessWidget {
  const ReaderSheetFrame({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    this.scrollController,
    this.bottomInset = 0,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final ScrollController? scrollController;

  /// Extra bottom space, e.g. the keyboard height.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return RedesignPageTypography(
      child: ListView(
        controller: scrollController,
        shrinkWrap: scrollController == null,
        padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 28 + bottomInset),
        children: <Widget>[
          const ReaderSheetHandle(),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: redesignDisplayStyle(context, size: 30),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 14, color: tokens.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// An eyebrow-labelled group of rows on one hairline card.
class ReaderSheetGroup extends StatelessWidget {
  const ReaderSheetGroup({
    super.key,
    required this.children,
    this.title,
    this.bottomPadding = 20,
  });

  final String? title;
  final List<Widget> children;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
              child: RedesignEyebrow(title!),
            ),
          HairlineCard(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < children.length; i++) ...<Widget>[
                    if (i > 0)
                      Divider(height: 1, thickness: 1, color: tokens.hair),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The round emerald-wash icon well used by every row.
class ReaderIconWell extends StatelessWidget {
  const ReaderIconWell({super.key, required this.icon, this.size = 38});

  /// A [DesignIcon] or an [Icon]; it is tinted by this widget.
  final Widget icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tokens.emWash, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: IconTheme(
        data: IconThemeData(color: tokens.emText, size: 20),
        child: icon,
      ),
    );
  }
}

/// A tappable row: icon well, title with an optional second line, an optional
/// value and a chevron. 64 px tall at minimum.
class ReaderOptionRow extends StatelessWidget {
  const ReaderOptionRow({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.showChevron = true,
    this.selected = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;

  /// Marks the current choice with a check.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              ReaderIconWell(icon: leading),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 13.5, color: tokens.muted),
                  ),
                ),
              ],
              if (selected) ...<Widget>[
                const SizedBox(width: 8),
                DesignIcon(
                  'check',
                  size: 20,
                  strokeWidth: 2,
                  color: tokens.emText,
                ),
              ] else if (showChevron) ...<Widget>[
                const SizedBox(width: 6),
                DesignIcon(
                  'chev',
                  size: 18,
                  strokeWidth: 1.8,
                  color: tokens.muted,
                  mirrorInRtl: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon-well row with a switch at the end.
class ReaderSwitchRow extends StatelessWidget {
  const ReaderSwitchRow({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Semantics(
      container: true,
      toggled: value,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 10, 10),
            child: Row(
              children: <Widget>[
                ReaderIconWell(icon: leading),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: tokens.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: tokens.filled,
                  activeThumbColor: Colors.white,
                  inactiveTrackColor: tokens.hair,
                  inactiveThumbColor: tokens.muted,
                  trackOutlineColor: WidgetStateProperty.resolveWith(
                    (Set<WidgetState> states) =>
                        states.contains(WidgetState.selected)
                        ? Colors.transparent
                        : tokens.hair2,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button labels replace the ambient text style, so the interface family has
/// to be named here.
TextStyle _buttonText(BuildContext context, double size) => TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w600,
  fontFamily: _isArabicScript(context) ? 'NotoNaskhArabic' : 'Inter',
  fontFamilyFallback: const <String>['NotoNaskhArabic'],
);

ButtonStyle readerFilledButtonStyle(BuildContext context) =>
    FilledButton.styleFrom(
      backgroundColor: context.equranTokens.filled,
      foregroundColor: Colors.white,
      disabledBackgroundColor: context.equranTokens.emWash,
      disabledForegroundColor: context.equranTokens.emText,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: _buttonText(context, 15),
    );

ButtonStyle readerOutlinedButtonStyle(BuildContext context) =>
    OutlinedButton.styleFrom(
      foregroundColor: context.equranColors.textPrimary,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      side: BorderSide(color: context.equranTokens.hair2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: _buttonText(context, 15),
    );

ButtonStyle readerTextButtonStyle(BuildContext context, {Color? color}) =>
    TextButton.styleFrom(
      foregroundColor: color ?? context.equranTokens.text2,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      textStyle: _buttonText(context, 14.5),
    );

/// A filled, hairline-bordered text field in the redesign's style.
InputDecoration readerInputDecoration(
  BuildContext context, {
  String? hint,
  String? label,
  String? errorText,
  String? suffixText,
  double radius = 16,
}) {
  final EquranTokens tokens = context.equranTokens;
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    labelText: label,
    labelStyle: TextStyle(color: tokens.muted, fontSize: 15),
    floatingLabelStyle: TextStyle(color: tokens.emText, fontSize: 14),
    errorText: errorText,
    suffixText: suffixText,
    hintStyle: TextStyle(color: tokens.muted, fontSize: 15),
    filled: true,
    fillColor: context.equranColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(tokens.hair2),
    enabledBorder: border(tokens.hair2),
    focusedBorder: border(tokens.emText),
    errorBorder: border(tokens.danger),
    focusedErrorBorder: border(tokens.danger),
    errorStyle: TextStyle(color: tokens.danger, fontSize: 12.5),
  );
}

/// The reader's dialog shell: surface card, 28 px radius, hairline border,
/// serif title and a right-aligned action row.
class ReaderDialog extends StatelessWidget {
  const ReaderDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const <Widget>[],
    this.icon,
    this.maxWidth = 420,
    this.scrollableContent = false,
    this.titleTrailing,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  /// A [DesignIcon] or [Icon] shown in an icon well before the title.
  final Widget? icon;
  final double maxWidth;

  /// True when [content] scrolls itself (a list); it then fills the space
  /// left under the title.
  final bool scrollableContent;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return ReaderFontScope(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        backgroundColor: context.equranColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.xxl),
          side: BorderSide(color: tokens.hair2),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 12, 12),
                child: Row(
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      ReaderIconWell(icon: icon!),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: redesignDisplayStyle(context, size: 24),
                      ),
                    ),
                    ?titleTrailing,
                  ],
                ),
              ),
              if (scrollableContent)
                Flexible(child: content)
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 22, 4),
                    child: content,
                  ),
                ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 14),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
              if (actions.isEmpty) const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// A two-button confirmation. [destructive] paints the confirm label in the
/// danger colour instead of filling it.
class ReaderConfirmDialog extends StatelessWidget {
  const ReaderConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    this.icon,
    this.destructive = false,
  });

  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;
  final Widget? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return ReaderDialog(
      title: title,
      icon: icon,
      content: Text(
        body,
        style: TextStyle(fontSize: 14.5, height: 1.45, color: tokens.text2),
      ),
      actions: <Widget>[
        TextButton(
          style: readerTextButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        if (destructive)
          TextButton(
            style: readerTextButtonStyle(context, color: tokens.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          )
        else
          FilledButton(
            style: readerFilledButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
      ],
    );
  }
}

/// A single-choice list in a dialog. Same data as [AppSelectionDialog], in the
/// reader's style.
class ReaderChoiceDialog<T> extends StatelessWidget {
  const ReaderChoiceDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.selectedValue,
    required this.options,
    this.maxWidth = 440,
  });

  final String title;
  final Widget icon;
  final T selectedValue;
  final List<AppSelectionOption<T>> options;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ReaderDialog(
      title: title,
      icon: icon,
      maxWidth: maxWidth,
      titleTrailing: IconButton44(
        designIcon: 'x',
        tooltip: l.close,
        ghost: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      scrollableContent: true,
      content: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: options.length,
        itemBuilder: (BuildContext context, int index) {
          final AppSelectionOption<T> option = options[index];
          return ReaderChoiceTile(
            title: option.title,
            subtitle: option.subtitle,
            leading: option.leading,
            selected: option.value == selectedValue,
            onTap: () => Navigator.of(context).pop(option.value),
          );
        },
      ),
    );
  }
}

/// One row of a choice list: the current choice gets the emerald wash and a
/// check.
class ReaderChoiceTile extends StatelessWidget {
  const ReaderChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? tokens.emWash : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EquranRadii.large),
          side: BorderSide(color: selected ? tokens.hair2 : Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 12, 8),
              child: Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    IconTheme(
                      data: IconThemeData(color: tokens.text2, size: 20),
                      child: leading!,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? tokens.emText
                                : colors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected) ...<Widget>[
                    const SizedBox(width: 8),
                    DesignIcon(
                      'check',
                      size: 20,
                      strokeWidth: 2,
                      color: tokens.emText,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
