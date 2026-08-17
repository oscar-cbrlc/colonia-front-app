import 'package:colonia_front_app/domain/models/territory.dart';
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

  Future<http.Response> getAllTerritories() async {
    return await _apiClient.get('/territories');
  }

  //Future<http.Response> impactTerritories(List<Territory>)
}
