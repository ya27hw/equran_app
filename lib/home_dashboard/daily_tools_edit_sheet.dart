import 'package:flutter/material.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/reader_sheet_chrome.dart';
import 'package:equran/widgets/redesign/page_typography.dart';
import 'package:equran/widgets/redesign/redesign_widgets.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/backend/daily_tools_config.dart';

class DailyToolsEditSheet extends StatefulWidget {
  const DailyToolsEditSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showReaderSheet<void>(
      context: context,
      builder: (context) => const DailyToolsEditSheet(),
    );
  }

  static String translateCustomizeTitle(String lang) {
    return switch (lang) {
      'ar' => 'تخصيص الأدوات اليومية',
      'fa' => 'شخصی‌سازی ابزارهای روزانه',
      'bn' => 'দৈনিক সরঞ্জাম কাস্টমাইজ করুন',
      'id' => 'Kustomisasi Alat Sehari-hari',
      'tr' => 'Günlük Araçları Özelleştir',
      'ur' => 'روزانہ کے اوزار ترتیب دیں',
      'de' => 'Tägliche Werkzeuge anpassen',
      _ => 'Customize Daily Tools',
    };
  }

  static String translateCustomizeDesc(String lang) {
    return switch (lang) {
      'ar' =>
        'اسحب لإعادة الترتيب. قم بتفعيل المفاتيح لإظهار أو إخفاء الأدوات في لوحتك.',
      'fa' =>
        'برای تغییر ترتیب بکشید. ابزارها را برای نمایش یا عدم نمایش در داشبورد خود تغییر دهید.',
      'bn' =>
        'ক্রম পরিবর্তন করতে ড্র্যাগ করুন। আপনার ড্যাশবোর্ডে দেখাতে বা লুকাতে টগল করুন।',
      'id' =>
        'Seret untuk mengatur ulang. Aktifkan sakelar untuk menampilkan/menyembunyikan alat.',
      'tr' =>
        'Yeniden sıralamak için sürükleyin. Panonuzda araçları göstermek veya gizlemek için açın/kapatın.',
      'ur' =>
        'ترتیب بدلنے کے لیے ڈریگ کریں۔ اپنے ڈیش بورڈ پر اوزار دکھانے یا چھپانے کے لیے ٹوگل کریں۔',
      'de' =>
        'Ziehen, um neu anzuordnen. Schalter umlegen, um Werkzeuge auf dem Dashboard anzuzeigen oder auszublenden.',
      _ =>
        'Drag to reorder. Toggle switches to show/hide tools on your dashboard.',
    };
  }

  @override
  State<DailyToolsEditSheet> createState() => _DailyToolsEditSheetState();
}

class _DailyToolsEditSheetState extends State<DailyToolsEditSheet> {
  late List<DailyToolType> _visibleTools;
  late List<DailyToolType> _allToolsOrdered;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  void _loadTools() {
    _visibleTools = List<DailyToolType>.from(
      SettingsDB().getVisibleDailyTools(),
    );

    // Construct the ordered list of all tools: visible ones first in their order,
    // followed by hidden ones.
    _allToolsOrdered = List<DailyToolType>.from(_visibleTools);
    for (final DailyToolType type in DailyToolType.values) {
      if (!_allToolsOrdered.contains(type)) {
        _allToolsOrdered.add(type);
      }
    }
  }

