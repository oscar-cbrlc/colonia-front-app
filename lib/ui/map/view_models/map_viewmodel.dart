import 'dart:async';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

import 'package:colonia_front_app/data/repositories/tracking_repository.dart';

class MapViewModel extends ChangeNotifier {
  final TrackingRepository _trackingRepository;

  static const double minZoomToRender = 13.0;
  static const double maxRenderRadius = 5000.0;

  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  bool _hasCenteredOnFirstPosition = false;
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

  MapViewModel(this._trackingRepository) {
    _trackingRepository.addListener(_onTrackingDataChanged);
  }

  void _onTrackingDataChanged() {
    if (!_hasCenteredOnFirstPosition && userPosition != null) {
      _hasCenteredOnFirstPosition = true;
      centerOnUser();
    }

    _updateH3Grid();
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
    //await _initializeTrackingPolygon();
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
      ),
    );
    
    centerOnUser();
  }

  Future<void> centerOnUser() async {
    if (!_isLocationPermissionGranted) {
      await requestLocationPermission();
    }

    if (userPosition == null) {
      await _trackingRepository.updateCurrentPosition();
    }

    if (_mapboxMap == null || userPosition == null) return;

    _viewport = const IdleViewportState();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));

    _viewport = CameraViewportState(
      center: userPosition,
      zoom: 13.0,
      bearing: currentBearing,
      pitch: 0.0,
    );
    notifyListeners();
  }

  Future<void> mapTrackUser() async {
    if (_mapboxMap == null || userPosition == null) return;

    _viewport = FollowPuckViewportState(
      zoom: 17.0,
      bearing: FollowPuckViewportStateBearingConstant(currentBearing),
      pitch: 0.0,
    );
    notifyListeners();
  }

  void onCameraChanged(CameraChangedEventData data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 25), () {
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

      // TODO: get team color
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
      marginBottom: 70,
    ));

    _mapboxMap!.logo.updateSettings(LogoSettings(
      position: OrnamentPosition.BOTTOM_LEFT,
      marginBottom: 70,
      marginLeft: 40,
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _trackingRepository.removeListener(_onTrackingDataChanged);
    super.dispose();
  }
}