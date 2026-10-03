import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom sheet avec drag handle, style iOS.
/// Wrap n'importe quel widget.
class AppSheet extends StatelessWidget {
  final Widget child;
  final double? initialChildSize;

  const AppSheet({
    super.key,
    required this.child,
    this.initialChildSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(child: child),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  /// Helper pour ouvrir
  static Future<T?> show<T>(BuildContext context, Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppSheet(child: child),
    );
  }
}
