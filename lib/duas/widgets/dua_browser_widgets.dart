import 'dart:async';
import 'dart:math' as math;

import 'package:equran/backend/library.dart';
import 'package:equran/duas/hisn_al_muslim_models.dart';
import 'package:equran/duas/hisn_category_translations.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:equran/prayer/prayer_settings_store.dart';
import 'package:equran/prayer/prayer_times_service.dart';
import 'package:equran/prayer/prayer_timezone_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as timezone;

String duaGroupName(AppLocalizations l, DuaGroup group) => switch (group) {
  DuaGroup.dailyAthkar => l.duaGroupDailyAthkar,
  DuaGroup.prayer => l.duaGroupPrayer,
  DuaGroup.hajjUmrah => l.duaGroupHajjUmrah,
  DuaGroup.travel => l.duaGroupTravel,
  DuaGroup.protectionHardship => l.duaGroupProtectionHardship,
  DuaGroup.healthIllness => l.duaGroupHealthIllness,
  DuaGroup.deathFunerals => l.duaGroupDeathFunerals,
  DuaGroup.repentance => l.duaGroupRepentance,
  DuaGroup.natureWeather => l.duaGroupNatureWeather,
  DuaGroup.marriageFamily => l.duaGroupMarriageFamily,
  DuaGroup.remembrancePraise => l.duaGroupRemembrancePraise,
  DuaGroup.socialEtiquette => l.duaGroupSocialEtiquette,
  DuaGroup.misc => l.duaGroupMisc,
};

IconData duaGroupIcon(DuaGroup group) => switch (group) {
  DuaGroup.dailyAthkar => Icons.wb_sunny_outlined,
  DuaGroup.prayer => Icons.front_hand_outlined,
  DuaGroup.hajjUmrah => Icons.account_balance_outlined,
  DuaGroup.travel => Icons.location_on_outlined,
  DuaGroup.protectionHardship => Icons.shield_outlined,
  DuaGroup.healthIllness => Icons.favorite_border,
  DuaGroup.deathFunerals => Icons.local_florist_outlined,
  DuaGroup.repentance => Icons.refresh,
  DuaGroup.natureWeather => Icons.cloud_outlined,
  DuaGroup.marriageFamily => Icons.family_restroom_outlined,
  DuaGroup.remembrancePraise => Icons.auto_awesome_outlined,
  DuaGroup.socialEtiquette => Icons.emoji_people_outlined,
  DuaGroup.misc => Icons.more_horiz,
};

class DuaGroupDisc extends StatelessWidget {
  const DuaGroupDisc({super.key, required this.group, this.size = 40});
  final DuaGroup group;
  final double size;
  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final gold = group == DuaGroup.dailyAthkar;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gold ? tokens.goldWash : tokens.emWash,
      ),
      child: Icon(
        duaGroupIcon(group),
        size: size / 2,
        color: gold ? tokens.goldText : tokens.emText,
      ),
    );
  }
}

/// UI font scope only; the dua reader's own Arabic typography is unchanged.
class DuaBrowserTypography extends StatelessWidget {
  const DuaBrowserTypography({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final arabic = const [
      'ar',
      'fa',
      'ur',
    ].contains(Localizations.localeOf(context).languageCode);
    final family = arabic ? 'NotoNaskhArabic' : 'Inter';
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: family,
          fontFamilyFallback: const ['NotoNaskhArabic'],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.3,
            colors: [
              context.equranTokens.glow,
              context.equranTokens.glow.withValues(alpha: 0),
            ],
            stops: const [0, .62],
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily: family,
            fontFamilyFallback: const ['NotoNaskhArabic'],
            color: context.equranColors.textPrimary,
          ),
          child: child,
        ),
      ),
    );
  }
}

TextStyle duaDisplayStyle(
  BuildContext context, {
  double size = 36,
  double height = 1.08,
  Color? color,
}) => EquranTextStyles.displayPageTitle(context, color: color).copyWith(
  fontSize: size,
  height: height,
  letterSpacing: (size == 24 ? -.01 : -.015) * size,
  fontVariations: [
    FontVariation('opsz', size),
    const FontVariation('wght', 500),
  ],
  fontFamilyFallback: const ['NotoNaskhArabic'],
);

