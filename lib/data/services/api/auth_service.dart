import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:colonia_front_app/data/services/api/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<http.Response> getUserById(int id) async {
    return await _apiClient.get('/users/$id');
  }

  Future<http.Response> getCurrentUserData() async {
    var currentUserId = AuthRepository.instance.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('No authenticated user found');
    }
    return await _apiClient.get('/users/$currentUserId');
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

  // updates authenticated user
  Future<http.Response> updateUser(Map<String, dynamic> data) async {
    return await _apiClient.put(
      '/users/',
      body: data,
    );
  }

  // deletes authenticated user
  Future<http.Response> deleteUser() async {
    return await _apiClient.delete('/users/');
  }

  Future<http.Response> login({
    required String email,
    required String password
  }) async {
    return await _apiClient.post(
        '/users/login',
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
