import 'dart:convert';
import 'dart:math';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
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

  Territory getTerritoryOrDefault(String id) {
    return _territories[id] ?? Territory(
      id: id,
      teamId: 0,
      healthPoints: GameConfig.baseTerritoryHealth,
    );
  }

  double impactTerritory({
    required String id,
    required double points,
  })  {
    var territory = getTerritoryOrDefault(id);
    double newHealth;
    int newTeamId = territory.teamId;

    if (AuthRepository.instance.currentUser?.userTeam != null && territory.teamId == AuthRepository.instance.currentUser!.userTeam) {
      newHealth = min(GameConfig.maxTerritoryHealth, territory.healthPoints + points);
    } else {
      newHealth = territory.healthPoints - points;
      if (newHealth < 0) {
        newHealth = min(GameConfig.maxTerritoryHealth, GameConfig.baseTerritoryHealth + newHealth.abs());
        newTeamId = AuthRepository.instance.currentUser?.userTeam ?? 0;
      }
    }
    
    final updatedTerritory = territory.copyWith(
      healthPoints: newHealth,
      teamId: newTeamId,
    );
    _territories[id] = updatedTerritory;
    notifyListeners();
    return updatedTerritory.healthPoints;
  }

  void clearCache() {
    _territories.clear();
    notifyListeners();
  }
}
