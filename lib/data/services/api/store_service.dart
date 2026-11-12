import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class StoreService {
  final ApiClient _apiClient;
  final String _route = '/store';

  StoreService(this._apiClient);

  Future<http.Response> getOffers() async {
    return await _apiClient.get('$_route/');
  }

  Future<http.Response> buyOffer(int offerId) async {
    return await _apiClient.patch('$_route/$offerId');
  }
}
