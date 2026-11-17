import 'package:colonia_front_app/domain/models/enums/har_activity.dart';

abstract class GameConfig {
  static const String appVersion = '1.0.0';
  static const String teamName = 'Colonia Team';
  static const String designerInstagramHandle = '@bleue__moon';
  static const String designerInstagramUrl = 'https://www.instagram.com/bleue__moon/';
  static const String privacyPolicyUrl = 'https://oscar-cbrlc.github.io/colonia-legal/';

  static const int h3Resolution = 10;

  // at resolution 10
  static const double baseMetersBetweenNodes = 131.4;

  static const double minMetersBetweenTracking = 1.0;
  static const Duration gpsUpdateInterval = Duration(seconds: 2);
  static const double validPaceRange = 0.20;

  static const double baseTerritoryHealth = 2000;
  static const double maxTerritoryHealth = 10000;

  static const int impactHexagonAreaLevel = 1;

  static const double baseInsidePerimeterMod = 10.0;

  static const int walkUnitPoints = 5;
  static const int bikeUnitPoints = 15;
  static const int runUnitPoints = 25;

  static const int unitSeconds = 5;

  static const pointSpeedMod = 0.5;


  static const defaultObjectiveDistance = 10000;
  static const defaultObjectiveTime = Duration(hours: 1, minutes: 30);
  static const defaultObjectivePace = 8.0;

  static int limitConsecutiveInvalidUnits = 5;

  static const harActivityKmHRange = <HarActivity, ({double min, double max})>{
    HarActivity.walk: (min: 0.0, max: 6.0),
    HarActivity.run: (min: 6.0, max: 20.0),
    HarActivity.bike: (min: 13.0, max: 35.0),
    HarActivity.vehicle: (min: 50.0, max: double.infinity),
  };


  static const String baseModelPath = 'assets/avatar/base_model/AntAtri.glb';

}