class DuaEyebrow extends StatelessWidget {
  const DuaEyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final arabic = const [
      'ar',
      'fa',
      'ur',
    ].contains(Localizations.localeOf(context).languageCode);
    return Text(
      arabic ? text : text.toUpperCase(),
      style: EquranTextStyles.eyebrow(context).copyWith(
        color: color,
        fontFamily: arabic ? 'NotoNaskhArabic' : 'Inter',
        height: arabic ? 1.6 : 1,
        letterSpacing: arabic ? 0 : 1.54,
      ),
    );
  }
}

class DuaSearchField extends StatelessWidget {
  const DuaSearchField({
    super.key,
    required this.controller,
    required this.hint,
  });
  final TextEditingController controller;
  final String hint;
  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: tokens.hair),
    );
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 15, color: context.equranColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.muted, fontSize: 15),
        prefixIcon: Icon(Icons.search, size: 19, color: tokens.muted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton44(
                icon: Icons.close,
                tooltip: AppLocalizations.of(context)!.clearSearch,
                ghost: true,
                onPressed: controller.clear,
              ),
        filled: true,
        fillColor: context.equranColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: tokens.emText),
        ),
      ),
    );
  }
}

bool duaCategoryMatches(
  DuaCategoryIndex category,
  String query,
  BuildContext context,
) =>
    category.matches(query, context) ||
    (hisnCategoryTranslations['ar']?[category.id] ?? '').contains(
      query.trim(),
    ) ||
    (hisnCategoryTranslations['en']?[category.id] ?? '').toLowerCase().contains(
      query.trim().toLowerCase(),
    );

enum DuaSuggestionLabel { morning, evening, resume, suggested }

/// Read-only presentation projection of existing prayer settings and view history.
class DuaSuggestion {
  const DuaSuggestion({required this.category, required this.label});
  final DuaCategoryIndex category;
  final DuaSuggestionLabel label;
  String eyebrow(AppLocalizations l) => switch (label) {
    DuaSuggestionLabel.morning => l.forThisMorning,
    DuaSuggestionLabel.evening => l.forThisEvening,
    DuaSuggestionLabel.resume => l.continueAction,
    DuaSuggestionLabel.suggested => l.suggestedForYou,
  };

  static DuaSuggestion? resolve({
    required List<DuaCategoryIndex> categories,
    required DateTime now,
    required PrayerLocation? location,
    required PrayerTimeSettings settings,
    required Iterable<dynamic> history,
  }) {
    if (categories.isEmpty) return null;
    final usual =
        categories.where((c) => c.id == '029').firstOrNull ?? categories.first;
    if (location == null) {
      return DuaSuggestion(
        category: usual,
        label: DuaSuggestionLabel.suggested,
      );
    }
    final zone = settings.useLocationTimezone
        ? PrayerTimezoneService.locationForId(location.timezoneId)
        : null;
    final localNow = zone == null
        ? now.toLocal()
        : timezone.TZDateTime.from(now.toUtc(), zone);
    final day = const PrayerTimesService().calculateDay(
      date: localNow,
      location: location,
      settings: settings,
    );
    if (localNow.hour < 12) {
      return DuaSuggestion(category: usual, label: DuaSuggestionLabel.morning);
    }
    if (!now.isBefore(day.entryFor(PrayerTimeKind.asr).time)) {
      return DuaSuggestion(category: usual, label: DuaSuggestionLabel.evening);
    }
    DateTime? latest;
    DuaCategoryIndex? lastOpened;
    for (final value in history) {
      if (value is! Map) continue;
      final timestamp = DateTime.tryParse(value['updatedAt']?.toString() ?? '');
      final category = categories
          .where((c) => c.id == value['categoryId'])
          .firstOrNull;
      if (category != null &&
          timestamp != null &&
          !timestamp.isAfter(now) &&
          (latest == null || timestamp.isAfter(latest))) {
        latest = timestamp;
        lastOpened = category;
      }
    }
    return DuaSuggestion(
      category: lastOpened ?? usual,
      label: lastOpened == null
          ? DuaSuggestionLabel.morning
          : DuaSuggestionLabel.resume,
    );
  }
}

/// Settings/history react immediately. Clock rebuilds pause with the route
/// and app lifecycle; it never writes history or asks for a location.
class DuaSuggestionScope extends StatefulWidget {
  const DuaSuggestionScope({
    super.key,
    required this.categories,
    required this.builder,
    this.now,
  });
  final List<DuaCategoryIndex> categories;
  final Widget Function(BuildContext, DuaSuggestion?) builder;
  final DateTime Function()? now;
  @override
  State<DuaSuggestionScope> createState() => _DuaSuggestionScopeState();
}

