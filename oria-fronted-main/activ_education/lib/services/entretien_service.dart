import '../models/models.dart';
import 'base_service.dart';

class EntretienService extends BaseService {
  static final EntretienService _instance = EntretienService._internal();
  factory EntretienService() => _instance;
  EntretienService._internal();

  Future<EntretienResponse> demarrerEntretien(StartEntretienRequest req) async {
    final res = await dio.post('/api/v1/entretien/start', data: req.toJson());
    return EntretienResponse.fromJson(res.data);
  }

  Future<EntretienResponse> repondre(String sessionId, String reponse) async {
    final res = await dio.post('/api/v1/entretien/$sessionId/repondre',
        data: {'reponse': reponse});
    return EntretienResponse.fromJson(res.data);
  }

  Future<ResultatEntretienResponse> getResultat(String sessionId) async {
    final res = await dioGet('/api/v1/entretien/$sessionId/resultat');
    return ResultatEntretienResponse.fromJson(res.data);
  }
}
