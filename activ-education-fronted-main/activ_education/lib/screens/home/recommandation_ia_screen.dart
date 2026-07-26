import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../widgets/common_widgets.dart';

class RecommandationIAScreen extends StatefulWidget {
  const RecommandationIAScreen({super.key});

  @override
  State<RecommandationIAScreen> createState() => _RecommandationIAScreenState();
}

class _RecommandationIAScreenState extends State<RecommandationIAScreen> {
  final _api = ApiService();
  String? _recommandation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final trackingId = await _api.getTrackingId();
      if (trackingId == null) {
        setState(() {
          _error = 'Vous devez être connecté';
          _isLoading = false;
        });
        return;
      }
      final response = await _api.dio.get(
        '/api/v1/eleves/$trackingId/recommandation-ia',
      );
      setState(() {
        _recommandation = response.data['recommandation'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _api.handleError(e);
        _isLoading = false;
      });
    }
  }

  /// Phase 4 — lance le parcours du moteur 3 signaux.
  /// Si l'élève n'a pas de niveau, on commence par `selection_niveau_screen`
  /// qui enchaînera sur les bulletins puis la recommandation v2.
  /// Sinon on va directement à la saisie des bulletins.
  Future<void> _lancerParcoursV2() async {
    try {
      final trackingId = await _api.getTrackingId();
      if (trackingId == null) return;
      final eleve = await _api.getEleve(trackingId);
      if (!mounted) return;
      if (eleve.niveauEtude == null || eleve.niveauEtude!.isEmpty) {
        Navigator.pushNamed(context, AppRoutes.selectionNiveau);
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.bulletinsHistorique,
          arguments: {
            'niveauCode': eleve.niveauEtude,
            'niveauLabel': eleve.niveauEtude,
          },
        );
      }
    } catch (e) {
      // En cas d'erreur, on tente quand même la saisie des bulletins —
      // l'élève pourra y voir son niveau actuel.
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.bulletinsHistorique,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon orientation personnalisée'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Réessayer',
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final aBesoinProfil = _recommandation != null &&
        _recommandation!.contains("pas encore assez d'informations");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: aBesoinProfil
                  ? const LinearGradient(
                      colors: [AppColors.warning, Color(0xFFE67E22)])
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(aBesoinProfil ? Icons.edit_note : Icons.auto_awesome,
                    color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  aBesoinProfil
                      ? 'Profil incomplet'
                      : 'Recommandation personnalisée',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aBesoinProfil
                      ? 'Ajoute tes informations pour obtenir une recommandation'
                      : 'Basée sur ton profil, tes notes et tes quiz',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: aBesoinProfil ? AppColors.warning : AppColors.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      aBesoinProfil
                          ? Icons.info_outline
                          : Icons.lightbulb_outline,
                      color: aBesoinProfil
                          ? AppColors.warning
                          : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      aBesoinProfil
                          ? 'Action requise'
                          : 'Conseils du conseiller IA',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _recommandation ?? '',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textDark,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlineButton(
              label: 'Actualiser',
              onPressed: _load,
            ),
          ),
          const SizedBox(height: 16),
          // Phase 4 — entrée vers le moteur 3 signaux
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_graph,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nouvelle recommandation (3 signaux)',
                        style: AppTextStyles.headingMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Un moteur structuré qui croise ton profil RIASEC, '
                  'ta trajectoire scolaire et ton engagement sur la plateforme.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMedium),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Tester la recommandation v2',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: _lancerParcoursV2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
