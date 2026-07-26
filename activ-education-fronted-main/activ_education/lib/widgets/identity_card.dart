import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_pill.dart';

/// Carte identité utilisateur (avatar + nom + email + badge rôle).
/// Utilisée dans Profil.
class IdentityCard extends StatelessWidget {
  final String nom;
  final String email;
  final String? photoUrl;
  final String? roleLabel;
  final AppPillVariant roleVariant;

  const IdentityCard({
    super.key,
    required this.nom,
    required this.email,
    this.photoUrl,
    this.roleLabel,
    this.roleVariant = AppPillVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.surfaceSubtle,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            nom.isEmpty ? 'Utilisateur' : nom,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (roleLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppPill(label: roleLabel!, variant: roleVariant, icon: Icons.school),
          ],
        ],
      ),
    );
  }
}
