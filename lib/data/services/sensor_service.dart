import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  final List<StreamSubscription<dynamic>> _streamSubscriptions;

  double _accelX = 0;
  double _accelY = 0;
  double _accelZ = 0;
  double _pitch = 0;
  double _roll = 0;
  double _yaw = 0;

  SensorService() : _streamSubscriptions = <StreamSubscription<dynamic>>[];

  double get accelX => _accelX;
  double get accelY => _accelY;
  double get accelZ => _accelZ;
  double get pitch => _pitch;
  double get roll => _roll;
  double get yaw => _yaw;

  void start() {
    _streamSubscriptions
        .add(accelerometerEventStream().listen((AccelerometerEvent event) {
          _accelX = event.x;
          _accelY = event.y;
          _accelZ = event.z;
        }
      )
    );
    _streamSubscriptions.add(gyroscopeEventStream().listen((GyroscopeEvent event) {
      _pitch = event.x;
      _roll = event.y;
      _yaw = event.z;
    }));
  }

  void stop() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }
}