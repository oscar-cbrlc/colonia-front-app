abstract class GameConfig {
  static const int h3Resolution = 10;

  static const double minMetersBetweenNodes = 100.0;
  static const double minMetersBetweenTracking = 1.0;
  static const Duration gpsUpdateInterval = Duration(seconds: 2);
  static const double validPaceRange = 0.10;

  static const double baseTerritoryHealth = 1000;
  static const double basePointsEffect = 100;
  static const double maxTerritoryHealth = 5000;
}