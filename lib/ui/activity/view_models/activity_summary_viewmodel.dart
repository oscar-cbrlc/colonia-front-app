import 'dart:convert';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class ActivitySummaryViewModel extends ChangeNotifier {
  final TrackingSession session;
  final String activity;
  final String trainingName;
  MapboxMap? _mapboxMap;
  bool _isMapReady = false;
  ViewportState? _viewport;

  ActivitySummaryViewModel({
    required this.session,
    required this.activity,
    required this.trainingName,
  });

  bool get isMapReady => _isMapReady;
  ViewportState? get viewport => _viewport;

  double get distanceKm => session.totalDistance / 1000;
  double get impactPoints => session.impactPoints;

  String get formattedTime {
    final d = Duration(seconds: session.durationSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String get formattedPace {
    if (session.averagePace == 0) return "--";
    return session.averagePace.toStringAsFixed(1);
  }

  double get score => (session.totalDistance * 0.1);

  void onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _fitCameraToRoute();
    _drawRoute();
    _configureOrnaments();
    _setMapDaylight();

    _isMapReady = true;
    notifyListeners();
  }

  void onStyleLoaded() async {
    await _drawRouteHexagons();
    await _drawRoute();
  }

  Future<void> _fitCameraToRoute() async {
    final map = _mapboxMap;
    if (map == null || session.route.isEmpty) return;

    try {
      Map<String, dynamic> geometry;
      if (session.route.length > 1) {
        geometry = {
          "type": "LineString",
          "coordinates": session.route.map((c) => [c.lon, c.lat]).toList(),
        };
      } else {
        geometry = {
          "type": "Point",
          "coordinates": [session.route.first.lon, session.route.first.lat],
        };
      }

      final camera = await map.cameraForGeometry(
          geometry,
          MbxEdgeInsets(top: 50, left: 50, bottom: 250, right: 50),
          0.0,
          0.0
      );

      await map.setCamera(camera);
    } catch (e) {
      debugPrint("Summary Map Centering Error: $e");
    }
  }

  Future<void> _drawRoute() async {
    final map = _mapboxMap;
    if (map == null || session.route.isEmpty) return;
    final style = map.style;

    final List<Map<String, dynamic>> features = [
      {
        "type": "Feature",
        "properties": {"type": "perimeter"},
        "geometry": {
          "type": "LineString",
          "coordinates": session.route.map((c) => [c.lon, c.lat]).toList(),
        }
      }
    ];

    for (final node in session.nodes) {
      features.add({
        "type": "Feature",
        "properties": {
          "type": "node",
          "points_label": node.points > 0 ? "+${node.points.toStringAsFixed(0)}" : "",
        },
        "geometry": {
          "type": "Point",
          "coordinates": [node.lon, node.lat]
        }
      });
    }

    final geojson = {
      "type": "FeatureCollection",
      "features": features
    };

    if (await style.styleSourceExists("route-source")) {
      await style.removeStyleLayer("route-layer");
      await style.removeStyleLayer("route-nodes-layer");
      await style.removeStyleSource("route-source");
    }

    await style.addSource(
      GeoJsonSource(id: "route-source", data: jsonEncode(geojson)),
    );

    await style.addLayer(
      LineLayer(
        id: "route-layer",
        sourceId: "route-source",
        filter: <Object>['==', ['get', 'type'], 'perimeter'],
        lineColor: Colors.white.toARGB32(),
        lineWidth: 5.0,
        lineJoin: LineJoin.ROUND,
        lineCap: LineCap.ROUND,
        lineEmissiveStrength: 1.0,
      ),
    );

    await style.addLayer(
      CircleLayer(
        id: "route-nodes-layer",
        sourceId: "route-source",
        filter: <Object>['==', ['get', 'type'], 'node'],
        circleRadius: 5.0,
        circleColor: AppTheme.secondaryColor.toARGB32(),
        circleStrokeWidth: 2.0,
        circleStrokeColor: Colors.white.toARGB32(),
      ),
    );

    await style.addLayer(
      SymbolLayer(
        id: "route-nodes-label-layer",
        sourceId: "route-source",
        filter: <Object>['==', ['get', 'type'], 'node'],
        textSize: 10.0,
        textColor: Colors.white.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 1.0,
        textOffset: [0, -1.2],
      ),
    );
    await style.setStyleLayerProperty("route-nodes-label-layer", "text-field", ["get", "points_label"]);
  }

  Future<void> _drawRouteHexagons() async {
    final map = _mapboxMap;
    if (map == null) return;
    final style = map.style;

    if (await style.styleSourceExists("h3-grid-source")) return;

    await style.addSource(
      GeoJsonSource(
        id: "h3-grid-source",
        data: jsonEncode({"type": "FeatureCollection", "features": []}),
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
        fillColor: AppTheme.primaryColor.withValues(alpha: 0.4).toARGB32(),
      ),
    );

    await style.addLayer(
      SymbolLayer(
        id: "h3-health-label-layer",
        sourceId: "h3-grid-source",
        textSize: 12.0,
        textColor: Colors.white.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 1.0,
      ),
    );
    await style.setStyleLayerProperty("h3-health-label-layer", "text-field", ["get", "health_label"]);

    final List<Map<String, dynamic>> features = [];
    for (final territory in session.territories) {
      final hexIndex = territory.id;
      final corners = H3Helper.getHexagonCorners(hexIndex);
      final safeId = int.tryParse(hexIndex.substring(hexIndex.length - 8), radix: 16) ?? 0;

      features.add({
        "type": "Feature",
        "id": safeId,
        "properties": {
          "h3_index": hexIndex,
          "health_label": territory.healthPoints.toStringAsFixed(0),
        },
        "geometry": {
          "type": "Polygon",
          "coordinates": [corners]
        }
      });
    }

    await style.setStyleSourceProperty(
      "h3-grid-source",
      "data",
      jsonEncode({
        "type": "FeatureCollection",
        "features": features,
      }),
    );
  }

  void _configureOrnaments() async {
    final map = _mapboxMap;
    if (map == null) return;

    map.compass.updateSettings(CompassSettings(enabled: false));
    map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    map.attribution.updateSettings(AttributionSettings(position: OrnamentPosition.BOTTOM_LEFT, marginLeft: 20, marginBottom: 70));
    map.logo.updateSettings(LogoSettings(position: OrnamentPosition.BOTTOM_LEFT, marginBottom: 70, marginLeft: 40));
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
}
