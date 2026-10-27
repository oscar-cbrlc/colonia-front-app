import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:h3_flutter/h3_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/map_control_group.dart';
import 'package:colonia_front_app/ui/events/widgets/event_details_card.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

class EventDetailsScreen extends StatefulWidget {
  final ActiveChallenge activeChallenge;

  const EventDetailsScreen({
    super.key,
    required this.activeChallenge,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  MapboxMap? _mapboxMap;
  final ValueNotifier<double> _bearingNotifier = ValueNotifier<double>(0.0);

  List<String> get _hexagonIds {
    final condition = widget.activeChallenge.challenge.objectiveCondition;
    final hexRaw = condition['hexagons'];
    if (hexRaw is List) {
      return hexRaw.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<GeoCoord> get _routeCords {
    final condition = widget.activeChallenge.challenge.objectiveCondition;
    final hexRaw = condition['hexagons'];
    if (hexRaw is List) {
      return hexRaw.map((e) => H3Helper.getHexCenter(e)).toList();
    }
    return [];
  }

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _configureOrnaments();
  }

  Future<void> _fitCameraToRoute() async {
    final map = _mapboxMap;
    if (map == null) return;
    try {
      Map<String, dynamic> geometry;
      if (_routeCords.length > 1) {
        geometry = {
          "type": "LineString",
          "coordinates": _routeCords.map((c) => [c.lon, c.lat]).toList(),
        };
      } else {
        geometry = {
          "type": "Point",
          "coordinates": [_routeCords.first.lon, _routeCords.first.lat],
        };
      }

      final camera = await map.cameraForGeometry(
          geometry,
          MbxEdgeInsets(top: 50, left: 50, bottom: 250, right: 50),
          0.0,
          0.0
      );
      await map.setCamera(CameraOptions(
        center: camera.center,
        zoom: camera.zoom != null? camera.zoom! - 1.5 : 12.0,
        pitch: camera.pitch,
        bearing: 0.0,
      ));
      _bearingNotifier.value = 0.0;
    } catch (e) {
      debugPrint("ActivitySummaryViewModel: Error in onMapCreated: $e");
    }



  }

  void _configureOrnaments() {
    final map = _mapboxMap;
    if (map == null) return;
    map.compass.updateSettings(CompassSettings(enabled: false));
    map.scaleBar.updateSettings(ScaleBarSettings(
      enabled: true,
      position: OrnamentPosition.TOP_RIGHT,
      marginTop: 60,
      marginRight: 10,
      isMetricUnits: true,
    ));
  }

  void _onCameraChanged(CameraChangedEventData data) {
    _bearingNotifier.value = data.cameraState.bearing;
  }

  Future<void> _centerOnUser() async {
    final trackingRepository = context.read<TrackingRepository>();
    if (trackingRepository.userPosition == null) {
      await trackingRepository.updateCurrentPosition();
    }
    final pos = trackingRepository.userPosition;
    if (pos != null && _mapboxMap != null) {
      await _mapboxMap!.setCamera(CameraOptions(center: pos, zoom: 15.0));
    } else {
      await _fitCameraToRoute();
    }
  }

  Future<void> _resetNorth() async {
    final map = _mapboxMap;
    if (map == null) return;
    final camera = await map.getCameraState();
    await map.setCamera(CameraOptions(
      center: camera.center,
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: 0.0,
    ));
    _bearingNotifier.value = 0.0;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    final map = _mapboxMap;
    if (map == null) return;

    await _initializeLayers();
    await _updateRouteLayer();
    await _fitCameraToRoute();
  }

  Future<void> _initializeLayers() async {
    final style = _mapboxMap?.style;
    if (style == null) return;

    if (!await style.styleSourceExists("event-selected-source")) {
      await style.addSource(GeoJsonSource(
        id: "event-selected-source",
        data: jsonEncode({"type": "FeatureCollection", "features": []}),
      ));
    }

    if (!await style.styleLayerExists("event-selected-fill-layer")) {
      await style.addLayer(FillLayer(
        id: "event-selected-fill-layer",
        sourceId: "event-selected-source",
        fillColor: AppTheme.primaryColor.toARGB32(),
        fillOpacity: 0.65,
      ));
    }

    if (!await style.styleLayerExists("event-selected-outline-layer")) {
      await style.addLayer(LineLayer(
        id: "event-selected-outline-layer",
        sourceId: "event-selected-source",
        lineColor: Colors.white.toARGB32(),
        lineWidth: 2.5,
      ));
    }
  }

  Future<void> _updateRouteLayer() async {
    final style = _mapboxMap?.style;
    if (style == null) return;

    final hexIds = _hexagonIds;
    final features = hexIds.map((hexId) {
      return {
        "type": "Feature",
        "properties": {"h3_index": hexId},
        "geometry": {
          "type": "Polygon",
          "coordinates": [H3Helper.getHexagonCorners(hexId)]
        }
      };
    }).toList();

    await style.setStyleSourceProperty(
      "event-selected-source",
      "data",
      jsonEncode({
        "type": "FeatureCollection",
        "features": features,
      }),
    );
  }

  @override
  void dispose() {
    _bearingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.activeChallenge.challenge;
    final hexIds = _hexagonIds;

    final rewards = challenge.boostRewards.map((br) {
      return RewardItem(boost: br.boost, amount: br.amount);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("event_details_map"),
            styleUri: MapboxStyles.STANDARD,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onCameraChangeListener: _onCameraChanged,
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.tertiaryColor,
                    size: 32.0,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120, right: 16),
                child: MapControlGroup(
                  listenable: _bearingNotifier,
                  currentBearing: _bearingNotifier.value,
                  onCenterOnUser: _centerOnUser,
                  onResetNorth: _resetNorth,
                  showPointsButton: false,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IndividualMapButton(
                    icon: Icons.route,
                    width: 54,
                    height: 54,
                    iconColor: AppTheme.primaryColor,
                    borderColor: AppTheme.primaryColor.withAlpha(180),
                    onPressed: () => _fitCameraToRoute(),
                  ),
                  const SizedBox(height: 12),
                  EventDetailsCard(
                    eventName: challenge.name ?? '',
                    territoriesCount: hexIds.length,
                    startDate: widget.activeChallenge.startDate,
                    endDate: widget.activeChallenge.endDate,
                    rewards: rewards,
                    bottomActions: null,
                    initiallyExpanded: false,
                  ),
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }
}
