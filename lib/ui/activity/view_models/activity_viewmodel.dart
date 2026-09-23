import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/training_repository.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
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
  final TeamRepository _teamRepository;

  static const double minZoomToRender = 13.0;
  static const double minZoomToShowPoints = 14.0;
  static const double maxRenderRadius = 5000.0;

  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  bool _showPoints = true;
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
  bool get showPoints => _showPoints;

  void toggleShowPoints() {
    _showPoints = !_showPoints;
    _updateMapLayers();
    notifyListeners();
  }

  String? _selectedPreActivity = "walk";
  String? _selectedPreTrainingName = "free";
  BoostInventory? _selectedBoost;
  String? get selectedPreActivity => _selectedPreActivity;
  set selectedPreActivity(String? value) { _selectedPreActivity = value; notifyListeners(); }
  String? get selectedPreTrainingName => _selectedPreTrainingName;
  set selectedPreTrainingName(String? value) { _selectedPreTrainingName = value; notifyListeners(); }
  BoostInventory? get selectedBoost => _selectedBoost;
  set selectedBoost(BoostInventory? value) { _selectedBoost = value; notifyListeners(); }

  PlayingState get playingState => _sessionRepository.playingState;
  Point? get userPosition => _trackingRepository.userPosition;
  double get currentBearing => _trackingRepository.currentBearing;
  String? get currentCell => _trackingRepository.currentCell;
  double get totalMetersTracked => _trackingRepository.totalMetersTracked;
  int get totalSecondsElapsed => _trackingRepository.totalSecondsElapsed;
  double get currentPace => _trackingRepository.currentPace;
  double get averagePace => _trackingRepository.averagePace;
  int get distanceTilNextNode => max(0, (_trackingRepository.metersBetweenNodes - _trackingRepository.metersSinceLastNode).toInt());

  static String formatPace(double pace) {
    if (pace <= 0 || pace.isNaN || pace.isInfinite) return "--";
    int minutes = pace.toInt();
    int seconds = ((pace - minutes) * 60).round();
    if (seconds >= 60) {
      minutes += 1;
      seconds = 0;
    }
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  String get formattedCurrentPace => formatPace(currentPace);
  String get formattedAveragePace => formatPace(averagePace);
  String get formattedSelectedPace => selectedPace != null ? formatPace(selectedPace!) : "--";

  TrainingConfig? get trainingConfig => _sessionRepository.trainingConfig;
  String? get selectedActivity => trainingConfig?.activity;
  String? get selectedTrainingName => trainingConfig?.training.name;
  double? get selectedDistance => trainingConfig?.distance;
  Duration? get selectedTime => trainingConfig?.time;
  double? get selectedPace => trainingConfig?.pace;
  double get selectedDistanceMeters => selectedDistance ?? 0.0;
  BoostInventory? get equippedBoost => trainingConfig?.boost ?? _selectedBoost;

  SessionRepository get sessionRepository => _sessionRepository;

  List<Training> get trainings => _trainingRepository.trainings;
  List<BoostInventory> get availableBoosts => _boostRepository.availableBoostsInventory;
  //int getBoostCount(int boostId) => _boostRepository.getBoostCount(boostId);
  bool get readyToStart => trainingConfig != null;

  double get currentMultiplier {
    final tName = (playingState == PlayingState.stopped) ? _selectedPreTrainingName : selectedTrainingName;
    final tObj = trainings.firstWhere((t) => t.name == (tName ?? "free"), orElse: () => trainings.first);
    double m = tObj.impactPoints;
    return m;
  }

  ActivityViewModel(this._sessionRepository, this._trackingRepository, this._trainingRepository, this._boostRepository, this._territoryRepository, this._teamRepository) {
    _trackingRepository.addListener(_onTrackingDataChanged);
    _sessionRepository.addListener(notifyListeners);
    _trainingRepository.addListener(notifyListeners);
    _boostRepository.addListener(notifyListeners);
    _territoryRepository.addListener(_onTerritoriesChanged);
    _territoryRepository.fetchAllTerritories();
    _boostRepository.getAvailableBoosts();
    _boostRepository.fetchMyInventory();
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

  String _colorToRgba(Color c, double alpha) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return 'rgba($r, $g, $b, $alpha)';
  }

  Color _getUserTeamColor() {
    final currentUser = AuthRepository.instance.currentUser;
    if (currentUser != null && currentUser.team != null) return Color(_teamRepository.currentTeam!.color);
    return AppTheme.primaryColor;
  }

  Future<void> _updateMapLayers() async {
    final style = _mapboxMap?.style;
    if (style == null) return;

    final camera = await _mapboxMap!.getCameraState();
    final currentUser = AuthRepository.instance.currentUser;
    final userTeamId = currentUser?.team?.id;
    final userTeamColor = _getUserTeamColor();
    final bool canShowPoints = _showPoints && camera.zoom >= minZoomToShowPoints;

    List<String> currentIndexes = [];
    if (camera.zoom >= minZoomToRender) {
      currentIndexes = H3Helper.getHexagonsInRadius(
        centerLat: camera.center.coordinates.lat.toDouble(),
        centerLon: camera.center.coordinates.lng.toDouble(),
        radiusMeters: maxRenderRadius / camera.zoom,
        resolution: GameConfig.h3Resolution,
      );
    }

    final Set<String> allHexIndexes = {
      ...currentIndexes,
      for (final t in _territoryRepository.territories) t.id,
    };

    final features = allHexIndexes.map((hexId) {
      final territory = _territoryRepository.getTerritoryOrDefault(hexId);
      final bool isCurrent = hexId == currentCell;
      final TerritoryTeam? claimedTeam = territory.team;

      String fillColor;
      if (claimedTeam == null) {
        fillColor = 'rgba(0, 0, 0, 0)';
      }
      else {
        final claimedColor = Color(claimedTeam.color);
        fillColor = _colorToRgba(claimedColor, 0.5);
      }

      return {
        "type": "Feature",
        "properties": {
          "h3_index": hexId, 
          "is_current": isCurrent,
          "health_label": (canShowPoints && territory.healthPoints > 0) ? territory.healthPoints.toStringAsFixed(0) : "",
          "team_id": territory.team?.id,
          "fill_color": fillColor,
        },
        "geometry": {"type": "Polygon", "coordinates": [H3Helper.getHexagonCorners(hexId)]}
      };
    }).toList();
    await style.setStyleSourceProperty("h3-grid-source", "data", jsonEncode({"type": "FeatureCollection", "features": features}));

    if (inActivity) {
      final features = <Map<String, dynamic>>[];
      for (final hexId in _trackingRepository.visitedCells) {
        final territory = _territoryRepository.getTerritoryOrDefault(hexId);
        final TerritoryTeam? hexTeam = territory.team;
        final Color hexColor = hexTeam != null ? Color(hexTeam.color) : userTeamColor;
        features.add({
          "type": "Feature", 
          "properties": {
            "type": "hexagon",
            "team_id": territory.team?.id,
            "fill_color": _colorToRgba(hexColor, 0.45),
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
            "node_type": node.type.name,
            "points_label": (_showPoints && node.points > 0) ? node.points.toStringAsFixed(0) : "",
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
      _trackingRepository.updateCurrentPosition();
      final currentUser = AuthRepository.instance.currentUser;
      if (currentUser != null && currentUser.team != null) _teamRepository.fetchTeamDetails(currentUser.team!.id);
    }

  }

  Future<void> onStyleLoaded() async {
    await _initializeH3Layer();
    await _initializeTrackingPolygon();
    if (userPosition != null) {
        centerOnUser();
    }
    unawaited(_territoryRepository.fetchAllTerritories());
    await _updateMapLayers();
  }

  Territory? getClaimedTerritoryAt(double lat, double lon) {
    final hexId = H3Helper.getHexagonAt(
      lat: lat,
      lon: lon,
      resolution: GameConfig.h3Resolution,
    );
    final territory = _territoryRepository.getTerritoryOrDefault(hexId);
    if (territory.team != null) {
      return territory;
    }
    return null;
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

  void setActivityConfig({required String activity, required String training, required double distance, required Duration time, required double pace, BoostInventory? boost}) {
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

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<Map<String, dynamic>?> onPushStopButton() async {
    _isSaving = true;
    notifyListeners();
    try {
      final activity = selectedActivity ?? _selectedPreActivity ?? "walk";
      final trainingName = selectedTrainingName ?? _selectedPreTrainingName ?? "free";
      
      final result = await _sessionRepository.stopAndSaveSession();
      if (result == null) {
        debugPrint("ActivityViewModel.onPushStopButton: stopAndSaveSession returned null");
        return null;
      }
      
      debugPrint("ActivityViewModel.onPushStopButton: Session saved successfully! Activity: $activity, Training: $trainingName");
      return {
        'session': result.session, 
        'activityResult': result.activityResult,
        'activity': activity, 
        'trainingName': trainingName
      };
    } catch (e, stackTrace) {
      debugPrint("Error in onPushStopButton: $e\n$stackTrace");
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void onCameraChanged(CameraChangedEventData data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () => _updateMapLayers());
  }

  Future<void> _initializeH3Layer() async {
    final style = _mapboxMap?.style;
    if (style == null || await style.styleSourceExists("h3-grid-source")) return;
    await style.addSource(GeoJsonSource(id: "h3-grid-source", data: jsonEncode({"type": "FeatureCollection", "features": []})));
    await style.addLayer(LineLayer(id: "h3-grid-outline-layer", sourceId: "h3-grid-source", lineColor: AppTheme.h3GridLineColor.toARGB32(), lineWidth: 0.8));
    
    await style.addLayer(FillLayer(
      id: "h3-grid-layer", 
      sourceId: "h3-grid-source", 
      fillEmissiveStrength: 0.6,
      fillColorExpression: <Object>['get', 'fill_color'],
    ));

    await style.addLayer(SymbolLayer(
      id: "h3-health-label-layer",
      sourceId: "h3-grid-source",
      textSize: 14.0,
      textFieldExpression: <Object>['get', 'health_label'],
      textFont: ["Open Sans Bold", "Arial Unicode MS Bold"],
      textColor: Colors.white.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textLetterSpacing: 0.1,
      textHaloWidth: 1.0,
      textOffset: [0, 0],
      textAllowOverlap: true,
      textIgnorePlacement: true,
    ));
  }

  Future<void> _initializeTrackingPolygon() async {
    final style = _mapboxMap?.style;
    if (style == null || await style.styleSourceExists('tracking-polygon-source')) return;
    await style.addSource(GeoJsonSource(id: 'tracking-polygon-source', data: jsonEncode({"type": "FeatureCollection", "features": []})));

    await style.addLayer(FillLayer(
      id: "tracking-hexagons-fill-layer", 
      sourceId: "tracking-polygon-source", 
      filter: <Object>['==', ['get', 'type'], 'hexagon'],
      fillColorExpression: <Object>['get', 'fill_color'],
    ));

    await style.addLayer(LineLayer(
      id: "tracking-perimeter-line-layer", 
      sourceId: "tracking-polygon-source", 
      filter: <Object>['==', ['get', 'type'], 'perimeter'], 
      lineColor: Colors.white.toARGB32(), 
      lineWidth: 4.5, 
      lineJoin: LineJoin.ROUND, 
      lineCap: LineCap.ROUND,
    ));

    final String pathColorRgba = _colorToRgba(AppTheme.secondaryColor, 1.0);
    final String areaColorRgba = _colorToRgba(AppTheme.tertiaryColor, 1.0);

    await style.addLayer(CircleLayer(
      id: "tracking-nodes-layer", 
      sourceId: "tracking-polygon-source", 
      filter: <Object>['==', ['get', 'type'], 'node'], 
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.white.toARGB32(),
      circleRadiusExpression: <Object>[
        "match",
        ["get", "node_type"],
        "path", 6.0,
        "area", 4.5,
        6.0
      ],
      circleColorExpression: <Object>[
        "match",
        ["get", "node_type"],
        "path", pathColorRgba,
        "area", areaColorRgba,
        pathColorRgba
      ],
    ));

    await style.addLayer(SymbolLayer(
      id: "tracking-nodes-label-layer",
      sourceId: "tracking-polygon-source",
      filter: <Object>['==', ['get', 'type'], 'node'],
      textSize: 12.0,
      textFieldExpression: <Object>['get', 'points_label'],
      textFont: ["Open Sans Bold", "Arial Unicode MS Bold"],
      textColor: Colors.white.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textHaloWidth: 1.0,
      textOffset: [0, -1.5],
      textAllowOverlap: true,
      textIgnorePlacement: true,
    ));
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
