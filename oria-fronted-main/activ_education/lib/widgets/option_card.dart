import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Carte de sélection réutilisable (rôle, pays, série, style d'apprentissage…).
///
/// Refactorisé depuis `_RoleCard` (privé dans `profile_setup_screen.dart`).
/// Utilisée par `signup_stepper_screen.dart` pour toutes les sélections à choix unique.
class OptionCard extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    this.icon,
    required this.label,
    this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : AppColors.textMedium,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.label.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sublabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            sublabel!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}