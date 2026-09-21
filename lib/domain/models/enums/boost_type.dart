enum BoostType {
  score,
  impact_area,
  impact_distance;

  String get name => toString().split('.').last;
}
