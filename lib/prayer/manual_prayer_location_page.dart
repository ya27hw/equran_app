import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:flutter/material.dart';

String? validatePrayerCoordinate(
  String? value, {
  required double min,
  required double max,
  required String label,
  required AppLocalizations localizations,
}) {
  final double? parsed = double.tryParse(value?.trim() ?? '');
  final String fieldName = label.toLowerCase();
  if ((value ?? '').trim().isEmpty) {
    return localizations.validationEnterField(fieldName);
  }
  if (parsed == null) {
    return localizations.validationShouldBeNumber(label);
  }
  if (parsed < min || parsed > max) {
    return localizations.validationMustBeBetween(
      label,
      min.toStringAsFixed(0),
      max.toStringAsFixed(0),
    );
  }
  return null;
}

class ManualPrayerLocationPage extends StatefulWidget {
  const ManualPrayerLocationPage({super.key, this.initialLocation});

  final PrayerLocation? initialLocation;

  @override
  State<ManualPrayerLocationPage> createState() =>
      _ManualPrayerLocationPageState();
}

class _ManualPrayerLocationPageState extends State<ManualPrayerLocationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  @override
  void initState() {
    super.initState();
    final PrayerLocation? initialLocation = widget.initialLocation;
    _labelController = TextEditingController(
      text: initialLocation?.mode == PrayerLocationMode.manual
          ? initialLocation?.label
          : null,
    );
    _latitudeController = TextEditingController(
      text: initialLocation == null
          ? ''
          : initialLocation.latitude.toStringAsFixed(6),
    );
    _longitudeController = TextEditingController(
      text: initialLocation == null
          ? ''
          : initialLocation.longitude.toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    String? helper,
    required Widget icon,
  }) {
    final EquranTokens tokens = context.equranTokens;
    return readerInputDecoration(context, label: label, hint: hint).copyWith(
      helperText: helper,
      helperMaxLines: 3,
      helperStyle: TextStyle(fontSize: 12.5, color: tokens.muted),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: IconTheme(
          data: IconThemeData(color: tokens.muted, size: 20),
          child: icon,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return RedesignSubpage(
      title: localizations.chooseLocationManually,
      child: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    HairlineCard(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        18,
                        18,
                        18,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const ReaderIconWell(icon: DesignIcon('pin')),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  localizations.coordinatesForPrayerTimes,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontVariations: const [
                                      FontVariation('opsz', 15.5),
                                    ],
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            localizations.manualLocationDescription,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: tokens.text2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _labelController,
                            textInputAction: TextInputAction.next,
                            decoration: _decoration(
                              label: localizations.locationLabel,
                              hint: localizations.locationLabelHint,
                              icon: const DesignIcon('tag'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: _decoration(
                              label: localizations.latitude,
                              hint: localizations.exampleCoordinate('25.2048'),
                              helper: localizations.latitudeHelperText,
                              icon: const DesignIcon('compass'),
                            ),
                            validator: (String? value) =>
                                validatePrayerCoordinate(
                                  value,
                                  min: -90,
                                  max: 90,
                                  label: localizations.latitude,
                                  localizations: localizations,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            decoration: _decoration(
                              label: localizations.longitude,
                              hint: localizations.exampleCoordinate('55.2708'),
                              helper: localizations.longitudeHelperText,
                              icon: const Icon(Icons.public_rounded),
                            ),
                            validator: (String? value) =>
                                validatePrayerCoordinate(
                                  value,
                                  min: -180,
                                  max: 180,
                                  label: localizations.longitude,
                                  localizations: localizations,
                                ),
                            onFieldSubmitted: (_) => _save(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ReaderNotice(
                      icon: const DesignIcon('info'),
                      text: localizations.manualLocationPrivacyNotice,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _save,
                      style: readerFilledButtonStyle(context),
                      icon: const DesignIcon('check', size: 18, strokeWidth: 2),
                      label: Text(localizations.saveLocation),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final double latitude = double.parse(_latitudeController.text.trim());
    final double longitude = double.parse(_longitudeController.text.trim());
    final String label = _labelController.text.trim().isEmpty
        ? localizations.manualLocation
        : _labelController.text.trim();

    Navigator.of(context).pop(
      PrayerLocation(
        latitude: latitude,
        longitude: longitude,
        label: label,
        mode: PrayerLocationMode.manual,
      ),
    );
  }
}
