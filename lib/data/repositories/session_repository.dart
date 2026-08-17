import 'dart:math';

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/session/on_track_node.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/domain/models/session/training_config.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';


class SessionRepository extends ChangeNotifier {
  final TrackingRepository _trackingRepository;
  final TerritoryRepository _territoryRepository;

  PlayingState _playingState = PlayingState.stopped;
  String _activeActivity = "walk";
  TrainingConfig? _trainingConfig;
  List<Territory> _affectedTerritories = [];
  double _accumulatedImpactPoints = 0.0;

  PlayingState get playingState => _playingState;
  String? get sportActivity => _activeActivity;
  TrainingConfig? get trainingConfig => _trainingConfig;
  double get targetDistance => _trainingConfig?.distance ?? 0.0;
  Duration get targetDuration => _trainingConfig?.time ?? Duration.zero;
  double get targetPace => _trainingConfig?.pace ?? 0.0;
  Boost? get boost => _trainingConfig?.boost;
  double get accumulatedImpactPoints => _accumulatedImpactPoints;

  List<Territory> get affectedTerritories => _affectedTerritories;

  SessionRepository(this._trackingRepository, this._territoryRepository) {
    _trackingRepository.addListener(_onMetricsUpdated);
    _trackingRepository.onNodeCompleted = _handleNodeCompleted;
  }

  void _handleNodeCompleted(OnTrackNode node) {
    if (_trainingConfig == null || _playingState != PlayingState.playing) return;

    final cellId = H3Helper.getHexagonAt(
      lat: node.lat,
      lon: node.lon,
      resolution: GameConfig.h3Resolution,
    );

    final baseEffect = GameConfig.basePointsEffect;
    final baseDamage = _trainingConfig!.training.attackPoints;
    final boostEffect = boost?.effect ?? 1.0;
    final totalEffect = baseEffect * baseDamage * boostEffect;
    _accumulatedImpactPoints += totalEffect;

    _trackingRepository.updateLastNodePoints(totalEffect);

    _territoryRepository.impactTerritory(id: cellId, points: totalEffect);

    notifyListeners();
  }

  void setupSession({
    required TrainingConfig config,
  }) {
    _activeActivity = config.activity;
    _trainingConfig = config;
    notifyListeners();
  }

  void startGame() {
    if (_playingState == PlayingState.playing) return;
    _playingState = PlayingState.playing;
    _accumulatedImpactPoints = 0.0;
    _trackingRepository.startActivity();
    notifyListeners();
  }

  void pauseGame() {
    if (_playingState != PlayingState.playing) return;
    _playingState = PlayingState.paused;
    _trackingRepository.pauseActivity();
    notifyListeners();
  }

  void resumeGame() {
    if (_playingState != PlayingState.paused) return;
    _playingState = PlayingState.playing;
    _trackingRepository.resumeActivity();
    notifyListeners();
  }

  Future<TrackingSession?> stopAndSaveSession() async {
    if (_playingState == PlayingState.stopped) return null;
    _playingState = PlayingState.stopped;

    final double finalDistance = _trackingRepository.totalMetersTracked;
    final int finalSeconds = _trackingRepository.totalSecondsElapsed;

    final session = _trackingRepository.stopActivity();
    final isValid = _verifyWorkoutCompletion(finalDistance, finalSeconds);
    session.isSuccess = isValid;

    if (isValid) {
      _affectedTerritories = List.from(session.territories);
    }

    _resetSessionData();
    notifyListeners();
    return session;
  }

  bool _verifyWorkoutCompletion(double actualDistanceMeters, int actualSeconds) {
    final trainingName = _trainingConfig?.training.name.toLowerCase();
    
    if (trainingName == "free" || trainingName == null) {
      return true;
    }
    
    if (trainingName == "distance") {
      return actualDistanceMeters >= targetDistance;
    }
    
    if (trainingName == "time" || trainingName == "duration") {
      return actualSeconds >= targetDuration.inSeconds;
    }
    
    if (trainingName == "pace") {
      if (actualDistanceMeters < 50) return false;
      final actualPace = (actualSeconds / 60) / (actualDistanceMeters / 1000);
      return actualPace >= (targetPace * (1.0 - GameConfig.validPaceRange)) &&
             actualPace <= (targetPace * (1.0 + GameConfig.validPaceRange));
    }
    
    if (trainingName == "timetrial") {
      return actualDistanceMeters >= targetDistance &&
             actualSeconds <= targetDuration.inSeconds;
    }
    
    return true;
  }

  void _onMetricsUpdated() {
    notifyListeners();
  }

  void _resetSessionData() {
    _trainingConfig = null;
  }

  @override
  void dispose() {
    _trackingRepository.removeListener(_onMetricsUpdated);
    super.dispose();
  }
}
