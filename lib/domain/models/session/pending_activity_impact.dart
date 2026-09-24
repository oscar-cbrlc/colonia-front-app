class PendingActivityImpact {
  final double totalDistance;
  final int totalTime;
  final String timestamp;
  final List<Map<String, dynamic>> territories;
  final int? boostId;

  PendingActivityImpact({
    required this.totalDistance,
    required this.totalTime,
    required this.timestamp,
    required this.territories,
    this.boostId,
  });

  Map<String, dynamic> toJson() => {
    'total_distance': totalDistance,
    'total_time': totalTime,
    'timestamp': timestamp,
    'territories': territories,
    'boost_id': boostId,
  };

  factory PendingActivityImpact.fromJson(Map<String, dynamic> json) => PendingActivityImpact(
    totalDistance: (json['total_distance'] as num).toDouble(),
    totalTime: (json['total_time'] as num).toInt(),
    timestamp: json['timestamp'] as String,
    territories: (json['territories'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    boostId: json['boost_id'] as int?,
  );
}
