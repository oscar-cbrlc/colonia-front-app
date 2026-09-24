import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/config/session_config.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/domain/models/activity_result.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/session/on_track_node.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';
import 'package:colonia_front_app/domain/models/session/pending_activity_impact.dart';
import 'package:colonia_front_app/data/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/domain/models/session/training_config.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';


class SessionRepository extends ChangeNotifier {
  final TrackingRepository _trackingRepository;
  final TerritoryRepository _territoryRepository;
  final LocalStorageService _localStorageService;
  final BoostRepository _boostRepository;
  
  SessionConfig _sessionConfig = SessionConfig.fromBase();
  
  LocalStorageService get localStorageService => _localStorageService;

  PlayingState _playingState = PlayingState.stopped;
  String _activeActivity = "walk";
  TrainingConfig? _trainingConfig;
  List<Territory> _affectedTerritories = [];
  double _accumulatedImpactPoints = 0.0;

  final Map<String, double> _sessionTerritoryImpacts = {};

  PlayingState get playingState => _playingState;
  String? get sportActivity => _activeActivity;
  TrainingConfig? get trainingConfig => _trainingConfig;
  double get targetDistance => _trainingConfig?.distance ?? 0.0;
  Duration get targetDuration => _trainingConfig?.time ?? Duration.zero;
  double get targetPace => _trainingConfig?.pace ?? 0.0;
  BoostInventory? get boost => _trainingConfig?.boost;
  double get accumulatedImpactPoints => _accumulatedImpactPoints;

  List<Territory> get affectedTerritories => _affectedTerritories;

  SessionRepository(this._trackingRepository, this._territoryRepository, this._localStorageService, this._boostRepository) {
    _trackingRepository.addListener(_onMetricsUpdated);
    _trackingRepository.onNodeCompleted = _handleNodeCompleted;
  }

  void Function()? onSyncNotification;

  void _handleNodeCompleted(OnTrackNode node) {
    if (_playingState != PlayingState.playing) return;

    final String? centerCell = H3Helper.getHexagonAt(
      lat: node.lat,
      lon: node.lon,
      resolution: GameConfig.h3Resolution,
    );

    if (centerCell == null) return;

    final double trainingImpact = _trainingConfig?.training.impactPoints ?? 1.0;
    final double primaryImpact = _sessionConfig.baseImpactPoints * trainingImpact;
    double nodeTotalImpact = 0;

    _applyImpactToCell(centerCell, primaryImpact);
    nodeTotalImpact += primaryImpact;

    final List<OnTrackNode> secondaryNodes = [];

    if (_sessionConfig.impactAreaLevel > 0) {
      final neighbors = H3Helper.getNeighbors(centerCell, ring: _sessionConfig.impactAreaLevel);
      final double secondaryImpact = primaryImpact * _sessionConfig.areaImpactMultiplier;
      
      for (final cellId in neighbors) {
        _applyImpactToCell(cellId, secondaryImpact);
        nodeTotalImpact += secondaryImpact;

        final center = H3Helper.getCellCenter(cellId);
        secondaryNodes.add(OnTrackNode(
          lat: center.lat - 0.0001,
          lon: center.lon,
          pace: node.pace,
          points: secondaryImpact,
          timestamp: node.timestamp,
          type: OnTrackNodeType.area,
        ));
      }
    }

    _accumulatedImpactPoints += nodeTotalImpact;
    _trackingRepository.updateLastNodePoints(primaryImpact);
    if (secondaryNodes.isNotEmpty) {
      _trackingRepository.addSecondaryNodes(secondaryNodes);
    }

    notifyListeners();
  }

  void _applyImpactToCell(String cellId, double points) {
    _sessionTerritoryImpacts[cellId] = (_sessionTerritoryImpacts[cellId] ?? 0.0) + points;
  }

  void setupSession({
    required TrainingConfig config,
  }) {
    _activeActivity = config.activity;
    _trainingConfig = config;
    
    _sessionConfig = SessionConfig.fromTrainingConfig(config);
    
    _trackingRepository.setMetersBetweenNodes(_sessionConfig.metersBetweenNodes);
    
    notifyListeners();
  }

