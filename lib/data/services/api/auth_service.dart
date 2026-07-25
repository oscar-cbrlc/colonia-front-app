import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<http.Response> getUserById(int id) async {
    return await _apiClient.get('/users/$id');
  }

  Future<http.Response> getUserByEmail(String email) async {
    return await _apiClient.get(
      '/users/',
      queryParameters: {
        'email': email,
      },
    );
  }

  Future<http.Response> register({
    required String email,
    required String username,
    required String password
  }) async {
    return await _apiClient.post(
      '/auth/register',
      body: {
        'email': email,
        'user_name': username,
        'password': password,
      }
    );
  }

  Future<http.Response> login({
    required String email,
    required String password
  }) async {
    return await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        }
    );
  }

  Future<http.Response> firebaseAuth({
    required String idToken,
  }) async {
    return await _apiClient.post(
      '/auth/firebase',
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
  }
}
