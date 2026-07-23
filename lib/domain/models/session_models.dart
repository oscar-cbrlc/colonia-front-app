import 'dart:ui';

enum SportActivity {
  walking,
  running,
  cycling
}

enum TrainingType {
  free,
  distance,
  duration,
  pace,
  timeTrial
}

enum PlayingState {
  playing,
  paused,
  stopped
}

class PlayNode {
  final PlayingState state;
  final Map<PlayingState, VoidCallback> stateCallsMap;

  const PlayNode({
    required this.state,
    required this.stateCallsMap,
  });

  Map<PlayingState, VoidCallback> get stateCalls => stateCallsMap;
}

class PlayNodeMachine {
  PlayNode _playNode;

  PlayNodeMachine({
    required PlayNode playNode,
  }) : _playNode = playNode;

  PlayingState get currentState => _playNode.state;

  void actionSignal(PlayNode playNode) {
    VoidCallback? call = _playNode.stateCalls[playNode.state];
    if (call != null) {
      _playNode = playNode;
      call.call();
    }
  }

  void transitionTo(PlayNode nextNode) {
    if (_playNode.stateCalls.containsKey(nextNode.state)) {
      _playNode = nextNode;
      _playNode.stateCalls[nextNode.state]?.call();
    }
  }
}