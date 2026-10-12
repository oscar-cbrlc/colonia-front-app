import 'package:colonia_front_app/config/game_config.dart';
import 'package:colonia_front_app/domain/models/enums/boost_type.dart';
import 'package:colonia_front_app/domain/models/session/training_config.dart';

class SessionConfig {
  final double metersBetweenNodes;
  final double scoreMultiplier;
  final int impactAreaLevel;
  final double areaImpactMultiplier;

  const SessionConfig({
    required this.metersBetweenNodes,
    required this.scoreMultiplier,
    required this.impactAreaLevel,
    required this.areaImpactMultiplier,
  });

  factory SessionConfig.fromBase() {
    return const SessionConfig(
      metersBetweenNodes: GameConfig.baseMetersBetweenNodes,
      scoreMultiplier: 1.0,
      impactAreaLevel: 0,
      areaImpactMultiplier: 0.0,
    );
  }

  factory SessionConfig.fromTrainingConfig(TrainingConfig trainingConfig) {
    double meters = GameConfig.baseMetersBetweenNodes;
    double mult = 1.0;
    int areaLevel = 0;
    double areaMult = 0.0;

    final boost = trainingConfig.boost;
    if (boost != null) {
      if (boost.type == BoostType.score.name) {
        mult *= boost.effect;
      } else if (boost.type == BoostType.impact_distance.name) {
        meters *= boost.effect;
      } else if (boost.type == BoostType.impact_area.name) {
        areaLevel = GameConfig.impactHexagonAreaLevel;
        areaMult = boost.effect;
      }
    }

    return SessionConfig(
      metersBetweenNodes: meters,
      scoreMultiplier: mult,
      impactAreaLevel: areaLevel,
      areaImpactMultiplier: areaMult,
    );
  }
}
