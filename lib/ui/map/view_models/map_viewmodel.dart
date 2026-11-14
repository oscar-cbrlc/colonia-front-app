import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/data/repositories/challenge_repository.dart';
import 'package:colonia_front_app/data/repositories/session_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:colonia_front_app/domain/models/started_challenge.dart';

class MapViewModel extends ChangeNotifier {
  final TrackingRepository _trackingRepository;
  final TerritoryRepository _territoryRepository;
  final TeamRepository _teamRepository;
  final SessionRepository _sessionRepository;
  final BoostRepository _boostRepository;
  final ChallengeRepository _challengeRepository;

  static const double minZoomToRender = 13.0;
  static const double minZoomToShowPoints = 15.0;
  static const double maxRenderRadius = 5000.0;

  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  bool _hasInitialCenter = false;
  bool _lastActivityState = false;
  bool _showPoints = true;
  bool _isOffline = false;
  bool _isReconnecting = false;
  bool _isMapReady = false;
  ViewportState? _viewport;

  Timer? _debounceTimer;
  Set<String> _lastH3Indexes = {};

  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  MapboxMap? get mapboxMap => _mapboxMap;
  ViewportState? get viewport => _viewport;
  bool get showPoints => _showPoints;
  bool get isOffline => _isOffline;
  bool get isReconnecting => _isReconnecting;
  bool get isMapReady => _isMapReady;

  void toggleShowPoints() {
    _showPoints = !_showPoints;
    _lastH3Indexes = {};
    _updateH3Grid();
    notifyListeners();
  }

  bool get inActivity => _trackingRepository.isActivityActive;
  Point? get userPosition => _trackingRepository.userPosition;
  double _mapBearing = 0.0;
  double get currentBearing => _mapBearing;
  String? get currentCell => _trackingRepository.currentCell;

  List<ActiveChallenge> get activeChallenges => _challengeRepository.activeChallenges;
  List<StartedChallenge> get myStartedChallenges => _challengeRepository.myStartedChallenges;
  bool get isChallengesLoading => _challengeRepository.isLoading;
  int get completedChallengesCount => myStartedChallenges.where((c) => c.isComplete).length;

  Future<void> fetchActiveChallenges() async {
    await _challengeRepository.fetchActiveChallenges();
    await _challengeRepository.fetchMyChallengeProgress();
  }

  MapViewModel(
    this._trackingRepository,
    this._territoryRepository,
    this._teamRepository,
    this._sessionRepository,
    this._boostRepository,
    this._challengeRepository,
  ) {
    _trackingRepository.addListener(_onTrackingDataChanged);
    _territoryRepository.addListener(_onTerritoriesChanged);
    _challengeRepository.addListener(notifyListeners);
    _lastActivityState = _trackingRepository.isActivityActive;
    _territoryRepository.fetchAllTerritories();
    _boostRepository.getAvailableBoosts();
    _boostRepository.fetchMyInventory();
    fetchActiveChallenges();
    
    _sessionRepository.onSyncNotification = () {
        _didSync = true;
        notifyListeners();
    };
    
    checkPendingActivities();
    checkConnectionAndReload();
  }

  bool _didSync = false;
  bool get didSync => _didSync;

  void clearSyncMessage() {
    _didSync = false;
    notifyListeners();
  }

  Future<void> checkPendingActivities() async {
    try {
      final pendingCount = (await _sessionRepository.localStorageService.getPendingActivityImpacts()).length;
      debugPrint('MapViewModel: checkPendingActivities found $pendingCount pending impacts');
      if (pendingCount > 0) {
        await _sessionRepository.syncPendingImpacts();
      }
    } catch (e) {
      debugPrint('MapViewModel: checkPendingActivities error: $e');
    }
  }

