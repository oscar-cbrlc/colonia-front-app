import 'dart:convert';
import 'dart:io';
import 'package:colonia_front_app/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import '../../domain/models/user.dart';
import '../services/api/auth_service.dart';

class UserNotFoundException implements Exception {
  String cause;
  UserNotFoundException(this.cause);
}

class AuthRepository extends ChangeNotifier {
  static AuthRepository? _instance;
  static AuthRepository get instance => _instance!;

  final AuthService _authService;
  final LocalStorageService _localStorageService;

  String? _cachedAuthToken;
  String? _cachedRefreshToken;
  User? _currentUser;

  User? get currentUser => _currentUser;
  String? get cachedToken => _cachedAuthToken;

  AuthRepository(this._authService, this._localStorageService) {
    _instance = this;
  }

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
      } else {
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
      } else {
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
    _currentUser = await _localStorageService.user;
    _cachedAuthToken = await _localStorageService.authToken;
    _cachedRefreshToken = await _localStorageService.refreshToken;

    if (_cachedAuthToken != null) {
      if (_isTokenExpired(_cachedAuthToken!)) {
        if (_cachedRefreshToken != null && !_isTokenExpired(_cachedRefreshToken!)) {
          await refreshSession();
        } else {
          await _localStorageService.clearSession();
          _clearLocalCache();
        }
      } else {
        fetchCurrentUser().catchError((e) {
          debugPrint('AuthRepository: Background refresh failed: $e');
        });
      }
    } else if (_cachedRefreshToken != null) {
      if (!_isTokenExpired(_cachedRefreshToken!)) {
        await refreshSession();
      } else {
        await _localStorageService.clearSession();
        _clearLocalCache();
      }
    } else {
      await _localStorageService.clearSession();
      _clearLocalCache();
    }
    notifyListeners();
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      final String decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final Map<String, dynamic> map = json.decode(decoded);
      if (!map.containsKey('exp')) return false;
      final exp = map['exp'] as int;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (_) {
      return true;
    }
  }

  Future<bool> refreshSession() async {
    final refreshToken = _cachedRefreshToken ?? await _localStorageService.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await _authService.refresh(refreshToken);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _cachedAuthToken = data['access_token'];
        _cachedRefreshToken = data['refresh_token'];
        
        await _localStorageService.saveAuthToken(_cachedAuthToken!);
        await _localStorageService.saveRefreshToken(_cachedRefreshToken!);
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('AuthRepository: Refresh session error: $e');
    }
    return false;
  }

  Future<void> updateCurrentUser(User user) async {
    _currentUser = user;
    await _localStorageService.saveUser(user);
    notifyListeners();
  }

  Future<User> fetchCurrentUser() async {
    try {
      final response = await _authService.getCurrentUserData().timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        final user = User.fromJson(jsonMap);
        
        _currentUser = user;
        await _localStorageService.saveUser(user);
        
        notifyListeners();
        return user;
      } else if (response.statusCode == 401) {
        final success = await refreshSession();
        if (success) {
           return await fetchCurrentUser();
        } else {
          await logout();
          throw Exception('Session expired');
        }
      } else {
        throw Exception('Failed to fetch current user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AuthRepository: fetchCurrentUser error: $e');
      rethrow;
    }
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

        _cachedAuthToken = loginResult.accessToken;
        _cachedRefreshToken = loginResult.refreshToken;
        _currentUser = loginResult.user;

        await _localStorageService.saveAuthToken(loginResult.accessToken);
        await _localStorageService.saveRefreshToken(loginResult.refreshToken);
        await _localStorageService.saveUser(loginResult.user);

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
    final refreshToken = _cachedRefreshToken ?? await _localStorageService.refreshToken;
    if (refreshToken != null) {
      try {
        await _authService.logout(refreshToken);
      } catch (e) {
        debugPrint('AuthRepository: Remote logout failed: $e');
      }
    }
    await _localStorageService.clearSession();
    _clearLocalCache();
  }

  void _clearLocalCache() {
    _cachedAuthToken = null;
    _cachedRefreshToken = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> completeSocialLogin({
    required User user,
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAuthToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _currentUser = user;
    
    await _localStorageService.saveAuthToken(accessToken);
    await _localStorageService.saveRefreshToken(refreshToken);
    await _localStorageService.saveUser(user);
    
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
          return await loginUser(email: email, password: password);
        } catch (loginError) {
          final Map<String, dynamic> jsonMap = jsonDecode(response.body);
          final user = User.fromJson(jsonMap);
          _currentUser = user;
          await _localStorageService.saveUser(user);
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

  bool get hasActiveSession => _cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty;
}
