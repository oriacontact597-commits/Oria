import '../models/models.dart';
import 'base_service.dart';

class PortfolioService extends BaseService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal();

  Future<List<CompetenceResponse>> listerCompetences(String eleveTrackingId) async {
    final res = await dioGet('/api/v1/portfolio/$eleveTrackingId');
    return (res.data as List).map((e) => CompetenceResponse.fromJson(e)).toList();
  }

  Future<CompetenceResponse> ajouterCompetence(
      String eleveTrackingId, CompetenceRequest request) async {
    final res = await dio.post('/api/v1/portfolio/$eleveTrackingId', data: request.toJson());
    return CompetenceResponse.fromJson(res.data);
  }

  Future<CompetenceResponse> modifierCompetence(
      String eleveTrackingId, String trackingId, CompetenceRequest request) async {
    final res = await dio.put('/api/v1/portfolio/$eleveTrackingId/$trackingId', data: request.toJson());
    return CompetenceResponse.fromJson(res.data);
  }

  Future<void> supprimerCompetence(String eleveTrackingId, String trackingId) async {
    await dio.delete('/api/v1/portfolio/$eleveTrackingId/$trackingId');
  }

  Future<AnalysePortfolioResponse> analyser(String eleveTrackingId) async {
    final res = await dioGet('/api/v1/portfolio/$eleveTrackingId/analyse');
    return AnalysePortfolioResponse.fromJson(res.data);
  }
}
