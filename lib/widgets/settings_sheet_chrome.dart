import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/app_slider_theme.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:flutter/material.dart';

/// Building blocks for the settings-style pages (Settings, Appearance,
/// Navigation, Downloads, Prayer settings, the location pickers). They extend
/// the reader sheet chrome with the few pieces those pages need that the
/// reader sheets did not: a slider row, a notice card, a dropdown field and a
/// resource row. Everything here only draws; callers keep their state.

/// A small label above a field, in the page's interface font.
class ReaderFieldLabel extends StatelessWidget {
  const ReaderFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: context.equranTokens.text2,
      ),
    ),
  );
}

/// An eyebrow label with the padding every grouped section uses.
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key, this.top = 4});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.fromSTEB(20, top + 10, 20, 8),
    child: RedesignEyebrow(text),
  );
}

/// A titled slider with its current value in an emerald pill, following the
/// reader's delay control.
class ReaderSliderBlock extends StatelessWidget {
  const ReaderSliderBlock({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.slider,
    this.leading,
    this.minLabel,
    this.maxLabel,
  });

  final String title;
  final String valueLabel;
  final Slider slider;
  final Widget? leading;

  /// Optional captions at the ends of the track, e.g. "A-" and "A+".
  final String? minLabel;
  final String? maxLabel;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final TextStyle endStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: tokens.muted,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                ReaderIconWell(icon: leading!),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontVariations: const [FontVariation('opsz', 15)],
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tokens.emWash,
                  borderRadius: BorderRadius.circular(EquranRadii.pill),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.emText,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: <Widget>[
              if (minLabel != null) Text(minLabel!, style: endStyle),
              Expanded(
                child: SliderTheme(
                  data: AppSliderTheme.player(context),
                  child: slider,
                ),
              ),
              if (maxLabel != null) Text(maxLabel!, style: endStyle),
            ],
          ),
        ],
      ),
    );
  }
}

/// An inline note: an icon and wrapped text on a quiet panel. [danger] turns
/// it into a warning (a missing permission); the icon and the wording carry
/// the meaning, not the colour alone.
class ReaderNotice extends StatelessWidget {
  const ReaderNotice({
    super.key,
    required this.icon,
    required this.text,
    this.danger = false,
    this.action,
    this.margin = EdgeInsets.zero,
  });

  /// A [DesignIcon] or an [Icon].
  final Widget icon;
  final String text;
  final bool danger;

  /// Usually a text button, shown under the text.
  final Widget? action;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final Color accent = danger ? tokens.danger : tokens.emText;
    return Container(
      margin: margin,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: danger
            ? tokens.danger.withValues(alpha: 0.1)
            : context.equranColors.surfaceAlt,
        borderRadius: BorderRadius.circular(EquranRadii.large),
        border: Border.all(
          color: danger ? tokens.danger.withValues(alpha: 0.32) : tokens.hair,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconTheme(
                data: IconThemeData(color: accent, size: 20),
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: tokens.text2,
                  ),
                ),
              ),
            ],
          ),
          if (action != null)
            Align(alignment: AlignmentDirectional.centerStart, child: action),
        ],
      ),
    );
  }
}

/// A text button for a [ReaderNotice] or a row, in the emerald text colour.
ButtonStyle readerNoticeButtonStyle(BuildContext context) =>
    readerTextButtonStyle(context, color: context.equranTokens.emText);

/// A dropdown in the redesign's field style.
class ReaderDropdownField<T> extends StatelessWidget {
  const ReaderDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.hair2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          itemHeight: 52,
          borderRadius: BorderRadius.circular(EquranRadii.large),
          dropdownColor: colors.surface,
          icon: DesignIcon('chevd', size: 18, color: tokens.muted),
          style: TextStyle(
            fontSize: 15,
            color: colors.textPrimary,
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            fontFamilyFallback: const <String>['NotoNaskhArabic'],
          ),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

/// One downloadable resource: an icon well, name, details, a status tag and a
/// trailing action. Used for tafsir, fonts and translations in Settings; the
/// word-by-word card keeps its own inset panel.
class SettingsResourceRow extends StatelessWidget {
  const SettingsResourceRow({
    super.key,
    required this.leading,
    required this.title,
    required this.details,
    required this.statusLabel,
    required this.trailing,
    this.selected = false,
    this.selectedLabel,
    this.installed = false,
    this.updateAvailable = false,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String details;
  final String statusLabel;
  final Widget trailing;

  /// The tafsir or translation currently in use; marked with a check tag
  /// reading [selectedLabel].
  final bool selected;
  final String? selectedLabel;
  final bool installed;
  final bool updateAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
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
                        fontVariations: const [FontVariation('opsz', 15)],
                        fontWeight: FontWeight.w600,
                        color: selected ? tokens.emText : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        PillTag(
                          statusLabel,
                          selected: installed,
                          gold: updateAvailable,
                          compact: true,
                        ),
                        if (selected && selectedLabel != null)
                          PillTag(
                            selectedLabel!,
                            selected: true,
                            designIcon: 'check',
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// The 44 px slot for a download in progress.
class SettingsProgressRing extends StatelessWidget {
  const SettingsProgressRing({super.key, this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return SizedBox.square(
      dimension: 44,
      child: Center(
        child: SizedBox.square(
          dimension: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            value: progress,
            color: tokens.emText,
            backgroundColor: tokens.hair2,
          ),
        ),
      ),
    );
  }
}
