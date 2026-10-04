import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:equran/widgets/redesign/hairline_card.dart';
import 'package:flutter/material.dart';

/// A collapsible settings section in the redesign's hairline card style.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final EquranTokens tokens = context.equranTokens;
    final EquranColors colors = context.equranColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HairlineCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(EquranRadii.xl - 1),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
              iconColor: tokens.muted,
              collapsedIconColor: tokens.muted,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.emWash,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: tokens.emText),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: tokens.muted),
              ),
              children: <Widget>[
                Divider(height: 1, thickness: 1, color: tokens.hair),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
