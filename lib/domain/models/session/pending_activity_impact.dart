class PendingActivityImpact {
  final double totalDistance;
  final int totalTime;
  final String timestamp;
  final List<Map<String, dynamic>> territories;
  final int? boostId;
  final int secondsWalk;
  final int secondsRun;
  final int secondsBike;
  final double distanceWalk;
  final double distanceRun;
  final double distanceBike;

  PendingActivityImpact({
    required this.totalDistance,
    required this.totalTime,
    required this.timestamp,
    required this.territories,
    this.boostId,
    this.secondsWalk = 0,
    this.secondsRun = 0,
    this.secondsBike = 0,
    this.distanceWalk = 0.0,
    this.distanceRun = 0.0,
    this.distanceBike = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'total_distance': totalDistance,
    'total_time': totalTime,
    'timestamp': timestamp,
    'territories': territories,
    'boost_id': boostId,
    'seconds_walk': secondsWalk,
    'seconds_run': secondsRun,
    'seconds_bike': secondsBike,
    'distance_walk': distanceWalk,
    'distance_run': distanceRun,
    'distance_bike': distanceBike,
  };

  factory PendingActivityImpact.fromJson(Map<String, dynamic> json) => PendingActivityImpact(
    totalDistance: (json['total_distance'] as num).toDouble(),
    totalTime: (json['total_time'] as num).toInt(),
    timestamp: json['timestamp'] as String,
    territories: (json['territories'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    boostId: json['boost_id'] as int?,
    secondsWalk: (json['seconds_walk'] as num?)?.toInt() ?? 0,
    secondsRun: (json['seconds_run'] as num?)?.toInt() ?? 0,
    secondsBike: (json['seconds_bike'] as num?)?.toInt() ?? 0,
    distanceWalk: (json['distance_walk'] as num?)?.toDouble() ?? 0.0,
    distanceRun: (json['distance_run'] as num?)?.toDouble() ?? 0.0,
    distanceBike: (json['distance_bike'] as num?)?.toDouble() ?? 0.0,
  );
}
