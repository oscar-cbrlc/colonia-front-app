import 'dart:async';
import 'package:colonia_front_app/data/services/location_service.dart';
import 'package:colonia_front_app/domain/models/session/on_track_node.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:h3_flutter/h3_flutter.dart';

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

class TrackingRepository extends ChangeNotifier {
  final LocationService _locationService;
  StreamSubscription<geo.Position>? _positionSubscription;


  bool _isActivityActive = false;
  bool _isPaused = false;

  Point? _userPosition;
  double _currentBearing = 0.0;
  String? _currentCell;

  final List<GeoCoord> _perimeter = [];
  final Set<String> _visitedCells = {};
  GeoCoord? _pausedPosition;
  GeoCoord? _temporaryPauseLineEnd;

  double _totalMetersTracked = 0.0;
  double _edgeMetersTracked = 0.0;
  int _totalSecondsElapsed = 0;
  DateTime? _lastTrackTime;
  double _currentSpeed = 0.0; // m/s
  double _averageSpeed = 0.0; // m/s
  double _currentPace = 0.0; // min/km
  double _averagePace = 0.0; // min/km
  Timer? _gameTimer;
  List<OnTrackNode> _onTrackNodes = [];

  geo.Position? _lastRecordedPosition;

  bool get isActivityActive => _isActivityActive;
  bool get isPaused => _isPaused;
  
  Point? get userPosition => _userPosition;
  double get currentBearing => _currentBearing;
  String? get currentCell => _currentCell;
  
  List<GeoCoord> get perimeter => _perimeter;
  Set<String> get visitedCells => _visitedCells;
  GeoCoord? get temporaryPauseLineEnd => _temporaryPauseLineEnd;
  double get totalMetersTracked => _totalMetersTracked;
  double get currentSpeed => _currentSpeed;
  double get averageSpeed => _averageSpeed;
  double get currentPace => _currentPace;
  double get averagePace => _averagePace;
  int get totalSecondsElapsed => _totalSecondsElapsed;
  List<OnTrackNode> get onTrackNodes => _onTrackNodes;

  double get metersPerEdge => GameConfig.minMetersBetweenVertices;

  TrackingRepository(this._locationService) {
    _initPassiveTracking();
  }

  void _initPassiveTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.positionStream.listen(_onLocationReceived);
  }

  void startActivity() {
    if (_isActivityActive) return;
    _isActivityActive = true;
    _isPaused = false;
    
    _totalMetersTracked = 0.0;
    _edgeMetersTracked = 0.0;
    _totalSecondsElapsed = 0;
    _perimeter.clear();
    _visitedCells.clear();
    _pausedPosition = null;
    _lastTrackTime = null;
    _currentSpeed = 0.0;
    _averageSpeed = 0.0;
    _currentPace = 0.0;
    _averagePace = 0.0;
    _temporaryPauseLineEnd = null;
    _lastRecordedPosition = null;
    _onTrackNodes = [];

    _startTimer();
    notifyListeners();
  }

  void pauseActivity() {
    if (!_isActivityActive || _isPaused) return;
    _isPaused = true;

    if (_lastRecordedPosition != null) {
      _pausedPosition = GeoCoord(
        lat: _lastRecordedPosition!.latitude,
        lon: _lastRecordedPosition!.longitude,
      );
    }

    _gameTimer?.cancel();
    notifyListeners();
  }

  void resumeActivity() {
    if (!_isActivityActive || !_isPaused) return;
    _isPaused = false;

    _lastRecordedPosition = null;

    if (_pausedPosition != null) {
      _perimeter.add(_pausedPosition!);
      _pausedPosition = null;
      _temporaryPauseLineEnd = null;
    }

    _startTimer();
    notifyListeners();
  }

  TrackingSession stopActivity() {
    final session = TrackingSession(
      route: List.from(_perimeter),
      totalDistance: _totalMetersTracked,
      durationSeconds: _totalSecondsElapsed,
      averageSpeed: _averageSpeed,
      averagePace: _averagePace,
      nodes: List.from(_onTrackNodes),
    );

    _isActivityActive = false;
    _isPaused = false;
    _gameTimer?.cancel();
    _gameTimer = null;

    notifyListeners();
    return session;
  }

  Future<void> updateCurrentPosition() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _onLocationReceived(position);
    } catch (e) {
      debugPrint('TrackingRepository: Error getting current position: $e');
    }
  }

  void _onLocationReceived(geo.Position position) {
    _userPosition = Point(coordinates: Position(position.longitude, position.latitude));
    _currentBearing = position.heading;

    _currentCell = H3Helper.getHexagonAt(
      lat: position.latitude,
      lon: position.longitude,
      resolution: GameConfig.h3Resolution,
    );

    if (!_isActivityActive) {
      notifyListeners();
      return;
    }

    if (_isPaused) {
      _temporaryPauseLineEnd = GeoCoord(
        lat: position.latitude,
        lon: position.longitude,
      );
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    
    if (_currentCell != null) {
      _visitedCells.add(_currentCell!);
    }

    if (_lastRecordedPosition != null) {
      double distanceDelta = geo.Geolocator.distanceBetween(
        _lastRecordedPosition!.latitude,
        _lastRecordedPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distanceDelta > 0.5) {
        _totalMetersTracked += distanceDelta;
        _edgeMetersTracked += distanceDelta;

        if (_lastTrackTime != null) {
          final timeDelta = now.difference(_lastTrackTime!).inMilliseconds / 1000.0;
          if (timeDelta > 0) {
            _currentSpeed = distanceDelta / timeDelta;
            _currentPace = _currentSpeed > 0.1 ? (16.6667 / _currentSpeed) : 0.0;
          }
        }

        if (_totalSecondsElapsed > 0) {
          _averageSpeed = _totalMetersTracked / _totalSecondsElapsed;
          _averagePace = _averageSpeed > 0.1 ? (16.6667 / _averageSpeed) : 0.0;
        }

        if (_edgeMetersTracked >= metersPerEdge) {
          _perimeter.add(GeoCoord(lat: position.latitude, lon: position.longitude));
          _edgeMetersTracked = 0.0;
        }

        _onTrackNodes.add(OnTrackNode(
          lat: position.latitude,
          lon: position.longitude,
          pace: _currentPace,
          timestamp: now,
        ));
      }
    } else {
      _perimeter.add(GeoCoord(lat: position.latitude, lon: position.longitude));
      _onTrackNodes.add(OnTrackNode(
        lat: position.latitude,
        lon: position.longitude,
        pace: 0.0,
        timestamp: now,
      ));
    }

    _lastTrackTime = now;
    _lastRecordedPosition = position;
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
    super.dispose();
  }
}

class TrackingSession {
  final List<GeoCoord> route;
  final double totalDistance;
  final int durationSeconds;
  final double averageSpeed;
  final double averagePace;
  final List<OnTrackNode> nodes;

  TrackingSession({
    required this.route,
    required this.totalDistance,
    required this.durationSeconds,
    required this.averageSpeed,
    required this.averagePace,
    required this.nodes,
  });
}
