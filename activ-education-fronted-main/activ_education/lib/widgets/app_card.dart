import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Carte générique, radius 16, shadow légère.
/// Utilisée partout dans Explorer, Profil, Home…
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: gradient == null
            ? Border.all(color: AppColors.borderSubtle, width: 1)
            : null,
        boxShadow: AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return container;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: container,
    );
  }
}
