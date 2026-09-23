import 'dart:convert';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/activity_result.dart';
import 'package:colonia_front_app/domain/models/territory.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class ActivitySummaryViewModel extends ChangeNotifier {
  final TrackingSession session;
  final ActivityResult? activityResult;
  final String activity;
  final String trainingName;
  MapboxMap? _mapboxMap;
  bool _isMapReady = true;
  ViewportState? _viewport;

  ActivitySummaryViewModel({
    required this.session,
    this.activityResult,
    required this.activity,
    required this.trainingName,
  }) {
    debugPrint("ActivitySummaryViewModel: Created with activity=$activity, trainingName=$trainingName, distance=${session.totalDistance}");
  }

  bool _showStats = true;

  bool get isMapReady => _isMapReady;
  ViewportState? get viewport => _viewport;
  bool get showStats => _showStats;

  MapboxMap? get mapboxMap => _mapboxMap;

  String _colorToRgba(Color c, double alpha) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return 'rgba($r, $g, $b, $alpha)';
  }


  void toggleShowStats() {
    _showStats = !_showStats;
    notifyListeners();
  }

  double get distanceKm => session.totalDistance / 1000;
  double get impactPoints => session.impactPoints;

  int get attackedCount {
    if (activityResult == null) return 0;
    return activityResult!.territories.where((t) => t.action?.toLowerCase() == 'attack').length;
  }

  int get defendedCount {
    if (activityResult == null) return 0;
    return activityResult!.territories.where((t) => t.action?.toLowerCase() == 'defend' || t.action?.toLowerCase() == 'defense').length;
  }

  int get capturedCount {
    if (activityResult == null) return 0;
    return activityResult!.territories.where((t) => t.action?.toLowerCase() == 'capture' || t.action?.toLowerCase() == 'claimed').length;
  }

  Territory? getAffectedTerritoryAt(double lat, double lon) {
    final hexId = H3Helper.getHexagonAt(
      lat: lat,
      lon: lon,
      resolution: GameConfig.h3Resolution,
    );

    if (activityResult != null) {
      for (final t in activityResult!.territories) {
        if (t.id == hexId) return t;
      }
    }

    for (final t in session.territories) {
      if (t.id == hexId) return t;
    }

    return null;
  }

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
    final pace = session.averagePace;
    if (pace <= 0 || pace.isNaN || pace.isInfinite) return "--";
    int minutes = pace.toInt();
    int seconds = ((pace - minutes) * 60).round();
    if (seconds >= 60) {
      minutes += 1;
      seconds = 0;
    }
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  double get score => (session.totalDistance * 0.1);

  void onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _isMapReady = true;
    notifyListeners();

    try {
      _fitCameraToRoute();
      _configureOrnaments();
      _setMapDaylight();
    } catch (e) {
      debugPrint("ActivitySummaryViewModel: Error in onMapCreated: $e");
    }
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
      _viewport = CameraViewportState(center: camera.center, zoom: camera.zoom ?? 12.0);
      notifyListeners();
    } catch (e) {
      debugPrint("Summary Map Centering Error: $e");
    }
  }

  Future<void> _drawRoute() async {
    final map = _mapboxMap;
    if (map == null) return;
    final style = map.style;

    final List<Map<String, dynamic>> features = [];

    if (session.route.length >= 2) {
      features.add({
        "type": "Feature",
        "properties": {"type": "perimeter"},
        "geometry": {
          "type": "LineString",
          "coordinates": session.route.map((c) => [c.lon, c.lat]).toList(),
        }
      });
    }

    for (final node in session.nodes) {
      features.add({
        "type": "Feature",
        "properties": {
          "type": "node",
          "node_type": node.type.name,
          "points_label": node.points > 0 ? node.points.toStringAsFixed(0) : "",
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

    final String pathColorRgba = _colorToRgba(AppTheme.secondaryColor, 1.0);
    final String areaColorRgba = _colorToRgba(AppTheme.tertiaryColor, 1.0);

    await style.addLayer(
      CircleLayer(
        id: "route-nodes-layer",
        sourceId: "route-source",
        filter: <Object>['==', ['get', 'type'], 'node'],
        circleStrokeWidth: 2.0,
        circleStrokeColor: Colors.white.toARGB32(),
        circleRadiusExpression: <Object>[
          "match",
          ["get", "node_type"],
          "path", 5.0,
          "area", 3.5,
          5.0
        ],
        circleColorExpression: <Object>[
          "match",
          ["get", "node_type"],
          "path", pathColorRgba,
          "area", areaColorRgba,
          pathColorRgba
        ],
      ),
    );

    await style.addLayer(
      SymbolLayer(
        id: "route-nodes-label-layer",
        sourceId: "route-source",
        filter: <Object>['==', ['get', 'type'], 'node'],
        textSize: 10.0,
        textFieldExpression: <Object>['get', 'points_label'],
        textFont: ["Open Sans Bold", "Arial Unicode MS Bold"],
        textColor: Colors.white.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 1.0,
        textOffset: [0, -1.2],
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
    );
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
        fillColorExpression: <Object>['get', 'fill_color'],
      ),
    );

    await style.addLayer(
      SymbolLayer(
        id: "h3-health-label-layer",
        sourceId: "h3-grid-source",
        textSize: 12.0,
        textFieldExpression: <Object>['get', 'health_label'],
        textFont: ["Open Sans Bold", "Arial Unicode MS Bold"],
        textColor: Colors.white.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 1.0,
      ),
    );

    final List<Territory> displayTerritories = activityResult?.territories ?? session.territories;
    final List<Map<String, dynamic>> features = [];

    for (final territory in displayTerritories) {
      final hexIndex = territory.id;
      if (hexIndex.isEmpty) continue;
      final corners = H3Helper.getHexagonCorners(hexIndex);
      final sub = hexIndex.length >= 8 ? hexIndex.substring(hexIndex.length - 8) : hexIndex;
      final safeId = int.tryParse(sub, radix: 16) ?? 0;

      final hexTeam = territory.team;
      final Color teamColor = hexTeam != null ? Color(hexTeam.color) : AppTheme.primaryColor;
      final String fillColor = 'rgba(${(teamColor.r * 255).round()}, ${(teamColor.g * 255).round()}, ${(teamColor.b * 255).round()}, 0.5)';

      features.add({
        "type": "Feature",
        "id": safeId,
        "properties": {
          "h3_index": hexIndex,
          "health_label": territory.healthPoints.toStringAsFixed(0),
          "fill_color": fillColor,
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
