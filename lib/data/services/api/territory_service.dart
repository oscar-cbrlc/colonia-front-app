import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class TerritoryService {
  final ApiClient _apiClient;

  final _route = '/territory';

  TerritoryService(this._apiClient);

  Future<http.Response> getTerritoryById(String id) async {
    return await _apiClient.get('$_route/$id');
  }

  Future<http.Response> getAllTerritories() async {
    return await _apiClient.get(_route);
  }

  Future<http.Response> applyPoints({
    required double totalDistance,
    required int totalTime,
    required String timestamp,
    required List<Map<String, dynamic>> territories,
    int? boostId,
  }) async {
    return await _apiClient.patch('/territory/apply-points', body: {
      'total_distance': totalDistance,
      'total_time': totalTime,
      'timestamp': timestamp,
      'territories': territories,
      'boost_id': ?boostId,
    });
  }
}
