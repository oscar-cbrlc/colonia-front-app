import 'dart:async';
import 'dart:math';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/services/location_service.dart';
import 'package:colonia_front_app/domain/models/session/on_track_node.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:h3_flutter/h3_flutter.dart';

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

class TrackingRepository extends ChangeNotifier {
  final LocationService _locationService;
  final TerritoryRepository _territoryRepository;
  StreamSubscription<geo.Position>? _positionSubscription;

  bool _isActivityActive = false;
  bool _isPaused = false;

  Point? _userPosition;
  double _currentBearing = 0.0;
  String? _currentCell;

  final List<GeoCoord> _perimeter = [];
  final Set<String> _visitedCells = {};
  final List<OnTrackNode> _onTrackNodes = [];

  double _totalMetersTracked = 0.0;
  double _metersSinceLastPerimeterPoint = 0.0;
  double _metersSinceLastNode = 0.0;
  double _metersBetweenNodes = GameConfig.baseMetersBetweenNodes;
  int _totalSecondsElapsed = 0;
  DateTime? _lastTrackTime;
  double _currentSpeed = 0.0; 
  double _averagePace = 0.0; 
  Timer? _gameTimer;
  Timer? _routineTimer;

  HarActivity _currentHarActivity = HarActivity.unknown;
  int _secondsWalk = 0;
  int _secondsRun = 0;
  int _secondsBike = 0;
  double _distanceWalk = 0.0;
  double _distanceRun = 0.0;
  double _distanceBike = 0.0;

  double _pendingNodeImpactPoints = 0.0;

  int _nodeSecondsWalk = 0;
  int _nodeSecondsRun = 0;
  int _nodeSecondsBike = 0;
  double _nodeDistanceWalk = 0.0;
  double _nodeDistanceRun = 0.0;
  double _nodeDistanceBike = 0.0;

  double _unitDistanceTracked = 0.0;

  void Function(OnTrackNode node)? onNodeCompleted;
  geo.Position? _lastRecordedPosition;
  int _pingsToSkip = 0;

  bool get isActivityActive => _isActivityActive;
  bool get isPaused => _isPaused;
  Point? get userPosition => _userPosition;
  double get currentBearing => _currentBearing;
  String? get currentCell => _currentCell;
  List<GeoCoord> get perimeter => _perimeter;
  Set<String> get visitedCells => _visitedCells;
  double get totalMetersTracked => _totalMetersTracked;
  double get currentSpeed => _currentSpeed;
  double get currentPace => _currentSpeed > 0.1 ? (16.6667 / _currentSpeed) : 0.0;
  double get averagePace => _averagePace;
  int get totalSecondsElapsed => _totalSecondsElapsed;
  List<OnTrackNode> get onTrackNodes => _onTrackNodes;
  double get metersSinceLastNode => _metersSinceLastNode;
  double get metersBetweenNodes => _metersBetweenNodes;

  HarActivity get currentHarActivity => _currentHarActivity;
  int get secondsWalk => _secondsWalk;
  int get secondsRun => _secondsRun;
  int get secondsBike => _secondsBike;
  double get distanceWalk => _distanceWalk;
  double get distanceRun => _distanceRun;
  double get distanceBike => _distanceBike;
  double get pendingNodeImpactPoints => _pendingNodeImpactPoints;

  TrackingRepository(this._locationService, this._territoryRepository) {
    _initPassiveTracking();
  }

  void onHarActivityPredicted(HarActivity activity) {
    _currentHarActivity = activity;
    if (_isActivityActive && !_isPaused) {
      int unitPts = 0;
      switch (activity) {
        case HarActivity.walk:
          unitPts = GameConfig.walkUnitPoints;
          _secondsWalk += GameConfig.unitSeconds;
          _nodeSecondsWalk += GameConfig.unitSeconds;
          _distanceWalk += _unitDistanceTracked;
          _nodeDistanceWalk += _unitDistanceTracked;
          break;
        case HarActivity.bike:
          unitPts = GameConfig.bikeUnitPoints;
          _secondsBike += GameConfig.unitSeconds;
          _nodeSecondsBike += GameConfig.unitSeconds;
          _distanceBike += _unitDistanceTracked;
          _nodeDistanceBike += _unitDistanceTracked;
          break;
        case HarActivity.run:
          unitPts = GameConfig.runUnitPoints;
          _secondsRun += GameConfig.unitSeconds;
          _nodeSecondsRun += GameConfig.unitSeconds;
          _distanceRun += _unitDistanceTracked;
          _nodeDistanceRun += _unitDistanceTracked;
          break;
        default:
          unitPts = 0;
          break;
      }
      _pendingNodeImpactPoints += unitPts;
      _unitDistanceTracked = 0.0;
      notifyListeners();
    }
  }

