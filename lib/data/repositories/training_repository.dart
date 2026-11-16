import 'dart:convert';

import 'package:colonia_front_app/data/services/api/training_service.dart';
import 'package:colonia_front_app/domain/models/enums/training_type.dart';
import 'package:colonia_front_app/domain/models/training.dart';
import 'package:colonia_front_app/domain/models/user_training.dart';
import 'package:flutter/widgets.dart';

class TrainingRepository extends ChangeNotifier {
  final TrainingService _trainingService;

  List<Training> _trainings = [
    Training(id: 1, name: TrainingType.free.name, impactPoints: 1),
    Training(id: 2, name: TrainingType.distance.name, impactPoints: 1.5),
    Training(id: 3, name: TrainingType.time.name, impactPoints: 1.25),
    Training(id: 4, name: TrainingType.pace.name, impactPoints: 1.75),
    Training(id: 5, name: TrainingType.timeTrial.name, impactPoints: 1.75),
  ];

  List<UserTraining> _userTrainings = [];
  bool _isUserTrainingsLoading = false;

  List<Training> get trainings => _trainings;
  List<UserTraining> get userTrainings => _userTrainings;
  bool get isUserTrainingsLoading => _isUserTrainingsLoading;

  Training? getTrainingFromList(int id) {
    try {
      return _trainings.firstWhere((training) => training.id == id);
    } catch (e) {
      return null;
    }
  }

  Training getTrainingByType(TrainingType type) {
    return _trainings.firstWhere(
      (training) => training.type == type,
      orElse: () => _trainings.first,
    );
  }

  TrainingRepository({required TrainingService trainingService})
      : _trainingService = trainingService;

  Future<void> fetchAllTrainings() async {
    try {
      final response = await _trainingService.getAllTrainings();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _trainings = data.map((json) => Training.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      // error
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
      // error
    }
    return null;
  }

  Future<void> fetchMyTrainings() async {
    _isUserTrainingsLoading = true;
    notifyListeners();
    try {
      final response = await _trainingService.getMyTrainings();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _userTrainings = data
            .map((json) => UserTraining.fromJson(json as Map<String, dynamic>))
            .toList();
        _userTrainings.sort((a, b) => b.startDate.compareTo(a.startDate));
      }
    } catch (e) {
      // error
    } finally {
      _isUserTrainingsLoading = false;
      notifyListeners();
    }
  }
}
