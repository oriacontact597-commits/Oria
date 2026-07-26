import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Ligne de 3 stats rapides (chiffre + label).
/// Utilisée dans Profil et Dashboard.
class StatsRow extends StatelessWidget {
  final List<StatItem> items;

  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _StatCard(item: items[i])),
          if (i < items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class StatItem {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;
  const StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });
}

class _StatCard extends StatelessWidget {
  final StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = item.color ?? AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Icon(item.icon, color: c, size: 22),
          const SizedBox(height: AppSpacing.xs),
          Text(item.value, style: AppTextStyles.headingLarge),
          Text(
            item.label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
