import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_text_styles.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/prayer/prayer_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum GalleryPalette {
  emeraldDark('emerald-dark', EquranColors.dark),
  emeraldLight('emerald-light', EquranColors.light),
  black('black-dark', EquranColors.blackDark),
  redLight('red-light', EquranColors.redLight);

  const GalleryPalette(this.label, this.colors);
  final String label;
  final EquranColors colors;
}

/// Uses bundled type and source palettes, without app startup or data services.
ThemeData galleryTheme(GalleryPalette palette) {
  final colors = palette.colors;
  return ThemeData(
    brightness: colors.background.computeLuminance() < 0.5
        ? Brightness.dark
        : Brightness.light,
    fontFamily: 'Inter',
    colorSchemeSeed: colors.primary,
    scaffoldBackgroundColor: colors.background,
    extensions: [colors, EquranTokens.fromColors(colors)],
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.4,
        color: colors.textPrimary,
      ),
    ),
  );
}

class RedesignGalleryApp extends StatefulWidget {
  const RedesignGalleryApp({
    super.key,
    this.palette = GalleryPalette.emeraldDark,
    this.textScale = 1,
    this.direction = TextDirection.ltr,
    this.showControls = true,
  });
  final GalleryPalette palette;
  final double textScale;
  final TextDirection direction;
  final bool showControls;

  @override
  State<RedesignGalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<RedesignGalleryApp> {
  late GalleryPalette palette = widget.palette;
  late double textScale = widget.textScale;
  late TextDirection direction = widget.direction;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: galleryTheme(palette),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.showControls)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in GalleryPalette.values)
                          ChipButton(
                            option.label,
                            selected: option == palette,
                            onPressed: () => setState(() => palette = option),
                          ),
                        ChipButton(
                          'Text 1.3',
                          selected: textScale == 1.3,
                          onPressed: () => setState(
                            () => textScale = textScale == 1 ? 1.3 : 1,
                          ),
                        ),
                        ChipButton(
                          'RTL',
                          selected: direction == TextDirection.rtl,
                          onPressed: () => setState(
                            () => direction = direction == TextDirection.ltr
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                  ),
                const RedesignWidgetGallery(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const gallerySampleNames = [
  'hairline-card',
  'eyebrow-label',
  'display-numeral',
  'pill-tag',
  'chip-button',
  'icon-button44',
  'floating-dock',
  'hero-panel',
  'ornament-divider',
  'salah-glyph',
  'progress-ring',
  'prayer-arch',
];

/// Sample data is confined to this debug file, never a real page.
Widget gallerySample(BuildContext context, String name) {
  final tokens = context.equranTokens;
  switch (name) {
    case 'hairline-card':
      return const HairlineCard(
        padding: EdgeInsets.all(20),
        child: Text('A quiet surface for saved ayahs.'),
      );
    case 'eyebrow-label':
      return const EyebrowLabel('Personal library');
    case 'display-numeral':
      return const Wrap(
        spacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DisplayNumeral('24', size: 22),
          DisplayNumeral('14 / 20', size: 28),
          DisplayNumeral('15:24', size: 40),
        ],
      );
    case 'pill-tag':
      return const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PillTag('#hope'),
          PillTag('Selected', selected: true),
          PillTag('Gratitude', gold: true, icon: Icons.folder_outlined),
        ],
      );
    case 'chip-button':
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChipButton('#patience', count: '4', onPressed: () {}),
          ChipButton('All saved', selected: true, onPressed: () {}),
          const ChipButton('Disabled', onPressed: null),
        ],
      );
    case 'icon-button44':
      return Wrap(
        spacing: 10,
        children: [
          IconButton44(icon: Icons.search, tooltip: 'Search', onPressed: () {}),
          IconButton44(
            icon: Icons.more_horiz,
            tooltip: 'More',
            ghost: true,
            onPressed: () {},
          ),
          const IconButton44(
            icon: Icons.edit_outlined,
            tooltip: 'Disabled',
            onPressed: null,
          ),
        ],
      );
    case 'floating-dock':
      return FloatingDock(
        items: galleryDockItems,
        selectedIndex: 1,
        onSelected: (_) {},
      );
    case 'hero-panel':
      return HeroPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For this evening',
              style: EquranTextStyles.displaySectionTitle(
                context,
                color: EquranColors.dark.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A moment of remembrance.',
              style: TextStyle(color: tokens.featText2),
            ),
            const SizedBox(height: 16),
            DisplayNumeral(
              '15:24',
              size: 40,
              color: EquranColors.dark.textPrimary,
            ),
          ],
        ),
      );
    case 'ornament-divider':
      return const OrnamentDivider();
    case 'salah-glyph':
      return Wrap(
        spacing: 18,
        runSpacing: 12,
        children: [
          for (final state in SalahGlyphState.values)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SalahGlyph(state: state, size: 28, semanticLabel: state.name),
                const SizedBox(height: 7),
                Text(
                  state.name,
                  style: TextStyle(fontSize: 11, color: tokens.muted),
                ),
              ],
            ),
        ],
      );
    case 'progress-ring':
      return Wrap(
        spacing: 28,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ProgressRing(
            value: 0.7,
            color: tokens.gold,
            trackColor: tokens.hair2,
            child: const DisplayNumeral('14', size: 22),
          ),
          ProgressRing(
            value: 0.7,
            innerValue: 0.4,
            color: tokens.gold,
            innerColor: tokens.emText,
            trackColor: tokens.hair2,
            size: 150,
            strokeWidth: 11.25,
            ringGap: 5.625,
            child: const DisplayNumeral('2 / 5', size: 28),
          ),
        ],
      );
    case 'prayer-arch':
      return Wrap(
        spacing: 22,
        children: [
          for (final kind in PrayerTimeKind.values)
            PrayerArch(kind: kind, semanticLabel: kind.name),
        ],
      );
    default:
      throw ArgumentError.value(name, 'name', 'Unknown gallery sample');
  }
}

