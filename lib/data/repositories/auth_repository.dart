import 'dart:convert';
import 'dart:io';
import 'package:colonia_front_app/data/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:colonia_front_app/domain/models/user.dart';

class AuthRepository {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'colonia_jwt_token';

  AuthRepository(
      this._authService, {
        FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<User> loginUser({
    required String email,
    required String password
  }) async {
    try {
      final response = await _authService.login(email: email, password: password);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);

        final loginResult = LoginResult.fromJson(jsonMap);

        await _secureStorage.write(
          key: _tokenKey,
          value: loginResult.accessToken,
        );

        return loginResult.user;
      } else {
        final errorDetail = jsonDecode(response.body)['detail'] ?? 'Incorrect credentials';
        throw Exception(errorDetail);
      }
    } on SocketException {
      throw Exception("Network error");
    } catch (e) {
      rethrow;
    }
  }

  Future<User> registerUser({
    required String email,
    required String username,
    required String password,
  }) async {

    try {
      final response = await _authService.register(
        email: email,
        username: username,
        password: password,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        return User.fromJson(jsonMap);
      } else {
        final errorDetail = jsonDecode(response.body)['detail'] ?? 'Error while register';
        throw Exception(errorDetail);
      }
    } on SocketException {
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<bool> hasActiveSession() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }
}