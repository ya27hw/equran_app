import 'package:equran/widgets/common/equran_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/l10n/app_localizations.dart';
import 'package:equran/backend/settings_db.dart';
import 'package:equran/backend/daily_tools_config.dart';

class DailyToolsEditSheet extends StatefulWidget {
  const DailyToolsEditSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
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
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String lang = localizations.localeName.split('_').first.toLowerCase();
    final ThemeData theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Bottom sheet handle bar
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.border.withAlpha(160),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Description Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DailyToolsEditSheet.translateCustomizeTitle(lang),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DailyToolsEditSheet.translateCustomizeDesc(lang),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              // Reorderable list
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  scrollController: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _allToolsOrdered.length,
                  // ignore: deprecated_member_use
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final DailyToolType tool = _allToolsOrdered[index];
                    final bool isPinned = _visibleTools.contains(tool);

                    return Container(
                      key: ValueKey<DailyToolType>(tool),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPinned
                              ? colors.primary.withAlpha(80)
                              : colors.border.withAlpha(110),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.mint.withAlpha(isPinned ? 135 : 60),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: tool.assetPath == null
                              ? Icon(
                                  tool.icon,
                                  color: isPinned
                                      ? colors.primary
                                      : colors.textSecondary,
                                  size: 24,
                                )
                              : Opacity(
                                  opacity: isPinned ? 1.0 : 0.6,
                                  child: EquranAssetImage(
                                    tool.assetPath!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        tool.icon,
                                        color: colors.primary,
                                        size: 24,
                                      );
                                    },
                                  ),
                                ),
                        ),
                        title: Text(
                          tool.getTitle(localizations),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isPinned
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          tool.getSubtitle(localizations),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isPinned,
                              activeThumbColor: colors.primary,
                              onChanged: (_) => _toggleTool(tool),
                            ),
                            const SizedBox(width: 4),
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
