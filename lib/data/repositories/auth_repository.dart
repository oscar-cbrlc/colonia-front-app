import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/user.dart';
import '../services/api/auth_service.dart';

class UserNotFoundException implements Exception {
  String cause;
  UserNotFoundException(this.cause);
}

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

  Future<User> getUserByEmail(String email) async {

    try {
      final response = await _authService.getUserByEmail(email);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (jsonList.isNotEmpty) {
          return User.fromJson(jsonList.first as Map<String, dynamic>);
        } else {
          throw UserNotFoundException('User not found');
        }
      } else if (response.statusCode == 404) {
        throw UserNotFoundException('User not found');
      }
      else {
        final errorDetail = jsonDecode(response.body)['detail'] ?? 'Server error';
        throw Exception(errorDetail);
      }
    } on SocketException {
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserById({
    required int id,
  }) async {
    try {
      final response = await _authService.getUserById(id);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (jsonList.isNotEmpty) {
          return User.fromJson(jsonList.first as Map<String, dynamic>);
        } else {
          throw UserNotFoundException('User not found');
        }
      } else if (response.statusCode == 404) {
        throw UserNotFoundException('User not found');
      }
      else {
        final errorDetail = jsonDecode(response.body)['detail'] ?? 'Server error';
        throw Exception(errorDetail);
      }
    } on SocketException {
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }

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

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    _cachedToken = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> completeSocialLogin({
    required User user,
    required String token,
  }) async {
    await _secureStorage.write(
      key: _tokenKey,
      value: token,
    );
    _cachedToken = token;
    _currentUser = user;
    notifyListeners();
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

  bool get hasActiveSession => _cachedToken != null && _cachedToken!.isNotEmpty;
}