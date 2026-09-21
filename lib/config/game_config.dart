abstract class GameConfig {
  static const int h3Resolution = 10;

  // at resolution 10
  static const double baseMetersBetweenNodes = 131.4;

  static const double minMetersBetweenTracking = 1.0;
  static const Duration gpsUpdateInterval = Duration(seconds: 2);
  static const double validPaceRange = 0.20;

  static const double baseTerritoryHealth = 1000;
  static const double basePointsEffect = 500;
  static const double maxTerritoryHealth = 5000;

  static const int impactHexagonAreaLevel = 1;
}