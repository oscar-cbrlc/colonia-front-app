import 'dart:async';
import 'package:colonia_front_app/data/models/sensor_reading.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/data/services/har_activity_resolver.dart';
import 'package:colonia_front_app/data/services/har_model_service.dart';
import 'package:colonia_front_app/data/services/sensor_service.dart';
import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
import 'package:colonia_front_app/utils/sensor_helper.dart';
import 'package:flutter/foundation.dart';

class SensorRepository extends ChangeNotifier {
  final SensorService _sensorService;
  final ModelService _modelService;
  final TrackingRepository? _trackingRepository;
  final HarActivityResolver _activityResolver;

  final double _millisPerReading = 5000;
  final double _millisIntvlPerReading = 1000;
  double _millisPassed = 0;

  final List<SensorReading> _readingBatch = [];
  HarActivity _currentActivity = HarActivity.unknown;
  Timer? _timer;
  bool _isReading = false;

  SensorRepository(
    this._sensorService,
    this._modelService, [
    this._trackingRepository,
    HarActivityResolver? activityResolver,
  ]) : _activityResolver = activityResolver ?? HarActivityResolver();

  HarActivity get currentActivity => _currentActivity;
  bool get isReading => _isReading;

  void startReading() {
    if (_isReading) return;
    _isReading = true;
    _modelService.load();
    _sensorService.start();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _millisIntvlPerReading.toInt()), (timer) {
      _registerReadings();
      _millisPassed += _millisIntvlPerReading;
      if (_millisPassed >= _millisPerReading) {
        _predictActivity();
        notifyListeners();
        _millisPassed = 0;
        _readingBatch.clear();
      }
    });
  }

  void stopReading() {
    _timer?.cancel();
    _timer = null;
    _sensorService.stop();
    _isReading = false;
    _readingBatch.clear();
    _millisPassed = 0;
    _currentActivity = HarActivity.unknown;
    _modelService.close();
    notifyListeners();
  }

  void _registerReadings() {
    _readingBatch.add(
      SensorReading(
        accelX: SensorHelper.ms2ToG(_sensorService.accelX),
        accelY: SensorHelper.ms2ToG(_sensorService.accelY),
        accelZ: SensorHelper.ms2ToG(_sensorService.accelZ),
        pitch: _sensorService.pitch,
        roll: _sensorService.roll,
        yaw: _sensorService.yaw,
      ),
    );
  }

  void _predictActivity() {
    if (_readingBatch.isEmpty) return;

    HarActivity? modelPrediction;
    try {
      modelPrediction = _modelService.predict(_readingBatch);
    } catch (e) {
      debugPrint('SensorRepository: Error predicting HAR activity via model: $e');
    }

    final speedMs = _trackingRepository?.currentSpeed ?? 0.0;
    final paceMinKm = _trackingRepository?.currentPace ?? 0.0;

    _currentActivity = _activityResolver.resolve(
      modelPrediction: modelPrediction,
      readings: _readingBatch,
      speedMs: speedMs,
      paceMinKm: paceMinKm,
    );
  }
}
