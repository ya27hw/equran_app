import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/manual_prayer_location_page.dart';
import 'package:equran/prayer/prayer_location_service.dart';
import 'package:equran/prayer/prayer_map_location_page.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart' show ReaderIconWell;
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';

/// Guided location setup in two steps: first choose one way to set the place
/// (current location, map or coordinates), then confirm the result. Pops with
/// the resolved [PrayerLocation], or with nothing when the user leaves.
class PrayerLocationSetupPage extends StatefulWidget {
  const PrayerLocationSetupPage({
    super.key,
    this.initialLocation,
    this.mapLocationPicker,
    this.locationService = const PrayerLocationService(),
  });

  /// The saved location when changing it; null on first setup.
  final PrayerLocation? initialLocation;
  final PrayerLocationPicker? mapLocationPicker;
  final PrayerLocationService locationService;

  @override
  State<PrayerLocationSetupPage> createState() =>
      _PrayerLocationSetupPageState();
}

class _PrayerLocationSetupPageState extends State<PrayerLocationSetupPage> {
  /// The place waiting for confirmation; null while choosing a method.
  PrayerLocation? _candidate;
  bool _resolvingName = false;
  bool _locatingDevice = false;
  String? _errorMessage;
  PrayerLocationFailureReason? _errorReason;

  bool get _isChoosing => _candidate == null;

  Future<void> _useCurrentDevice() async {
    if (_locatingDevice) return;
    setState(() {
      _locatingDevice = true;
      _errorMessage = null;
      _errorReason = null;
    });
    final PrayerLocationResult result = await widget.locationService
        .currentDeviceLocation();
    if (!mounted) return;
    setState(() => _locatingDevice = false);

    final PrayerLocation? location = result.location;
    if (location == null) {
      setState(() {
        _errorMessage = result.message;
        _errorReason = result.failureReason;
      });
      return;
    }
    // Device fixes come back with their place name already resolved.
    setState(() => _candidate = location);
  }

  Future<void> _pickOnMap() async {
    final PrayerLocationPicker picker =
        widget.mapLocationPicker ?? showPrayerMapLocationPicker;
    final PrayerLocation? picked = await picker(
      context,
      widget.initialLocation,
    );
    if (picked == null || !mounted) return;
    await _confirm(picked);
  }

  Future<void> _enterManually() async {
    final PrayerLocation? picked = await Navigator.of(context)
        .push<PrayerLocation>(
          MaterialPageRoute<PrayerLocation>(
            builder: (BuildContext context) => ManualPrayerLocationPage(
              initialLocation: widget.initialLocation,
            ),
          ),
        );
    if (picked == null || !mounted) return;
    await _confirm(picked);
  }

  /// Moves to the confirm step and looks up the place name for [location].
  Future<void> _confirm(PrayerLocation location) async {
    setState(() {
      _candidate = location;
      _resolvingName = true;
      _errorMessage = null;
    });
    final PrayerLocation resolved = await widget.locationService
        .resolveLocationForSave(
          location,
          previousLocation: widget.initialLocation,
        );
    if (!mounted) return;
    setState(() {
      _candidate = resolved;
      _resolvingName = false;
    });
  }

  void _save() {
    final PrayerLocation? candidate = _candidate;
    if (candidate == null || _resolvingName) return;
    Navigator.of(context).pop(candidate);
  }

  void _backToChoices() {
    setState(() {
      _candidate = null;
      _resolvingName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return PopScope(
      // Back from the confirm step returns to the choices, not out of setup.
      canPop: _isChoosing,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !_isChoosing) _backToChoices();
      },
      child: RedesignSubpage(
        title: l.setPrayerLocation,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _isChoosing
                    ? _buildChoices(context, l)
                    : _buildConfirm(context, l),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoices(BuildContext context, AppLocalizations l) {
    final EquranTokens tokens = context.equranTokens;
    final bool busy = _locatingDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.locationSetupTitle, style: _titleStyle(context)),
        const SizedBox(height: 8),
        _bodyText(context, l.locationSetupSubtitle),
        const SizedBox(height: 22),
        _LocationOptionCard(
          key: const ValueKey<String>('location-setup-current'),
          icon: Icons.my_location_rounded,
          title: l.useCurrentLocation,
          description: l.locationOptionCurrentDescription,
          badge: l.recommendedLabel,
          busy: _locatingDevice,
          onTap: busy ? null : _useCurrentDevice,
        ),
        const SizedBox(height: 12),
        _LocationOptionCard(
          key: const ValueKey<String>('location-setup-map'),
          icon: Icons.map_outlined,
          title: l.chooseOnMap,
          description: l.locationOptionMapDescription,
          onTap: busy ? null : _pickOnMap,
        ),
        const SizedBox(height: 12),
        _LocationOptionCard(
          key: const ValueKey<String>('location-setup-manual'),
          icon: Icons.edit_location_alt_outlined,
          title: l.enterCoordinatesManually,
          description: l.locationOptionManualDescription,
          onTap: busy ? null : _enterManually,
        ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 16),
          _SetupError(
            key: const ValueKey<String>('location-setup-error'),
            message: _errorMessage!,
            reason: _errorReason,
          ),
        ],
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.shield_outlined, size: 16, color: tokens.muted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.locationUseNotice,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: tokens.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirm(BuildContext context, AppLocalizations l) {
    final PrayerLocation candidate = _candidate!;
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.confirmLocationTitle, style: _titleStyle(context)),
        const SizedBox(height: 20),
        HairlineCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              ReaderIconWell(
                icon: Icon(Icons.place_outlined, color: tokens.emText),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _resolvingName ? l.findingLocation : candidate.label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${candidate.latitude.toStringAsFixed(4)}, ${candidate.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.muted,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.locationUseNotice,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, height: 1.4, color: tokens.muted),
        ),
        const SizedBox(height: 22),
        FilledButton(
          key: const ValueKey<String>('location-setup-save'),
          onPressed: _resolvingName ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
          child: Text(l.saveLocation),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey<String>('location-setup-change'),
          onPressed: _backToChoices,
          child: Text(l.chooseAnotherWay),
        ),
      ],
    );
  }

  TextStyle _titleStyle(BuildContext context) =>
      redesignDisplayStyle(context, size: 28);

  Widget _bodyText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.45,
        color: context.equranTokens.text2,
      ),
    );
  }
}

/// One way to set the location: an icon, a short name and what it does.
class _LocationOptionCard extends StatelessWidget {
  const _LocationOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? badge;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tokens.hair),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ReaderIconWell(icon: Icon(icon, color: tokens.emText)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (badge != null) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.emWash,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tokens.emText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: tokens.text2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded, color: tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explains a failed device lookup and offers the settings screen that fixes it.
class _SetupError extends StatelessWidget {
  const _SetupError({super.key, required this.message, required this.reason});

  final String message;
  final PrayerLocationFailureReason? reason;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final EquranColors colors = context.equranColors;
    final PrayerLocationService service = const PrayerLocationService();
    final (String, VoidCallback)? fix = switch (reason) {
      PrayerLocationFailureReason.servicesDisabled => (
        l.settings,
        () => service.openLocationSettings(),
      ),
      PrayerLocationFailureReason.permissionDeniedForever => (
        l.appSettings,
        () => service.openAppSettings(),
      ),
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.warningSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: colors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (fix != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(onPressed: fix.$2, child: Text(fix.$1)),
            ),
        ],
      ),
    );
  }
}
