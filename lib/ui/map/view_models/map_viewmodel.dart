import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

import 'package:colonia_front_app/data/repositories/tracking_repository.dart';

class MapViewModel extends ChangeNotifier {
  final TrackingRepository _trackingRepository;
  final TerritoryRepository _territoryRepository;
  final TeamRepository _teamRepository;

  static const double minZoomToRender = 13.0;
  static const double maxRenderRadius = 5000.0;

  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  bool _hasInitialCenter = false;
  bool _lastActivityState = false;
  ViewportState? _viewport;

  Timer? _debounceTimer;
  Set<String> _lastH3Indexes = {};

  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  MapboxMap? get mapboxMap => _mapboxMap;
  ViewportState? get viewport => _viewport;

  bool get inActivity => _trackingRepository.isActivityActive;
  Point? get userPosition => _trackingRepository.userPosition;
  double get currentBearing => _trackingRepository.currentBearing;
  String? get currentCell => _trackingRepository.currentCell;

  MapViewModel(this._trackingRepository, this._territoryRepository, this._teamRepository) {
    _trackingRepository.addListener(_onTrackingDataChanged);
    _territoryRepository.addListener(_onTerritoriesChanged);
    //_teamRepository.addListener(())
    _lastActivityState = _trackingRepository.isActivityActive;
  }

  void _onTerritoriesChanged() {
    _updateH3Grid();
  }

  void _onTrackingDataChanged() {
    if (!_hasInitialCenter && userPosition != null) {
      _hasInitialCenter = true;
      centerOnUser();
    }

    if (_lastActivityState == true && !_trackingRepository.isActivityActive) {
      centerOnUser();
    }
    _lastActivityState = _trackingRepository.isActivityActive;

    notifyListeners();
  }

  void onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _configureOrnaments();
    _checkInitialPermission();
    _setMapDaylight();
    
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
    await _initializeH3Layer();
    if (userPosition != null) {
      _hasInitialCenter = true;
      centerOnUser();
    }
    await _updateH3Grid();
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
    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true, 
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );
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
      await _mapboxMap!.setCamera(CameraOptions(center: pos, zoom: 15.0, pitch: 0.0));
    }

    _viewport = FollowPuckViewportState(
      zoom: 15.0, 
      bearing: FollowPuckViewportStateBearingHeading(), 
      pitch: 0.0
    );
    
    notifyListeners();
  }

  void onCameraChanged(CameraChangedEventData data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () => _updateH3Grid());
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
    ));
    await style.setStyleLayerProperty("h3-grid-layer", "fill-color", ["get", "fill_color"]);

    await style.addLayer(SymbolLayer(
      id: "h3-health-label-layer",
      sourceId: "h3-grid-source",
      textSize: 12.0,
      textColor: Colors.white.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textHaloWidth: 1.0,
      textOffset: [0, 0],
    ));
    await style.setStyleLayerProperty("h3-health-label-layer", "text-field", ["get", "health_label"]);
  }

  Future<void> _updateH3Grid() async {
    final style = _mapboxMap?.style;
    final map = _mapboxMap;
    if (map == null || style == null) return;

    final camera = await map.getCameraState();
    if (camera.zoom < minZoomToRender) {
      await style.setStyleSourceProperty("h3-grid-source", "data", {
        "type": "FeatureCollection", 
        "features": []
      });
      _lastH3Indexes = {};
      return;
    }

    final currentIndexes = H3Helper.getHexagonsInRadius(
      centerLat: camera.center.coordinates.lat.toDouble(),
      centerLon: camera.center.coordinates.lng.toDouble(),
      radiusMeters: maxRenderRadius / camera.zoom,
      resolution: GameConfig.h3Resolution,
    );

    final Set<String> indexSet = currentIndexes.toSet();
    if (_setEquals(_lastH3Indexes, indexSet)) return;
    _lastH3Indexes = indexSet;

    final currentUser = AuthRepository.instance.currentUser;
    final userTeamId = currentUser?.team?.id;
    final userTeamColor = _getUserTeamColor();

    final features = currentIndexes.map((hexId) {
      final territory = _territoryRepository.getTerritoryOrDefault(hexId);
      final bool isCurrent = hexId == currentCell;
      final TerritoryTeam? claimedTeam = territory.team;

      String fillColor;
      if (isCurrent) {
        if (claimedTeam == null) {
          fillColor = _colorToRgba(userTeamColor, 0.55);
        } else {
          final claimedColor = Color(claimedTeam.color);
          if (userTeamId != null && claimedTeam.id == userTeamId) {
            fillColor = _colorToRgba(userTeamColor, 0.70);
          } else {
            final blended = Color.fromARGB(
              255,
              (((userTeamColor.r * 255) + (claimedColor.r * 255)) ~/ 2),
              (((userTeamColor.g * 255) + (claimedColor.g * 255)) ~/ 2),
              (((userTeamColor.b * 255) + (claimedColor.b * 255)) ~/ 2),
            );
            fillColor = _colorToRgba(blended, 0.65);
          }
        }
      } else if (claimedTeam != null) {
        final claimedColor = Color(claimedTeam.color);
        fillColor = _colorToRgba(claimedColor, 0.40);
      } else {
        fillColor = 'rgba(0, 0, 0, 0)';
      }

      return {
        "type": "Feature",
        "properties": {
          "h3_index": hexId, 
          "is_current": isCurrent,
          "health": territory.healthPoints,
          "health_label": territory.healthPoints.toStringAsFixed(0),
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

  bool _setEquals(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  void _configureOrnaments() {
    final map = _mapboxMap;
    if (map == null) return;
    map.compass.updateSettings(CompassSettings(position: OrnamentPosition.TOP_RIGHT, marginTop: 105, marginRight: 20));
    map.scaleBar.updateSettings(ScaleBarSettings(enabled: true, position: OrnamentPosition.TOP_RIGHT, marginTop: 60, marginRight: 10));
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
    super.dispose();
  }
}
