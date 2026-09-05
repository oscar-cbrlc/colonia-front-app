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
  int _totalSecondsElapsed = 0;
  DateTime? _lastTrackTime;
  double _currentSpeed = 0.0; 
  double _averagePace = 0.0; 
  Timer? _gameTimer;
  Timer? _routineTimer;

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
  double get currentPace => _currentSpeed > 0.1 ? (16.6667 / _currentSpeed) : 0.0;
  double get averagePace => _averagePace;
  int get totalSecondsElapsed => _totalSecondsElapsed;
  List<OnTrackNode> get onTrackNodes => _onTrackNodes;
  double get metersSinceLastNode => _metersSinceLastNode;

  TrackingRepository(this._locationService, this._territoryRepository) {
    _initPassiveTracking();
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

    final session = TrackingSession(
      route: List.from(_perimeter),
      totalDistance: _totalMetersTracked,
      durationSeconds: _totalSecondsElapsed,
      averagePace: _averagePace,
      nodes: List.from(_onTrackNodes),
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
      );
      notifyListeners();
    }
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
        _currentSpeed = delta / max(1.0, timeElapsed);
        
        double avgSpeed = _totalMetersTracked / max(1, _totalSecondsElapsed);
        _averagePace = avgSpeed > 0.1 ? (16.6667 / avgSpeed) : 0.0;

        if (_metersSinceLastPerimeterPoint >= GameConfig.minMetersBetweenTracking) {
          _perimeter.add(GeoCoord(lat: position.latitude, lon: position.longitude));
          _metersSinceLastPerimeterPoint = 0;
        }

        if (_metersSinceLastNode >= GameConfig.minMetersBetweenNodes) {
          final node = OnTrackNode(
            lat: position.latitude, 
            lon: position.longitude, 
            pace: currentPace, 
            points: 0,
            timestamp: now
          );
          if (_currentCell != null) _visitedCells.add(_currentCell!);
          _onTrackNodes.add(node);
          
          _metersSinceLastNode -= GameConfig.minMetersBetweenNodes;

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
