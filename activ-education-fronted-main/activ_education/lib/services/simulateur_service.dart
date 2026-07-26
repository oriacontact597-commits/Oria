// lib/services/simulateur_service.dart
//
// Service Flutter pour le module Simulateur (Chantiers A + B).
// Encapsule les 3 endpoints :
//   - GET  /api/v1/simulateur/scenarios-types
//   - GET  /api/v1/simulateur/scenarios-types/{id}
//   - POST /api/v1/simulateur/scenarios-types/{id}/executer
//   - POST /api/v1/simulateur/comparer
//
// Pattern : singleton héritant de BaseService, comme tous les autres
// sous-services (cf. ExplorerService, FileService, etc.).

import '../models/models.dart';
import 'base_service.dart';

class SimulateurService extends BaseService {
  static final SimulateurService _instance = SimulateurService._internal();
  factory SimulateurService() => _instance;
  SimulateurService._internal();

  // ─── Chantier B : scénarios types (templates préfabriqués) ─────────

  /// Liste les 6 templates de scénarios triés par catégorie puis par titre.
  /// GET /api/v1/simulateur/scenarios-types
  Future<List<ScenarioTemplateModel>> listerTemplates() async {
    final res = await dioGet('/api/v1/simulateur/scenarios-types');
    return ((res.data as List<dynamic>?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ScenarioTemplateModel.fromJson)
        .toList();
  }

  /// Détail d'un template. Lève une exception Dio 404 si l'id est inconnu.
  /// GET /api/v1/simulateur/scenarios-types/{id}
  Future<ScenarioTemplateModel> getTemplate(String trackingId) async {
    final res = await dio.get(
      '/api/v1/simulateur/scenarios-types/$trackingId',
    );
    return ScenarioTemplateModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  /// Exécute un template et renvoie un ScenarioResult prêt à afficher.
  /// POST /api/v1/simulateur/scenarios-types/{id}/executer
  ///
  /// [eleveTrackingId] est optionnel : s'il est fourni, il est passé en
  /// query param (utile pour traçabilité côté backend / logs futurs).
  Future<ScenarioResultModel> executerTemplate(
    String trackingId, {
    String? eleveTrackingId,
  }) async {
    final res = await dio.post(
      '/api/v1/simulateur/scenarios-types/$trackingId/executer',
      queryParameters: eleveTrackingId != null
          ? {'eleveTrackingId': eleveTrackingId}
          : null,
    );
    return ScenarioResultModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  // ─── Chantier A : comparaison enrichie ─────────────────────────────

  /// Compare 2 à 4 scénarios et renvoie leurs résultats.
  /// Chaque map représente un ScenarioRequest (cf. explorer()).
  /// POST /api/v1/simulateur/comparer
  ///
  /// Le backend attache l'analyse comparative (meilleur/pire scénario,
  /// delta par filière commune) au PREMIER résultat de la liste —
  /// voir `SimulateurParcoursService.comparer()` pour le détail.
  Future<List<ScenarioResultModel>> comparer(
    List<Map<String, dynamic>> scenarios,
  ) async {
    final res = await dio.post(
      '/api/v1/simulateur/comparer',
      data: scenarios,
    );
    return ((res.data as List<dynamic>?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ScenarioResultModel.fromJson)
        .toList();
  }
}
