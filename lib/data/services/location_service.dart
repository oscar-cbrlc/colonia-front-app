import 'dart:io';
import 'package:geolocator/geolocator.dart' as geo;

class LocationService {
  Future<geo.Position> getCurrentPosition() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return Future.error('Location permissions are denied');
    }

    return await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.best,
    );
  }

  Stream<geo.Position> get positionStream {
    geo.LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.best,
        distanceFilter: 2,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationText: "Colonia is tracking your workout",
          notificationTitle: "Tracking Active",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = geo.AppleSettings(
        accuracy: geo.LocationAccuracy.best,
        distanceFilter: 2,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return geo.Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
