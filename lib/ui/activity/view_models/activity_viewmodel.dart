import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/training_repository.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/domain/models/session/training_config.dart';
import 'package:colonia_front_app/domain/models/training.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

import 'package:colonia_front_app/data/repositories/session_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';

class ActivityViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final SessionRepository _sessionRepository;
  final TrackingRepository _trackingRepository;
  final TrainingRepository _trainingRepository;
  final BoostRepository _boostRepository;
  final TerritoryRepository _territoryRepository;

  static const double minZoomToRender = 13.0;
  static const double maxRenderRadius = 5000.0;

  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  ViewportState? _viewport;

  Timer? _debounceTimer;

  Timer? _drawingThrottle;
  Set<String> _lastH3Indexes = {};
  bool _hasInitialCenter = false;
  bool _isFollowingUser = true;

  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  MapboxMap? get mapboxMap => _mapboxMap;
  ViewportState? get viewport => _viewport;
  bool get inActivity => _trackingRepository.isActivityActive;

  String? _selectedPreActivity = "walk";
  String? _selectedPreTrainingName = "free";
  Boost? _selectedBoost;
  String? get selectedPreActivity => _selectedPreActivity;
  set selectedPreActivity(String? value) { _selectedPreActivity = value; notifyListeners(); }
  String? get selectedPreTrainingName => _selectedPreTrainingName;
  set selectedPreTrainingName(String? value) { _selectedPreTrainingName = value; notifyListeners(); }
  Boost? get selectedBoost => _selectedBoost;
  set selectedBoost(Boost? value) { _selectedBoost = value; notifyListeners(); }

  PlayingState get playingState => _sessionRepository.playingState;
  Point? get userPosition => _trackingRepository.userPosition;
  double get currentBearing => _trackingRepository.currentBearing;
  String? get currentCell => _trackingRepository.currentCell;
  double get totalMetersTracked => _trackingRepository.totalMetersTracked;
  int get totalSecondsElapsed => _trackingRepository.totalSecondsElapsed;
  double get currentPace => _trackingRepository.currentPace;
  double get averagePace => _trackingRepository.averagePace;
  int get distanceTilNextNode => max(0, (GameConfig.minMetersBetweenNodes - _trackingRepository.metersSinceLastNode).toInt());

  TrainingConfig? get trainingConfig => _sessionRepository.trainingConfig;
  String? get selectedActivity => trainingConfig?.activity;
  String? get selectedTrainingName => trainingConfig?.training.name;
  double? get selectedDistance => trainingConfig?.distance;
  Duration? get selectedTime => trainingConfig?.time;
  double? get selectedPace => trainingConfig?.pace;
  double get selectedDistanceMeters => selectedDistance ?? 0.0;

  List<Training> get trainings => _trainingRepository.trainings;
  List<Boost> get availableBoosts => _boostRepository.userBoostInventory;
  int getBoostCount(int boostId) => _boostRepository.getBoostCount(boostId);
  bool get readyToStart => trainingConfig != null;

  double get currentAttackMultiplier {
    final tName = (playingState == PlayingState.stopped) ? _selectedPreTrainingName : selectedTrainingName;
    final tObj = trainings.firstWhere((t) => t.name == (tName ?? "free"), orElse: () => trainings.first);
    double m = tObj.attackPoints;
    final b = (playingState == PlayingState.stopped) ? _selectedBoost : trainingConfig?.boost;
    if (b != null) m *= b.effect;
    return m;
  }

  double get currentDefenseMultiplier {
    final tName = (playingState == PlayingState.stopped) ? _selectedPreTrainingName : selectedTrainingName;
    final tObj = trainings.firstWhere((t) => t.name == (tName ?? "free"), orElse: () => trainings.first);
    double m = tObj.defensePoints;
    final b = (playingState == PlayingState.stopped) ? _selectedBoost : trainingConfig?.boost;
    if (b != null) m *= b.effect;
    return m;
  }

  ActivityViewModel(this._sessionRepository, this._trackingRepository, this._trainingRepository, this._boostRepository, this._territoryRepository) {
    _trackingRepository.addListener(_onTrackingDataChanged);
    _sessionRepository.addListener(notifyListeners);
    _trainingRepository.addListener(notifyListeners);
    _boostRepository.addListener(notifyListeners);
    _territoryRepository.addListener(_onTerritoriesChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onTerritoriesChanged() {
    _updateMapLayers();
  }

  void _onTrackingDataChanged() {
    notifyListeners();

    if (_isFollowingUser && userPosition != null && !_hasInitialCenter) {
      _hasInitialCenter = true;
      centerOnUser();
    }

    if (_drawingThrottle?.isActive ?? false) return;
    _drawingThrottle = Timer(const Duration(milliseconds: 1000), () => _updateMapLayers());
  }

  Future<void> _updateMapLayers() async {
    final style = _mapboxMap?.style;
    if (style == null) return;

    final camera = await _mapboxMap!.getCameraState();

    if (camera.zoom >= minZoomToRender) {
      final currentIndexes = H3Helper.getHexagonsInRadius(
        centerLat: camera.center.coordinates.lat.toDouble(),
        centerLon: camera.center.coordinates.lng.toDouble(),
        radiusMeters: maxRenderRadius / camera.zoom,
        resolution: GameConfig.h3Resolution,
      );
      final features = currentIndexes.map((hexId) {
        final territory = _territoryRepository.getTerritoryOrDefault(hexId);
        return {
          "type": "Feature",
          "properties": {
            "h3_index": hexId, 
            "is_current": hexId == currentCell,
            "health_label": territory.healthPoints.toStringAsFixed(2),
          },
          "geometry": {"type": "Polygon", "coordinates": [H3Helper.getHexagonCorners(hexId)]}
        };
      }).toList();
      await style.setStyleSourceProperty("h3-grid-source", "data", jsonEncode({"type": "FeatureCollection", "features": features}));
    }

    if (playingState == PlayingState.playing) {
      final features = <Map<String, dynamic>>[];
      for (final hexId in _trackingRepository.visitedCells) {
        final territory = _territoryRepository.getTerritoryOrDefault(hexId);
        features.add({
          "type": "Feature", 
          "properties": {
            "type": "hexagon",
            "health_label": territory.healthPoints.toStringAsFixed(2),
          }, 
          "geometry": {"type": "Polygon", "coordinates": [H3Helper.getHexagonCorners(hexId)]}
        });
      }
      if (_trackingRepository.perimeter.length >= 2) {
        features.add({
          "type": "Feature", "properties": {"type": "perimeter"}, "geometry": {"type": "LineString", "coordinates": _trackingRepository.perimeter.map((p) => [p.lon, p.lat]).toList()}
        });
      }
      for (final node in _trackingRepository.onTrackNodes) {
        features.add({
          "type": "Feature", 
          "properties": {
            "type": "node",
            "points_label": node.points > 0 ? "+${node.points.toStringAsFixed(2)}" : "",
          }, 
          "geometry": {"type": "Point", "coordinates": [node.lon, node.lat]}
        });
      }
      await style.setStyleSourceProperty("tracking-polygon-source", "data", jsonEncode({"type": "FeatureCollection", "features": features}));
    }
  }

  void onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _configureOrnaments();
    _checkInitialPermission();
    _setMapDaylight();
    
    if (userPosition != null) {
      centerOnUser();
    } else {
      _trackingRepository.updateCurrentPosition();
    }
  }

  Future<void> onStyleLoaded() async {
    await _initializeH3Layer();
    await _initializeTrackingPolygon();
    if (userPosition != null) {
        centerOnUser();
    }
    _updateMapLayers();
  }

  Future<void> centerOnUser() async {
    _isFollowingUser = true;
    final pos = userPosition ?? await _trackingRepository.updateCurrentPosition().then((_) => userPosition);
    if (pos == null) return;
    
    if (_mapboxMap != null) {
      await _mapboxMap!.setCamera(CameraOptions(center: pos, zoom: 17.0, pitch: 45.0));
    }

    _viewport = FollowPuckViewportState(zoom: 17.0, bearing: FollowPuckViewportStateBearingHeading(), pitch: 45.0);
    notifyListeners();
  }

  void setActivityConfig({required String activity, required String training, required double distance, required Duration time, required double pace, Boost? boost}) {
    _selectedPreActivity = activity; _selectedPreTrainingName = training; _selectedBoost = boost;
    final config = TrainingConfig(activity: activity, training: trainings.firstWhere((tr) => tr.name == training, orElse: () => trainings.first), distance: distance, time: time, pace: pace, boost: boost);
    _sessionRepository.setupSession(config: config);
    notifyListeners();
  }

  void onPushPlayButton() {
    if (playingState == PlayingState.stopped) _sessionRepository.startGame();
    else if (playingState == PlayingState.playing) _sessionRepository.pauseGame();
    else if (playingState == PlayingState.paused) _sessionRepository.resumeGame();
  }

  Future<Map<String, dynamic>?> onPushStopButton() async {
    final activity = selectedActivity ?? _selectedPreActivity ?? "walk";
    final trainingName = selectedTrainingName ?? _selectedPreTrainingName ?? "free";
    
    final session = await _sessionRepository.stopAndSaveSession();
    if (session == null) return null;
    
    return {
      'session': session, 
      'activity': activity, 
      'trainingName': trainingName
    };
  }

  void onCameraChanged(CameraChangedEventData data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () => _updateMapLayers());
  }

  Future<void> _initializeH3Layer() async {
    final style = _mapboxMap?.style;
    if (style == null || await style.styleSourceExists("h3-grid-source")) return;
    await style.addSource(GeoJsonSource(id: "h3-grid-source", data: jsonEncode({"type": "FeatureCollection", "features": []})));
    await style.setStyleLayerProperty("h3-grid-layer", "fill-color", ['case', ['to-boolean', ['get', 'is_current']], 'rgba(100, 138, 7, 0.4)', 'rgba(0, 0, 0, 0)']);
    await style.addLayer(LineLayer(id: "h3-grid-outline-layer", sourceId: "h3-grid-source", lineColor: AppTheme.h3GridLineColor.toARGB32(), lineWidth: 0.8));
    await style.addLayer(FillLayer(id: "h3-grid-layer", sourceId: "h3-grid-source"));

    await style.addLayer(SymbolLayer(
      id: "h3-health-label-layer",
      sourceId: "h3-grid-source",
      textSize: 12.0,
      textColor: Colors.white.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textHaloWidth: 1.0,
    ));
    await style.setStyleLayerProperty("h3-health-label-layer", "text-field", ["get", "health_label"]);
  }

  Future<void> _initializeTrackingPolygon() async {
    final style = _mapboxMap?.style;
    if (style == null || await style.styleSourceExists('tracking-polygon-source')) return;
    await style.addSource(GeoJsonSource(id: 'tracking-polygon-source', data: jsonEncode({"type": "FeatureCollection", "features": []})));

    await style.addLayer(FillLayer(id: "tracking-hexagons-fill-layer", sourceId: "tracking-polygon-source", filter: <Object>['==', ['get', 'type'], 'hexagon']));
    await style.setStyleLayerProperty("tracking-hexagons-fill-layer", "fill-color", AppTheme.primaryColor.withValues(alpha: 0.4).toARGB32());

    await style.addLayer(LineLayer(id: "tracking-perimeter-line-layer", sourceId: "tracking-polygon-source", filter: <Object>['==', ['get', 'type'], 'perimeter'], lineColor: Colors.white.toARGB32(), lineWidth: 4.5, lineJoin: LineJoin.ROUND, lineCap: LineCap.ROUND));
    await style.addLayer(CircleLayer(id: "tracking-nodes-layer", sourceId: "tracking-polygon-source", filter: <Object>['==', ['get', 'type'], 'node'], circleRadius: 6.0, circleColor: AppTheme.secondaryColor.toARGB32(), circleStrokeWidth: 2.0, circleStrokeColor: Colors.white.toARGB32()));
    
    await style.addLayer(SymbolLayer(
      id: "tracking-nodes-label-layer",
      sourceId: "tracking-polygon-source",
      filter: <Object>['==', ['get', 'type'], 'node'],
      textSize: 12.0,
      textColor: Colors.white.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textHaloWidth: 1.0,
      textOffset: [0, -1.5],
    ));
    await style.setStyleLayerProperty("tracking-nodes-label-layer", "text-field", ["get", "points_label"]);

    
    await style.addLayer(SymbolLayer(
      id: "tracking-hexagons-label-layer",
      sourceId: "tracking-polygon-source",
      filter: <Object>['==', ['get', 'type'], 'hexagon'],
      textSize: 12.0,
      textColor: Colors.white.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textHaloWidth: 1.0,
    ));
    await style.setStyleLayerProperty("tracking-hexagons-label-layer", "text-field", ["get", "health_label"]);
  }

  void _configureOrnaments() {
    _mapboxMap?.compass.updateSettings(CompassSettings(position: OrnamentPosition.TOP_RIGHT, marginTop: 115, marginRight: 20));
    _mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false, position: OrnamentPosition.TOP_RIGHT, marginTop: 60, marginRight: 10));
  }

  void _setMapDaylight() {
    final hour = DateTime.now().hour;
    String preset = (hour >= 5 && hour < 8) ? "dawn" : (hour >= 8 && hour < 17) ? "day" : (hour >= 17 && hour < 20) ? "dusk" : "night";
    try { _mapboxMap?.style.setStyleImportConfigProperty("basemap", "lightPreset", preset); } catch (_) {}
  }

  Future<void> _checkInitialPermission() async {
    _isLocationPermissionGranted = await Permission.location.isGranted;
    if (_isLocationPermissionGranted) await _enableLocationComponent();
    notifyListeners();
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    _isLocationPermissionGranted = status.isGranted;
    if (_isLocationPermissionGranted) {
      _trackingRepository.refreshTracking();
      await _enableLocationComponent();
    }
    notifyListeners();
  }

  Future<void> _enableLocationComponent() async {
    final map = _mapboxMap;
    if (map == null) return;
    await map.location.updateSettings(LocationComponentSettings(enabled: true, pulsingEnabled: true, puckBearingEnabled: true, puckBearing: PuckBearing.HEADING));
    centerOnUser();
  }

  @override
  void dispose() {
    _trackingRepository.removeListener(_onTrackingDataChanged);
    _sessionRepository.removeListener(notifyListeners);
    _territoryRepository.removeListener(_onTerritoriesChanged);
    WidgetsBinding.instance.removeObserver(this);
    _drawingThrottle?.cancel();
    super.dispose();
  }
}
