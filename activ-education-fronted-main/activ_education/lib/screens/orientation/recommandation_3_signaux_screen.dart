// lib/screens/orientation/recommandation_3_signaux_screen.dart
//
// Écran "Ma recommandation 3 signaux" — Phase 4 du Module Prédiction.
// Consomme GET /api/v1/eleves/{id}/recommandation-ia/v2 et affiche le
// top 10 avec, pour chaque filière, 3 barres de progression
// (aspiration / réalité / engagement) + score final + badge "Découverte".
//
// Bouton de fallback "Conseil du conseiller IA (v1)" → RecommandationIAScreen.

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class Recommandation3SignauxScreen extends StatefulWidget {
  const Recommandation3SignauxScreen({super.key});

  @override
  State<Recommandation3SignauxScreen> createState() =>
      _Recommandation3SignauxScreenState();
}

class _Recommandation3SignauxScreenState
    extends State<Recommandation3SignauxScreen> {
  final _api = ApiService();

  Recommandation3SignauxModel? _data;
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
      final id = await _api.getTrackingId();
      if (id == null) {
        setState(() {
          _error = 'Vous devez être connecté';
          _isLoading = false;
        });
        return;
      }
      final res = await _api.prediction.recommander3Signaux(id);
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _api.handleError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recommandations 3 signaux'),
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
            Text(_error!,
                style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Réessayer', onPressed: _load),
            const SizedBox(height: 12),
            OutlineButton(
              label: 'Conseil du conseiller IA (v1)',
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.recommandationIA),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data;
    if (data == null) {
      return const Center(child: Text('Aucune donnée'));
    }
    if (data.top.isEmpty) {
      return _buildEmpty();
    }
    return Column(
      children: [
        _buildHeader(data),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.top.length,
            itemBuilder: (context, i) => _buildFiliereCard(data.top[i], i + 1),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: 'Conseil IA (v1)',
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.recommandationIA),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                    label: 'Actualiser',
                    onPressed: _load,
                    trailingIcon: Icons.refresh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Recommandation3SignauxModel data) {
    final p = data.profil;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Top ${data.top.length} pour toi',
                  style: AppTextStyles.headingMedium
                      .copyWith(color: Colors.white),
                ),
              ),
              if (data.decouvertesAjoutees > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data.decouvertesAjoutees} découverte${data.decouvertesAjoutees > 1 ? 's' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (p != null) ...[
            if (p.profilDecouvert != null && p.profilDecouvert!.isNotEmpty)
              Text(
                'Profil RIASEC : ${p.profilDecouvert}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.white70),
              ),
            if (p.noteActuelle != null)
              Text(
                'Dernière moyenne : ${p.noteActuelle!.toStringAsFixed(2)}/20'
                '${p.noteExtrapol != null ? "  •  Projection : ${p.noteExtrapol!.toStringAsFixed(2)}/20" : ''}'
                '  •  Confiance : ${(p.confianceTrajectoire * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            'Pondération : aspiration ${(data.poidsAspiration * 100).toStringAsFixed(0)}%'
            ' • réalité ${(data.poidsRealite * 100).toStringAsFixed(0)}%'
            ' • engagement ${(data.poidsEngagement * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFiliereCard(FiliereScoreeModel f, int rang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: f.estDecouverte ? AppColors.accent : AppColors.cardBorder,
          width: f.estDecouverte ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Redirige vers la fiche filière (détaillée) si dispo, sinon
          // ouvre un bottom-sheet d'aperçu. À ajuster si la fiche-detail
          // attend d'autres arguments.
          Navigator.pushNamed(
            context,
            AppRoutes.ficheDetail,
            arguments: {
              'trackingId': f.trackingId,
              'typeFiche': 'filiere',
              'titre': f.titre,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$rang',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.titre,
                          style: AppTextStyles.headingMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (f.domaine.isNotEmpty || f.duree.isNotEmpty)
                          Text(
                            [f.domaine, f.duree]
                                .where((s) => s.isNotEmpty)
                                .join(' • '),
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMedium),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(f.scoreFinal * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.headingMedium
                            .copyWith(color: AppColors.primary),
                      ),
                      Text(
                        'score final',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ],
              ),
              if (f.estDecouverte) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Découverte — à explorer',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _ScoreBar(
                label: 'Aspiration (RIASEC)',
                value: f.scoreAspiration,
                color: AppColors.primary,
              ),
              const SizedBox(height: 6),
              _ScoreBar(
                label: 'Réalité (notes)',
                value: f.scoreRealite,
                color: AppColors.success,
              ),
              const SizedBox(height: 6),
              _ScoreBar(
                label: 'Engagement (consultations)',
                value: f.scoreEngagement,
                color: AppColors.warning,
                hint: 'plafonné à 20%',
              ),
              if (f.raisonClassement != null &&
                  f.raisonClassement!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  f.raisonClassement!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
            const SizedBox(height: 24),
            Text(
              'Pas encore de recommandation',
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Renseigne ton niveau et tes 3 dernières moyennes pour que le moteur puisse te proposer des filières adaptées.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Compléter mon profil',
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.bulletinsHistorique,
              ),
            ),
            const SizedBox(height: 12),
            OutlineButton(
              label: 'Conseil du conseiller IA (v1)',
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.recommandationIA),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final Color color;
  final String? hint;

  const _ScoreBar({
    required this.label,
    required this.value,
    required this.color,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMedium),
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.backgroundGrey,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (hint != null)
          Text(
            hint!,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textLight, fontSize: 10),
          ),
      ],
    );
  }
}
