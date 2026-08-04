import 'dart:async';
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

class ActivityViewModel extends ChangeNotifier {
  final SessionRepository _sessionRepository;
  final TrackingRepository _trackingRepository;
  final TrainingRepository _trainingRepository;
  final BoostRepository _boostRepository;

  static const double minZoomToRender = 6.0;
  static const double maxRenderRadius = 5000.0;

  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  ViewportState? _viewport;

  Timer? _debounceTimer;
  Timer? _throttleTimer;
  double _smoothedBearing = 0.0;
  static const double _bearingFilterFactor = 0.15;
  
  Set<String> _lastH3Indexes = {};
  bool _hasCenteredOnFirstPosition = false;

  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  MapboxMap? get mapboxMap => _mapboxMap;
  ViewportState? get viewport => _viewport;

  double get smoothedBearing => _smoothedBearing;

  bool get readyToStart => _trainingConfig != null;
  bool get inActivity => _trackingRepository.isActivityActive;

  String? _selectedPreActivity = "walk";
  String? _selectedPreTrainingName = "free";

  String? get selectedPreActivity => _selectedPreActivity;
  set selectedPreActivity(String? value) {
    _selectedPreActivity = value;
    notifyListeners();
  }

  String? get selectedPreTrainingName => _selectedPreTrainingName;
  set selectedPreTrainingName(String? value) {
    _selectedPreTrainingName = value;
    notifyListeners();
  }

  TrainingConfig? _trainingConfig;

  PlayingState get playingState => _sessionRepository.playingState;
  Point? get userPosition => _trackingRepository.userPosition;
  double get currentBearing => _trackingRepository.currentBearing;
  String? get currentCell => _trackingRepository.currentCell;

  double get totalMetersTracked => _trackingRepository.totalMetersTracked;
  int get totalSecondsElapsed => _trackingRepository.totalSecondsElapsed;
  double get currentPace => _trackingRepository.currentPace;
  double get averagePace => _trackingRepository.averagePace;
  double get distanceTilNextNode => _trackingRepository.metersPerEdge - _trackingRepository.edgeMetersTracked;


  String? get selectedActivity => _trainingConfig?.activity;
  String? get selectedTrainingName => _trainingConfig?.training.name;
  double? get selectedDistance => _trainingConfig?.distance;
  Duration? get selectedTime => _trainingConfig?.time;
  double? get selectedPace => _trainingConfig?.pace;

  List<Training> get trainings => _trainingRepository.trainings;
  List<Boost> get availableBoosts => _boostRepository.userBoostInventory;

  double get currentAttackMultiplier {
    final trainingObj = trainings.firstWhere(
      (t) => t.name == selectedPreTrainingName,
      orElse: () => trainings.first,
    );
    double multiplier = trainingObj.attackPoints;
    if (selectedBoost != null) {
      multiplier *= selectedBoost!.effect;
    }
    return multiplier;
  }

  double get currentDefenseMultiplier {
    final trainingObj = trainings.firstWhere(
      (t) => t.name == selectedPreTrainingName,
      orElse: () => trainings.first,
    );
    double multiplier = trainingObj.defensePoints;
    if (selectedBoost != null) {
      multiplier *= selectedBoost!.effect;
    }
    return multiplier;
  }

  int getBoostCount(int boostId) => _boostRepository.getBoostCount(boostId);

  Boost? _selectedBoost;
  Boost? get selectedBoost => _selectedBoost;
  set selectedBoost(Boost? value) {
    _selectedBoost = value;
    notifyListeners();
  }

  ActivityViewModel(
    this._sessionRepository, 
    this._trackingRepository, 
    this._trainingRepository,
    this._boostRepository,
  ) {
    _trackingRepository.addListener(_onTrackingDataChanged);
    _sessionRepository.addListener(_onSessionStateChanged);
    _trainingRepository.addListener(_onTrainingDataChanged);
    _boostRepository.addListener(notifyListeners);
    

    // _boostRepository.fetchAndSetUserBoosts(userId);
  }

  void setActivityConfig({
    required String activity,
    required String training,
    required double distance,
    required Duration time,
    required double pace,
    Boost? boost,
  }) {
    selectedPreActivity = activity;
    selectedPreTrainingName = training;
    selectedBoost = boost;
    _trainingConfig = TrainingConfig(
        activity: activity,
        training: trainings.firstWhere( (tr) => tr.name == training),
        distance: distance,
        time: time,
        pace: pace,
        boost: boost
    );
    _sessionRepository.setupSession(config: _trainingConfig!);
    notifyListeners();
  }