  void startGame() {
    if (_playingState == PlayingState.playing) return;
    _playingState = PlayingState.playing;
    _accumulatedImpactPoints = 0.0;
    _sessionTerritoryImpacts.clear();
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

  Future<({TrackingSession session, ActivityResult? activityResult, bool isOffline, String? error})?> stopAndSaveSession() async {
    if (_playingState == PlayingState.stopped) return null;
    _playingState = PlayingState.stopped;

    final double finalDistance = _trackingRepository.totalMetersTracked;
    final int finalSeconds = _trackingRepository.totalSecondsElapsed;

    final session = _trackingRepository.stopActivity();
    final isValid = _verifyWorkoutCompletion(finalDistance, finalSeconds);
    session.isSuccess = isValid;

    ActivityResult? activityResult;
    bool isOffline = false;
    String? error;

    if (isValid) {
      _affectedTerritories = List.from(session.territories);

      try {
        final territoriesJson = _sessionTerritoryImpacts.entries.map((entry) => {
          'territory_id': entry.key,
          'points': entry.value,
        }).toList();

        final impact = PendingActivityImpact(
          totalDistance: finalDistance,
          totalTime: finalSeconds,
          timestamp: DateTime.now().toIso8601String(),
          territories: territoriesJson,
          boostId: _trainingConfig?.boost?.id,
        );

        final impactResult = await _territoryRepository.applyTerritoryImpact(
          totalDistance: impact.totalDistance,
          totalTime: impact.totalTime,
          timestamp: impact.timestamp,
          territories: impact.territories,
          boostId: impact.boostId,
        );

        activityResult = impactResult.result;
        isOffline = impactResult.isOffline;
        error = impactResult.error;

        if (activityResult != null) {
          if (impact.boostId != null) {
            _boostRepository.fetchMyInventory();
          }
        } else {
          if (impact.boostId != null) {
            _boostRepository.consumeLocalBoost(impact.boostId!);
          }
          final pending = await _localStorageService.getPendingActivityImpacts();
          pending.add(impact);
          await _localStorageService.savePendingActivityImpacts(pending);
          debugPrint('SessionRepository: Saved impact locally for later sync (isOffline: $isOffline, error: $error)');
        }
      } catch (e) {
        debugPrint('SessionRepository: Error applying territory impact: $e');
        isOffline = true;
        error = e.toString();
      }
    }

    _resetSessionData();
    notifyListeners();
    return (session: session, activityResult: activityResult, isOffline: isOffline, error: error);
  }

  Future<void> syncPendingImpacts() async {
    try {
      final pending = await _localStorageService.getPendingActivityImpacts();
      if (pending.isEmpty) return;

      debugPrint('SessionRepository: Attempting to sync ${pending.length} pending impacts');
      final List<PendingActivityImpact> remaining = [];
      bool syncedAny = false;

      for (final impact in pending) {
        try {
          final impactResult = await _territoryRepository.applyTerritoryImpact(
            totalDistance: impact.totalDistance,
            totalTime: impact.totalTime,
            timestamp: impact.timestamp,
            territories: impact.territories,
            boostId: impact.boostId,
          );
          if (impactResult.result == null) {
            debugPrint('SessionRepository: Sync failed for impact (isOffline: ${impactResult.isOffline}, error: ${impactResult.error})');
            remaining.add(impact);
          } else {
            debugPrint('SessionRepository: Successfully synced pending impact');
            syncedAny = true;
          }
        } catch (e) {
          debugPrint('SessionRepository: Error syncing pending impact: $e');
          remaining.add(impact);
        }
      }

      final int syncedCount = pending.length - remaining.length;
      await _localStorageService.savePendingActivityImpacts(remaining);
      
      if (syncedAny) {
        await _boostRepository.fetchMyInventory();
        await _territoryRepository.fetchAllTerritories();
      }

      if (syncedCount > 0) {
        debugPrint('SessionRepository: $syncedCount pending impacts synced successfully');
        onSyncNotification?.call();
      }
    } catch (e) {
      debugPrint('SessionRepository.syncPendingImpacts error: $e');
    }
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