const galleryDockItems = [
  FloatingDockItem(icon: 'home', label: 'Home'),
  FloatingDockItem(icon: 'quran', label: 'Quran'),
  FloatingDockItem(icon: 'clock', label: 'Prayer'),
  FloatingDockItem(icon: 'arch', label: 'Duas'),
  FloatingDockItem(icon: 'grid', label: 'More'),
];

class RedesignWidgetGallery extends StatelessWidget {
  const RedesignWidgetGallery({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Shared widgets',
            style: EquranTextStyles.displayPageTitle(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Phase 1 · debug gallery',
            style: TextStyle(color: context.equranTokens.muted),
          ),
          for (final name in gallerySampleNames) ...[
            const SizedBox(height: 24),
            Text(
              name,
              style: TextStyle(fontSize: 12, color: context.equranTokens.muted),
            ),
            const SizedBox(height: 10),
            // The dock owns its 14 px inset, rather than inheriting page padding.
            if (name == 'floating-dock')
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: 72,
                  child: OverflowBox(
                    minWidth: constraints.maxWidth + 40,
                    maxWidth: constraints.maxWidth + 40,
                    child: gallerySample(context, name),
                  ),
                ),
              )
            else
              gallerySample(context, name),
          ],
          const SizedBox(height: 32),
          const EyebrowLabel('Newsreader axes'),
          const SizedBox(height: 12),
          const NewsreaderSpecimen(),
        ],
      ),
    );
  }
}

class NewsreaderSpecimen extends StatelessWidget {
  const NewsreaderSpecimen({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final face in [
        (400, false),
        (500, false),
        (600, false),
        (400, true),
      ]) ...[
        const SizedBox(height: 16),
        Text(
          '${face.$1}${face.$2 ? ' italic' : ' upright'}',
          style: TextStyle(fontSize: 12, color: context.equranTokens.muted),
        ),
        for (final size in [16.0, 24.0, 36.0, 40.0])
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${size.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.equranTokens.muted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Mercy 012',
                    style: TextStyle(
                      fontFamily: 'Newsreader',
                      fontSize: size,
                      height: 1.15,
                      fontWeight: FontWeight.values[face.$1 ~/ 100 - 1],
                      fontStyle: face.$2 ? FontStyle.italic : FontStyle.normal,
                      fontVariations: [
                        FontVariation('wght', face.$1.toDouble()),
                        FontVariation('opsz', size),
                      ],
                      fontFeatures: const [
                        FontFeature.liningFigures(),
                        FontFeature.tabularFigures(),
                      ],
                      color: context.equranColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
}
