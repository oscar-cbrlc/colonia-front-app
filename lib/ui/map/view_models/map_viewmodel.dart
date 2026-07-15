import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapViewModel extends ChangeNotifier {
  MapboxMap? _mapboxMap;
  bool _isLocationPermissionGranted = false;
  Position? _userPosition;
  ViewportState? _viewport;

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
