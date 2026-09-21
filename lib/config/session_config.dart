import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/enums/boost_type.dart';
import 'package:colonia_front_app/domain/models/session/training_config.dart';

class SessionConfig {
  final double metersBetweenNodes;
  final double baseImpactPoints;
  final int impactAreaLevel;
  final double areaImpactMultiplier;

  const SessionConfig({
    required this.metersBetweenNodes,
    required this.baseImpactPoints,
    required this.impactAreaLevel,
    required this.areaImpactMultiplier,
  });

  factory SessionConfig.fromBase() {
    return const SessionConfig(
      metersBetweenNodes: GameConfig.baseMetersBetweenNodes,
      baseImpactPoints: GameConfig.basePointsEffect,
      impactAreaLevel: 0,
      areaImpactMultiplier: 0.0,
    );
  }

  factory SessionConfig.fromTrainingConfig(TrainingConfig trainingConfig) {
    double meters = GameConfig.baseMetersBetweenNodes;
    double points = GameConfig.basePointsEffect;
    int areaLevel = 0;
    double areaMult = 0.0;

    final boost = trainingConfig.boost;
    if (boost != null) {
      if (boost.type == BoostType.score.name) {
        points *= boost.effect;
      } else if (boost.type == BoostType.impact_distance.name) {
        meters *= boost.effect;
      } else if (boost.type == BoostType.impact_area.name) {
        areaLevel = GameConfig.impactHexagonAreaLevel;
        areaMult = boost.effect;
      }
    }

    return SessionConfig(
      metersBetweenNodes: meters,
      baseImpactPoints: points,
      impactAreaLevel: areaLevel,
      areaImpactMultiplier: areaMult,
    );
  }
}