  void _toggleTool(DailyToolType tool) {
    final bool isCurrentlyVisible = _visibleTools.contains(tool);

    if (isCurrentlyVisible && _visibleTools.length <= 1) {
      // Prevent disabling the last tool
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      final String locale = localizations.localeName
          .split('_')
          .first
          .toLowerCase();
      final String msg = locale == 'ar'
          ? 'يجب أن تظل أداة واحدة على الأقل مثبتة.'
          : locale == 'fa'
          ? 'حداقل یک ابزار باید سنجاق شده باقی بماند.'
          : 'At least one tool must remain pinned.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() {
      if (isCurrentlyVisible) {
        _visibleTools.remove(tool);
      } else {
        _visibleTools.add(tool);
      }

      // Keep visible list aligned with _allToolsOrdered sequence
      final List<DailyToolType> updatedVisible = <DailyToolType>[];
      for (final DailyToolType t in _allToolsOrdered) {
        if (_visibleTools.contains(t)) {
          updatedVisible.add(t);
        }
      }
      _visibleTools = updatedVisible;

      SettingsDB().setVisibleDailyTools(_visibleTools);
    });
  }

  /// [newIndex] is already adjusted for the removed item (`onReorderItem`).
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final DailyToolType item = _allToolsOrdered.removeAt(oldIndex);
      _allToolsOrdered.insert(newIndex, item);

      // Update the visible list order to reflect the new reordering
      final List<DailyToolType> updatedVisible = <DailyToolType>[];
      for (final DailyToolType t in _allToolsOrdered) {
        if (_visibleTools.contains(t)) {
          updatedVisible.add(t);
        }
      }
      _visibleTools = updatedVisible;

      SettingsDB().setVisibleDailyTools(_visibleTools);
    });
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String lang = localizations.localeName.split('_').first.toLowerCase();

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return RedesignPageTypography(
            child: Column(
              children: [
                const ReaderSheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DailyToolsEditSheet.translateCustomizeTitle(lang),
                        style: redesignDisplayStyle(context, size: 30),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DailyToolsEditSheet.translateCustomizeDesc(lang),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reorderable list
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    scrollController: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _allToolsOrdered.length,
                    onReorderItem: _onReorder,
                    proxyDecorator: (child, index, animation) =>
                        Material(color: Colors.transparent, child: child),
                    itemBuilder: (context, index) {
                      final DailyToolType tool = _allToolsOrdered[index];
                      final bool isPinned = _visibleTools.contains(tool);

                      return Container(
                        key: ValueKey<DailyToolType>(tool),
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: const BoxConstraints(minHeight: 68),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(EquranRadii.xl),
                          border: Border.all(
                            color: isPinned ? tokens.hair2 : tokens.hair,
                          ),
                        ),
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          14,
                          8,
                          4,
                          8,
                        ),
                        child: Row(
                          children: [
                            Opacity(
                              opacity: isPinned ? 1 : 0.55,
                              child: ReaderIconWell(
                                icon: DesignIcon(
                                  _dailyToolDesignIcons[tool] ?? 'grid',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tool.getTitle(localizations),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontVariations: const [
                                        FontVariation('opsz', 15),
                                      ],
                                      fontWeight: FontWeight.w600,
                                      color: isPinned
                                          ? colors.textPrimary
                                          : tokens.text2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tool.getSubtitle(localizations),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.3,
                                      color: tokens.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isPinned,
                              onChanged: (_) => _toggleTool(tool),
                              activeTrackColor: tokens.filled,
                              activeThumbColor: Colors.white,
                              inactiveTrackColor: tokens.hair,
                              inactiveThumbColor: tokens.muted,
                              trackOutlineColor:
                                  WidgetStateProperty.resolveWith(
                                    (Set<WidgetState> states) =>
                                        states.contains(WidgetState.selected)
                                        ? Colors.transparent
                                        : tokens.hair2,
                                  ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                // The design has no drag-grip icon.
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  size: 22,
                                  color: tokens.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The same icons Home shows for each tool.
const Map<DailyToolType, String> _dailyToolDesignIcons =
    <DailyToolType, String>{
      DailyToolType.quran: 'quran',
      DailyToolType.prayer: 'clock',
      DailyToolType.qibla: 'compass',
      DailyToolType.tasbih: 'beads',
      DailyToolType.dua: 'arch',
      DailyToolType.downloads: 'download',
      DailyToolType.search: 'search',
      DailyToolType.readingPlans: 'route',
      DailyToolType.hifz: 'book',
      DailyToolType.asmaUlHusna: 'diamond',
      DailyToolType.statistics: 'bars',
      DailyToolType.calendar: 'calendar',
      DailyToolType.zakah: 'calc',
    };
