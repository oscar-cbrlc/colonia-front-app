import 'dart:math';
import 'package:colonia_front_app/data/models/sensor_reading.dart';
import 'package:colonia_front_app/domain/models/enums/activity_type.dart';
import 'package:colonia_front_app/domain/models/enums/har_activity.dart';
import 'package:flutter/foundation.dart';

final harActivityKmHRange = <HarActivity, ({double min, double max})>{
  HarActivity.walk: (min: 0.0, max: 6.0),
  HarActivity.run: (min: 6.0, max: 20.0),
  HarActivity.bike: (min: 13.0, max: 35.0),
  HarActivity.vehicle: (min: 35.0, max: double.infinity),
};

class HarActivityResolver {
  HarActivity resolve({
    required HarActivity? modelPrediction,
    required ActivityType? activityType,
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

    if (speedKmH <= 0.5 || heuristic == HarActivity.standing) {
      return HarActivity.standing;
    }

    if (inSpeedRange(HarActivity.vehicle, speedKmH) ||
        (model == HarActivity.vehicle && heuristic == HarActivity.vehicle)) {
      return HarActivity.vehicle;
    }

    if (activityType == ActivityType.onFoot) {
      if (model == HarActivity.walk ||
          model == HarActivity.run ||
          heuristic == HarActivity.walk ||
          heuristic == HarActivity.run) {
        if (inSpeedRange(HarActivity.walk, speedKmH)) return HarActivity.walk;
        if (inSpeedRange(HarActivity.run, speedKmH)) return HarActivity.run;
      }
    } else {
      if (model == HarActivity.bike ||
          heuristic == HarActivity.bike ||
          model == HarActivity.vehicle ||
          heuristic == HarActivity.vehicle) {
        if (inSpeedRange(HarActivity.bike, speedKmH)) return HarActivity.bike;
        if (inSpeedRange(HarActivity.vehicle, speedKmH)) return HarActivity.vehicle;
      }
    }

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

    debugPrint(
      'HarActivityResolver: Heuristics - deltaG=${deltaG.toStringAsFixed(2)}, stdDev=${stdDev.toStringAsFixed(2)}, avgGyro=${avgGyro.toStringAsFixed(2)}',
    );

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

  bool inSpeedRange(HarActivity activity, double speedKmH) {
    final range = harActivityKmHRange[activity];
    if (range == null) return false;
    return speedKmH >= range.min && speedKmH <= range.max;
  }
}
