enum AchievementType {
  total_distance,
  total_time,
  captured_territories,
  total_attack,
  total_defense;

  String get name => toString().split('.').last;
}