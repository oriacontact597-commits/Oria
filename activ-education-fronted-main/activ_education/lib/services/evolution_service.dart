import 'base_service.dart';

class EvolutionService extends BaseService {
  static final EvolutionService _instance = EvolutionService._();
  factory EvolutionService() => _instance;
  EvolutionService._();

  Future<Map<String, dynamic>> orchestrate(String studentId,
      {String? country, String? config}) async {
    final params = <String, dynamic>{};
    if (country != null) params['country'] = country;
    if (config != null) params['config'] = config;

    final response = await dio.post(
      '/api/v1/evolution/$studentId/orchestrate',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> compute(String studentId) async {
    final response = await dio.post('/api/v1/evolution/$studentId/compute');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile(String studentId) async {
    final response = await dio.get('/api/v1/evolution/$studentId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, double>> getDefaultConfig() async {
    final response = await dio.get('/api/v1/evolution/configs');
    final data = response.data as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}
