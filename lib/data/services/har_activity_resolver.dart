import 'dart:math';
import 'package:colonia_front_app/data/models/sensor_reading.dart';
import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
import 'package:flutter/foundation.dart';

class HarActivityResolver {
  HarActivity resolve({
    required HarActivity? modelPrediction,
    required List<SensorReading> readings,
    required double speedMs,
    required double paceMinKm,
  }) {
    final model = modelPrediction ?? HarActivity.unknown;
    final heuristic = estimateHeuristically(readings);
    final speedKmH = speedMs * 3.6;

    debugPrint(
      'HarActivityResolver: model=$model, heuristic=$heuristic, speed=${speedKmH.toStringAsFixed(1)}km/h, pace=${paceMinKm.toStringAsFixed(1)}min/km',
    );

    if (speedKmH < 1.5) {
      if (heuristic == HarActivity.standing) {
        return HarActivity.standing;
      }
      if (model == HarActivity.vehicle || model == HarActivity.bike) {
        return HarActivity.standing;
      }
    }

    if (speedKmH > 30.0) {
      return HarActivity.vehicle;
    }

    if (speedKmH >= 10.0 && speedKmH <= 25.0) {
      if (model == HarActivity.vehicle || heuristic == HarActivity.vehicle) {
        return HarActivity.vehicle;
      }
      return HarActivity.bike;
    }

    if (speedKmH >= 7.0) {
      if (model == HarActivity.run || heuristic == HarActivity.run) {
        return HarActivity.run;
      }
    }

    if (speedKmH >= 1.5 && speedKmH < 7.0) {
      if (heuristic == HarActivity.walk || model == HarActivity.walk) {
        return HarActivity.walk;
      }
      if (model == HarActivity.bike && speedKmH > 5.0) {
        return HarActivity.bike;
      }
      return HarActivity.walk;
    }

    if (heuristic != HarActivity.unknown) return heuristic;
    if (model != HarActivity.unknown) return model;

    return HarActivity.unknown;
  }

  HarActivity estimateHeuristically(List<SensorReading> readings) {
    if (readings.isEmpty) return HarActivity.unknown;

    final magnitudes = readings.map((r) {
      return sqrt(r.accelX * r.accelX + r.accelY * r.accelY + r.accelZ * r.accelZ);
    }).toList();

    final maxG = magnitudes.reduce(max);
    final minG = magnitudes.reduce(min);
    final deltaG = maxG - minG;

    final avgG = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((g) => (g - avgG) * (g - avgG)).reduce((a, b) => a + b) / magnitudes.length;
    final stdDev = sqrt(variance);

    final avgGyro = readings.map((r) {
      return sqrt(r.pitch * r.pitch + r.roll * r.roll + r.yaw * r.yaw);
    }).reduce((a, b) => a + b) / readings.length;

    debugPrint('HarActivityResolver: Heuristics - deltaG=${deltaG.toStringAsFixed(2)}, stdDev=${stdDev.toStringAsFixed(2)}, avgGyro=${avgGyro.toStringAsFixed(2)}');

    if (deltaG < 0.35 && stdDev < 0.10) {
      return HarActivity.standing;
    }

    if (deltaG > 1.8 || stdDev > 0.65) {
      return HarActivity.run;
    }

    if (deltaG >= 0.35 || stdDev >= 0.15) {
      return HarActivity.walk;
    }

    if (avgGyro > 0.35 && stdDev >= 0.08) {
      return HarActivity.bike;
    }

    if (deltaG < 0.35 && stdDev < 0.12) {
      return HarActivity.vehicle;
    }

    return HarActivity.unknown;
  }
}
