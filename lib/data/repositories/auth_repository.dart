import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/user.dart';
import '../services/auth_service.dart';

class AuthRepository extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'colonia_jwt_token';
  String? _cachedToken;
  User? _currentUser;

  User? get currentUser => _currentUser;
  String? get cachedToken => _cachedToken;

  AuthRepository(
      this._authService, {
        FlutterSecureStorage? secureStorage,
      }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> initializeSession() async {
    _cachedToken = await _secureStorage.read(key: _tokenKey);
    notifyListeners();
  }

  Future<User> loginUser({
    required String email,
    required String password,
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

        _cachedToken = loginResult.accessToken;
        _currentUser = loginResult.user;

        notifyListeners();
        return loginResult.user;
      } else {
        final errorDetail = jsonDecode(response.body)['detail'] ?? 'Incorrect credentials';
        throw Exception(errorDetail);
      }
    } on SocketException {
      throw Exception('Network error');
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
          try {
            final loggedInUser = await loginUser(email: email, password: password);
            return loggedInUser;
          } catch (loginError) {
            final Map<String, dynamic> jsonMap = jsonDecode(response.body);
            _currentUser = User.fromJson(jsonMap);
            notifyListeners();
            return _currentUser!;
          }
        } else {
          final errorDetail = jsonDecode(response.body)['detail'] ?? 'Process error';
          throw Exception(errorDetail);
        }
      } on SocketException {
        throw Exception('Network error');
      } catch (e) {
        rethrow;
      }
    }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    _cachedToken = null;
    _currentUser = null;
    notifyListeners();
  }

  bool get hasActiveSession => _cachedToken != null && _cachedToken!.isNotEmpty;
}