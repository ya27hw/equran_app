import 'dart:convert';

import 'package:equran/duas/widgets/dua_browser_widgets.dart'
    show DuaSearchField;
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:equran/widgets/redesign/hero_panel.dart';
import 'package:equran/widgets/redesign/ornament_divider.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/pill_tag.dart';
import 'package:equran/widgets/redesign/redesign_subpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _asmaUlHusnaAssetPath = 'assets/data/dua/asma_al_husna.json';

/// Widest the hero, search and name grid get on a desktop window; the page
/// frame itself stays full width. Matches the Duas page's column.
const double _asmaContentMaxWidth = 880;

class AsmaUlHusnaName {
  const AsmaUlHusnaName({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.meaning,
  });

  final int number;
  final String name;
  final String transliteration;
  final String meaning;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final String normalizedQuery = query.toLowerCase();
    return name.contains(query) ||
        transliteration.toLowerCase().contains(normalizedQuery) ||
        meaning.toLowerCase().contains(normalizedQuery);
  }

  static AsmaUlHusnaName? fromJson(Object? value) {
    if (value is! Map<String, Object?>) return null;
    final Object? numberValue = value['number'];
    final Object? englishValue = value['en'];
    final Object? meaningValue = englishValue is Map<String, Object?>
        ? englishValue['meaning']
        : null;
    final int? number = numberValue is num ? numberValue.toInt() : null;
    final String? name = value['name'] as String?;
    final String? transliteration = value['transliteration'] as String?;
    final String? meaning = meaningValue as String?;
    if (number == null ||
        name == null ||
        transliteration == null ||
        meaning == null) {
      return null;
    }
    return AsmaUlHusnaName(
      number: number,
      name: name,
      transliteration: transliteration,
      meaning: meaning,
    );
  }
}

class AsmaUlHusnaPage extends StatefulWidget {
  const AsmaUlHusnaPage({super.key, this.showAppBar = true});

  /// Kept for the callers that choose between a tab and a pushed page. The
  /// shared page frame shows a back button only when the route can pop, so
  /// both cases look right.
  final bool showAppBar;

  @override
  State<AsmaUlHusnaPage> createState() => _AsmaUlHusnaPageState();
}

class _AsmaUlHusnaPageState extends State<AsmaUlHusnaPage> {
  late final Future<List<AsmaUlHusnaName>> _namesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _namesFuture = _loadNames();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AsmaUlHusnaName>> _loadNames() async {
    final String rawJson = await rootBundle.loadString(_asmaUlHusnaAssetPath);
    final Object? decoded = jsonDecode(rawJson);
    final Object? data = decoded is Map<String, Object?>
        ? decoded['data']
        : null;
    if (data is! List<Object?>) return const <AsmaUlHusnaName>[];
    return data
        .map(AsmaUlHusnaName.fromJson)
        .whereType<AsmaUlHusnaName>()
        .toList(growable: false);
  }

