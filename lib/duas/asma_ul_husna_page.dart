import 'dart:convert';

import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/utils/app_radii.dart';
import 'package:equran/utils/quran_display.dart';
import 'package:equran/widgets/redesign/page_typography.dart'
    show redesignDisplayStyle;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _asmaUlHusnaAssetPath = 'assets/data/dua/asma_al_husna.json';

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

  final bool showAppBar;

  @override
  State<AsmaUlHusnaPage> createState() => _AsmaUlHusnaPageState();
}

class _AsmaUlHusnaPageState extends State<AsmaUlHusnaPage> {
  late final Future<List<AsmaUlHusnaName>> _namesFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  bool _searchActive = false;

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
    _searchFocusNode.dispose();
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

  void _focusSearch() {
    setState(() {
      _searchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool showAppBar = widget.showAppBar;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          if (showAppBar)
            SliverAppBar(
              pinned: true,
              toolbarHeight: 64,
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _searchActive
                    ? _NavSearchField(
                        key: const ValueKey<String>('asma-search-field'),
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                      )
                    : Text(
                        localizations.asmaUlHusna,
                        key: const ValueKey<String>('asma-title'),
                      ),
              ),
              centerTitle: !_searchActive,
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: theme.textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              iconTheme: IconThemeData(color: colors.textSecondary),
              actionsIconTheme: IconThemeData(color: colors.textSecondary),
              actions: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: IconButton(
                    key: ValueKey<bool>(_searchActive),
                    tooltip: _searchActive
                        ? localizations.closeSearch
                        : localizations.searchNames,
                    onPressed: _searchActive ? _closeSearch : _focusSearch,
                    icon: Icon(
                      _searchActive
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                    ),
                  ),
                ),
              ],
            ),
          if (!showAppBar)
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        localizations.asmaUlHusna,
                        style: redesignDisplayStyle(context, size: 32),
                      ),
                      const SizedBox(height: 14),
                      _NavSearchField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverSafeArea(
            top: false,
            bottom: true,
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[
                FutureBuilder<List<AsmaUlHusnaName>>(
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

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: _AsmaNamesContent(
                          names: names,
                          visibleNames: visibleNames,
                        ),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSearchField extends StatelessWidget {
  const _NavSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: localizations.searchNamesHint,
        hintStyle: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
        prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
        filled: true,
        fillColor: colors.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: colors.accentGold),
        ),
      ),
    );
  }
}

class _AsmaNamesContent extends StatelessWidget {
  const _AsmaNamesContent({required this.names, required this.visibleNames});

  final List<AsmaUlHusnaName> names;
  final List<AsmaUlHusnaName> visibleNames;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _AsmaHeaderCard(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          child: Text(
            localizations.allNamesCount(names.length).toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (visibleNames.isEmpty)
          _AsmaMessageState(
            title: localizations.noNamesFound,
            message: localizations.tryAnotherAsmaSearch,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int columns = width >= 1040
                  ? 4
                  : width >= 720
                  ? 3
                  : 2;
              final double aspectRatio = columns >= 4
                  ? 1.18
                  : columns == 3
                  ? 1.08
                  : 0.95;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleNames.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final AsmaUlHusnaName name = visibleNames[index];
                  return _NameCard(
                    name: name,
                    onTap: () => _showNameSheet(context, name),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _AsmaHeaderCard extends StatelessWidget {
  const _AsmaHeaderCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final Color ornamentColor = colors.accentGold.withValues(alpha: 0.50);
    final Color referenceColor = colors.accentGold.withValues(alpha: 0.80);
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= 720;
        final double titleSize = wide ? 44 : 34;
        final double ayahSize = wide ? 30 : 24;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                colors.primaryGradientStart,
                colors.primaryGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: colors.accentGold.withValues(alpha: 0.30),
            ),
          ),
          child: CustomPaint(
            painter: _CornerOrnamentPainter(color: ornamentColor),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, wide ? 30 : 24, 18, 24),
              child: Column(
                children: <Widget>[
                  Text(
                    'أَسْمَاءُ اللَّهِ الْحُسْنَى',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFamily: 'NotoNaskhArabic',
                      color: colors.onPrimary,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    localizations.the99BeautifulNamesOfAllah,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 100,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.accentGold.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFamily: 'NotoNaskhArabic',
                      color: referenceColor,
                      fontSize: ayahSize,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizedSurahAyahLabel(localizations, 7, 180),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: referenceColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CornerOrnamentPainter extends CustomPainter {
  const _CornerOrnamentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const double inset = 8;
    const double length = 16;

    void drawCorner(double x, double y, double horizontal, double vertical) {
      canvas.drawLine(Offset(x, y), Offset(x + horizontal, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + vertical), paint);
    }

    drawCorner(inset, inset, length, length);
    drawCorner(size.width - inset, inset, -length, length);
    drawCorner(inset, size.height - inset, length, -length);
    drawCorner(size.width - inset, size.height - inset, -length, -length);
  }

  @override
  bool shouldRepaint(covariant _CornerOrnamentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.name, required this.onTap});

  final AsmaUlHusnaName name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final TextStyle arabicStyle =
        (theme.textTheme.headlineLarge ?? const TextStyle()).copyWith(
          fontFamily: 'NotoNaskhArabic',
          color: colors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.45,
        );

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.large),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    name.number.toString().padLeft(2, '0'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.accentGold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 38,
                start: 0,
                end: 0,
                bottom: 58,
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.topEnd,
                    child: Text(
                      name.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: arabicStyle,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name.transliteration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name.meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator(color: colors.primary)),
    );
  }
}

class _AsmaMessageState extends StatelessWidget {
  const _AsmaMessageState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

Future<void> _showNameSheet(BuildContext context, AsmaUlHusnaName name) async {
  final ThemeData theme = Theme.of(context);
  final EquranColors colors = context.equranColors;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                name.name,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 52,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name.transliteration,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.accentGold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.meaning,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 100,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.accentGold.withValues(alpha: 0.50),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                localizations.reciteThisNameInDua,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
                child: Text(localizations.close),
              ),
            ],
          ),
        ),
      );
    },
  );
}
