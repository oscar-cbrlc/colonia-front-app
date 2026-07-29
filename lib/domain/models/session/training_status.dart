import 'session_enums.dart';

class TrainingStatus {
  final PlayingState state;
  final DateTime lastUpdate;

  const TrainingStatus({
    this.state = PlayingState.stopped,
    required this.lastUpdate,
  });

  TrainingStatus copyWith({
    PlayingState? state,
    DateTime? lastUpdate,
  }) {
    return TrainingStatus(
      state: state ?? this.state,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
