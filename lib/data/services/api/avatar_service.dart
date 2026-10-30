import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class AvatarService {
  final ApiClient _apiClient;
  final String _route = '/avatar';

  AvatarService(this._apiClient);

  Future<http.Response> listAvatarItems() async {
    return await _apiClient.get('$_route/');
  }

  Future<http.Response> getMyAvatarInventory() async {
    return await _apiClient.get('$_route/users/me/inventory');
  }

  Future<http.Response> updateAvatar(Map<String, dynamic> updateData) async {
    return await _apiClient.patch('$_route/users/me', body: updateData);
  }
}
