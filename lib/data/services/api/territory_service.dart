import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class TerritoryService {
  final ApiClient _apiClient;

  TerritoryService(this._apiClient);

  Future<http.Response> getTerritoryById(String id) async {
    return await _apiClient.get('/territories/$id');
  }

  Future<http.Response> getTerritoriesInRadius(double lat, double lon, double radius) async {
    return await _apiClient.get('/territories/radius?lat=$lat&lon=$lon&radius=$radius');
  }

  Future<http.Response> claimTerritory(String territoryId, int teamId, double healthPoints) async {
    return await _apiClient.post('/territories/claim', body: {
      'territory_id': territoryId,
      'team_id': teamId,
      'health_points': healthPoints,
    });
  }

  Future<http.Response> claimTerritories(List<String> ids, int teamId, List<double> healthPoints) async {
    return await _apiClient.post('/territories/claim-bulk', body: {
      'ids': ids,
      'team_id': teamId,
      'health_points': healthPoints,
    });
  }

  Future<http.Response> updateTerritoryHealth(String territoryId, double healthDelta) async {
    return await _apiClient.patch('/territories/$territoryId/health', body: {
      'health_delta': healthDelta,
    });
  }
}
