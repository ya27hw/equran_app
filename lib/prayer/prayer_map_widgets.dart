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

/// The card pinned to the bottom of the map: where the pin is, the Qibla
/// bearing and, when picking a location, the three ways to confirm it.
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
    return Container(
      decoration: BoxDecoration(
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
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            locationLabel,
            style: TextStyle(
              fontSize: 15.5,
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
          if (picker != null) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: picker!.onUsePin,
              style: readerOutlinedButtonStyle(context),
              icon: const DesignIcon('pin', size: 18),
              label: Text(picker!.usePinLabel),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: picker!.onUseLive,
              style: readerFilledButtonStyle(context),
              icon: picker!.liveLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(picker!.useLiveLabel),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: picker!.onEnterManually,
              style: readerTextButtonStyle(context, color: tokens.emText),
              icon: const DesignIcon('edit', size: 18),
              label: Text(picker!.enterManuallyLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// The labels and callbacks of the picker buttons. A null callback disables
/// that button.
class PrayerMapPickerActions {
  const PrayerMapPickerActions({
    required this.usePinLabel,
    required this.useLiveLabel,
    required this.enterManuallyLabel,
    required this.onUsePin,
    required this.onUseLive,
    required this.onEnterManually,
    this.liveLoading = false,
  });

  final String usePinLabel;
  final String useLiveLabel;
  final String enterManuallyLabel;
  final VoidCallback? onUsePin;
  final VoidCallback? onUseLive;
  final VoidCallback onEnterManually;
  final bool liveLoading;
}
