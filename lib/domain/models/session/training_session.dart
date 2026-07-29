import 'session_enums.dart';

class TrainingSession {
  final String id;
  final SportActivity activity;
  final TrainingType type;
  final DateTime startTime;
  final DateTime? endTime;
  final double distance; // in meters
  final Duration duration;
  final Duration pace;


  const TrainingSession({
    required this.id,
    required this.activity,
    required this.type,
    required this.startTime,
    this.endTime,
    this.distance = 0.0,
    this.duration = Duration.zero,
    this.pace = Duration.zero,
  });

  TrainingSession copyWith({
    String? id,
    SportActivity? activity,
    TrainingType? type,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    Duration? duration,
    Duration? pace,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      activity: activity ?? this.activity,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      pace: pace ?? this.pace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity': activity.name,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'distance': distance,
      'duration': duration.inMilliseconds,
      'pace': pace.inMilliseconds,
    };
  }

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      activity: SportActivity.values.byName(json['activity'] as String),
      type: TrainingType.values.byName(json['type'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      distance: (json['distance'] as num).toDouble(),
      duration: Duration(milliseconds: json['duration'] as int),
      pace: Duration(milliseconds: json['pace'] as int),
    );
  }
}
