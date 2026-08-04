import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/data/services/api/territory_service.dart';
import 'package:colonia_front_app/domain/models/territory.dart';

// PLACEHOLDERSS
// TODO: update endpoints when available
class TerritoryRepository extends ChangeNotifier {
  final TerritoryService _territoryService;

  Map<String, Territory> _territories = {};

  TerritoryRepository(this._territoryService);

  List<Territory> get territories => _territories.values.toList();

  Future<void> fetchTerritoriesInRadius({
    required double lat,
    required double lon,
    required double radius,
  }) async {
    try {
      final response = await _territoryService.getTerritoriesInRadius(lat, lon, radius);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final newTerritories = {
          for (var json in data) json['territory_id'] as String: Territory.fromJson(json)
        };
        _territories.addAll(newTerritories);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TerritoryRepository: Error fetching territories: $e');
    }
  }

  Future<Territory> claimTerritory({
    required String territoryId,
    required int teamId,
    required double healthPoints,
  }) async {
    try {
      final response = await _territoryService.claimTerritory(territoryId, teamId, healthPoints);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final updatedTerritory = Territory.fromJson(data);
        _territories[territoryId] = updatedTerritory;
        notifyListeners();
        return updatedTerritory;
      }
    } catch (e) {
      debugPrint('TerritoryRepository: Error claiming territory: $e');
      rethrow;
    }
    throw Exception('Failed to claim territory');
  }

  Future<List<Territory>> claimTerritories({
    required List<String> ids,
    required int teamId,
    required List<double> healthPoints,
  }) async {
    try {
      final response = await _territoryService.claimTerritories(ids, teamId, healthPoints);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        final updatedTerritories = data.map((json) => Territory.fromJson(json)).toList();
        for (var territory in updatedTerritories) {
          _territories[territory.id] = territory;
        }
        notifyListeners();
        return updatedTerritories;
      }
    } catch (e) {
      debugPrint('TerritoryRepository: Error claiming territories: $e');
      rethrow;
    }
    throw Exception('Failed to claim territories');
  }

  Future<void> updateTerritoryHealth({
    required String territoryId,
    required double healthDelta,
  }) async {
    try {
      final response = await _territoryService.updateTerritoryHealth(territoryId, healthDelta);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedTerritory = Territory.fromJson(data);
        _territories[territoryId] = updatedTerritory;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TerritoryRepository: Error updating territory health: $e');
    }
  }

  Territory? getTerritory(String id) => _territories[id];

  void clearCache() {
    _territories.clear();
    notifyListeners();
  }
}
