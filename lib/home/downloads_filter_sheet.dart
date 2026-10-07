import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:equran/widgets/redesign/pill_tag.dart' show ChipButton;
import 'package:equran/widgets/settings_sheet_chrome.dart';
import 'package:flutter/material.dart';

/// The filters and sort order picked in [DownloadsFilterSheet].
class DownloadsFilterResult {
  const DownloadsFilterResult({
    required this.reciter,
    required this.category,
    required this.surah,
    required this.type,
    required this.sort,
    required this.search,
    required this.groupBy,
  });

  final String reciter;
  final String category;
  final int? surah;
  final String type;
  final String sort;
  final String search;
  final String groupBy;
}

/// Filter and sort sheet for the Downloads page. It starts from the page's
/// current values and pops a [DownloadsFilterResult] on Apply, or null on
/// Cancel. The page decides what to do with it.
class DownloadsFilterSheet extends StatefulWidget {
  const DownloadsFilterSheet({
    super.key,
    required this.initial,
    required this.reciterNames,
    required this.surahItems,
  });

  final DownloadsFilterResult initial;

  /// Reciter code to display name, with `all` first.
  final Map<String, String> reciterNames;

  /// "All surahs" (value null) followed by one item per downloaded surah.
  final List<DropdownMenuItem<int?>> surahItems;

  @override
  State<DownloadsFilterSheet> createState() => _DownloadsFilterSheetState();
}

class _DownloadsFilterSheetState extends State<DownloadsFilterSheet> {
  late String _reciter = widget.initial.reciter;
  late String _category = widget.initial.category;
  late int? _surah = widget.initial.surah;
  late String _type = widget.initial.type;
  late String _sort = widget.initial.sort;
  late String _search = widget.initial.search;
  late String _groupBy = widget.initial.groupBy;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.initial.search,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reciterNames.containsKey(_reciter)) _reciter = 'all';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<(String, String, IconData)> get _sortOptions => _groupBy == 'reciter'
      ? const <(String, String, IconData)>[
          ('reciterAsc', 'Reciter (A → Z)', Icons.sort_by_alpha_rounded),
          ('reciterDesc', 'Reciter (Z → A)', Icons.sort_by_alpha_rounded),
          ('sizeDesc', 'Size (largest first)', Icons.storage_rounded),
          ('sizeAsc', 'Size (smallest first)', Icons.storage_rounded),
        ]
      : const <(String, String, IconData)>[
          ('surahAsc', 'Surah (1 → 114)', Icons.format_list_numbered_rounded),
          ('surahDesc', 'Surah (114 → 1)', Icons.format_list_numbered_rounded),
          ('sizeDesc', 'Size (largest first)', Icons.storage_rounded),
          ('sizeAsc', 'Size (smallest first)', Icons.storage_rounded),
        ];

  void _reset() {
    setState(() {
      _reciter = _category = _type = 'all';
      _surah = null;
      _sort = 'reciterAsc';
      _search = '';
      _searchController.clear();
      _groupBy = 'reciter';
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DownloadsFilterResult(
        reciter: _reciter,
        category: _category,
        surah: _surah,
        type: _type,
        sort: _sort,
        search: _search,
        groupBy: _groupBy,
      ),
    );
  }

  Widget _chips(
    List<(String, String)> options,
    String selected,
    ValueChanged<String> onSelected,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      for (final (String value, String label) in options)
        ChipButton(
          label,
          selected: selected == value,
          designIcon: selected == value ? 'check' : null,
          onPressed: () => onSelected(value),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: ReaderSheetFrame(
                title: 'Filter & Sort Downloads',
                subtitle:
                    'More control over which recitations appear in your library',
                bottomInset: 0,
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (String value) =>
                        setState(() => _search = value.trim()),
                    decoration:
                        readerInputDecoration(
                          context,
                          hint: 'Search recitations or surahs...',
                        ).copyWith(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: DesignIcon(
                              'search',
                              size: 20,
                              color: tokens.muted,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                          ),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).clearButtonTooltip,
                                  icon: DesignIcon(
                                    'x',
                                    size: 18,
                                    color: tokens.muted,
                                  ),
                                  onPressed: () => setState(() {
                                    _search = '';
                                    _searchController.clear();
                                  }),
                                )
                              : null,
                        ),
                  ),
                  const SizedBox(height: 22),
                  const ReaderFieldLabel('Group by'),
                  _chips(
                    const <(String, String)>[
                      ('reciter', 'Reciter'),
                      ('surah', 'Surah'),
                    ],
                    _groupBy,
                    (String value) => setState(() {
                      _groupBy = value;
                      if (value == 'reciter' &&
                          (_sort == 'surahAsc' || _sort == 'surahDesc')) {
                        _sort = 'reciterAsc';
                      }
                      if (value == 'surah' &&
                          (_sort == 'reciterAsc' || _sort == 'reciterDesc')) {
                        _sort = 'surahAsc';
                      }
                    }),
                  ),
                  const SizedBox(height: 22),
                  const ReaderFieldLabel('Sort by'),
                  for (final (String value, String label, IconData icon)
                      in _sortOptions)
                    ReaderChoiceTile(
                      title: label,
                      leading: Icon(icon),
                      selected: _sort == value,
                      onTap: () => setState(() => _sort = value),
                    ),
                  const SizedBox(height: 18),
                  const ReaderFieldLabel('Reciter'),
                  ReaderDropdownField<String>(
                    value: _reciter,
                    onChanged: (String? value) {
                      if (value != null) setState(() => _reciter = value);
                    },
                    items: <DropdownMenuItem<String>>[
                      for (final MapEntry<String, String> e
                          in widget.reciterNames.entries)
                        DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(
                            e.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const ReaderFieldLabel('Surah'),
                  ReaderDropdownField<int?>(
                    value: _surah,
                    onChanged: (int? value) => setState(() => _surah = value),
                    items: widget.surahItems,
                  ),
                  const SizedBox(height: 22),
                  const ReaderFieldLabel('Category'),
                  ReaderDropdownField<String>(
                    value: _category,
                    onChanged: (String? value) {
                      if (value != null) setState(() => _category = value);
                    },
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'all',
                        child: Text(
                          'All',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'makki',
                        child: Text(
                          'Makki',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'madani',
                        child: Text(
                          'Madani',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const ReaderFieldLabel('Content type'),
                  _chips(
                    const <(String, String)>[
                      ('all', 'All'),
                      ('surahs', 'Surahs'),
                      ('ayahs', 'Ayahs'),
                    ],
                    _type,
                    (String value) => setState(() => _type = value),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tokens.hair)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: <Widget>[
                    TextButton(
                      style: readerTextButtonStyle(context),
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    TextButton(
                      style: readerTextButtonStyle(context),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: readerFilledButtonStyle(context),
                      onPressed: _apply,
                      child: const Text('Apply'),
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
}
