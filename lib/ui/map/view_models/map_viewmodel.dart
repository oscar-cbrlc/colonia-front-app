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

    notifyListeners();
  }

  void centerOnUser() {
    _viewport = const FollowPuckViewportState(
      zoom: 16.0,
      pitch: 0,
    );
    notifyListeners();
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
      locationPuck: LocationPuck(
        locationPuck2D: DefaultLocationPuck2D(
          shadowImage: null,
          topImage: null,
          bearingImage: null,
        ),
      )
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
      marginTop: 100,
      marginRight: 20,
    ));

    _mapboxMap!.scaleBar.updateSettings(ScaleBarSettings(
      enabled: true,
      isMetricUnits: true,
      distanceUnits: DistanceUnits.METRIC,
      position: OrnamentPosition.TOP_LEFT,
      marginTop: 100,
      marginLeft: 20,
    ));

    _mapboxMap!.attribution.updateSettings(AttributionSettings(
      position: OrnamentPosition.TOP_LEFT,
      marginBottom: 20,
    ));

    _mapboxMap!.logo.updateSettings(LogoSettings(
      position: OrnamentPosition.BOTTOM_LEFT,
      marginBottom: 20,
      marginLeft: 100,
    ));
  }
}
