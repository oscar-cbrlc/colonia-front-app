import 'dart:async';
import 'dart:convert';
import 'package:colonia_front_app/utils/h3_helper.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapViewModel extends ChangeNotifier {
  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  Position? _userPosition;
  ViewportState? _viewport;

  Timer? _debounceTimer;
  Set<String> _lastH3Indexes = {};

  static const double minZoomToRender = 11.0;
  static const int h3Resolution = 10;

  static const double maxRenderRadius = 5000;

  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  MapboxMap? get mapboxMap => _mapboxMap;
  ViewportState? get viewport => _viewport;

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    _isLocationPermissionGranted = status.isGranted;

    if (_isLocationPermissionGranted) {
      _enableLocationComponent();
    }

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
    _updateH3Grid();
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
        data: jsonEncode({"type": "FeatureCollection", "features": []}),
      ),
    );

    await style.addLayer(
      LineLayer(
        id: "h3-grid-layer",
        sourceId: "h3-grid-source",
        lineColor: Colors.black.withOpacity(0.3).value,
        lineWidth: 1.0,
      ),
    );
  }

  Future<void> _updateH3Grid() async {
    if (_mapboxMap == null) return;

    final cameraState = await _mapboxMap!.getCameraState();
    if (cameraState.zoom < minZoomToRender) {
      await _updateSource({"type": "FeatureCollection", "features": []});
      return;
    }

    int currentRes = h3Resolution;
    double currentRadius = maxRenderRadius/cameraState.zoom;

    //if (cameraState.zoom < 14) {
      //currentRes = 8;
      //currentRadius = 6000;
    //}
    //else if (cameraState.zoom > 16) {
      //currentRes = 10;
    //}

    //final viewportBounds = await _mapboxMap!.coordinateBoundsForCamera(
      //cameraState.toCameraOptions(),
    //);

    Point cameraCenter =  cameraState.toCameraOptions().center!;



    //final h3Indexes = H3Helper.getHexagonsInViewport(
      //minLat: viewportBounds.southwest.coordinates[1]!.toDouble(),
      //maxLat: viewportBounds.northeast.coordinates[1]!.toDouble(),
      //minLon: viewportBounds.southwest.coordinates[0]!.toDouble(),
      //maxLon: viewportBounds.northeast.coordinates[0]!.toDouble(),
      //resolution: currentRes,
    //).toSet();

    final h3Indexes = H3Helper.getHexagonsInRadius(
        centerLat: cameraCenter.coordinates.lat.toDouble(),
        centerLon: cameraCenter.coordinates.lng.toDouble(),
        radiusMeters: currentRadius,
        resolution: currentRes
    ).toSet();

    if (_setEquals(_lastH3Indexes, h3Indexes)) return;
    _lastH3Indexes = h3Indexes;

    final features = h3Indexes.map((h3Index) {
      return {
        "type": "Feature",
        "id": h3Index,
        "geometry": {
          "type": "Polygon",
          "coordinates": [H3Helper.getHexagonCorners(h3Index)]
        },
        "properties": {"h3_index": h3Index}
      };
    }).toList();

    await _updateSource({
      "type": "FeatureCollection",
      "features": features,
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  Future<void> _updateSource(Map<String, dynamic> geojson) async {
    await _mapboxMap?.style.setStyleSourceProperty(
      "h3-grid-source",
      "data",
      jsonEncode(geojson),
    );
  }

  Future<void> centerOnUser() async {
    if (!_isLocationPermissionGranted) {
      final status = await Permission.location.request();
      _isLocationPermissionGranted = status.isGranted;

      if (_isLocationPermissionGranted) {
        _enableLocationComponent();
        return;
      }
    }

    if (_isLocationPermissionGranted) {
      _viewport = const IdleViewportState();
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 50));

      _viewport = FollowPuckViewportState(
        zoom: 16.0,
        pitch: 0,
      );
      notifyListeners();
    }
  }

  Future<void> _checkInitialPermission() async {
    _isLocationPermissionGranted = await Permission.location.isGranted;
    if (_isLocationPermissionGranted) {
      _enableLocationComponent();
    }
    notifyListeners();
  }

  void _enableLocationComponent() {
    if (_mapboxMap == null) return;

    _mapboxMap!.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));

    centerOnUser();
  }

  void setUserPosition(Position pos) {
    _userPosition = pos;
    notifyListeners();
  }

  void _configureOrnaments() {
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
      marginBottom: 20,
    ));

    _mapboxMap!.logo.updateSettings(LogoSettings(
      position: OrnamentPosition.BOTTOM_LEFT,
      marginBottom: 20,
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
}