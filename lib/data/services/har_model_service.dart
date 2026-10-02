import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
import 'package:flutter/foundation.dart';
import 'package:colonia_front_app/data/models/sensor_reading.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'dart:math';

class ModelService {
  CompiledModel? _model;
  bool _isLoaded = false;

  final List<HarActivity> _labels = [
    HarActivity.walk,
    HarActivity.run,
    HarActivity.bike,
    HarActivity.vehicle,
  ];

  ModelService();

  Future<void> load() async {
    const assetPath = 'assets/har_model/har_model_pipeline.tflite';

    try {
      debugPrint('ModelService: Loading TFLite model from $assetPath...');
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List modelBytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      try {
        _model = CompiledModel.fromBuffer(modelBytes);
      } catch (e) {
        debugPrint('ModelService: fromBuffer fallback to withConfig: $e');
        _model = CompiledModel.fromBufferWithConfig(
          modelBytes,
          config: const CompiledModelConfig.auto(),
        );
      }

      _isLoaded = true;
      debugPrint('ModelService: HAR model loaded successfully.');
    } catch (e) {
      _isLoaded = false;
      debugPrint('ModelService: Could not load $assetPath: $e');
    }
  }

  HarActivity? predict(List<SensorReading> readings) {
    if (!_isLoaded || _model == null) {
      debugPrint('ModelService: Model not loaded yet.');
      return null;
    }
    if (readings.length != 5) return null;

    try {
      final input = Float32List.fromList(
        readings.map((reading) {
          return [
            reading.accelX,
            reading.accelY,
            reading.accelZ,
            reading.pitch,
            reading.roll,
            reading.yaw,
          ];
        }).expand((element) => element).toList(),
      );

      final result = _model!.run([input]);
      debugPrint('ModelService: TFLite output = $result');
      return _labels[result.first.indexOf(result.first.reduce(max))];
    } catch (e) {
      debugPrint('ModelService: Error during prediction: $e');
      return null;
    }
  }

  void close() {
    _model?.close();
    _model = null;
    _isLoaded = false;
  }
}
