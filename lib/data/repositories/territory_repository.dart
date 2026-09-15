import 'dart:convert';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/activity_result.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/data/services/api/territory_service.dart';
import 'package:colonia_front_app/domain/models/territory.dart';

class TerritoryRepository extends ChangeNotifier {
  final TerritoryService _territoryService;

  Map<String, Territory> _territories = {};

  TerritoryRepository(this._territoryService);

  List<Territory> get territories => _territories.values.toList();


  Future<void> fetchAllTerritories() async {
    try {
      final response = await _territoryService.getAllTerritories();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _territories = {
          for (var json in data) json['territory_id'] as String: Territory.fromJson(json)
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TerritoryRepository: Error fetching all territories: $e');
    }
  }

  Future<ActivityResult?> applyTerritoryImpact({
    required double totalDistance,
    required int totalTime,
    required String timestamp,
    required List<Map<String, dynamic>> territories,
  }) async {
    try {
      final response = await _territoryService.applyPoints(
        totalDistance: totalDistance,
        totalTime: totalTime,
        timestamp: timestamp,
        territories: territories,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(response.body);
        final result = ActivityResult.fromJson(decoded);

        for (final territory in result.territories) {
          _territories[territory.id] = territory;
        }
        notifyListeners();

        return result;
      }
    } catch (e) {
      debugPrint('TerritoryRepository: Error applying territory impact: $e');
    }
    return null;
  }

  Territory getTerritoryOrDefault(String id) {
    return _territories[id] ?? Territory(
      id: id,
      healthPoints: GameConfig.baseTerritoryHealth,
    );
  }


  void clearCache() {
    _territories.clear();
    notifyListeners();
  }
}
