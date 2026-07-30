import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/session/on_track_node.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/domain/models/session/training_config.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:h3_flutter/h3_flutter.dart';

class SessionRepository extends ChangeNotifier {
  final TrackingRepository _trackingRepository;

  PlayingState _playingState = PlayingState.stopped;
  String _activeActivity = "walk";
  TrainingConfig? _trainingConfig;

  PlayingState get playingState => _playingState;
  String? get sportActivity => _activeActivity;
  TrainingConfig? get trainingConfig => _trainingConfig;
  double get targetDistance => _trainingConfig?.distance ?? 0.0;
  Duration get targetDuration => _trainingConfig?.time ?? Duration.zero;
  double get targetPace => _trainingConfig?.pace ?? 0.0;
  Boost? get boost => _trainingConfig?.boost;

  SessionRepository(this._trackingRepository) {
    _trackingRepository.addListener(_onMetricsUpdated);
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

  Future<void> stopAndSaveSession() async {
    if (_playingState == PlayingState.stopped) return;
    _playingState = PlayingState.stopped;

    final double finalDistance = _trackingRepository.totalMetersTracked;
    final int finalSeconds = _trackingRepository.totalSecondsElapsed;
    final List<OnTrackNode> onTrackNodes = _trackingRepository.onTrackNodes;

    // TODO:  use actual team id
    /*final List<Territory> affectedTerritories = onTrackNodes.map((node) {
      final h3Index = H3Helper.getHexagonAt(lat: node.lat, lon: node.lon, resolution: GameConfig.h3Resolution);
      //return Territory(id: h3Index.toString(), teamId: 1, healthPoints: );
    }).toList();*/

    _trackingRepository.stopActivity();

    final isValid = _verifyWorkoutCompletion(finalDistance, finalSeconds);

    // TODO(game_session): retrieve points from DB
    if (isValid) {
      const int basePoints = 100;
      double multiplier = 1.0;

      final trainingType = _trainingConfig?.training.name;
      if (trainingType == TrainingType.distance.toString()) multiplier = 1.5;
      if (trainingType == TrainingType.duration.toString()) multiplier = 1.25;
      if (trainingType == TrainingType.pace.toString()) multiplier = 1.75;
      if (trainingType == TrainingType.timeTrial.toString()) multiplier = 1.75;
      if (boost != null) multiplier *= boost!.effect;



      final double calculatedScore = finalDistance * basePoints * multiplier;

      //await _syncSessionWithServer(vertices, calculatedScore);
    }

    _resetSessionData();
    notifyListeners();
  }

  bool _verifyWorkoutCompletion(double actualDistanceMeters, int actualSeconds) {
    // TODO: verify with ML model
    final trainingType = _trainingConfig?.training.name;
    if (trainingType == TrainingType.free.toString() || trainingType == null) {
      return true;
    }
    if (trainingType == TrainingType.distance.toString()) {
      return actualDistanceMeters >= targetDistance;
    }
    if (trainingType == TrainingType.duration.toString()) {
      return actualSeconds >= targetDuration.inSeconds;
    }
    if (trainingType == TrainingType.pace.toString()) {
      final actualPace = actualSeconds / (actualDistanceMeters / 1000);
      return
        targetPace * (1-GameConfig.validPaceRange) <= actualPace
            && targetPace * (1+GameConfig.validPaceRange) >= actualPace;
    }
    if (trainingType == TrainingType.timeTrial.toString()) {
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



  Future<void> _syncSessionWithServer(List<GeoCoord> path, double score) async {
    // TODO: API Send
  }

  @override
  void dispose() {
    _trackingRepository.removeListener(_onMetricsUpdated);
    super.dispose();
  }
}
