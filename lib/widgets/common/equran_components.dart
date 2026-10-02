import 'package:equran/widgets/common/equran_asset_image.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:flutter/material.dart';

class EquranSurfaceCard extends StatelessWidget {
  const EquranSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(EquranSpacing.cardPadding),
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final BorderRadius borderRadius = BorderRadius.circular(EquranRadii.large);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? colors.surface,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor ?? colors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.shadow.withAlpha(
                  Theme.of(context).brightness == Brightness.light ? 13 : 32,
                ),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                minimumSize: const Size(42, 42),
                padding: const EdgeInsets.all(10),
                iconSize: 26,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class EquranGradientCard extends StatelessWidget {
  const EquranGradientCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(EquranSpacing.cardPadding),
    this.borderRadius = EquranRadii.xl,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: colors.heroGradient,
            borderRadius: radius,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.primaryStrong.withAlpha(
                  Theme.of(context).brightness == Brightness.light ? 52 : 70,
                ),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class EquranSectionHeader extends StatelessWidget {
  const EquranSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 19, color: colors.primary),
          const SizedBox(width: EquranSpacing.s),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

class EquranIconBadge extends StatelessWidget {
  const EquranIconBadge({
    super.key,
    required this.icon,
    this.size = 42,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.mint,
        borderRadius: BorderRadius.circular(EquranRadii.medium),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: foregroundColor ?? colors.primary,
      ),
    );
  }
}

class EquranShortcutTile extends StatelessWidget {
  const EquranShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.assetPath,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EquranRadii.medium),
      child: SizedBox(
        height: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: colors.mint,
                borderRadius: BorderRadius.circular(EquranRadii.medium),
                border: Border.all(color: colors.border),
              ),
              child: assetPath == null
                  ? Icon(icon, color: colors.primary, size: 30)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(EquranRadii.small),
                      child: EquranAssetImage(
                        assetPath!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(icon, color: colors.primary, size: 30);
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EquranMosqueSilhouette extends StatelessWidget {
  const EquranMosqueSilhouette({super.key, this.opacity = 0.36});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MosqueSilhouettePainter(
        color: Colors.white.withAlpha((opacity * 255).round()),
      ),
    );
  }
}

class _MosqueSilhouettePainter extends CustomPainter {
  const _MosqueSilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;
    final double baseY = h * 0.88;

    final RRect base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.48, w * 0.55, h * 0.40),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(base, paint);

    final Path dome = Path()
      ..moveTo(w * 0.22, h * 0.50)
      ..quadraticBezierTo(w * 0.46, h * 0.12, w * 0.70, h * 0.50)
      ..close();
    canvas.drawPath(dome, paint);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.18, w * 0.035, h * 0.20),
      paint,
    );
    canvas.drawCircle(Offset(w * 0.447, h * 0.15), w * 0.025, paint);

    final RRect minaret = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.72, h * 0.22, w * 0.12, h * 0.66),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(minaret, paint);
    final Path cap = Path()
      ..moveTo(w * 0.70, h * 0.24)
      ..lineTo(w * 0.78, h * 0.10)
      ..lineTo(w * 0.86, h * 0.24)
      ..close();
    canvas.drawPath(cap, paint);

    final Paint cutout = Paint()
      ..color = Colors.white.withAlpha(115)
      ..style = PaintingStyle.fill;
    final RRect arch = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, h * 0.60, w * 0.18, h * 0.28),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(arch, cutout);

    final Paint stepPaint = Paint()
      ..color = color.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(w * 0.10, baseY),
      Offset(w * 0.88, baseY),
      stepPaint,
    );
    canvas.drawLine(
      Offset(w * 0.16, baseY + h * 0.06),
      Offset(w * 0.82, baseY + h * 0.06),
      stepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MosqueSilhouettePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class EquranOpenBookMark extends StatelessWidget {
  const EquranOpenBookMark({super.key, this.opacity = 0.32});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OpenBookPainter(
        color: Colors.white.withAlpha((opacity * 255).round()),
        gold: context.equranColors.accentGold.withAlpha(
          ((opacity + 0.1).clamp(0, 1) * 255).round(),
        ),
      ),
    );
  }
}

class _OpenBookPainter extends CustomPainter {
  const _OpenBookPainter({required this.color, required this.gold});

  final Color color;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pagePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final double w = size.width;
    final double h = size.height;

    final Path left = Path()
      ..moveTo(w * 0.12, h * 0.34)
      ..quadraticBezierTo(w * 0.36, h * 0.18, w * 0.50, h * 0.36)
      ..lineTo(w * 0.50, h * 0.82)
      ..quadraticBezierTo(w * 0.34, h * 0.64, w * 0.12, h * 0.76)
      ..close();
    final Path right = Path()
      ..moveTo(w * 0.50, h * 0.36)
      ..quadraticBezierTo(w * 0.64, h * 0.18, w * 0.88, h * 0.34)
      ..lineTo(w * 0.88, h * 0.76)
      ..quadraticBezierTo(w * 0.66, h * 0.64, w * 0.50, h * 0.82)
      ..close();
    canvas.drawPath(left, pagePaint);
    canvas.drawPath(right, pagePaint);
    canvas.drawLine(
      Offset(w * 0.50, h * 0.34),
      Offset(w * 0.50, h * 0.84),
      linePaint,
    );
    for (final double y in <double>[0.46, 0.56, 0.66]) {
      canvas.drawLine(
        Offset(w * 0.22, h * y),
        Offset(w * 0.42, h * (y - 0.03)),
        linePaint,
      );
      canvas.drawLine(
        Offset(w * 0.58, h * (y - 0.03)),
        Offset(w * 0.80, h * y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OpenBookPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.gold != gold;
  }
}
