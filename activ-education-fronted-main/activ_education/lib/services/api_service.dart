import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'explorer_service.dart';
import 'diagnostic_service.dart';
import 'interaction_service.dart';
import 'file_service.dart';
import 'score_matrice_service.dart';
import 'portfolio_service.dart';
import 'datahub_service.dart';
import 'entretien_service.dart';
import 'reseau_service.dart';
import 'badge_service.dart';
import 'temoignage_service.dart';
import 'prediction_service.dart';
import 'simulateur_service.dart';
import 'base_service.dart';
import '../models/models.dart';

class ApiService extends BaseService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Sub-services
  final auth = AuthService();
  final explorer = ExplorerService();
  final diagnostic = DiagnosticService();
  final interaction = InteractionService();
  final files = FileService();
  final scoreMatrice = ScoreMatriceService();
  final portfolio = PortfolioService();
  final datahub = DataHubService();
  final entretien = EntretienService();
  final reseau = ReseauService();
  final badge = BadgeService();
  final temoignage = TemoignageService();
  final prediction = PredictionService();
  final simulateur = SimulateurService();

  void init() {}

  // ─── PROXY METHODS (Backward Compatibility) ────────────────────────────────

  // Auth & Profile
  Future<TokenResponse> login(String email, String password) =>
      auth.login(email, password);
  Future<void> saveToken(String token) => auth.saveToken(token);
  Future<void> saveUserData({
    required String trackingId,
    required String role,
    String? nom,
    String? prenom,
    String? email,
    String? niveauEtude,
    String? filiere,
    String? metierSouhaite,
  }) =>
      auth.saveUserData(
        trackingId: trackingId,
        role: role,
        nom: nom,
        prenom: prenom,
        email: email,
        niveauEtude: niveauEtude,
        filiere: filiere,
        metierSouhaite: metierSouhaite,
      );
  Future<void> logout() => auth.logout();
  Future<Map<String, String>> getUtilisateurNom(String trackingId) =>
      auth.getUtilisateurNom(trackingId);
  Future<EleveResponse> getEleve(String id) => auth.getEleve(id);
  Future<EleveResponse> getEleveByEmail(String email) async {
    final res = await dio.get('/api/v1/eleves/by-email/$email');
    return EleveResponse.fromJson(res.data);
  }

  Future<EleveResponse> inscrireEleve(EleveRequest req) =>
      auth.inscrireEleve(req);
  Future<EleveResponse> modifierEleve(String id, EleveRequest req) async {
    final res = await dio.put('/api/v1/eleves/$id', data: req.toJson());
    return EleveResponse.fromJson(res.data);
  }

  Future<ParentResponse> getParent(String id) => auth.getParent(id);
  Future<ParentResponse> modifierParent(
      String id, Map<String, dynamic> data) async {
    final res = await dio.put('/api/v1/parents/$id', data: data);
    return ParentResponse.fromJson(res.data);
  }

  Future<ConseillerResponse> getConseiller(String id) => auth.getConseiller(id);
  Future<List<ConseillerResponse>> getConseillers(
          {int page = 0, int size = 100}) =>
      auth.getConseillers(page: page, size: size);

  // Explorer & Favorites
  Future<PageResponse<FicheSerieResponse>> listerSeries(
          {int page = 0, int size = 10}) =>
      explorer.listerSeries(page: page, size: size);
  Future<PageResponse<FicheFiliereResponse>> listerFilieres(
          {int page = 0, int size = 10}) =>
      explorer.listerFilieres(page: page, size: size);
  Future<PageResponse<FicheMetierResponse>> listerMetiers(
          {int page = 0, int size = 10}) =>
      explorer.listerMetiers(page: page, size: size);
  Future<PageResponse<FicheEtablissementResponse>> listerEtablissements(
          {int page = 0, int size = 10}) =>
      explorer.listerEtablissements(page: page, size: size);
  Future<FavoriResponse> ajouterFavori(FavoriRequest req) =>
      explorer.ajouterFavori(req);
  Future<void> supprimerFavori(String id) => explorer.supprimerFavori(id);
  Future<List<String>> getEtablissementsList() =>
      explorer.getEtablissementsList();
  Future<List<String>> getFilieresList() => explorer.getFilieresList();
  Future<List<String>> getVilles() => explorer.getVilles();

  // Recherche
  Future<List<RechercheGlobaleResponse>> rechercherGlobalement(String phrase,
          {int limite = 10}) =>
      explorer.rechercherGlobalement(phrase, limite: limite);

  // Diagnostic
  Future<PageResponse<QuizResponse>> listerQuiz(
          {int page = 0, int size = 10}) =>
      diagnostic.listerQuizzes(page: page, size: size);
  Future<QuizResponse> getQuiz(String id) async {
    final res = await dio.get('/api/v1/quiz/$id');
    return QuizResponse.fromJson(res.data);
  }

  Future<List<QuestionResponse>> getQuestionsQuiz(String id) =>
      diagnostic.getQuestionsQuiz(id);
  Future<List<ReponseResponse>> getReponsesQuestion(String id) =>
      diagnostic.getReponsesQuestion(id);
  Future<ResultatDiagnosticResponse> enregistrerResultat(
          ResultatDiagnosticRequest req) =>
      diagnostic.soumettreResultat(req);
  Future<PageResponse<ResultatDiagnosticResponse>> getResultatsEleve(String id,
          {int page = 0, int size = 10}) =>
      diagnostic.getResultatsEleve(id, page: page, size: size);
  Future<ResultatDiagnosticResponse?> getDernierResultat(
          String eId, String qId) =>
      diagnostic.getDernierResultat(eId, qId);
  Future<List<QuestionResponse>> recommanderQuestions(String eId, String qId,
          {int nombre = 20}) =>
      diagnostic.recommanderQuestions(eId, qId, nombre: nombre);
  Future<String?> getRecommandationIA(String eleveTrackingId) async {
    try {
      final res = await dio.get('/api/v1/eleves/$eleveTrackingId/recommandation-ia');
      return res.data['recommandation'] as String?;
    } catch (_) {
      return null;
    }
  }
  // Evolution (Student Evolution Engine — Phase 3.3)
  Future<Map<String, dynamic>> getEvolutionEvents(String studentTrackingId) async {
    final res = await dio.get('/api/v1/evolution/$studentTrackingId/events');
    return res.data as Map<String, dynamic>;
  }
  // Interaction
  Future<MessageResponse> envoyerMessage(
      String expId, MessageRequest req) async {
    final res = await dio.post('/api/v1/utilisateurs/$expId/messages',
        data: req.toJson());
    return MessageResponse.fromJson(res.data);
  }

  Future<List<MessageResponse>> getConversation(String u1, String u2) =>
      interaction.getConversation(u1, u2);
  Future<PageResponse<MessageResponse>> getMessagesRecus(String id,
      {int page = 0, int size = 20}) async {
    final res = await dio.get('/api/v1/utilisateurs/$id/messages/recus',
        queryParameters: {'page': page, 'size': size});
    return PageResponse.fromJson(
        res.data, (json) => MessageResponse.fromJson(json));
  }

  Future<PageResponse<MessageResponse>> getMessagesEnvoyes(String id,
      {int page = 0, int size = 20}) async {
    final res = await dio.get('/api/v1/utilisateurs/$id/messages/envoyes',
        queryParameters: {'page': page, 'size': size});
    return PageResponse.fromJson(
        res.data, (json) => MessageResponse.fromJson(json));
  }

  Future<int> getMessagesNonLus(String id) => interaction.getMessagesNonLus(id);
  Future<void> marquerConversationLue(String exp, String dest) =>
      interaction.marquerConversationLue(exp, dest);

  Future<List<RendezVousResponse>> getRDVEleve(String id) =>
      interaction.getRDVEleve(id);
  Future<List<RendezVousResponse>> getRDVConseiller(String id) =>
      interaction.getRDVConseiller(id);
  Future<List<DisponibiliteResponse>> getDisponibilitesConseiller(String id) =>
      interaction.getDisponibilitesConseiller(id);
  Future<RendezVousResponse> planifierRDV(RendezVousRequest req) =>
      interaction.planifierRDV(req);
  Future<void> annulerRDV(String id) => interaction.annulerRDV(id);
  Future<RendezVousResponse> terminerRDV(String id) =>
      interaction.terminerRDV(id);

  Future<List<NotificationResponse>> getNotifications(String id) =>
      interaction.getNotificationsUtilisateur(id);
  Future<List<NotificationResponse>> getNotificationsNonLues(String id) async {
    final res =
        await dio.get('/api/v1/utilisateurs/$id/notifications/non-lues');
    return ((res.data as List<dynamic>?) ?? [])
        .map((e) => NotificationResponse.fromJson(e))
        .toList();
  }

  Future<void> marquerNotificationLue(String id) => interaction.marquerLue(id);
  Future<void> marquerToutesLues(String id) =>
      interaction.marquerToutesLues(id);

  // Documents
  Future<PageResponse<DocumentResponse>> getDocuments(String trackingId,
      {int page = 0, int size = 20}) async {
    final res = await dio.get(
      '/api/v1/eleves/$trackingId/documents',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      res.data, (json) => DocumentResponse.fromJson(json),
    );
  }

  Future<DocumentResponse> uploadDocument(
    String trackingId,
    PlatformFile file, {
    required String typeDocument,
    String? description,
    String? dateDocument,
  }) async {
    final MultipartFile multipartFile;
    if (kIsWeb) {
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else {
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    }
    final formData = FormData.fromMap({
      'file': multipartFile,
      'typeDocument': typeDocument,
      if (description != null) 'description': description,
      if (dateDocument != null) 'dateDocument': dateDocument,
    });
    final res = await dio.post(
      '/api/v1/eleves/$trackingId/documents',
      data: formData,
    );
    return DocumentResponse.fromJson(res.data);
  }

  Future<void> deleteDocument(String trackingId, int documentId) async {
    await dio.delete('/api/v1/eleves/$trackingId/documents/$documentId');
  }

  Future<int> countDocuments(String trackingId) async {
    final res = await dio.get('/api/v1/eleves/$trackingId/documents/count');
    return (res.data as int?) ?? 0;
  }

  // Files
  Future<FileUploadResponse> uploadFichier(File f, String t) =>
      files.uploadFichier(f, t);
  Future<EleveResponse> uploadPhotoProfil(String trackingId, List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res =
        await dio.patch('/api/v1/eleves/$trackingId/photo', data: formData);
    return EleveResponse.fromJson(res.data);
  }

  Future<void> supprimerMessage(String trackingId) async {
    await dio.delete('/api/v1/messages/$trackingId');
  }

  Future<Map<String, dynamic>> genererQuizIA(String type, String entityId, {int nombre = 5}) =>
      diagnostic.genererQuizIA(type, entityId, nombre: nombre);

  // ORIA Chat IA
  Future<Map<String, dynamic>> envoyerMessageOria(String message, {String? sessionId}) async {
    final res = await dio.post('/api/v1/oria/message', data: {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
    });
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getSessionOria(String sessionId) async {
    final res = await dio.get('/api/v1/oria/session/$sessionId');
    return (res.data as Map<String, dynamic>?) ?? {};
  }

  Future<void> effacerSessionOria(String sessionId) async {
    await dio.delete('/api/v1/oria/session/$sessionId');
  }
}
