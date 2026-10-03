import '../models/models.dart';
import 'base_service.dart';

class TemoignageService extends BaseService {
  static final TemoignageService _instance = TemoignageService._internal();
  factory TemoignageService() => _instance;
  TemoignageService._internal();

  Future<List<TemoignageResponse>> getPublies({int page = 0, int size = 20}) async {
    final res = await dioGet('/api/v1/temoignages/publies', queryParameters: {'page': page, 'size': size});
    return ((res.data['content'] as List<dynamic>?) ?? []).map((e) => TemoignageResponse.fromJson(e)).toList();
  }

  Future<List<TemoignageResponse>> getVedettes() async {
    final res = await dioGet('/api/v1/temoignages/vedettes');
    return ((res.data as List<dynamic>?) ?? []).map((e) => TemoignageResponse.fromJson(e)).toList();
  }

  Future<List<TemoignageResponse>> getParMetier(String metierTrackingId, {int page = 0, int size = 20}) async {
    final res = await dioGet('/api/v1/temoignages/metier/$metierTrackingId', queryParameters: {'page': page, 'size': size});
    return ((res.data['content'] as List<dynamic>?) ?? []).map((e) => TemoignageResponse.fromJson(e)).toList();
  }

  Future<TemoignageResponse> getTemoignage(String trackingId) async {
    final res = await dioGet('/api/v1/temoignages/$trackingId');
    return TemoignageResponse.fromJson(res.data);
  }
}