  void onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _configureOrnaments();
    _checkInitialPermission();
    _setMapDaylight();
    notifyListeners();
  }

  Future<void> onStyleLoaded() async {
    await _initializeH3Layer();
    await _initializeTrackingPolygon();
    await _updateH3Grid();
  }

  Future<void> _checkInitialPermission() async {
    _isLocationPermissionGranted = await Permission.location.isGranted;
    if (_isLocationPermissionGranted) {
      await _enableLocationComponent();
    }
    notifyListeners();
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    _isLocationPermissionGranted = status.isGranted;

    if (_isLocationPermissionGranted) {
      await Permission.notification.request();

      await Permission.locationAlways.request();

      await _enableLocationComponent();
    }
    notifyListeners();
  }

  Future<void> _enableLocationComponent() async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );

    //_trackingRepository.startTracking();
    centerOnUser();
  }

  Future<void> centerOnUser() async {
    if (!_isLocationPermissionGranted) {
      await requestLocationPermission();
    }
    if (_mapboxMap == null || userPosition == null) return;

    _viewport = CameraViewportState(
      center: userPosition,
      zoom: 15.0,
      bearing: currentBearing,
      pitch: 0.0,
    );
    notifyListeners();
  }

  Future<void> mapTrackUser() async {
    if (_mapboxMap == null || userPosition == null) return;

    _viewport = FollowPuckViewportState(
      zoom: 17.0,
      bearing: FollowPuckViewportStateBearingHeading(),
      pitch: 0.0,
    );
    notifyListeners();
  }

  void onCameraChanged(CameraChangedEventData data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _updateH3Grid();
    });
  }


  Future<void> _initializeH3Layer() async {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;

    if (await style.styleSourceExists("h3-grid-source")) return;

    await style.addSource(
      GeoJsonSource(
        id: "h3-grid-source",
        data: '{"type": "FeatureCollection", "features": []}',
      ),
    );

    await style.addLayer(
      LineLayer(
        id: "h3-grid-outline-layer",
        sourceId: "h3-grid-source",
        lineColor: AppTheme.h3GridLineColor.toARGB32(),
        lineWidth: 1.0,
      ),
    );

    await style.addLayer(
      FillLayer(
        id: "h3-grid-layer",
        sourceId: "h3-grid-source",
        fillColorExpression: [
          'case',
          ['to-boolean', ['get', 'is_current']],
          'rgba(100, 138, 7, 0.4)',
          'rgba(0, 0, 0, 0)',
        ],
      ),
    );
  }

  Future<void> _updateH3Grid() async {
    if (_mapboxMap == null) return;

    final cameraState = await _mapboxMap!.getCameraState();
    final zoom = cameraState.zoom;

    if (zoom < minZoomToRender) {
      await _updateSource({"type": "FeatureCollection", "features": []});
      _lastH3Indexes = {};
      return;
    }

    final double currentRadius = maxRenderRadius / zoom;

    final List<String> currentIndexes = H3Helper.getHexagonsInRadius(
      centerLat: cameraState.center.coordinates.lat.toDouble(),
      centerLon: cameraState.center.coordinates.lng.toDouble(),
      radiusMeters: currentRadius,
      resolution: GameConfig.h3Resolution,
    );

    final Set<String> indexSet = currentIndexes.toSet();

    if (_setEquals(_lastH3Indexes, indexSet)) return;
    _lastH3Indexes = indexSet;

    final List<Map<String, dynamic>> features = [];
    for (final hexIndex in currentIndexes) {
      final corners = H3Helper.getHexagonCorners(hexIndex);

      final safeId = int.tryParse(hexIndex.substring(hexIndex.length - 8), radix: 16) ?? 0;

      String? teamColor;

      features.add({
        "type": "Feature",
        "id": safeId,
        "properties": {
          "h3_index": hexIndex,
          "team_color": teamColor,
          "is_current": hexIndex == currentCell,
        },
        "geometry": {
          "type": "Polygon",
          "coordinates": [corners]
        }
      });
    }

    await _updateSource({
      "type": "FeatureCollection",
      "features": features,
    });
  }

  Future<void> _updateSource(Map<String, dynamic> geojson) async {
    await _mapboxMap?.style.setStyleSourceProperty(
      "h3-grid-source",
      "data",
      geojson,
    );
  }

  Future<void> _initializeTrackingPolygon() async {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;

    if (await style.styleSourceExists('tracking-polygon-source')) return;

    await style.addSource(
      GeoJsonSource(
        id: 'tracking-polygon-source',
        data: '{"type": "FeatureCollection", "features": []}',
      ),
    );

    await style.addLayer(
      FillLayer(
        id: "tracking-hexagons-fill-layer",
        sourceId: "tracking-polygon-source",
        filter: ['==', ['geometry-type'], 'Polygon'],
        fillColor: AppTheme.primaryColor.withOpacity(0.3).toARGB32(),
      ),
    );

    await style.addLayer(
      LineLayer(
        id: "tracking-hexagons-outline-layer",
        sourceId: "tracking-polygon-source",
        filter: ['==', ['geometry-type'], 'Polygon'],
        lineColor: AppTheme.h3GridLineColor.toARGB32(),
        lineWidth: 1.0,
      ),
    );

    await style.addLayer(
      LineLayer(
        id: "tracking-perimeter-line-layer",
        sourceId: "tracking-polygon-source",
        filter: ['==', ['geometry-type'], 'LineString'],
        lineColor: Colors.white.toARGB32(),
        lineWidth: 4.0,
        lineJoin: LineJoin.ROUND,
        lineCap: LineCap.ROUND,
      ),
    );
  }

  Future<void> _updateTrackingPolygon() async {
    if (_mapboxMap == null) return;

    final visitedIndexes = _trackingRepository.visitedCells;
    final perimeter = _trackingRepository.perimeter;

    final List<Map<String, dynamic>> features = [];

    for (final hexIndex in visitedIndexes) {
      final corners = H3Helper.getHexagonCorners(hexIndex);
      final safeId = int.tryParse(hexIndex.substring(hexIndex.length - 8), radix: 16) ?? 0;

      features.add({
        "type": "Feature",
        "id": safeId,
        "properties": {
          "h3_index": hexIndex,
        },
        "geometry": {
          "type": "Polygon",
          "coordinates": [corners]
        }
      });
    }

    if (perimeter.length >= 2) {
      features.add({
        "type": "Feature",
        "id": 9999,
        "properties": {
          "is_perimeter": true,
        },
        "geometry": {
          "type": "LineString",
          "coordinates": perimeter.map((p) => [p.lon, p.lat]).toList()
        }
      });
    }

    await _mapboxMap?.style.setStyleSourceProperty(
      "tracking-polygon-source",
      "data",
      {
        "type": "FeatureCollection",
        "features": features,
      },
    );
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }


  void _configureOrnaments() async {
    if (_mapboxMap == null) return;

    _mapboxMap!.compass.updateSettings(CompassSettings(
      position: OrnamentPosition.TOP_RIGHT,
      marginTop: 105,
      marginRight: 20,
    ));

    _mapboxMap!.scaleBar.updateSettings(ScaleBarSettings(
      enabled: true,
      isMetricUnits: true,
      distanceUnits: DistanceUnits.METRIC,
      position: OrnamentPosition.TOP_RIGHT,
      marginTop: 60,
      marginRight: 10,
    ));

    _mapboxMap!.attribution.updateSettings(AttributionSettings(
      position: OrnamentPosition.BOTTOM_LEFT,
      marginLeft: 20,
      marginBottom: 90,
    ));

    _mapboxMap!.logo.updateSettings(LogoSettings(
      position: OrnamentPosition.BOTTOM_LEFT,
      marginBottom: 90,
      marginLeft: 45,
    ));
  }

  void _setMapDaylight() {
    if (_mapboxMap == null) return;

    final int hour = DateTime.now().hour;
    String preset;
    if (hour >= 5 && hour < 8) {
      preset = "dawn";
    } else if (hour >= 8 && hour < 17) {
      preset = "day";
    } else if (hour >= 17 && hour < 20) {
      preset = "dusk";
    } else {
      preset = "night";
    }

    _mapboxMap?.style.setStyleImportConfigProperty("basemap", "lightPreset", preset);
  }


  void onPushPlayButton() {
    switch (playingState) {
      case PlayingState.stopped:
        _sessionRepository.startGame();
        break;
      case PlayingState.playing:
        _sessionRepository.pauseGame();
        break;
      case PlayingState.paused:
        _sessionRepository.resumeGame();
        break;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> onPushStopButton() async {
    final activity = _trainingConfig?.activity;
    final trainingName = _trainingConfig?.training.name;

    final session = await _sessionRepository.stopAndSaveSession();
    if (session == null) return null;

    notifyListeners();
    return {
      'session': session,
      'activity': activity,
      'trainingName': trainingName,
    };
  }


  bool _isMapUpdating = false;

  void _onTrainingDataChanged() {
    //_trainings = _trainingRepository.trainings;
  }

  void _onTrackingDataChanged() async {
    double delta = currentBearing - _smoothedBearing;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    _smoothedBearing = (_smoothedBearing + (_bearingFilterFactor * delta)) % 360;
    if (_smoothedBearing < 0) _smoothedBearing += 360;

    if (!_hasCenteredOnFirstPosition && userPosition != null) {
      _hasCenteredOnFirstPosition = true;
      centerOnUser();
    }

    if (_isMapUpdating) return;

    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 100), () async {
      _isMapUpdating = true;
      try {
        if (playingState == PlayingState.playing) {
          await _updateTrackingPolygon();
          if (viewport == null) {
            mapTrackUser();
          }
        }
        await _updateH3Grid();
      } finally {
        _isMapUpdating = false;
        notifyListeners();
      }
    });
  }

  void _onSessionStateChanged() {
    if (playingState == PlayingState.playing) {
      mapTrackUser();
    } else if (playingState == PlayingState.stopped) {
      _updateTrackingPolygon();
    }
    notifyListeners();
  }

  void finishActivity() {

  }

  @override
  void dispose() {
    _trackingRepository.removeListener(_onTrackingDataChanged);
    _sessionRepository.removeListener(_onSessionStateChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }
}