  void setMetersBetweenNodes(double meters) {
    _metersBetweenNodes = meters;
    notifyListeners();
  }

  void _initPassiveTracking() async {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.positionStream.listen(_onLocationReceived);
  }

  void refreshTracking() => _initPassiveTracking();

  Future<void> updateCurrentPosition() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      _onLocationReceived(pos);
    } catch (_) {}
  }

  void startActivity() {
    _isActivityActive = true;
    _isPaused = false;
    _totalMetersTracked = 0;
    _metersSinceLastNode = 0;
    _metersSinceLastPerimeterPoint = 0;
    _totalSecondsElapsed = 0;
    _secondsWalk = 0;
    _secondsRun = 0;
    _secondsBike = 0;
    _distanceWalk = 0.0;
    _distanceRun = 0.0;
    _distanceBike = 0.0;
    _nodeSecondsWalk = 0;
    _nodeSecondsRun = 0;
    _nodeSecondsBike = 0;
    _nodeDistanceWalk = 0.0;
    _nodeDistanceRun = 0.0;
    _nodeDistanceBike = 0.0;
    _unitDistanceTracked = 0.0;
    _pendingNodeImpactPoints = 0.0;
    _currentHarActivity = HarActivity.unknown;
    _perimeter.clear();
    _onTrackNodes.clear();
    _visitedCells.clear();
    _lastRecordedPosition = null;
    _lastTrackTime = DateTime.now();
    _pingsToSkip = 0;
    _startTimer();
    _startRoutinePolling();
    notifyListeners();
  }

  void _startRoutinePolling() {
    _routineTimer?.cancel();
    _routineTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isActivityActive && !_isPaused) {
        updateCurrentPosition();
      }
    });
  }

  TrackingSession stopActivity() {
    _isActivityActive = false;
    _gameTimer?.cancel();
    _routineTimer?.cancel();

    final partialSeconds = _totalSecondsElapsed % GameConfig.unitSeconds;
    if (partialSeconds > 0 || _unitDistanceTracked > 0) {
      switch (_currentHarActivity) {
        case HarActivity.walk:
          _secondsWalk += partialSeconds;
          _nodeSecondsWalk += partialSeconds;
          _distanceWalk += _unitDistanceTracked;
          _nodeDistanceWalk += _unitDistanceTracked;
          break;
        case HarActivity.bike:
          _secondsBike += partialSeconds;
          _nodeSecondsBike += partialSeconds;
          _distanceBike += _unitDistanceTracked;
          _nodeDistanceBike += _unitDistanceTracked;
          break;
        case HarActivity.run:
          _secondsRun += partialSeconds;
          _nodeSecondsRun += partialSeconds;
          _distanceRun += _unitDistanceTracked;
          _nodeDistanceRun += _unitDistanceTracked;
          break;
        default:
          break;
      }
      _unitDistanceTracked = 0.0;
    }

    final session = TrackingSession(
      route: List.from(_perimeter),
      totalDistance: _totalMetersTracked,
      durationSeconds: _totalSecondsElapsed,
      averagePace: _averagePace,
      nodes: List.from(_onTrackNodes),
      secondsBike: _secondsBike,
      secondsRun: _secondsRun,
      secondsWalk: _secondsWalk,
      distanceBike: _distanceBike,
      distanceRun: _distanceRun,
      distanceWalk: _distanceWalk,
      territories: _visitedCells.map((id) => 
        _territoryRepository.getTerritoryOrDefault(id)
      ).toList(),
    );

    notifyListeners();
    return session;
  }

  void updateLastNodePoints(double points) {
    if (_onTrackNodes.isNotEmpty) {
      final lastIdx = _onTrackNodes.length - 1;
      final lastNode = _onTrackNodes[lastIdx];
      _onTrackNodes[lastIdx] = OnTrackNode(
        lat: lastNode.lat,
        lon: lastNode.lon,
        pace: lastNode.pace,
        points: points,
        timestamp: lastNode.timestamp,
        secondsWalk: lastNode.secondsWalk,
        secondsRun: lastNode.secondsRun,
        secondsBike: lastNode.secondsBike,
        distanceWalk: lastNode.distanceWalk,
        distanceRun: lastNode.distanceRun,
        distanceBike: lastNode.distanceBike,
        type: lastNode.type,
      );
      notifyListeners();
    }
  }

  void addSecondaryNodes(List<OnTrackNode> nodes) {
    for (final node in nodes) {
      final cellId = H3Helper.getHexagonAt(
        lat: node.lat, 
        lon: node.lon, 
        resolution: GameConfig.h3Resolution,
      );
      if (cellId.isNotEmpty) {
        _visitedCells.add(cellId);
      }

      final existingIndex = _onTrackNodes.indexWhere((existing) {
        if (existing.type != node.type) return false;
        final existingCell = H3Helper.getHexagonAt(
          lat: existing.lat,
          lon: existing.lon,
          resolution: GameConfig.h3Resolution,
        );
        return existingCell == cellId;
      });

      if (existingIndex != -1) {
        final existing = _onTrackNodes[existingIndex];
        _onTrackNodes[existingIndex] = OnTrackNode(
          lat: existing.lat,
          lon: existing.lon,
          pace: node.pace,
          points: existing.points + node.points,
          timestamp: node.timestamp,
          secondsWalk: existing.secondsWalk,
          secondsRun: existing.secondsRun,
          secondsBike: existing.secondsBike,
          distanceWalk: existing.distanceWalk,
          distanceRun: existing.distanceRun,
          distanceBike: existing.distanceBike,
          type: existing.type,
        );
      } else {
        _onTrackNodes.add(node);
      }
    }
    notifyListeners();
  }

  void _onLocationReceived(geo.Position position) {
    if (position.accuracy < 30.0) {
        _userPosition = Point(coordinates: Position(position.longitude, position.latitude));
        _currentBearing = position.heading;
        _currentCell = H3Helper.getHexagonAt(lat: position.latitude, lon: position.longitude, resolution: GameConfig.h3Resolution);
    }

    if (position.accuracy > 15.0) {
      notifyListeners(); 
      return;
    }

    final now = DateTime.now();
    if (now.difference(position.timestamp).inSeconds > 3) {
      notifyListeners();
      return;
    }

    if (!_isActivityActive || _isPaused) {
      notifyListeners();
      return;
    }

    if (_pingsToSkip > 0) {
      _lastRecordedPosition = position;
      _lastTrackTime = now;
      _pingsToSkip--;
      notifyListeners();
      return;
    }

    if (_lastRecordedPosition != null) {
      double delta = geo.Geolocator.distanceBetween(
        _lastRecordedPosition!.latitude, _lastRecordedPosition!.longitude,
        position.latitude, position.longitude
      );

      double reportedSpeed = position.speed;
      double timeElapsed = now.difference(_lastTrackTime!).inMilliseconds / 1000.0;

      bool isMovementValid = false;
      
      if (delta < position.accuracy) {
          notifyListeners();
          return;
      }

      if (reportedSpeed < 0.5) {
        if (delta > 10.0) isMovementValid = true;
      } else {
        if (delta > 2.5) isMovementValid = true;
      }

      if (isMovementValid) {
        _totalMetersTracked += delta;
        _metersSinceLastPerimeterPoint += delta;
        _metersSinceLastNode += delta;
        _unitDistanceTracked += delta;
        _currentSpeed = delta / max(1.0, timeElapsed);
        
        double avgSpeed = _totalMetersTracked / max(1, _totalSecondsElapsed);
        _averagePace = avgSpeed > 0.1 ? (16.6667 / avgSpeed) : 0.0;

        if (_metersSinceLastPerimeterPoint >= GameConfig.minMetersBetweenTracking) {
          _perimeter.add(GeoCoord(lat: position.latitude, lon: position.longitude));
          _metersSinceLastPerimeterPoint = 0;
        }

        if (_metersSinceLastNode >= _metersBetweenNodes) {
          final double nodePoints = _pendingNodeImpactPoints;

          final node = OnTrackNode(
            lat: position.latitude, 
            lon: position.longitude, 
            pace: currentPace, 
            points: nodePoints,
            timestamp: now,
            secondsWalk: _nodeSecondsWalk,
            secondsRun: _nodeSecondsRun,
            secondsBike: _nodeSecondsBike,
            distanceWalk: _nodeDistanceWalk,
            distanceRun: _nodeDistanceRun,
            distanceBike: _nodeDistanceBike,
          );
          if (_currentCell != null) _visitedCells.add(_currentCell!);
          _onTrackNodes.add(node);
          
          _metersSinceLastNode -= _metersBetweenNodes;

          _pendingNodeImpactPoints = 0.0;
          _nodeSecondsWalk = 0;
          _nodeSecondsRun = 0;
          _nodeSecondsBike = 0;
          _nodeDistanceWalk = 0.0;
          _nodeDistanceRun = 0.0;
          _nodeDistanceBike = 0.0;

          onNodeCompleted?.call(node);
        }
        
        _lastRecordedPosition = position;
        _lastTrackTime = now;
      }
    } else {
      _lastRecordedPosition = position;
      _lastTrackTime = now;
      _perimeter.add(GeoCoord(lat: position.latitude, lon: position.longitude));
    }

    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalSecondsElapsed++;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _gameTimer?.cancel();
    _routineTimer?.cancel();
    super.dispose();
  }

  void pauseActivity() {
    _isPaused = true;
    _gameTimer?.cancel();
    _routineTimer?.cancel();
    notifyListeners();
  }

  void resumeActivity() {
    _isPaused = false;
    _pingsToSkip = 2;
    _lastTrackTime = DateTime.now();
    _startTimer();
    _startRoutinePolling();
    notifyListeners();
  }

  void clear() {
    _isActivityActive = false;
    _isPaused = false;
    _userPosition = null;
    _currentCell = null;
    _perimeter.clear();
    _visitedCells.clear();
    _onTrackNodes.clear();
    _totalMetersTracked = 0.0;
    _totalSecondsElapsed = 0;
    _averagePace = 0.0;
    _currentSpeed = 0.0;
    _secondsWalk = 0;
    _secondsRun = 0;
    _secondsBike = 0;
    _distanceWalk = 0.0;
    _distanceRun = 0.0;
    _distanceBike = 0.0;
    _nodeSecondsWalk = 0;
    _nodeSecondsRun = 0;
    _nodeSecondsBike = 0;
    _nodeDistanceWalk = 0.0;
    _nodeDistanceRun = 0.0;
    _nodeDistanceBike = 0.0;
    _unitDistanceTracked = 0.0;
    _pendingNodeImpactPoints = 0.0;
    _currentHarActivity = HarActivity.unknown;
    _gameTimer?.cancel();
    _routineTimer?.cancel();
    notifyListeners();
  }
}

