import '../models/models.dart';
import 'base_service.dart';

class DataHubService extends BaseService {
  static final DataHubService _instance = DataHubService._internal();
  factory DataHubService() => _instance;
  DataHubService._internal();

  Future<DataHubResponse> getDataHub() async {
    final res = await dioGet('/api/v1/datahub');
    return DataHubResponse.fromJson(res.data);
  }

  Future<DataHubResponse> getDataHubParVille(String ville) async {
    final res = await dioGet('/api/v1/datahub/ville/$ville');
    return DataHubResponse.fromJson(res.data);
  }
}
