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

  Future<http.Response> processTraining(Map<String, dynamic> body) async {
    return await _apiClient.post('/userTraining/', body: body);
  }
}
