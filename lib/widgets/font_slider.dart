import 'package:equran/backend/library.dart' show SettingsDB;
import 'package:equran/backend/qpc_v4_font_service.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:equran/utils/number_formatting.dart';
import 'package:flutter/material.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

const double _minArabicFontSize = 25;
const double _maxArabicFontSize = 45;
const double _minTranslationFontSize = 10;
const double _maxTranslationFontSize = 25;

class FontSlider extends StatefulWidget {
  const FontSlider({super.key, required this.showTranslationControls});

  final bool showTranslationControls;

  @override
  State<FontSlider> createState() => _FontSliderState();
}

class _FontSliderState extends State<FontSlider> {
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
      defaultValue: 12,
      min: _minTranslationFontSize,
      max: _maxTranslationFontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = _savedFontSize(
      key: 'fontSize',
      defaultValue: 31,
      min: _minArabicFontSize,
      max: _maxArabicFontSize,
    );
    double fontSizeTranslation = _savedFontSize(
      key: 'fontSizeTranslation',
      defaultValue: 12,
      min: _minTranslationFontSize,
      max: _maxTranslationFontSize,
    );
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: <Widget>[
        _buildSliderRow(
          context: context,
          title: localizations.arabicTextSize,
          value: fontSize,
          min: _minArabicFontSize,
          max: _maxArabicFontSize,
          onChanged: (value) {
            setState(() {
              fontSize = value;
              SettingsDB().put('fontSize', value);
            });
          },
        ),
        if (widget.showTranslationControls)
          _buildSliderRow(
            context: context,
            title: localizations.translationTextSize,
            value: fontSizeTranslation,
            min: _minTranslationFontSize,
            max: _maxTranslationFontSize,
            onChanged: (value) {
              setState(() {
                fontSizeTranslation = value;
                SettingsDB().put('fontSizeTranslation', value);
              });
            },
          ),
        _FontPreview(
          fontSize: fontSize,
          fontSizeTranslation: fontSizeTranslation,
          showTranslation: widget.showTranslationControls,
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
}

class _FontPreview extends StatelessWidget {
  const _FontPreview({
    required this.fontSize,
    required this.fontSizeTranslation,
    required this.showTranslation,
  });

  final double fontSize;
  final double fontSizeTranslation;
  final bool showTranslation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranTokens tokens = context.equranTokens;

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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.text2,
                fontSize: fontSizeTranslation,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
