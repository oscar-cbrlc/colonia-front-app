enum OnTrackNodeType { path, area }

class OnTrackNode  {
  final double lat;
  final double lon;
  final double pace;
  final double points;
  final DateTime timestamp;
  final OnTrackNodeType type;

  OnTrackNode({
    required this.lat,
    required this.lon,
    required this.pace,
    required this.points,
    required this.timestamp,
    this.type = OnTrackNodeType.path,
  });
}