class _DuaSuggestionScopeState extends State<DuaSuggestionScope>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = true;
  late final Listenable _changes;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _changes = Listenable.merge([
      SettingsDB().listener,
      DuaInteractionsDB().listener,
    ]);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_active && TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _changes,
    builder: (context, _) {
      final store = PrayerSettingsStore();
      final suggestion = DuaSuggestion.resolve(
        categories: widget.categories,
        now: widget.now?.call() ?? DateTime.now(),
        location: store.getLocation(),
        settings: store.getSettings(),
        history: DuaInteractionsDB().box.values,
      );
      return widget.builder(context, suggestion);
    },
  );
}

class DuaCategoryRow extends StatelessWidget {
  const DuaCategoryRow({
    super.key,
    required this.category,
    required this.position,
    required this.onTap,
    this.suggestion,
  });
  final DuaCategoryIndex category;
  final int position;
  final VoidCallback onTap;
  final DuaSuggestion? suggestion;
  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final l = AppLocalizations.of(context)!;
    final highlighted = suggestion?.category.id == category.id;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final secondary =
        hisnCategoryTranslations[isArabic ? 'en' : 'ar']?[category.id] ??
        category.title;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.hair)),
        gradient: highlighted
            ? LinearGradient(
                begin: Directionality.of(context) == TextDirection.rtl
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                end: Directionality.of(context) == TextDirection.rtl
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                stops: const [0, .7],
                colors: [tokens.goldWash, tokens.goldWash.withValues(alpha: 0)],
              )
            : null,
      ),
      child: Semantics(
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 4, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 34,
                    child: Center(
                      child: DisplayNumeral(
                        position.toString().padLeft(2, '0'),
                        size: 17,
                        height: 1,
                        color: tokens.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.localizedTitle(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (highlighted)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: PillTag(suggestion!.eyebrow(l), gold: true),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          secondary,
                          textDirection: isArabic
                              ? TextDirection.ltr
                              : TextDirection.rtl,
                          textAlign:
                              Directionality.of(context) == TextDirection.rtl
                              ? TextAlign.right
                              : TextAlign.left,
                          style: TextStyle(
                            fontFamily: isArabic ? 'Inter' : 'NotoNaskhArabic',
                            fontSize: 15,
                            height: 1.7,
                            color: tokens.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      DisplayNumeral(
                        '${category.duaCount}',
                        size: 20,
                        height: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.duaCount == 1 ? l.dua : l.duasLabel,
                        style: TextStyle(fontSize: 11.5, color: tokens.muted),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.chevron_right, size: 18, color: tokens.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DuaSuggestionHero extends StatelessWidget {
  const DuaSuggestionHero({
    super.key,
    required this.suggestion,
    required this.onBegin,
  });
  final DuaSuggestion suggestion;
  final VoidCallback onBegin;
  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final l = AppLocalizations.of(context)!;
    final heroGold = EquranTokens.ensure(
      tokens.gold,
      against: [tokens.featA, tokens.featB],
      target: 4.5,
      toward: EquranColors.dark.textPrimary,
    );
    return HeroPanel(
      child: Stack(
        children: [
          PositionedDirectional(
            end: -14,
            bottom: -4,
            child: ExcludeSemantics(
              child: CustomPaint(
                size: const Size(210, 130),
                painter: _DuaArchPainter(tokens.gold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DuaEyebrow(suggestion.eyebrow(l), color: heroGold),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Text(
                    suggestion.category.localizedTitle(context),
                    style: duaDisplayStyle(
                      context,
                      size: 27,
                      height: 1.12,
                      color: EquranColors.dark.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l.duasCount(suggestion.category.duaCount)} · ${duaGroupName(l, suggestion.category.group)}',
                  style: TextStyle(fontSize: 13.5, color: tokens.featText2),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onBegin,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(l.beginAction),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.gold,
                    foregroundColor: EquranColors.blackDark.background,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaArchPainter extends CustomPainter {
  const _DuaArchPainter(this.gold);
  final Color gold;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gold.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final radius in [85.0, 59.0, 33.0]) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(105, 130), radius: radius),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
    paint.style = PaintingStyle.fill;
    paint.color = gold.withValues(alpha: .16);
    canvas.drawCircle(const Offset(105, 74), 17, paint);
    paint.color = gold;
    canvas.drawCircle(const Offset(105, 74), 8, paint);
  }

  @override
  bool shouldRepaint(_DuaArchPainter oldDelegate) => oldDelegate.gold != gold;
}
