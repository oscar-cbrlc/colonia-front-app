import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/domain/models/training.dart';

class TrainingConfig {
  final String activity;
  final Training training;
  final double distance;
  final Duration time;
  final double pace;
  final Boost? boost;

  const TrainingConfig({
    required this.activity,
    required this.training,
    required this.distance,
    required this.time,
    required this.pace,
    this.boost,
  });
}
