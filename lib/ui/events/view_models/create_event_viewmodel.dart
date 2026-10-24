import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/data/repositories/boost_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/utils/h3_helper.dart';

enum MapRouteEditMode { paint, erase, navigate }

class CreateEventViewModel extends ChangeNotifier {
  final TrackingRepository _trackingRepository;
  final BoostRepository _boostRepository;

  MapboxMap? _mapboxMap;
  Timer? _debounceTimer;

  double _mapBearing = 0.0;
  bool _showPoints = true;

  final List<String> _selectedHexagonIds = [];
  String _eventName = '';

  DateTime? _startDate;
  DateTime? _endDate;

  final Map<int, int> _boostQuantities = {};

  MapRouteEditMode _mapMode = MapRouteEditMode.navigate;

  CreateEventViewModel({
    required TrackingRepository trackingRepository,
    required BoostRepository boostRepository,
  })  : _trackingRepository = trackingRepository,
        _boostRepository = boostRepository {
    _boostRepository.addListener(notifyListeners);
    _boostRepository.getAvailableBoosts();
  }

  MapboxMap? get mapboxMap => _mapboxMap;
  Point? get userPosition => _trackingRepository.userPosition;

  double get currentBearing => _mapBearing;
  bool get showPoints => _showPoints;

  List<Boost> get availableBoosts => _boostRepository.availableBoosts;

  List<String> get selectedHexagonIds => List.unmodifiable(_selectedHexagonIds);
  int get selectedHexagonsCount => _selectedHexagonIds.length;

  String get eventName => _eventName;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  Map<Boost, int> get boostQuantities {
    final Map<Boost, int> result = {};
    for (final boost in availableBoosts) {
      result[boost] = _boostQuantities[boost.id] ?? 0;
    }
    return result;
  }

  int getBoostQuantity(Boost boost) => _boostQuantities[boost.id] ?? 0;

  String getBoostName(Boost boost, AppLocalizations locale) => boost.getName(locale);

  bool get hasSelectedRewards => _boostQuantities.values.any((quantity) => quantity > 0);

  bool get isHexagonSelectionValid => _selectedHexagonIds.isNotEmpty;

  static DateTime getEndOfWeekSunday(DateTime date) {
    final daysUntilSunday = DateTime.sunday - date.weekday;
    final sunday = date.add(Duration(days: daysUntilSunday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  }

  bool get isDetailsValid {
    if (_eventName.trim().isEmpty) return false;
    if (_startDate == null || _endDate == null) return false;
    if (!_endDate!.isAfter(_startDate!)) return false;
    if (_endDate!.isAfter(getEndOfWeekSunday(_startDate!))) return false;
    if (!hasSelectedRewards) return false;
    return true;
  }

  bool get isSaveEnabled => isHexagonSelectionValid && isDetailsValid;

  MapRouteEditMode get mapMode => _mapMode;
  bool get inEditMode => mapMode != MapRouteEditMode.navigate;

  void toggleShowPoints() {
    _showPoints = !_showPoints;
    _updateH3Grid();
    notifyListeners();
  }

  Future<void> centerOnUser() async {
    if (userPosition == null) {
      await _trackingRepository.updateCurrentPosition();
    }
    final pos = userPosition;
    if (pos == null) return;
    if (_mapboxMap != null) {
      await _mapboxMap!.setCamera(CameraOptions(center: pos, zoom: 15.0, pitch: 0.0));
    }
    notifyListeners();
  }

  Future<void> resetNorth() async {
    final map = _mapboxMap;
    if (map == null) return;
    final camera = await map.getCameraState();
    await map.setCamera(CameraOptions(
      center: camera.center,
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: 0.0,
    ));
    _mapBearing = 0.0;
    notifyListeners();
  }

  void setEventName(String name) {
    _eventName = name;
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void setBoostQuantity(Boost boost, int quantity) {
    _boostQuantities[boost.id] = quantity < 0 ? 0 : quantity;
    notifyListeners();
  }

  void toggleHexagonSelection(String hexId) {
    if (_selectedHexagonIds.contains(hexId)) {
      _selectedHexagonIds.remove(hexId);
    } else {
      _selectedHexagonIds.add(hexId);
    }
    _updateSelectedHexagonsLayer();
    notifyListeners();
  }

  void paintHexagon(String hexId) {
    if (!_selectedHexagonIds.contains(hexId)) {
      _selectedHexagonIds.add(hexId);
      _updateSelectedHexagonsLayer();
      notifyListeners();
    }
  }

  void eraseHexagon(String hexId) {
    if (_selectedHexagonIds.contains(hexId)) {
      _selectedHexagonIds.remove(hexId);
      _updateSelectedHexagonsLayer();
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedHexagonIds.clear();
    _updateSelectedHexagonsLayer();
    notifyListeners();
  }

  Future<void> setMapMode(MapRouteEditMode mode) async {
    _mapMode = mode;
    await _updateGestureSettings();
    notifyListeners();
  }

  Future<void> _updateGestureSettings() async {
    final map = _mapboxMap;
    if (map == null) return;
    await map.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: !inEditMode,
        pinchToZoomEnabled: !inEditMode,
        doubleTapToZoomInEnabled: !inEditMode,
        doubleTouchToZoomOutEnabled: !inEditMode,
        quickZoomEnabled: !inEditMode,
        pitchEnabled: !inEditMode,
        rotateEnabled: !inEditMode,
      ),
    );
  }

  void onMapCreated(MapboxMap map) {
    _mapboxMap = map;
  }

  Future<void> onStyleLoaded() async {
    await _initializeLayers();
    if (inEditMode) {
      await _updateGestureSettings();
    }
    if (userPosition != null) {
      await _mapboxMap?.setCamera(
        CameraOptions(center: userPosition!, zoom: 15.0),
      );
    }
    await _updateH3Grid();
    await _updateSelectedHexagonsLayer();
  }

  void onCameraChanged(CameraChangedEventData data) {
    _mapBearing = data.cameraState.bearing;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _updateH3Grid();
      notifyListeners();
    });
  }

