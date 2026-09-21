import 'dart:convert';
import 'package:colonia_front_app/domain/models/session/pending_activity_impact.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'colonia_jwt_token';
  static const String _userKey = 'colonia_user_data';
  static const String _activityKey = 'colonia_pending_activity_data';
  static const String _inventoryKey = 'colonia_inventory_data';

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
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveUser(User user) async {
    await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  Future<List<PendingActivityImpact>> getPendingActivityImpacts() async {
    final data = await _secureStorage.read(key: _activityKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => PendingActivityImpact.fromJson(e)).toList();
  }

  Future<void> savePendingActivityImpacts(List<PendingActivityImpact> impacts) async {
    await _secureStorage.write(key: _activityKey, value: jsonEncode(impacts.map((e) => e.toJson()).toList()));
  }

  Future<List<BoostInventory>> getInventory() async {
    final data = await _secureStorage.read(key: _inventoryKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => BoostInventory.fromJson(e)).toList();
  }

  Future<void> saveInventory(List<BoostInventory> boostInventory) async {
    await _secureStorage.write(key: _inventoryKey, value: jsonEncode(boostInventory.map((e) => e.toJson()).toList()));
  }
}