class TrackingSession {
  final List<GeoCoord> route;
  final double totalDistance;
  final int durationSeconds;
  final double averagePace;
  final List<OnTrackNode> nodes;
  final int secondsBike;
  final int secondsRun;
  final int secondsWalk;
  final double distanceBike;
  final double distanceRun;
  final double distanceWalk;
  List<Territory> territories;
  bool isSuccess; 
  double impactPoints;

  TrackingSession({
    required this.route,
    required this.totalDistance,
    required this.durationSeconds,
    required this.averagePace,
    required this.nodes,
    required this.territories,
    this.secondsBike = 0,
    this.secondsRun = 0,
    this.secondsWalk = 0,
    this.distanceBike = 0.0,
    this.distanceRun = 0.0,
    this.distanceWalk = 0.0,
    this.isSuccess = true,
    this.impactPoints = 0.0,
  });

  void setTerritories(List<Territory> newTerritories) => territories = newTerritories;

  Point? get routeCenter {
    if (route.isEmpty) return null;
    double minLat = route.map((c) => c.lat).reduce(min);
    double maxLat = route.map((c) => c.lat).reduce(max);
    double minLon = route.map((c) => c.lon).reduce(min);
    double maxLon = route.map((c) => c.lon).reduce(max);
    return Point(coordinates: Position((minLon + maxLon) / 2, (minLat + maxLat) / 2));
  }
}
