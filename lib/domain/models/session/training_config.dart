import 'package:colonia_front_app/domain/models/boost_inventory.dart';
import 'package:colonia_front_app/domain/models/enums/activity_type.dart';
import 'package:colonia_front_app/domain/models/training.dart';

class TrainingConfig {
  final ActivityType activityType;
  final Training training;
  final double distance;
  final Duration time;
  final double pace;
  final BoostInventory? boost;

  const TrainingConfig({
    required this.activityType,
    required this.training,
    required this.distance,
    required this.time,
    required this.pace,
    this.boost,
  });
}
