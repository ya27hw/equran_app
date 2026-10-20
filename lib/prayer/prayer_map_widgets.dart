import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:flutter/material.dart';

/// Chrome that floats over the location map. The map, its tiles and markers
/// stay in `prayer_map_location_page.dart`; these only draw.

/// The round "find me" button at the top corner of the map.
class PrayerMapLocateButton extends StatelessWidget {
  const PrayerMapLocateButton({
    super.key,
    required this.loading,
    required this.tooltip,
    required this.onPressed,
  });

  final bool loading;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.equranColors.surface,
        shape: CircleBorder(side: BorderSide(color: tokens.hair2)),
        elevation: 0,
        shadowColor: tokens.shadow,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: loading
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.emText,
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      size: 22,
                      color: tokens.emText,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card pinned to the bottom of the map. Picking a location shows a small
/// bar with the pin's coordinates and one button; the Qibla map shows its
/// bearing instead.
class PrayerMapInfoCard extends StatelessWidget {
  const PrayerMapInfoCard({
    super.key,
    required this.locationLabel,
    required this.coordinates,
    this.qiblaLine,
    this.picker,
  });

  final String locationLabel;
  final String coordinates;

  /// "Qibla: 245.3° • 3,200 km to the Kaaba"; null hides the row.
  final String? qiblaLine;

  /// Null on the read-only Qibla map.
  final PrayerMapPickerActions? picker;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final BoxDecoration decoration = BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(EquranRadii.xl),
      border: Border.all(color: tokens.hair2),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: tokens.shadow,
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
    final PrayerMapPickerActions? pick = picker;
    if (pick != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: decoration,
            padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coordinates,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.text2,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: pick.onUsePin,
                  style: readerFilledButtonStyle(context).copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 18),
                    ),
                  ),
                  child: Text(pick.usePinLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: decoration,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            locationLabel,
            style: TextStyle(
              fontSize: 15.5,
              fontVariations: const [FontVariation('opsz', 15.5)],
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            coordinates,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 13,
              color: tokens.text2,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (qiblaLine != null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DesignIcon('compass', size: 17, color: tokens.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    qiblaLine!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tokens.text2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The label and callback of the picker's one button. A null callback
/// disables it.
class PrayerMapPickerActions {
  const PrayerMapPickerActions({
    required this.usePinLabel,
    required this.onUsePin,
  });

  final String usePinLabel;
  final VoidCallback? onUsePin;
}
