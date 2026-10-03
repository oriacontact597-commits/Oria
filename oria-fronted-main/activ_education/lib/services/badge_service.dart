import '../models/models.dart';
import 'base_service.dart';

class BadgeService extends BaseService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  Future<List<BadgeResponse>> getBadges(String eleveTrackingId) async {
    final res = await dioGet('/api/v1/badges/$eleveTrackingId');
    return ((res.data as List<dynamic>?) ?? []).map((e) => BadgeResponse.fromJson(e)).toList();
  }

  Future<int> getTotal(String eleveTrackingId) async {
    final res = await dioGet('/api/v1/badges/$eleveTrackingId/total');
    return (res.data as int?) ?? 0;
  }

  Future<List<BadgeResponse>> verifierEtAttribuer(String eleveTrackingId) async {
    final res = await dio.post('/api/v1/badges/$eleveTrackingId/verifier');
    return ((res.data as List<dynamic>?) ?? []).map((e) => BadgeResponse.fromJson(e)).toList();
  }
}