  Future<bool> checkConnectionAndReload() async {
    _isReconnecting = true;
    notifyListeners();

    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isOffline = false;
        _isReconnecting = false;
        notifyListeners();
        await reloadMapData();
        return true;
      }
    } catch (_) {
      _isOffline = true;
    } finally {
      _isReconnecting = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> reloadMapData() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      _isOffline = !(result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } catch (_) {
      _isOffline = true;
    }
    notifyListeners();

    await checkPendingActivities();
    await _territoryRepository.fetchAllTerritories();
    await fetchActiveChallenges();
    _lastH3Indexes = {};
    await _updateH3Grid();
    await centerOnUser();
  }

  void _onTerritoriesChanged() {
    _lastH3Indexes = {};
    _updateH3Grid();
  }

  void _onTrackingDataChanged() {
    if (!_hasInitialCenter && userPosition != null) {
      _hasInitialCenter = true;
      centerOnUser();
    }

    if (_lastActivityState == true && !_trackingRepository.isActivityActive) {
      centerOnUser();
      _lastH3Indexes = {};
      _territoryRepository.fetchAllTerritories();
    }
    _lastActivityState = _trackingRepository.isActivityActive;
    _updatePuckRing();

    notifyListeners();
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
      _hasInitialCenter = true;
      centerOnUser();
    } else {
      _trackingRepository.updateCurrentPosition();
      final currentUser = AuthRepository.instance.currentUser;
      if (currentUser != null && currentUser.team != null) _teamRepository.fetchTeamDetails(currentUser.team!.id);
    }

    notifyListeners();
  }

  Future<void> onStyleLoaded() async {
    try {
      await _initializeH3Layer();
      if (_isLocationPermissionGranted) {
        await _enableLocationComponent();
      }
      if (userPosition != null) {
        _hasInitialCenter = true;
        centerOnUser();
      }
      unawaited(_territoryRepository.fetchAllTerritories());
      await _updateH3Grid();
    } catch (e) {
      debugPrint("MapViewModel: Error in onStyleLoaded: $e");
    } finally {
      _isMapReady = true;
      notifyListeners();
    }
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
    if (await map.style.styleLayerExists("puck-ring-outline-layer")) {
      topLayerId = "puck-ring-outline-layer";
    } else if (await map.style.styleLayerExists("h3-health-label-layer")) {
      topLayerId = "h3-health-label-layer";
    } else if (await map.style.styleLayerExists("h3-grid-layer")) {
      topLayerId = "h3-grid-layer";
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
            modelReceiveShadows: true

            //modelOpacity: 0.5,
          ),
        ),
      ),
    );
    await _updatePuckRing();
    centerOnUser();
  }

  Future<void> centerOnUser() async {
    if (!_isLocationPermissionGranted) await requestLocationPermission();
    
    if (userPosition == null) {
      await _trackingRepository.updateCurrentPosition();
    }

    final pos = userPosition;
    if (pos == null) return;
    
    if (_mapboxMap != null) {
      await _mapboxMap!.setCamera(CameraOptions(center: pos, zoom: 16.0, pitch: 0.0));
    }

    _viewport = FollowPuckViewportState(
      zoom: 16.0,
      bearing: FollowPuckViewportStateBearingHeading(), 
      pitch: 0.0
    );
    
    notifyListeners();
  }

  void onCameraChanged(CameraChangedEventData data) {
    _mapBearing = data.cameraState.bearing;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () => _updateH3Grid());
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

  String _colorToRgba(Color c, double alpha) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return 'rgba($r, $g, $b, $alpha)';
  }

  Future<void> _initializeH3Layer() async {
    final style = _mapboxMap?.style;
    if (style == null) return;
    
    if (await style.styleSourceExists("h3-grid-source")) return;

    await style.addSource(GeoJsonSource(
      id: "h3-grid-source",
      data: jsonEncode({"type": "FeatureCollection", "features": []}),
    ));

    await style.addLayer(LineLayer(
      id: "h3-grid-outline-layer",
      sourceId: "h3-grid-source",
      lineColor: AppTheme.h3GridLineColor.toARGB32(),
      lineWidth: 1.0,
    ));

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
      debugPrint("MapViewModel: SymbolLayer error (health label): $e");
    }

    await _updateH3Grid();
  }

  Future<void> _updateH3Grid() async {
    final style = _mapboxMap?.style;
    final map = _mapboxMap;
    if (map == null || style == null) return;
    if (!await style.styleSourceExists("h3-grid-source")) return;

    final camera = await map.getCameraState();

    List<String> currentIndexes = [];
    if (camera.zoom >= minZoomToRender) {
      final centerLat = camera.center.coordinates.lat.toDouble();
      final centerLon = camera.center.coordinates.lng.toDouble();
      final radius = math.max(1500.0, maxRenderRadius / camera.zoom);

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
    };

    if (_setEquals(_lastH3Indexes, allHexIndexes)) return;
    _lastH3Indexes = allHexIndexes;

    final bool canShowPoints = _showPoints && camera.zoom >= minZoomToShowPoints;

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
          "health": territory.healthPoints,
          "health_label": (canShowPoints && territory.healthPoints > 0) ? territory.healthPoints.toStringAsFixed(0) : "",
          "team_id": territory.team?.id,
          "fill_color": fillColor,
        },
        "geometry": {"type": "Polygon", "coordinates": [H3Helper.getHexagonCorners(hexId)]}
      };
    }).toList();

    await style.setStyleSourceProperty("h3-grid-source", "data", {
      "type": "FeatureCollection",
      "features": features,
    });
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
      final angleRad = (i * 60.0) * (math.pi / 180.0);
      final dLat = (radiusMeters * math.sin(angleRad)) / 111111.0;
      final dLng = (radiusMeters * math.cos(angleRad)) / (111111.0 * math.cos(centerLat * math.pi / 180.0));
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
        fillOpacity: 0.5,
        //fillEmissiveStrength: 2.0
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

  bool _setEquals(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  void _configureOrnaments() {
    final map = _mapboxMap;
    if (map == null) return;
    map.compass.updateSettings(CompassSettings(enabled: false));
    map.scaleBar.updateSettings(ScaleBarSettings(enabled: true, position: OrnamentPosition.TOP_RIGHT, marginTop: 60, marginRight: 10, isMetricUnits: true));
    map.attribution.updateSettings(AttributionSettings(
      position: OrnamentPosition.TOP_RIGHT,
      marginTop: 90,
      marginRight: 20,
    ));
    map.logo.updateSettings(LogoSettings(
      position: OrnamentPosition.TOP_RIGHT,
      marginTop: 90,
      marginRight: 45,
    ));
  }

  void _setMapDaylight() {
    final map = _mapboxMap;
    if (map == null) return;
    final hour = DateTime.now().hour;
    String preset = (hour >= 5 && hour < 8) ? "dawn" : (hour >= 8 && hour < 17) ? "day" : (hour >= 17 && hour < 20) ? "dusk" : "night";
    try {
        map.style.setStyleImportConfigProperty("basemap", "lightPreset", preset);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _trackingRepository.removeListener(_onTrackingDataChanged);
    _territoryRepository.removeListener(_onTerritoriesChanged);
    _challengeRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
