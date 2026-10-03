import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/base_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_pill.dart';
import '../../widgets/identity_card.dart';
import '../../widgets/stats_row.dart';

/// Profil utilisateur — style iOS Settings.
/// Carte identité + 3 stats + sections groupées (Parcours / Préférences / Sécurité / À propos).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nom = '';
  String _email = '';
  String _niveauEtude = '';
  String _objectif = '';
  String _etablissement = '';
  String? _photoUrl;
  int _favorisCount = 0;
  int _rdvCount = 0;
  int _recoCount = 0;
  String _role = 'Élève';
  AppPillVariant _roleVariant = AppPillVariant.primary;
  bool _notificationsOn = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final nom = await BaseService.readSecure('user_nom') ?? '';
      final prenom = await BaseService.readSecure('user_prenom') ?? '';
      final email = await BaseService.readSecure('user_email') ?? '';
      final role = await BaseService.readSecure('user_role') ?? 'ELEVE';
      final niveauEtude =
          await BaseService.readSecure('user_niveau_etude') ?? '';
      final filiere = await BaseService.readSecure('user_filiere') ?? '';
      final metierSouhaite =
          await BaseService.readSecure('user_metier_souhaite') ?? '';
      final etablissementActuel =
          await BaseService.readSecure('user_etablissement_actuel') ?? '';
      final photoUrl = await BaseService.readSecure('user_photo_url');
      String pretty = role;
      AppPillVariant variant = AppPillVariant.primary;
      switch (role.toUpperCase()) {
        case 'ELEVE':
          pretty = 'Élève 🎓';
          variant = AppPillVariant.primary;
          break;
        case 'PARENT':
          pretty = 'Parent 👨‍👩‍👧';
          variant = AppPillVariant.warning;
          break;
        case 'CONSEILLER':
          pretty = 'Conseiller 💼';
          variant = AppPillVariant.success;
          break;
        case 'ADMIN':
        case 'SUPER_ADMIN':
          pretty = 'Administrateur 🛡️';
          variant = AppPillVariant.error;
          break;
      }
      if (mounted) {
        setState(() {
          _nom = '$prenom $nom'.trim();
          _email = email;
          _niveauEtude = niveauEtude;
          _objectif = metierSouhaite.isNotEmpty ? metierSouhaite : filiere;
          _etablissement = etablissementActuel;
          _photoUrl = photoUrl;
          _role = pretty;
          _roleVariant = variant;
        });
      }
      await _refreshFromBackend(role);
      await _loadDynamicStats(role);
    } catch (_) {
      // pas grave
    }
  }

  Future<void> _refreshFromBackend(String role) async {
    final trackingId = await BaseService.readSecure('user_tracking_id');
    if (trackingId == null || trackingId.isEmpty) return;
    if (role.toUpperCase() != 'ELEVE') return;

    try {
      final eleve = await AuthService().getEleve(trackingId);
      await AuthService().saveEleveProfile(eleve);
      if (!mounted) return;
      setState(() {
        _nom = eleve.nomComplet.trim();
        _email = eleve.email;
        _niveauEtude = eleve.niveauEtude ?? '';
        _objectif = (eleve.metierSouhaite?.isNotEmpty ?? false)
            ? eleve.metierSouhaite!
            : (eleve.filiere ?? '');
        _etablissement = eleve.etablissementActuel ?? _etablissement;
        _photoUrl = eleve.photoUrl ?? _photoUrl;
      });
    } catch (_) {}
  }

  Future<void> _loadDynamicStats(String role) async {
    final trackingId = await BaseService.readSecure('user_tracking_id');
    if (trackingId == null || trackingId.isEmpty) return;
    if (role.toUpperCase() != 'ELEVE') return;

    try {
      final stats = await Future.wait([
        AuthService().getEleve(trackingId).then((eleve) async {
          final favs = await ApiService()
              .explorer
              .getFavorisUtilisateur(trackingId, size: 100);
          final rdvs = await ApiService().interaction.getRDVEleve(trackingId);
          final recs =
              await ApiService().prediction.recommander3Signaux(trackingId);
          return {
            'favoris': favs.content.length,
            'rdv': rdvs.length,
            'recommendations': recs.top.length,
            'etablissement': eleve.etablissementActuel ?? '',
            'photo': eleve.photoUrl,
          };
        }),
      ]);

      final payload = stats.first as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _favorisCount = (payload['favoris'] as int?) ?? 0;
        _rdvCount = (payload['rdv'] as int?) ?? 0;
        _recoCount = (payload['recommendations'] as int?) ?? 0;
        if ((payload['etablissement'] as String?)?.isNotEmpty ?? false) {
          _etablissement = payload['etablissement'] as String;
        }
        if ((payload['photo'] as String?) != null) {
          _photoUrl = payload['photo'] as String;
        }
      });
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        title: const Text('Se déconnecter ?'),
        content:
            const Text('Tu devras te reconnecter pour accéder à ton compte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AuthService().logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ─── Identité ────────────────────────────────────────────────
          IdentityCard(
            nom: _nom.isEmpty ? 'Utilisateur' : _nom,
            email: _email.isEmpty ? '—' : _email,
            photoUrl: _photoUrl != null ? resolveImageUrl(_photoUrl) : null,
            roleLabel: _role,
            roleVariant: _roleVariant,
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Stats rapides ──────────────────────────────────────────
          StatsRow(items: [
            StatItem(
              value: '$_favorisCount',
              label: 'Favoris',
              icon: Icons.favorite_rounded,
              color: AppColors.error,
            ),
            StatItem(
              value: '$_recoCount',
              label: 'Recommandations',
              icon: Icons.psychology_alt_rounded,
              color: AppColors.primary,
            ),
            StatItem(
              value: '$_rdvCount',
              label: 'RDV à venir',
              icon: Icons.event_rounded,
              color: AppColors.accent,
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // ─── Mon parcours ───────────────────────────────────────────
          _Section(
            title: 'Mon parcours',
            children: [
              _Tile(
                icon: Icons.school_rounded,
                iconColor: AppColors.primary,
                title: 'Niveau actuel',
                trailing: _TrailingText(
                  _niveauEtude.isEmpty ? 'Non renseigné' : _niveauEtude,
                ),
                onTap: () {},
              ),
              _Tile(
                icon: Icons.school_rounded,
                iconColor: AppColors.success,
                title: 'Université / Établissement',
                trailing: _TrailingText(
                  _etablissement.isEmpty ? 'Non renseigné' : _etablissement,
                ),
                onTap: () {},
              ),
              _Tile(
                icon: Icons.flag_rounded,
                iconColor: AppColors.success,
                title: 'Objectif',
                trailing: _TrailingText(
                  _objectif.isEmpty ? 'Non renseigné' : _objectif,
                ),
                onTap: () {},
              ),
              _Tile(
                icon: Icons.history_rounded,
                iconColor: AppColors.accent,
                title: 'Mes bulletins',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Préférences ────────────────────────────────────────────
          _Section(
            title: 'Préférences',
            children: [
              _Tile(
                icon: Icons.language_rounded,
                iconColor: AppColors.primary,
                title: 'Langue',
                trailing:
                    const Text('Français', style: AppTextStyles.bodyMedium),
                onTap: () {},
              ),
              _Tile(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.warning,
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsOn,
                  onChanged: (v) => setState(() => _notificationsOn = v),
                  activeColor: AppColors.primary,
                ),
                onTap: null,
              ),
              _Tile(
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.textMedium,
                title: 'Mode sombre',
                trailing: const Text(
                  'Bientôt',
                  style: AppTextStyles.caption,
                ),
                onTap: null,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Sécurité ───────────────────────────────────────────────
          _Section(
            title: 'Sécurité',
            children: [
              _Tile(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.primary,
                title: 'Changer le mot de passe',
                onTap: () {},
              ),
              _Tile(
                icon: Icons.shield_outlined,
                iconColor: AppColors.success,
                title: 'Authentification 2FA',
                trailing: const AppPill(
                  label: 'Activé',
                  variant: AppPillVariant.success,
                  icon: Icons.check,
                ),
                onTap: () {},
              ),
              _Tile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.error,
                title: 'Se déconnecter',
                iconOnError: true,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _logout();
                },
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── À propos ───────────────────────────────────────────────
          _Section(
            title: 'À propos',
            children: [
              _Tile(
                icon: Icons.description_outlined,
                iconColor: AppColors.textMedium,
                title: 'Conditions générales',
                onTap: () {},
              ),
              _Tile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.textMedium,
                title: 'Confidentialité',
                onTap: () {},
              ),
              _Tile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textMedium,
                title: 'Version',
                trailing: const Text(
                  '1.2.0',
                  style: AppTextStyles.bodyMedium,
                ),
                onTap: null,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─── Sous-widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMedium,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLast;
  final bool iconOnError;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
    this.isLast = false,
    this.iconOnError = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (iconOnError ? AppColors.error : iconColor)
                    .withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconOnError ? AppColors.error : iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: iconOnError ? AppColors.error : AppColors.textDark,
                  fontWeight: iconOnError ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
            if (onTap != null && trailing == null) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right,
                  color: AppColors.textLight, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrailingText extends StatelessWidget {
  final String text;

  const _TrailingText(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}
