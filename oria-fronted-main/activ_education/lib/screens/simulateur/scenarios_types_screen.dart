// lib/screens/simulateur/scenarios_types_screen.dart
//
// Écran listant les 6 templates de scénarios préfabriqués (Chantier B).
// Chaque carte expose un titre + une description + un bouton "Exécuter"
// qui POST /scenarios-types/{id}/executer et navigue vers l'écran
// résultat existant (SimulateurResultatScreen).
//
// Pattern : StatefulWidget + ApiService() + setState + mounted checks.
// Suit le style de simulateur_parcours_screen.dart.

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'simulateur_resultat_screen.dart';

class ScenariosTypesScreen extends StatefulWidget {
  const ScenariosTypesScreen({super.key});

  @override
  State<ScenariosTypesScreen> createState() => _ScenariosTypesScreenState();
}

class _ScenariosTypesScreenState extends State<ScenariosTypesScreen> {
  final _api = ApiService();
  List<ScenarioTemplateModel> _templates = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _executingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.simulateur.listerTemplates();
      if (!mounted) return;
      setState(() {
        _templates = res;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _api.handleError(e);
      });
    }
  }

  Future<void> _executer(ScenarioTemplateModel t) async {
    if (_executingIds.contains(t.trackingId)) return;
    setState(() => _executingIds.add(t.trackingId));
    try {
      // On récupère l'élève courant s'il existe (utile pour traçabilité
      // côté backend — mais optionnel). Si l'appel échoue (pas encore
      // loggué), on retente sans le param.
      String? eleveId;
      try {
        eleveId = await _api.getTrackingId();
      } catch (_) {
        eleveId = null;
      }

      final result = await _api.simulateur.executerTemplate(
        t.trackingId,
        eleveTrackingId: eleveId,
      );
      if (!mounted) return;
      // On passe par une map pour réutiliser SimulateurResultatScreen
      // existant (qui consomme des Map<String, dynamic>).
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SimulateurResultatScreen(
            resultat: _resultToMap(result),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${_api.handleError(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _executingIds.remove(t.trackingId));
      }
    }
  }

  /// Reconvertit un ScenarioResultModel en Map pour réutiliser
  /// SimulateurResultatScreen (qui n'a pas été refondu pour le moment).
  Map<String, dynamic> _resultToMap(ScenarioResultModel r) {
    return {
      'titre': r.titre,
      'serieTitre': r.serieTitre,
      'stats': r.stats == null
          ? null
          : {
              'totalFilieres': r.stats!.totalFilieres,
              'totalMetiers': r.stats!.totalMetiers,
              'totalEtablissements': r.stats!.totalEtablissements,
              'scoreMoyenCompatibilite': r.stats!.scoreMoyenCompatibilite,
              'dureeMin': r.stats!.dureeMin,
              'dureeMax': r.stats!.dureeMax,
            },
      'filieres': r.filieres
          .map((f) => {
                'trackingId': f.trackingId,
                'titre': f.titre,
                'resume': f.resume,
                'domaine': f.domaine,
                'duree': f.duree,
                'niveauRequis': f.niveauRequis,
                'scoreCompatibilite': f.scoreCompatibilite,
              })
          .toList(),
      'metiers': r.metiers
          .map((m) => {
                'trackingId': m.trackingId,
                'titre': m.titre,
                'resume': m.resume,
                'secteur': m.secteur,
                'fourchetteSalaire': m.fourchetteSalaire,
              })
          .toList(),
      'etablissements': r.etablissements
          .map((e) => {
                'trackingId': e.trackingId,
                'titre': e.titre,
                'ville': e.ville,
                'estPublic': e.estPublic,
              })
          .toList(),
    };
  }

  IconData _iconForCategorie(CategorieTemplate c) {
    switch (c) {
      case CategorieTemplate.PROGRESSION_NOTES:
        return Icons.trending_up;
      case CategorieTemplate.MOBILITE_GEO:
        return Icons.location_on;
      case CategorieTemplate.ALTERNATIVE_FILIERE:
        return Icons.alt_route;
      case CategorieTemplate.TRANSITION_SERIE:
        return Icons.swap_horiz;
      case CategorieTemplate.OPTION_MATIERE:
        return Icons.menu_book;
      case CategorieTemplate.ETABLISSEMENT:
        return Icons.account_balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Scénarios types',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _load();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _templates.isEmpty
                  ? const Center(
                      child: Text('Aucun scénario type disponible.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _templates.length,
                        itemBuilder: (_, i) =>
                            _buildCard(_templates[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(ScenarioTemplateModel t) {
    final isExecuting = _executingIds.contains(t.trackingId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForCategorie(t.categorie),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.titre,
                        style: AppTextStyles.headingSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.categorie.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.description,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isExecuting ? null : () => _executer(t),
                icon: isExecuting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(isExecuting ? 'Exécution...' : 'Exécuter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
