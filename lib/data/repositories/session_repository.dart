import 'package:flutter/material.dart';
import 'package:colonia_front_app/domain/models/session_models.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:h3_flutter/h3_flutter.dart';

class SessionRepository extends ChangeNotifier {
  final TrackingRepository _trackingRepository;

  PlayingState _playingState = PlayingState.stopped;
  SportActivity _activeActivity = SportActivity.walking;
  TrainingType _activeTraining = TrainingType.free;

  double _targetDistance = 0.0;
  Duration _targetDuration = Duration.zero;
  double _targetPace = 0.0;

  PlayingState get playingState => _playingState;
  SportActivity get sportActivity => _activeActivity;
  TrainingType get trainingType => _activeTraining;
  double get targetDistance => _targetDistance;
  Duration get targetDuration => _targetDuration;
  double get targetPace => _targetPace;

  SessionRepository(this._trackingRepository) {
    _trackingRepository.addListener(_onMetricsUpdated);
  }

  void setupSession({
    required SportActivity activity,
    required TrainingType training,
    double distance = 0.0,
    Duration? duration,
    double pace = 0.0,
  }) {
    _activeActivity = activity;
    _activeTraining = training;
    _targetDistance = distance;
    _targetDuration = duration ?? Duration.zero;
    _targetPace = pace;
    notifyListeners();
  }

  void startGame() {
    if (_playingState == PlayingState.playing) return;
    _playingState = PlayingState.playing;
    _trackingRepository.startTracking();
    notifyListeners();
  }

  void pauseGame() {
    if (_playingState != PlayingState.playing) return;
    _playingState = PlayingState.paused;
    _trackingRepository.pauseTracking();
    notifyListeners();
  }

  void resumeGame() {
    if (_playingState != PlayingState.paused) return;
    _playingState = PlayingState.playing;
    _trackingRepository.resumeTracking();
    notifyListeners();
  }

  Future<void> stopAndSaveSession() async {
    if (_playingState == PlayingState.stopped) return;
    _playingState = PlayingState.stopped;

    final double finalDistance = _trackingRepository.totalMetersTracked;
    final int finalSeconds = _trackingRepository.totalSecondsElapsed;
    final vertices = List<GeoCoord>.from(_trackingRepository.perimeter);

    _trackingRepository.stopTracking();

    final isValid = _verifyWorkoutCompletion(finalDistance, finalSeconds);

    // TODO(game_session): retrieve points from DB
    if (isValid) {
      const int basePoints = 100;
      double multiplier = 1.0;

      if (_activeTraining == TrainingType.distance) multiplier = 1.5;
      if (_activeTraining == TrainingType.duration) multiplier = 1.25;
      if (_activeTraining == TrainingType.timeTrial) multiplier = 1.75;

      final double calculatedScore = finalDistance * basePoints * multiplier;

      await _syncSessionWithServer(vertices, calculatedScore);
    }

    _resetSessionData();
    notifyListeners();
  }

  bool _verifyWorkoutCompletion(double actualDistanceMeters, int actualSeconds) {
    // TODO: verify with ML model
    if (_activeTraining == TrainingType.free) {
      return true;
    }
    if (_activeTraining == TrainingType.distance) {
      return actualDistanceMeters >= _targetDistance;
    }
    if (_activeTraining == TrainingType.duration) {
      return actualSeconds >= _targetDuration.inSeconds;
    }
    return true;
  }

  void _onMetricsUpdated() {
    notifyListeners();
  }

  void _resetSessionData() {
    _targetDistance = 0.0;
    _targetDuration = Duration.zero;
    _targetPace = 0.0;
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