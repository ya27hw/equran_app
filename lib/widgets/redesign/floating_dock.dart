import 'dart:ui' show ImageFilter;
import 'package:equran/services/device_capability_service.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/design_icon.dart';
import 'package:flutter/material.dart';

@immutable
class FloatingDockItem {
  const FloatingDockItem({required this.icon, required this.label});
  final String icon;
  final String label;
}

/// A navigation presentation; the caller owns index and navigation.
/// Place above the caller's safe-area inset.
class FloatingDock extends StatelessWidget {
  const FloatingDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.enableBlur = true,
  }) : assert(items.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < items.length);
  static const double height = 72;
  static const double bottomGap = 12;

  final List<FloatingDockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final radius = BorderRadius.circular(EquranRadii.xxl);
    return ValueListenableBuilder(
      valueListenable: DeviceCapabilityService.instance,
      builder: (context, profile, _) {
        final blur =
            enableBlur &&
            profile.allowsDecorativeEffects &&
            !MediaQuery.disableAnimationsOf(context);
        final body = Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i != 0) const SizedBox(width: 2),
                  Expanded(
                    child: Semantics(
                      selected: selectedIndex == i,
                      button: true,
                      label: items[i].label,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: selectedIndex == i
                              ? tokens.emWash
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: InkWell(
                          onTap: () => onSelected(i),
                          borderRadius: BorderRadius.circular(22),
                          child: ExcludeSemantics(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DesignIcon(
                                  items[i].icon,
                                  size: 22,
                                  strokeWidth: 1.7,
                                  color: selectedIndex == i
                                      ? tokens.emText
                                      : tokens.muted,
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      items[i].label,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        height: 1.2,
                                        fontWeight: FontWeight.w500,
                                        color: selectedIndex == i
                                            ? tokens.emText
                                            : tokens.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
        final surface = DecoratedBox(
          decoration: BoxDecoration(
            color: blur ? tokens.dock : context.equranColors.surface,
            borderRadius: radius,
            border: Border.all(color: tokens.hair2),
          ),
          child: body,
        );
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: tokens.shadow,
                  blurRadius: Theme.of(context).brightness == Brightness.dark
                      ? 34
                      : 26,
                  offset: Offset(
                    0,
                    Theme.of(context).brightness == Brightness.dark ? 14 : 10,
                  ),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: blur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: surface,
                    )
                  : surface,
            ),
          ),
        );
      },
    );
  }
}
