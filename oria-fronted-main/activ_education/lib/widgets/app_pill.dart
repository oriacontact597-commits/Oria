import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pastille/badge coloré (status).
/// Variantes : success, warning, error, primary, neutral.
class AppPill extends StatelessWidget {
  final String label;
  final AppPillVariant variant;
  final IconData? icon;

  const AppPill({
    super.key,
    required this.label,
    this.variant = AppPillVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _variantColors(variant);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colors.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _PillColors _variantColors(AppPillVariant v) {
    switch (v) {
      case AppPillVariant.success:
        return _PillColors(AppColors.success.withOpacity(0.12), AppColors.success);
      case AppPillVariant.warning:
        return _PillColors(AppColors.warning.withOpacity(0.12), AppColors.warning);
      case AppPillVariant.error:
        return _PillColors(AppColors.error.withOpacity(0.12), AppColors.error);
      case AppPillVariant.primary:
        return _PillColors(AppColors.primary.withOpacity(0.10), AppColors.primary);
      case AppPillVariant.neutral:
        return _PillColors(AppColors.surfaceSubtle, AppColors.textMedium);
    }
  }
}

enum AppPillVariant { primary, success, warning, error, neutral }

class _PillColors {
  final Color background;
  final Color foreground;
  _PillColors(this.background, this.foreground);
}
