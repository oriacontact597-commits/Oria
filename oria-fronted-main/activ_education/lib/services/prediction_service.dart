// lib/services/prediction_service.dart
//
// Service HTTP pour le Module Prédiction & Recommandation IA — Phase 4.
// Consomme les endpoints /niveaux, /filieres, /notes-historique,
// /recommandation-ia/v2 ajoutés au backend (Phases 1-3).
//
// Pattern : singleton extends BaseService (cf. academic_service.dart).

import '../models/models.dart';
import 'base_service.dart';

class PredictionService extends BaseService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  // ─── Niveaux ──────────────────────────────────────────────────────────────

  /// GET /api/v1/niveaux
  /// Liste des 7 niveaux canoniques (COLLEGE, LYCEE_2ND, ..., BAC_3).
  Future<List<NiveauModel>> listerNiveaux() async {
    final res = await dioGet('/api/v1/niveaux');
    return ((res.data as List<dynamic>?) ?? [])
        .map((e) => NiveauModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Filières filtrées par niveau ─────────────────────────────────────────

  /// GET /api/v1/filieres?niveau={code}
  Future<List<FilierePourNiveauModel>> listerFilieresParNiveau(
      String codeNiveau) async {
    final res = await dioGet(
      '/api/v1/filieres',
      queryParameters: {'niveau': codeNiveau},
    );
    return ((res.data as List<dynamic>?) ?? [])
        .map((e) => FilierePourNiveauModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Notes historiques (bulletins) ────────────────────────────────────────

  /// GET /api/v1/eleves/{id}/notes-historique/moyennes-generales
  /// Renvoie uniquement les lignes "moyenne générale" (source du moteur
  /// de trajectoire Phase 3).
  Future<List<NoteHistoriqueResponse>> getMoyennesGenerales(String eleveId) async {
    final res = await dioGet(
      '/api/v1/eleves/$eleveId/notes-historique/moyennes-generales',
    );
    return ((res.data as List<dynamic>?) ?? [])
        .map((e) => NoteHistoriqueResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/eleves/{id}/notes-historique
  /// Historique complet (toutes matières).
  Future<List<NoteHistoriqueResponse>> getHistoriqueComplet(String eleveId) async {
    final res = await dioGet('/api/v1/eleves/$eleveId/notes-historique');
    return ((res.data as List<dynamic>?) ?? [])
        .map((e) => NoteHistoriqueResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/eleves/{id}/notes-historique
  Future<NoteHistoriqueResponse> ajouterNoteHistorique(
      String eleveId, NoteHistoriqueRequest request) async {
    final res = await dio.post(
      '/api/v1/eleves/$eleveId/notes-historique',
      data: request.toJson(),
    );
    return NoteHistoriqueResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// DELETE /api/v1/eleves/{id}/notes-historique/{trackingId}
  Future<void> supprimerNoteHistorique(String eleveId, String trackingId) async {
    await dio.delete('/api/v1/eleves/$eleveId/notes-historique/$trackingId');
  }

  // ─── Mise à jour du niveau de l'élève ─────────────────────────────────────

  /// PUT /api/v1/eleves/{id}  (modification du `niveauEtude`).
  /// On envoie un payload minimal qui ne touche QUE le champ `niveauEtude`
  /// (le reste du profil est conservé côté backend via update partiel /
  /// mapper — le backend ignore les champs null).
  Future<EleveResponse> majNiveauEleve(String eleveId, String codeNiveau) async {
    final res = await dio.put(
      '/api/v1/eleves/$eleveId',
      data: {'niveauEtude': codeNiveau},
    );
    return EleveResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // ─── Recommandation 3 signaux ─────────────────────────────────────────────

  /// GET /api/v1/eleves/{trackingId}/recommandation-ia/v2
  /// Renvoie le top 10 + sous-scores + découvertes.
  Future<Recommandation3SignauxModel> recommander3Signaux(
      String trackingId) async {
    final res = await dioGet(
      '/api/v1/eleves/$trackingId/recommandation-ia/v2',
    );
    return Recommandation3SignauxModel.fromJson(
        res.data as Map<String, dynamic>);
  }
}
