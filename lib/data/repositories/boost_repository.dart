import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:flutter/cupertino.dart';

class BoostRepository extends ChangeNotifier {

  List<BoostInventory> _inventory = [];
  List<Boost> _availableBoosts = [];

  List<Boost> get userBoostInventory => _inventory.isEmpty ? _dummyBoosts : _availableBoosts;

  int getBoostCount(int boostId) {
    if (_inventory.isEmpty) {
      final dummy = _dummyInventory.firstWhere((i) => i.boostId == boostId, orElse: () => const BoostInventory(boostId: 0, userId: 0, amount: 0));
      return dummy.amount;
    }
    final item = _inventory.firstWhere((i) => i.boostId == boostId, orElse: () => BoostInventory(boostId: boostId, userId: 0, amount: 0));
    return item.amount;
  }

  // TODO: replace dummies
  final List<Boost> _dummyBoosts = [
    Boost(id: 1, name: "attack", description: "Increases attack by 15%", effect: 1.15, image: "assets/images/attack.png"),
    Boost(id: 2, name: "defense", description: "Increases defense power by 15%", effect: 1.15, image: "assets/images/defense.png"),
    Boost(id: 3, name: "power", description: "Increases attack and defense by 15%", effect: 1.15, image: "assets/images/shield.png"),
  ];
  final List<BoostInventory> _dummyInventory = [
    BoostInventory(boostId: 1, userId: 1, amount: 2),
    BoostInventory(boostId: 2, userId: 1, amount: 2),
    BoostInventory(boostId: 3, userId: 1, amount: 2),
  ];

  Future<List<Boost>> getAvailableBoosts() async {
    // TODO: Implement API call to fetch available boosts
    return [];
  }

  Future<List<BoostInventory>> getUserInventory(int userId) async {
    // TODO: Implement API call to fetch user inventory
    return [];
  }

  Future<void> addBoostToInventory(int userId, int boostId) async {
    // TODO: Implement API call to add boost to user inventory
    return;
  }

  Future<void> removeBoostFromInventory(int userId, int boostId) async {
    // TODO: Implement API call to remove boost from user inventory
    return;
  }

  Future<void> fetchAndSetUserBoosts(int userId) async {
    final inventory = await getUserInventory(userId);
    final availableBoosts = await getAvailableBoosts();

    final List<Boost> boosts = inventory.map((item) {
      return availableBoosts.firstWhere(
        (boost) => boost.id == item.boostId, orElse: () => throw Exception('Boost not found'),
      );
    }).toList();

    _inventory = inventory;
    _availableBoosts = boosts;
    notifyListeners();
  }


}