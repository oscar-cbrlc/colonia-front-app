import 'dart:convert';

import 'package:colonia_front_app/data/services/api/training_service.dart';
import 'package:colonia_front_app/domain/models/training.dart';
import 'package:flutter/widgets.dart';

// TODO(training):  check response bodies
class TrainingRepository extends ChangeNotifier {
  final TrainingService _trainingService;

  // TODO: get trainings from API
  // placeholders
  List<Training> _trainings = [
    Training(id: 1, name: "free", attackPoints: 1, defensePoints: 1),
    Training(id: 2, name: "distance", attackPoints: 1.5, defensePoints: 1.5),
    Training(id: 3, name: "time", attackPoints: 1.25, defensePoints: 1.25),
    Training(id: 4, name: "pace", attackPoints: 1.75, defensePoints: 1.75),
    Training(id: 5, name: "timeTrial", attackPoints: 1.75, defensePoints: 1.75),
  ];
  List<Training> get trainings => _trainings;


  Training? getTrainingFromList(int id) {
    try {
      return _trainings.firstWhere((training) => training.id == id);
    } catch (e) {
      return null;
    }
  }

  TrainingRepository({required TrainingService trainingService})
      : _trainingService = trainingService {
    //fetchAllTrainings();
  }

  Future<void> fetchAllTrainings() async {
    try {
      final response = await _trainingService.getAllTrainings();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _trainings = data.map((json) => Training.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      //  error
    }
  }

  Future<Training?> fetchTrainingById(int id) async {
    try {
      final response = await _trainingService.getTrainingById(id);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (jsonList.isNotEmpty) {
          return Training.fromJson(jsonList.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      //  error
    }
    return null;
  }
}