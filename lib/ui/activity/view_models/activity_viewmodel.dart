import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/training_repository.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/enums/activity_type.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:colonia_front_app/domain/models/session/session_enums.dart';
import 'package:colonia_front_app/domain/models/session/training_config.dart';
import 'package:colonia_front_app/domain/models/training.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/repositories/sensor_repository.dart';
import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
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
  final SensorRepository? _sensorRepository;

  static const double minZoomToRender = 13.0;
  static const double minZoomToShowPoints = 15.0;
  static const double maxRenderRadius = 5000.0;

  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  bool _showPoints = true;
  bool _isMapReady = false;
  ViewportState? _viewport;

  Timer? _debounceTimer;

  Timer? _drawingThrottle;
  bool _hasInitialCenter = false;
  bool _isFollowingUser = true;

  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  MapboxMap? get mapboxMap => _mapboxMap;
  ViewportState? get viewport => _viewport;
  bool get isMapReady => _isMapReady;
  bool get inActivity => _trackingRepository.isActivityActive;
  bool get showPoints => _showPoints;

  void toggleShowPoints() {
    _showPoints = !_showPoints;
    _updateMapLayers();
    notifyListeners();
  }

  HarActivity? _selectedPreActivity = HarActivity.walk;
  TrainingType? _selectedPreTrainingType = TrainingType.free;
  BoostInventory? _selectedBoost;
  HarActivity? get selectedPreActivity => _selectedPreActivity;
  set selectedPreActivity(HarActivity? value) { _selectedPreActivity = value; notifyListeners(); }
  TrainingType? get selectedPreTrainingType => _selectedPreTrainingType;
  set selectedPreTrainingType(TrainingType? value) { _selectedPreTrainingType = value; notifyListeners(); }
  BoostInventory? get selectedBoost => _selectedBoost;
  set selectedBoost(BoostInventory? value) { _selectedBoost = value; notifyListeners(); }

  ActivityType? _selectedActivityType = ActivityType.onFoot;
  ActivityType? get selectedActivityType => _selectedActivityType;
  set selectedActivityType(ActivityType? value) { _selectedActivityType = value; notifyListeners(); }

  PlayingState get playingState => _sessionRepository.playingState;
  Point? get userPosition => _trackingRepository.userPosition;
  double _mapBearing = 0.0;
  double get currentBearing => _mapBearing;
  String? get currentCell => _trackingRepository.currentCell;
  double get totalMetersTracked => _trackingRepository.totalMetersTracked;
  int get totalSecondsElapsed => _trackingRepository.totalSecondsElapsed;
  double get currentPace => _trackingRepository.currentPace;
  double get averagePace => _trackingRepository.averagePace;
  int get distanceTilNextNode => max(0, (_trackingRepository.metersBetweenNodes - _trackingRepository.metersSinceLastNode).toInt());
  double get pendingNodeImpactPoints => _trackingRepository.pendingNodeImpactPoints;
  bool get pausedBySuspectedInvalid => _trackingRepository.pausedBySuspectedInvalid;
  TrackingRepository get trackingRepository => _trackingRepository;

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
  String get formattedSelectedDistance => selectedDistanceMeters.toStringAsFixed(0);
  TrainingConfig? get trainingConfig => _sessionRepository.trainingConfig;
  TrainingType? get selectedTrainingType => trainingConfig?.training.type;
  String? get selectedTrainingName => trainingConfig?.training.name;
  double? get selectedDistance => trainingConfig?.distance;
  Duration? get selectedTime => trainingConfig?.time;
  double? get selectedPace => trainingConfig?.pace;
  double get selectedDistanceMeters => selectedDistance ?? 0.0;
  BoostInventory? get equippedBoost => trainingConfig?.boost ?? _selectedBoost;

  bool get isObjectiveCompleted {
    final tType = selectedTrainingType ?? _selectedPreTrainingType ?? TrainingType.free;
    if (tType == TrainingType.free) return true;

    if (tType == TrainingType.distance) {
      final targetDist = selectedDistanceMeters;
      return targetDist > 0 && _trackingRepository.totalMetersTracked >= targetDist;
    }

    if (tType == TrainingType.time) {
      final targetTime = selectedTime;
      return targetTime != null && targetTime != Duration.zero && _trackingRepository.totalSecondsElapsed >= targetTime.inSeconds;
    }

    if (tType == TrainingType.pace) {
      if (_trackingRepository.totalMetersTracked < 50) return false;
      final targetPaceVal = selectedPace;
      if (targetPaceVal == null || targetPaceVal <= 0) return false;
      final actualPace = (_trackingRepository.totalSecondsElapsed / 60) / (_trackingRepository.totalMetersTracked / 1000);
      return actualPace >= (targetPaceVal * (1.0 - GameConfig.validPaceRange)) &&
             actualPace <= (targetPaceVal * (1.0 + GameConfig.validPaceRange));
    }

    if (tType == TrainingType.timeTrial) {
      final targetDist = selectedDistanceMeters;
      final targetTime = selectedTime;
      return targetDist > 0 &&
             _trackingRepository.totalMetersTracked >= targetDist &&
             targetTime != null &&
             _trackingRepository.totalSecondsElapsed <= targetTime.inSeconds;
    }

    return true;
  }

  SessionRepository get sessionRepository => _sessionRepository;

  List<Training> get trainings => _trainingRepository.trainings;
  List<BoostInventory> get availableBoosts => _boostRepository.availableBoostsInventory;
  List<BoostInventory> get onlyExistingInventory => availableBoosts.where((b) => b.quantity > 0).toList();
  bool get readyToStart => trainingConfig != null;

  double get currentMultiplier {
    final tType = (playingState == PlayingState.stopped) ? (_selectedPreTrainingType ?? TrainingType.free) : (selectedTrainingType ?? TrainingType.free);
    final tObj = _trainingRepository.getTrainingByType(tType);
    return tObj.impactPoints;
  }

  HarActivity get currentHarActivity => _sensorRepository?.currentActivity ?? HarActivity.unknown;

  ActivityViewModel(
    this._sessionRepository,
    this._trackingRepository,
    this._trainingRepository,
    this._boostRepository,
    this._territoryRepository,
    this._teamRepository, [
    this._sensorRepository,
  ]) {
    _trackingRepository.addListener(_onTrackingDataChanged);
    _sessionRepository.addListener(notifyListeners);
    _trainingRepository.addListener(notifyListeners);
    _boostRepository.addListener(notifyListeners);
    _territoryRepository.addListener(_onTerritoriesChanged);
    _sensorRepository?.addListener(notifyListeners);
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
    _updatePuckRing();

    if (_isFollowingUser && userPosition != null && !_hasInitialCenter) {
      _hasInitialCenter = true;
      centerOnUser();
    }

    _updateMapLayers();
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
    if (!await style.styleSourceExists("h3-grid-source")) return;

    final camera = await _mapboxMap!.getCameraState();
    final userTeamColor = _getUserTeamColor();
    final bool canShowPoints = _showPoints && camera.zoom >= minZoomToShowPoints;

    List<String> currentIndexes = [];
    if (camera.zoom >= minZoomToRender) {
      final centerLat = camera.center.coordinates.lat.toDouble();
      final centerLon = camera.center.coordinates.lng.toDouble();
      final radius = max(1500.0, maxRenderRadius / camera.zoom);

      currentIndexes = H3Helper.getHexagonsInRadius(
        centerLat: centerLat,
        centerLon: centerLon,
        radiusMeters: radius,
        resolution: GameConfig.h3Resolution,
      );

      final currentHex = H3Helper.getHexagonAt(
        lat: centerLat,
        lon: centerLon,
        resolution: GameConfig.h3Resolution,
      );
      if (currentHex.isNotEmpty) {
        currentIndexes.add(currentHex);
        currentIndexes.addAll(H3Helper.getNeighbors(currentHex, ring: 3));
      }
    }

    final Set<String> allHexIndexes = {
      ...currentIndexes,
      for (final t in _territoryRepository.territories) t.id,
      for (final cell in _trackingRepository.visitedCells) cell,
      if (currentCell != null && currentCell!.isNotEmpty) currentCell!,
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
    
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!_isMapReady) {
        _isMapReady = true;
        notifyListeners();
      }
    });

    if (userPosition != null) {
      centerOnUser();
    } else {
      _trackingRepository.updateCurrentPosition();
      final currentUser = AuthRepository.instance.currentUser;
      if (currentUser != null && currentUser.team != null) {
        _teamRepository.fetchTeamDetails(currentUser.team!.id);
      }
    }

    notifyListeners();
  }

  Future<void> onStyleLoaded() async {
    try {
      await _initializeH3Layer();
      await _initializeTrackingPolygon();
      if (_isLocationPermissionGranted) {
        await _enableLocationComponent();
      }
      if (userPosition != null) {
        centerOnUser();
      }
      unawaited(_territoryRepository.fetchAllTerritories());
      await _updateMapLayers();
    } catch (e) {
      debugPrint("ActivityViewModel: Error in onStyleLoaded: $e");
    } finally {
      _isMapReady = true;
      notifyListeners();
    }
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
      await _mapboxMap!.setCamera(CameraOptions(center: pos, zoom: 18.0, pitch: 60.0));
    }

    _viewport = FollowPuckViewportState(
        zoom: 18.0,
        bearing: FollowPuckViewportStateBearingHeading(),
        pitch: 60.0,
        padding: MbxEdgeInsets(top: -110, left: 0, bottom: 0, right: 0),
    );
    notifyListeners();
  }

  void setActivityConfig({
    required ActivityType activityType,
    required TrainingType trainingType,
    required double distance,
    required Duration time,
    required double pace,
    BoostInventory? boost,
  }) {
    _selectedActivityType = activityType;
    _selectedPreTrainingType = trainingType;
    _selectedBoost = boost;

    final trainingObj = _trainingRepository.getTrainingByType(trainingType);

    final config = TrainingConfig(
      activityType: activityType,
      training: trainingObj,
      distance: distance,
      time: time,
      pace: pace,
      boost: boost,
    );
    _sessionRepository.setupSession(config: config);
    notifyListeners();
  }

  void onPushPlayButton() {
    if (playingState == PlayingState.stopped) {
      _sessionRepository.startGame();
      _sensorRepository?.startReading();
    } else if (playingState == PlayingState.playing) {
      _sessionRepository.pauseGame();
    } else if (playingState == PlayingState.paused) {
      _sessionRepository.resumeGame();
      _sensorRepository?.startReading();
    }
  }

  void cancelActivity() {
    _sensorRepository?.stopReading();
    _sessionRepository.cancelSession();
    _selectedBoost = null;
    _selectedPreTrainingType = TrainingType.free;
    _selectedActivityType = ActivityType.onFoot;
    notifyListeners();
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<Map<String, dynamic>?> onPushStopButton() async {
    _isSaving = true;
    _sensorRepository?.stopReading();
    notifyListeners();
    try {
      final trainingType = selectedTrainingType ?? _selectedPreTrainingType ?? TrainingType.free;
      final targetDistance = selectedDistance;
      final targetDuration = selectedTime;
      final targetPace = selectedPace;

      final result = await _sessionRepository.stopAndSaveSession();
      if (result == null) {
        debugPrint("ActivityViewModel.onPushStopButton: stopAndSaveSession returned null");
        return null;
      }

      return {
        'session': result.session, 
        'activityResult': result.activityResult,
        'activityType': _selectedActivityType,
        'trainingType': trainingType,
        'trainingName': trainingType.name,
        'targetDistance': targetDistance,
        'targetDuration': targetDuration,
        'targetPace': targetPace,
        'isOffline': result.isOffline,
        'error': result.error,
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
    _mapBearing = data.cameraState.bearing;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () => _updateMapLayers());
  }

  Future<void> resetNorth() async {
    final map = _mapboxMap;
    if (map == null) return;
    final camera = await map.getCameraState();
    await map.setCamera(CameraOptions(
      center: camera.center,
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: 0.0,
    ));
    _mapBearing = 0.0;
    notifyListeners();
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

    try {
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
    } catch (e) {
      debugPrint("ActivityViewModel: SymbolLayer error (health label): $e");
    }
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

    try {
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
    } catch (e) {
      debugPrint("ActivityViewModel: SymbolLayer error (nodes label): $e");
    }
  }

  void _configureOrnaments() {
    _mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));
    _mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    _mapboxMap?.attribution.updateSettings(AttributionSettings(
      position: OrnamentPosition.TOP_LEFT,
      marginTop: 170,
      marginLeft: 225,
    ));
    _mapboxMap?.logo.updateSettings(LogoSettings(
      position: OrnamentPosition.TOP_LEFT,
      marginTop: 170,
      marginLeft: 135,
    ));
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

    String? topLayerId;
    if (await map.style.styleLayerExists("tracking-nodes-label-layer")) {
      topLayerId = "tracking-nodes-label-layer";
    } else if (await map.style.styleLayerExists("tracking-nodes-layer")) {
      topLayerId = "tracking-nodes-layer";
    } else if (await map.style.styleLayerExists("puck-ring-outline-layer")) {
      topLayerId = "puck-ring-outline-layer";
    } else if (await map.style.styleLayerExists("h3-health-label-layer")) {
      topLayerId = "h3-health-label-layer";
    }

    final puckModelUri = await _sessionRepository.localStorageService.getMergedModelPathOrDefault();

    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        layerAbove: topLayerId,
        locationPuck: LocationPuck(
          locationPuck3D: LocationPuck3D(
            modelUri: puckModelUri,
            modelRotation: [0, 0, 180],
            modelScale: [1, 1, 1],
            modelScaleMode: ModelScaleMode.MAP,
            modelEmissiveStrength: 1.0,
          ),
        ),
      ),
    );
    await _updatePuckRing();
    centerOnUser();
  }

  Future<void> _updatePuckRing() async {
    final map = _mapboxMap;
    final pos = userPosition;
    if (map == null || pos == null) return;

    final style = map.style;

    final centerLng = pos.coordinates.lng;
    final centerLat = pos.coordinates.lat;
    const radiusMeters = 15.0;

    final hexagonCoords = <List<double>>[];
    for (var i = 0; i <= 6; i++) {
      final angleRad = (i * 60.0) * (pi / 180.0);
      final dLat = (radiusMeters * sin(angleRad)) / 111111.0;
      final dLng = (radiusMeters * cos(angleRad)) / (111111.0 * cos(centerLat * pi / 180.0));
      hexagonCoords.add([centerLng + dLng, centerLat + dLat]);
    }

    final hexagonJson = jsonEncode({
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [hexagonCoords]
      }
    });

    if (!await style.styleSourceExists("puck-ring-source")) {
      await style.addSource(GeoJsonSource(
        id: "puck-ring-source",
        data: hexagonJson,
      ));

      await style.addLayer(FillLayer(
        id: "puck-ring-glow-layer",
        sourceId: "puck-ring-source",
        fillColor: Colors.white.toARGB32(),
        fillOpacity: 0.25,
      ));

      await style.addLayer(LineLayer(
        id: "puck-ring-outline-layer",
        sourceId: "puck-ring-source",
        lineColor: Colors.white.toARGB32(),
        lineWidth: 2.0,
      ));
    } else {
      final source = await style.getSource("puck-ring-source") as GeoJsonSource?;
      await source?.updateGeoJSON(hexagonJson);
    }
  }

  @override
  void dispose() {
    _sensorRepository?.removeListener(notifyListeners);
    _sensorRepository?.stopReading();
    _trackingRepository.removeListener(_onTrackingDataChanged);
    _sessionRepository.removeListener(notifyListeners);
    _territoryRepository.removeListener(_onTerritoriesChanged);
    WidgetsBinding.instance.removeObserver(this);
    _drawingThrottle?.cancel();
    super.dispose();
  }
}
