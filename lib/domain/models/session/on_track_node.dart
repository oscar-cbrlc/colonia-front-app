enum OnTrackNodeType { path, area }

class OnTrackNode  {
  final double lat;
  final double lon;
  final double pace;
  final double points;
  final DateTime timestamp;
  final OnTrackNodeType type;
  final int secondsWalk;
  final int secondsRun;
  final int secondsBike;
  final double distanceWalk;
  final double distanceRun;
  final double distanceBike;

  OnTrackNode({
    required this.lat,
    required this.lon,
    required this.pace,
    required this.points,
    required this.timestamp,
    this.secondsWalk = 0,
    this.secondsRun = 0,
    this.secondsBike = 0,
    this.distanceWalk = 0.0,
    this.distanceRun = 0.0,
    this.distanceBike = 0.0,
    this.type = OnTrackNodeType.path,
  });
}