import 'dart:io';
import 'package:geolocator/geolocator.dart' as geo;

class LocationService {
  Future<geo.Position> getCurrentPosition() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await geo.Geolocator.getCurrentPosition();
  }

  Future<bool> handlePermission() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    return permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse;
  }

  Stream<geo.Position> get positionStream {
    geo.LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 1,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationText: "Colonia is tracking your workout",
          notificationTitle: "Tracking Active",
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      locationSettings = geo.AppleSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 1,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 1,
      );
    }

    return geo.Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return geo.Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  double bearingBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return geo.Geolocator.bearingBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }
}