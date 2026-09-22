import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<http.Response> getUserById(int id) async {
    return await _apiClient.get(
      '/users/',
      queryParameters: {
        'user_id': id.toString(),
      },
    );
  }

  Future<http.Response> getCurrentUserData() async {
    return await _apiClient.get('/users/me');
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
      '/users/',
      body: {
        'email': email,
        'user_name': username,
        'password': password,
      }
    );
  }

  Future<http.Response> updateUser(Map<String, dynamic> data) async {
    return await _apiClient.patch(
      '/users/',
      body: data,
    );
  }

  Future<http.Response> deleteUser() async {
    return await _apiClient.delete('/users/');
  }

  Future<http.Response> login({
    required String email,
    required String password
  }) async {
    return await _apiClient.post(
        '/session/login',
        body: {
          'email': email,
          'password': password,
        }
    );
  }

  Future<http.Response> logout(String refreshToken) async {
    return await _apiClient.post(
      '/session/logout',
      queryParameters: {
        'refresh_token': refreshToken,
      },
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

  Future<http.Response> refresh(String refreshToken) async {
    return await _apiClient.post(
      '/session/refresh',
      queryParameters: {
        'refresh_token': refreshToken,
      },
    );
  }
}
