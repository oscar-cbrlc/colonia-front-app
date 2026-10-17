import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'active_challenge.freezed.dart';
part 'active_challenge.g.dart';

enum ChallengeDifficulty {
  easy,
  medium,
  hard;

  String getLocale(AppLocalizations locale) {
    switch (this) {
      case ChallengeDifficulty.easy:
        return locale.easy;
      case ChallengeDifficulty.medium:
        return locale.medium;
      case ChallengeDifficulty.hard:
        return locale.hard;
    }
  }
}

enum ChallengeObjectiveType {
  total_time,
  walk_time,
  run_time,
  bike_time,
  total_distance,
  walk_distance,
  run_distance,
  bike_distance,
  territories_captured,
  route;

  String get name => toString().split('.').last;

  String getLocale(AppLocalizations locale) {
    switch (this) {
      case ChallengeObjectiveType.total_time:
        return locale.total_time;
      case ChallengeObjectiveType.walk_time:
        return locale.walk_time;
      case ChallengeObjectiveType.run_time:
        return locale.run_time;
      case ChallengeObjectiveType.bike_time:
        return locale.bike_time;
      case ChallengeObjectiveType.total_distance:
        return locale.total_distance;
      case ChallengeObjectiveType.walk_distance:
        return locale.walk_distance;
      case ChallengeObjectiveType.run_distance:
        return locale.run_distance;
      case ChallengeObjectiveType.bike_distance:
        return locale.bike_distance;
      case ChallengeObjectiveType.territories_captured:
        return locale.territories_captured;
      case ChallengeObjectiveType.route:
        return locale.route;
    }
  }
}

@freezed
abstract class ActiveChallenge with _$ActiveChallenge {
  const ActiveChallenge._();
  const factory ActiveChallenge({
    @JsonKey(name: 'active_challenge_id') required int id,
    @JsonKey(name: 'challenge') required Challenge challenge,
    @JsonKey(name: 'challenge_start_date') required DateTime startDate,
    @JsonKey(name: 'challenge_end_date') required DateTime endDate,
  }) = _ActiveChallenge;

  factory ActiveChallenge.fromJson(Map<String, dynamic> json) => _$ActiveChallengeFromJson(json);
}

@freezed
abstract class Challenge with _$Challenge {
  const Challenge._();
  const factory Challenge({
      @JsonKey(name: 'challenge_id') required int id,
      @JsonKey(name: 'challenge_name') required String name,
      @JsonKey(name: 'challenge_reward') required ChallengeReward reward,
      @JsonKey(name: 'objective_type') required String objectiveType,
      @JsonKey(name: 'objective_condition') required Map<String, dynamic> objectiveCondition,
      @JsonKey(name: 'challenge_difficulty') required String challengeDifficulty,
      @JsonKey(name: 'challenge_xp_reward') required int xpReward,
    }) = _Challenge;

  ChallengeDifficulty get difficulty {
    switch (challengeDifficulty) {
      case 'easy':
        return ChallengeDifficulty.easy;
      case 'medium':
        return ChallengeDifficulty.medium;
      case 'hard':
        return ChallengeDifficulty.hard;
      default:
        throw Exception('Invalid challenge difficulty: $challengeDifficulty');
    }
  }

  ChallengeObjectiveType get objective {
    switch(objectiveType) {
      case 'total_time':
        return ChallengeObjectiveType.total_time;
      case 'walk_time':
        return ChallengeObjectiveType.walk_time;
      case 'run_time':
        return ChallengeObjectiveType.run_time;
      case 'bike_time':
        return ChallengeObjectiveType.bike_time;
      case 'total_distance':
        return ChallengeObjectiveType.total_distance;
      case 'walk_distance':
        return ChallengeObjectiveType.walk_distance;
      case 'run_distance':
        return ChallengeObjectiveType.run_distance;
      case 'bike_distance':
        return ChallengeObjectiveType.bike_distance;
      case 'territories_captured':
        return ChallengeObjectiveType.territories_captured;
      case 'route':
        return ChallengeObjectiveType.route;
      default:
        throw Exception('Invalid challenge objective type: $objectiveType');
    }
  }

  Map<ChallengeObjectiveType, int> get conditionMap {
    final condition = <ChallengeObjectiveType, int>{};
    if (objectiveCondition.containsKey('total_time')) {
      condition[ChallengeObjectiveType.total_time] = objectiveCondition['total_time'] as int;
    }
    if (objectiveCondition.containsKey('walk_time')) {
      condition[ChallengeObjectiveType.walk_time] = objectiveCondition['walk_time'] as int;
    }
    if (objectiveCondition.containsKey('run_time')) {
      condition[ChallengeObjectiveType.run_time] = objectiveCondition['run_time'] as int;
    }
    if (objectiveCondition.containsKey('bike_time')) {
      condition[ChallengeObjectiveType.bike_time] = objectiveCondition['bike_time'] as int;
    }
    if (objectiveCondition.containsKey('total_distance')) {
      condition[ChallengeObjectiveType.total_distance] = objectiveCondition['total_distance'] as int;
    }
    if (objectiveCondition.containsKey('walk_distance')) {
      condition[ChallengeObjectiveType.walk_distance] = objectiveCondition['walk_distance'] as int;
    }

    if (objectiveCondition.containsKey('run_distance')) {
      condition[ChallengeObjectiveType.run_distance] = objectiveCondition['run_distance'] as int;
    }

    if (objectiveCondition.containsKey('bike_distance')) {
      condition[ChallengeObjectiveType.bike_distance] = objectiveCondition['bike_distance'] as int;
    }
    if (objectiveCondition.containsKey('territories_captured')) {
      condition[ChallengeObjectiveType.territories_captured] = objectiveCondition['territories_captured'] as int;
    }
    if (objectiveCondition.containsKey('route')) {
      condition[ChallengeObjectiveType.route] = objectiveCondition['route'] as int;
    }
    return condition;
  }

  factory Challenge.fromJson(Map<String, dynamic> json) => _$ChallengeFromJson(json);
}

@freezed
abstract class ChallengeReward with _$ChallengeReward {
  const ChallengeReward._();
  const factory ChallengeReward({
    @JsonKey(name: 'reward_id') required int id,
    @JsonKey(name: 'reward_type') required String type,
    @JsonKey(name: 'reward_amount') required int amount,
    @JsonKey(name: 'reward_item') required AvatarItem? avatarItem,
    @JsonKey(name: 'reward_boost') required Boost? boost,
  }) = _ChallengeReward;

  factory ChallengeReward.fromJson(Map<String, dynamic> json) => _$ChallengeRewardFromJson(json);
}