  Future<void> _initializeLayers() async {
    final style = _mapboxMap?.style;
    if (style == null) return;

    if (!await style.styleSourceExists("event-grid-source")) {
      await style.addSource(GeoJsonSource(
        id: "event-grid-source",
        data: jsonEncode({"type": "FeatureCollection", "features": []}),
      ));
    }

    if (!await style.styleSourceExists("event-selected-source")) {
      await style.addSource(GeoJsonSource(
        id: "event-selected-source",
        data: jsonEncode({"type": "FeatureCollection", "features": []}),
      ));
    }

    if (!await style.styleLayerExists("event-grid-outline-layer")) {
      await style.addLayer(LineLayer(
        id: "event-grid-outline-layer",
        sourceId: "event-grid-source",
        lineColor: AppTheme.h3GridLineColor.toARGB32(),
        lineWidth: 1.0,
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

  Future<void> _updateH3Grid() async {
    final style = _mapboxMap?.style;
    final map = _mapboxMap;
    if (map == null || style == null) return;

    final camera = await map.getCameraState();
    if (camera.zoom < 12.0) return;

    final currentIndexes = H3Helper.getHexagonsInRadius(
      centerLat: camera.center.coordinates.lat.toDouble(),
      centerLon: camera.center.coordinates.lng.toDouble(),
      radiusMeters: 4000.0 / camera.zoom,
      resolution: GameConfig.h3Resolution,
    );

    final features = currentIndexes.map((hexId) {
      return {
        "type": "Feature",
        "properties": {"h3_index": hexId},
        "geometry": {
          "type": "Polygon",
          "coordinates": [H3Helper.getHexagonCorners(hexId)]
        }
      };
    }).toList();

    await style.setStyleSourceProperty("event-grid-source", "data", jsonEncode({
      "type": "FeatureCollection",
      "features": features,
    }));
  }

  Future<void> _updateSelectedHexagonsLayer() async {
    final style = _mapboxMap?.style;
    if (style == null) return;

    final features = [];
    for (int i = 0; i < _selectedHexagonIds.length; i++) {
      final hexId = _selectedHexagonIds[i];
      features.add({
        "type": "Feature",
        "properties": {
          "h3_index": hexId,
        },
        "geometry": {
          "type": "Polygon",
          "coordinates": [H3Helper.getHexagonCorners(hexId)]
        }
      });
    }

    await style.setStyleSourceProperty("event-selected-source", "data", jsonEncode({
      "type": "FeatureCollection",
      "features": features,
    }));
  }

  void saveEvent() {
    if (!isSaveEnabled) return;
    debugPrint("Event created: Name='$_eventName', Start=$_startDate, End=$_endDate, Boosts=$_boostQuantities, Hexagons=$_selectedHexagonIds");
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _boostRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
