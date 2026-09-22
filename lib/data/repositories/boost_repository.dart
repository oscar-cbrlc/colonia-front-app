import 'dart:convert';

import 'package:colonia_front_app/data/services/api/boost_service.dart';
import 'package:colonia_front_app/data/services/local_storage_service.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:flutter/cupertino.dart';

class BoostRepository extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final BoostService _boostService;

  List<BoostInventory> _inventory = [];

  BoostRepository(this._localStorageService, this._boostService) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    _inventory = await _localStorageService.getInventory();
    notifyListeners();
  }

  List<BoostInventory> get userBoostInventory => _inventory;

  int getBoostCount(int boostId) {
    final list =_inventory;
    try {
      final item = list.firstWhere((i) => i.id == boostId);
      return item.quantity;
    } catch (_) {
      return 0;
    }
  }

  // TODO: replace dummies
  /*final List<BoostInventory> _dummyInventory = [
    BoostInventory(id: 1, type: BoostType.score.name, quantity: 5, effect: 2.0),
    BoostInventory(id: 2, type: BoostType.impact_area.name, quantity: 3, effect: 0.5),
    BoostInventory(id: 3, type: BoostType.impact_distance.name, quantity: 1, effect: 0.75),
  ];*/

  Future<List<Boost>> getAvailableBoosts() async {
    try {
      final response = await _boostService.getAllBoosts();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Boost.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('BoostRepository: Error fetching boosts: $e');
    }
    return [];
  }

  Future<void> fetchMyInventory() async {
    try {
      final response = await _boostService.getMyInventory();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _inventory = data.map((json) => BoostInventory.fromJson(json)).toList();
        await _localStorageService.saveInventory(_inventory);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('BoostRepository: Error fetching inventory: $e');
    }
  }

  Future<void> updateBoostInventory(int userId, int boostId, int amount) async {
    try {
      final response = await _boostService.updateBoostInventory(userId, boostId, amount);
      if (response.statusCode == 200) {
        await fetchMyInventory();
      }
    } catch (e) {
      debugPrint('BoostRepository: Error updating boost inventory: $e');
    }
  }

  void clearCache() {
    _inventory = [];
    _localStorageService.saveInventory([]);
    notifyListeners();
  }


}