  void _handleSearchChanged() {
    final String nextQuery = _searchController.text.trim();
    if (nextQuery == _query) return;
    setState(() {
      _query = nextQuery;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return RedesignSubpage(
      title: localizations.asmaUlHusna,
      child: FutureBuilder<List<AsmaUlHusnaName>>(
        future: _namesFuture,
        builder: (context, snapshot) {
          final List<AsmaUlHusnaName> names =
              snapshot.data ?? const <AsmaUlHusnaName>[];
          final List<AsmaUlHusnaName> visibleNames = names
              .where((name) => name.matches(_query))
              .toList(growable: false);

          if (snapshot.connectionState != ConnectionState.done) {
            return const _AsmaLoadingState();
          }
          if (snapshot.hasError || names.isEmpty) {
            return _AsmaMessageState(
              title: localizations.namesUnavailable,
              message: localizations.unableLoadAsmaUlHusna,
            );
          }

          return _AsmaNamesContent(
            names: names,
            visibleNames: visibleNames,
            searchController: _searchController,
          );
        },
      ),
    );
  }
}

class _AsmaNamesContent extends StatelessWidget {
  const _AsmaNamesContent({
    required this.names,
    required this.visibleNames,
    required this.searchController,
  });

  final List<AsmaUlHusnaName> names;
  final List<AsmaUlHusnaName> visibleNames;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _asmaContentMaxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Columns follow the content width after the page gutters, so a
            // phone keeps two readable columns and a laptop gets five.
            final double width =
                constraints.maxWidth - 2 * EquranSpacing.pagePadding;
            final int columns = width >= 720
                ? 5
                : width >= 560
                ? 4
                : width >= 400
                ? 3
                : 2;
            // Cards grow with the text size so the meaning never clips.
            final double textScale = MediaQuery.textScalerOf(context)
                .scale(1)
                .clamp(1.0, 2.0);
            final double cardHeight = 176 * textScale;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    EquranSpacing.pagePadding,
                    4,
                    EquranSpacing.pagePadding,
                    0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(<Widget>[
                      DuaSearchField(
                        controller: searchController,
                        hint: localizations.searchNamesHint,
                      ),
                      const SizedBox(height: 16),
                      const _AsmaHeaderCard(),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          4,
                          26,
                          4,
                          12,
                        ),
                        child: RedesignEyebrow(
                          localizations.allNamesCount(names.length),
                        ),
                      ),
                      if (visibleNames.isEmpty)
                        _AsmaMessageState(
                          title: localizations.noNamesFound,
                          message: localizations.tryAnotherAsmaSearch,
                        ),
                    ]),
                  ),
                ),
                if (visibleNames.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      EquranSpacing.pagePadding,
                      0,
                      EquranSpacing.pagePadding,
                      32,
                    ),
                    sliver: SliverGrid.builder(
                      itemCount: visibleNames.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: cardHeight,
                      ),
                      itemBuilder: (context, index) {
                        final AsmaUlHusnaName name = visibleNames[index];
                        return _NameCard(
                          name: name,
                          onTap: () => _showNameSheet(context, name),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AsmaHeaderCard extends StatelessWidget {
  const _AsmaHeaderCard();

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return HeroPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 22, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DesignIcon('sparkle', size: 16, color: tokens.featGold),
              const SizedBox(width: 8),
              Flexible(
                child: RedesignEyebrow(
                  localizations.the99BeautifulNamesOfAllah,
                  color: tokens.featText2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'أَسْمَاءُ اللَّهِ الْحُسْنَى',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: EquranTextStyles.surahTitleStyle(
              fontSize: 38,
              color: tokens.onFeat,
            ),
          ),
          const SizedBox(height: 14),
          const OrnamentDivider(onHero: true),
          const SizedBox(height: 14),
          Text(
            'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: EquranTextStyles.surahTitleStyle(
              fontSize: 24,
              color: tokens.featGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localizedSurahAyahLabel(localizations, 7, 180),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.featText2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.name, required this.onTap});

  final AsmaUlHusnaName name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;

    // The same hairline surface and tap ink as the Duas theme tiles.
    return HairlineCard(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(EquranRadii.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PillTag(
                    name.number.toString().padLeft(2, '0'),
                    gold: true,
                    compact: true,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name.name,
                        maxLines: 1,
                        textDirection: TextDirection.rtl,
                        style: EquranTextStyles.surahTitleStyle(
                          fontSize: 32,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  name.transliteration,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.emText,
                  ),
                ),
                const SizedBox(height: 3),
                // Two lines always reserved, so one-line and two-line meanings
                // keep the names and transliterations on the same baseline.
                SizedBox(
                  height:
                      MediaQuery.textScalerOf(context).scale(12.5) * 1.3 * 2,
                  child: Text(
                    name.meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: tokens.text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AsmaLoadingState extends StatelessWidget {
  const _AsmaLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: CircularProgressIndicator(color: context.equranTokens.emText),
      ),
    );
  }
}

class _AsmaMessageState extends StatelessWidget {
  const _AsmaMessageState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: redesignDisplayStyle(context, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: tokens.text2),
          ),
        ],
      ),
    );
  }
}

Future<void> _showNameSheet(BuildContext context, AsmaUlHusnaName name) async {
  await showReaderSheet<void>(
    context: context,
    builder: (BuildContext context) {
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      final EquranColors colors = context.equranColors;
      final EquranTokens tokens = context.equranTokens;
      return RedesignPageTypography(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const ReaderSheetHandle(),
              const SizedBox(height: 10),
              Text(
                name.name,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: EquranTextStyles.surahTitleStyle(
                  fontSize: 52,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.transliteration,
                textAlign: TextAlign.center,
                style: redesignDisplayStyle(
                  context,
                  size: 26,
                  color: tokens.goldText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.meaning,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontVariations: const [FontVariation('opsz', 15)],
                  height: 1.45,
                  color: tokens.text2,
                ),
              ),
              const SizedBox(height: 22),
              const OrnamentDivider(),
              const SizedBox(height: 18),
              Text(
                localizations.reciteThisNameInDua,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  color: tokens.muted,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: readerOutlinedButtonStyle(context),
                child: Text(localizations.close),
              ),
            ],
          ),
        ),
      );
    },
  );
}
