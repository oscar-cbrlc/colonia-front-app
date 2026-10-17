import 'package:colonia_front_app/domain/models/active_challenge.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'started_challenge.freezed.dart';
part 'started_challenge.g.dart';

@freezed
abstract class StartedChallenge with _$StartedChallenge {
  const StartedChallenge._();

  const factory StartedChallenge({
    @JsonKey(name: 'active_challenge') required ActiveChallenge activeChallenge,
    @JsonKey(name: 'progress') required int progress,
    @JsonKey(name: 'is_complete') required bool isComplete,
  }) = _StartedChallenge;

  factory StartedChallenge.fromJson(Map<String, dynamic> json) => _$StartedChallengeFromJson(json);
}