import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class BoostService {
  final ApiClient _apiClient;

  final String _route = '/boosts';

  BoostService(this._apiClient);

  Future<http.Response> getAllBoosts() async {
    return await _apiClient.get('$_route/');
  }

  Future<http.Response> getBoostById(int boostId) async {
    return await _apiClient.get('$_route/$boostId');
  }

  Future<http.Response> getMyInventory() async {
    return await _apiClient.get('$_route/users/me/inventory');
  }

  // admin
  Future<http.Response> updateBoostInventory(int userId, int boostId, int amount) async {
    return await _apiClient.patch('$_route/users/$userId/boosts/$boostId', body: {
      'boost_amount': amount,
    });
  }
}
