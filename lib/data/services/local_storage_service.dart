import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/session/pending_activity_impact.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'colonia_jwt_access_token';
  static const String _refreshTokenKey = 'colonia_jwt_refresh_token';
  static const String _userKey = 'colonia_user_data';
  static const String _activityKey = 'colonia_pending_activity_data';
  static const String _inventoryKey = 'colonia_inventory_data';
  static const String _availableBoostsKey = 'colonia_available_boosts_data';


  LocalStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(),
            );

  Future<User?> get user async {
    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<String?> get authToken async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> get refreshToken async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> saveUser(User user) async {
    await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  Future<List<PendingActivityImpact>> getPendingActivityImpacts() async {
    try {
      final data = await _secureStorage.read(key: _activityKey);
      if (data == null || data.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => PendingActivityImpact.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('LocalStorageService: Error reading pending impacts: $e');
      return [];
    }
  }

  Future<void> savePendingActivityImpacts(List<PendingActivityImpact> impacts) async {
    await _secureStorage.write(key: _activityKey, value: jsonEncode(impacts.map((e) => e.toJson()).toList()));
  }

  Future<List<Boost>> getAvailableBoosts() async {
    final data = await _secureStorage.read(key: _availableBoostsKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Boost.fromJson(e)).toList();
  }

  Future<List<BoostInventory>> getInventory() async {
    final data = await _secureStorage.read(key: _inventoryKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => BoostInventory.fromJson(e)).toList();
  }

  Future<void> saveAvailableBoosts(List<Boost> boosts) async {
    await _secureStorage.write(key: _availableBoostsKey, value: jsonEncode(boosts.map((e) => e.toJson()).toList()));
  }

  Future<void> saveInventory(List<BoostInventory> boostInventory) async {
    await _secureStorage.write(key: _inventoryKey, value: jsonEncode(boostInventory.map((e) => e.toJson()).toList()));
  }
}
