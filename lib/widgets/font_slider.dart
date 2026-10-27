import 'package:equran/backend/library.dart' show SettingsDB;
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:equran/utils/number_formatting.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

const double _minArabicFontSize = 25;
const double _maxArabicFontSize = 45;

/// Translation text size shared with the reader card and the hifz session.
/// Stored under `fontSizeTranslation`; the backup check allows 10 to 30.
const double kMinTranslationFontSize = 10;
const double kMaxTranslationFontSize = 30;
const double kDefaultTranslationFontSize = 16;

class FontSlider extends StatefulWidget {
  const FontSlider({super.key, required this.showTranslationControls});

  final bool showTranslationControls;

  @override
  State<FontSlider> createState() => _FontSliderState();
}

class _FontSliderState extends State<FontSlider> {
  late double _fontSize;
  late double _fontSizeTranslation;
  late String _translationFontFamily;
  late bool _translationFontBold;
  late bool _translationHighContrast;

  @override
  void initState() {
    super.initState();
    if (SettingsDB().quranScriptStyle == 'qpc-v4') {
      QpcV4FontService.instance.ensureFontLoadedForPage(1).then((success) {
        if (success && mounted) {
          setState(() {});
        }
      });
    }
    _normalizeSavedFontSize(
      key: 'fontSize',
      defaultValue: 31,
      min: _minArabicFontSize,
      max: _maxArabicFontSize,
    );
    _normalizeSavedFontSize(
      key: 'fontSizeTranslation',
      defaultValue: kDefaultTranslationFontSize,
      min: kMinTranslationFontSize,
      max: kMaxTranslationFontSize,
    );
    _fontSize = _savedFontSize(
      key: 'fontSize',
      defaultValue: 31,
      min: _minArabicFontSize,
      max: _maxArabicFontSize,
    );
    _fontSizeTranslation = _savedFontSize(
      key: 'fontSizeTranslation',
      defaultValue: kDefaultTranslationFontSize,
      min: kMinTranslationFontSize,
      max: kMaxTranslationFontSize,
    );
    _translationFontFamily = SettingsDB().translationFontFamily;
    _translationFontBold = SettingsDB().translationFontBold;
    _translationHighContrast = SettingsDB().translationHighContrast;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: <Widget>[
        _buildSliderRow(
          context: context,
          title: localizations.arabicTextSize,
          value: _fontSize,
          min: _minArabicFontSize,
          max: _maxArabicFontSize,
          onChanged: (value) {
            setState(() {
              _fontSize = value;
            });
            SettingsDB().put('fontSize', value);
          },
        ),
        if (widget.showTranslationControls) ...<Widget>[
          _buildSliderRow(
            context: context,
            title: localizations.translationTextSize,
            value: _fontSizeTranslation,
            min: kMinTranslationFontSize,
            max: kMaxTranslationFontSize,
            onChanged: (value) {
              setState(() {
                _fontSizeTranslation = value;
              });
              SettingsDB().put('fontSizeTranslation', value);
            },
          ),
          _buildAccessibilityOptionsRow(context),
        ],
        _FontPreview(
          fontSize: _fontSize,
          fontSizeTranslation: _fontSizeTranslation,
          showTranslation: widget.showTranslationControls,
          fontFamily: _translationFontFamily,
          isBold: _translationFontBold,
          highContrast: _translationHighContrast,
        ),
      ],
    );
  }

  double _savedFontSize({
    required String key,
    required double defaultValue,
    required double min,
    required double max,
  }) {
    final Object? value = SettingsDB().get(key, defaultValue: defaultValue);
    final double fontSize = value is num ? value.toDouble() : defaultValue;
    return fontSize.clamp(min, max).toDouble();
  }

  void _normalizeSavedFontSize({
    required String key,
    required double defaultValue,
    required double min,
    required double max,
  }) {
    final Object? value = SettingsDB().get(key, defaultValue: defaultValue);
    final double fontSize = value is num ? value.toDouble() : defaultValue;
    final double clampedFontSize = fontSize.clamp(min, max).toDouble();
    if (fontSize != clampedFontSize || value is! double) {
      SettingsDB().put(key, clampedFontSize);
    }
  }

  Widget _buildSliderRow({
    required BuildContext context,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return ReaderSliderBlock(
      title: title,
      valueLabel: formatCompactNumber(value),
      minLabel: 'A−',
      maxLabel: 'A+',
      slider: Slider(
        value: value,
        min: min,
        max: max,
        label: formatCompactNumber(value),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAccessibilityOptionsRow(BuildContext context) {
    final tokens = context.equranTokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ACCESSIBILITY & STYLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: tokens.muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildChoiceChip(
                label: 'Serif',
                selected: _translationFontFamily == 'Newsreader',
                onSelected: (_) {
                  setState(() => _translationFontFamily = 'Newsreader');
                  SettingsDB().setTranslationFontFamily('Newsreader');
                },
              ),
              _buildChoiceChip(
                label: 'Sans',
                selected: _translationFontFamily == 'Inter',
                onSelected: (_) {
                  setState(() => _translationFontFamily = 'Inter');
                  SettingsDB().setTranslationFontFamily('Inter');
                },
              ),
              _buildFilterChip(
                label: 'Bold',
                icon: Icons.format_bold_rounded,
                selected: _translationFontBold,
                onSelected: (val) {
                  setState(() => _translationFontBold = val);
                  SettingsDB().setTranslationFontBold(val);
                },
              ),
              _buildFilterChip(
                label: 'High Contrast',
                icon: Icons.contrast_rounded,
                selected: _translationHighContrast,
                onSelected: (val) {
                  setState(() => _translationHighContrast = val);
                  SettingsDB().setTranslationHighContrast(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final tokens = context.equranTokens;
    final colors = context.equranColors;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelected(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? tokens.emWash : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? tokens.emText : tokens.hair2,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? tokens.emText : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final tokens = context.equranTokens;
    final colors = context.equranColors;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelected(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? tokens.emWash : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? tokens.emText : tokens.hair2,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 15,
              color: selected ? tokens.emText : colors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? tokens.emText : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontPreview extends StatelessWidget {
  const _FontPreview({
    required this.fontSize,
    required this.fontSizeTranslation,
    required this.showTranslation,
    this.fontFamily,
    this.isBold,
    this.highContrast,
  });

  final double fontSize;
  final double fontSizeTranslation;
  final bool showTranslation;
  final String? fontFamily;
  final bool? isBold;
  final bool? highContrast;

  @override
  Widget build(BuildContext context) {
    final int translationIndex = SettingsDB().get(
      'translation',
      defaultValue: 0,
    );
    final quran.Translation selectedTranslation = quran
        .Translation
        .values[translationIndex.clamp(0, quran.Translation.values.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            quran.getVerse(1, 1),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: EquranTextStyles.fontFamilyForVerse(1, 1),
              height: 1.65,
              fontSize: fontSize,
            ),
          ),
          if (showTranslation) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              quran.cleanTranslationText(
                quran.getVerseTranslation(
                  1,
                  1,
                  translation: selectedTranslation,
                ),
              ),
              textAlign: TextAlign.center,
              // Same resolver as the reader card (ReadQuranCard), so the
              // preview shows the reader's translation face and colour.
              style: EquranTextStyles.displayTranslation(
                context,
                size: fontSizeTranslation,
                fontFamily: fontFamily,
                isBold: isBold,
                highContrast: highContrast,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
