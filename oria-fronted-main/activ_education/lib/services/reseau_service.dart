import '../models/models.dart';
import 'base_service.dart';

class ReseauService extends BaseService {
  static final ReseauService _instance = ReseauService._internal();
  factory ReseauService() => _instance;
  ReseauService._internal();

  Future<List<PublicationResponse>> getFeed(String userId, {int page = 0, int size = 20}) async {
    final res = await dioGet('/api/v1/reseau/feed/$userId', queryParameters: {'page': page, 'size': size});
    return _parsePublications(res.data);
  }

  Future<List<PublicationResponse>> getTendances({int page = 0, int size = 20}) async {
    final res = await dioGet('/api/v1/reseau/tendances', queryParameters: {'page': page, 'size': size});
    return _parsePublications(res.data);
  }

  Future<List<PublicationResponse>> getPublicationsUtilisateur(String auteurId,
      {int page = 0, int size = 20, String? currentUserId}) async {
    final res = await dioGet('/api/v1/reseau/utilisateur/$auteurId',
        queryParameters: {'page': page, 'size': size, 'currentUserId': currentUserId ?? ''});
    return _parsePublications(res.data);
  }

  Future<PublicationResponse> publier(String auteurId, String auteurNom, String contenu,
      {String auteurRole = 'ELEVE', String? tags}) async {
    final res = await dio.post('/api/v1/reseau/publications',
        queryParameters: {'auteurId': auteurId, 'auteurNom': auteurNom, 'auteurRole': auteurRole},
        data: {'contenu': contenu, 'tags': tags});
    return PublicationResponse.fromJson(res.data);
  }

  Future<void> supprimerPublication(String trackingId, String utilisateurId) async {
    await dio.delete('/api/v1/reseau/publications/$trackingId',
        queryParameters: {'utilisateurId': utilisateurId});
  }

  Future<void> reactionner(String trackingId, String utilisateurId) async {
    await dio.post('/api/v1/reseau/publications/$trackingId/reaction',
        queryParameters: {'utilisateurId': utilisateurId});
  }

  Future<List<CommentaireResponse>> getCommentaires(String publicationTrackingId,
      {int page = 0, int size = 20}) async {
    final res = await dioGet('/api/v1/reseau/publications/$publicationTrackingId/commentaires',
        queryParameters: {'page': page, 'size': size});
    return _parseCommentaires(res.data);
  }

  Future<CommentaireResponse> commenter(String publicationTrackingId,
      String auteurId, String auteurNom, String contenu) async {
    final res = await dio.post('/api/v1/reseau/publications/$publicationTrackingId/commentaires',
        queryParameters: {'auteurId': auteurId, 'auteurNom': auteurNom},
        data: {'contenu': contenu});
    return CommentaireResponse.fromJson(res.data);
  }

  Future<void> suivre(String abonneId, String abonnementId) async {
    await dio.post('/api/v1/reseau/abonnements',
        queryParameters: {'abonneId': abonneId, 'abonnementId': abonnementId});
  }

  Future<void> nePlusSuivre(String abonneId, String abonnementId) async {
    await dio.delete('/api/v1/reseau/abonnements',
        queryParameters: {'abonneId': abonneId, 'abonnementId': abonnementId});
  }

  Future<bool> estAbonne(String abonneId, String abonnementId) async {
    final res = await dioGet('/api/v1/reseau/abonnements/verifier',
        queryParameters: {'abonneId': abonneId, 'abonnementId': abonnementId});
    return res.data == true;
  }

  Future<int> nombreAbonnes(String utilisateurId) async {
    final res = await dioGet('/api/v1/reseau/abonnements/nombre/$utilisateurId');
    return res.data as int;
  }

  List<PublicationResponse> _parsePublications(dynamic data) {
    final content = (data is Map ? data['content'] : data) as List<dynamic>? ?? [];
    return content.map((e) => PublicationResponse.fromJson((e as Map<String, dynamic>?) ?? {})).toList();
  }

  List<CommentaireResponse> _parseCommentaires(dynamic data) {
    final content = (data is Map ? data['content'] : data) as List<dynamic>? ?? [];
    return content.map((e) => CommentaireResponse.fromJson((e as Map<String, dynamic>?) ?? {})).toList();
  }
}
