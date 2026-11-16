import 'dart:convert';
import 'dart:io';

import 'package:colonia_front_app/data/services/api/training_service.dart';
import 'package:colonia_front_app/domain/models/activity_result.dart';
import 'package:colonia_front_app/domain/models/enums/training_type.dart';
import 'package:colonia_front_app/domain/models/training.dart';
import 'package:colonia_front_app/domain/models/user_training.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class TrainingRepository extends ChangeNotifier {
  final TrainingService _trainingService;

  List<Training> _trainings = [
    Training(id: 1, name: TrainingType.free.name, impactPoints: 1),
    Training(id: 2, name: TrainingType.distance.name, impactPoints: 1.5),
    Training(id: 3, name: TrainingType.time.name, impactPoints: 1.25),
    Training(id: 4, name: TrainingType.pace.name, impactPoints: 1.75),
    Training(id: 5, name: TrainingType.timeTrial.name, impactPoints: 1.75),
  ];

  List<UserTraining> _myUserTrainings = [];

  List<Training> get trainings => _trainings;
  List<UserTraining> get myUserTrainings => _myUserTrainings;

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

  Future<List<UserTraining>> fetchAllMyUserTrainings() async {
    try {
      final response = await _trainingService.getAllMyUserTrainings();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        _myUserTrainings = data.map((json) => UserTraining.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
        return _myUserTrainings;
      }
    } catch (e) {
      debugPrint('TrainingRepository: Error fetching all my user trainings: $e');
    }
    return _myUserTrainings;
  }

  Future<UserTraining?> fetchUserTraining(int userId, String trainingUuid) async {
    try {
      final response = await _trainingService.getUserTraining(userId, trainingUuid);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserTraining.fromJson(data);
      }
    } catch (e) {
      debugPrint('TrainingRepository: Error fetching user training $trainingUuid for user $userId: $e');
    }
    return null;
  }

  Future<({ActivityResult? result, bool isOffline, String? error})> processUserTraining(
    UserTraining userTraining,
    List<Map<String, dynamic>> territoriesJson,
  ) async {
    try {
      final body = userTraining.toCreateJson(territoriesJson);

      final response = await _trainingService.processUserTraining(body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(response.body);
        final result = ActivityResult.fromJson(decoded as Map<String, dynamic>);
        return (result: result, isOffline: false, error: null);
      } else {
        debugPrint('TrainingRepository: API error ${response.statusCode}: ${response.body}');
        return (result: null, isOffline: false, error: 'Server error');
      }
    } on SocketException catch (e) {
      debugPrint('TrainingRepository: SocketException uploading training: $e');
      return (result: null, isOffline: true, error: 'Network error');
    } on http.ClientException catch (e) {
      debugPrint('TrainingRepository: ClientException uploading training: $e');
      return (result: null, isOffline: true, error: 'Network error');
    } catch (e) {
      debugPrint('TrainingRepository: Error uploading training: $e');
      return (result: null, isOffline: true, error: e.toString());
    }
  }
}
