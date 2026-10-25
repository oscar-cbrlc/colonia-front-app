import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/boost.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/utils/time_converter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'active_challenge.freezed.dart';
part 'active_challenge.g.dart';

enum ChallengeDifficulty {
  easy,
  normal,
  hard;

  String getLocale(AppLocalizations locale) {
    switch (this) {
      case ChallengeDifficulty.easy:
        return locale.easy;
      case ChallengeDifficulty.normal:
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
  captured_territories,
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
      case ChallengeObjectiveType.captured_territories:
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
      @JsonKey(name: 'challenge_name') String? name,
      @JsonKey(name: 'objective_type') required String objectiveType,
      @JsonKey(name: 'objective_condition') required Map<String, dynamic> objectiveCondition,
      @JsonKey(name: 'challenge_difficulty') required String challengeDifficulty,
      @JsonKey(name: 'challenge_xp_reward') required int xpReward,
      @JsonKey(name: 'boost_reward') required List<BoostReward> boostRewards,
      @JsonKey(name: 'item_reward') AvatarItem? avatarItemReward,
    }) = _Challenge;

  ChallengeDifficulty get difficulty {
    switch (challengeDifficulty) {
      case 'easy':
        return ChallengeDifficulty.easy;
      case 'normal':
        return ChallengeDifficulty.normal;
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
      case 'captured_territories':
        return ChallengeObjectiveType.captured_territories;
      case 'route':
        return ChallengeObjectiveType.route;
      default:
        throw Exception('Invalid challenge objective type: $objectiveType');
    }
  }

  Object get objectiveValue => objectiveCondition[objective.name]!;

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
      condition[ChallengeObjectiveType.captured_territories] = objectiveCondition['territories_captured'] as int;
    }
    if (objectiveCondition.containsKey('route')) {
      condition[ChallengeObjectiveType.route] = objectiveCondition['route'] as int;
    }
    return condition;
  }

  String getDescription(AppLocalizations locale) {
    switch(objective) {
      case ChallengeObjectiveType.total_time:
        return locale.totalTimeChallengeDescription(conditionMap[ChallengeObjectiveType.total_time]!);
      case ChallengeObjectiveType.walk_time:
        return locale.activityTimeChallengeDescription(conditionMap[ChallengeObjectiveType.walk_time]!, locale.walk);
      case ChallengeObjectiveType.run_time:
        return locale.activityTimeChallengeDescription(conditionMap[ChallengeObjectiveType.run_time]!, locale.run);
      case ChallengeObjectiveType.bike_time:
        return locale.activityTimeChallengeDescription(conditionMap[ChallengeObjectiveType.bike_time]!, locale.bike);
      case ChallengeObjectiveType.total_distance:
        return locale.totalDistanceChallengeDescription(conditionMap[ChallengeObjectiveType.total_distance]!);
      case ChallengeObjectiveType.walk_distance:
        return locale.activityDistanceChallengeDescription(conditionMap[ChallengeObjectiveType.walk_distance]!, locale.walk);
      case ChallengeObjectiveType.run_distance:
        return locale.activityDistanceChallengeDescription(conditionMap[ChallengeObjectiveType.run_distance]!, locale.run);
      case ChallengeObjectiveType.bike_distance:
        return locale.activityDistanceChallengeDescription(conditionMap[ChallengeObjectiveType.bike_distance]!, locale.bike);
      case ChallengeObjectiveType.captured_territories:
        return locale.territoriesCapturedChallengeDescription(conditionMap[ChallengeObjectiveType.captured_territories]!);
      case ChallengeObjectiveType.route:
        return locale.routeChallengeDescription;
    }
  }

  Map<String, String> getDescriptionParts(AppLocalizations locale) {
    return {
      'action': objective == ChallengeObjectiveType.captured_territories ? locale.capture : locale.complete,
      'value': objective == ChallengeObjectiveType.total_time
                || objective == ChallengeObjectiveType.walk_time
                || objective == ChallengeObjectiveType.run_time
                || objective == ChallengeObjectiveType.bike_time?
                  TimeConverter.secondsToHours(int.parse(objectiveValue.toString())).round().toString() :
                objective == ChallengeObjectiveType.total_distance
                || objective == ChallengeObjectiveType.walk_distance
                || objective == ChallengeObjectiveType.run_distance
                || objective == ChallengeObjectiveType.bike_distance?
                  TimeConverter.metersToKilometers(int.parse(objectiveValue.toString())).round().toString() :
                objectiveValue.toString(),
      'unit': objective == ChallengeObjectiveType.total_time? locale.hoursOfTotalActivity :
              objective == ChallengeObjectiveType.total_distance? locale.kmOfTotalActivity :
              objective == ChallengeObjectiveType.captured_territories? locale.territories.toLowerCase() :
              objective == ChallengeObjectiveType.walk_time? locale.hoursOfWalkActivity :
              objective == ChallengeObjectiveType.run_time? locale.hoursOfRunActivity :
              objective == ChallengeObjectiveType.bike_time? locale.hoursOfBikeActivity :
              objective == ChallengeObjectiveType.walk_distance? locale.kmOfWalkActivity :
              objective == ChallengeObjectiveType.run_distance? locale.kmOfRunActivity :
              objective == ChallengeObjectiveType.bike_distance? locale.kmOfBikeActivity :
              '?'
    };
  }

  IconData get objectiveIcon {
    switch(objective) {
      case ChallengeObjectiveType.total_time:
        return Icons.timer_sharp;
      case ChallengeObjectiveType.walk_time:
        return Icons.directions_walk_sharp;
      case ChallengeObjectiveType.run_time:
        return Icons.directions_run_sharp;
      case ChallengeObjectiveType.bike_time:
        return Icons.directions_bike_sharp;
      case ChallengeObjectiveType.total_distance:
        return Icons.linear_scale;
      case ChallengeObjectiveType.walk_distance:
        return Icons.directions_walk_sharp;
      case ChallengeObjectiveType.run_distance:
        return Icons.directions_run_sharp;
      case ChallengeObjectiveType.bike_distance:
        return Icons.directions_bike_sharp;
      case ChallengeObjectiveType.captured_territories:
        return Icons.hexagon_outlined;
      case ChallengeObjectiveType.route:
        return Icons.route;
    }
  }

  factory Challenge.fromJson(Map<String, dynamic> json) => _$ChallengeFromJson(json);
}

@freezed
abstract class BoostReward with _$BoostReward {
  const BoostReward._();
  const factory BoostReward({
    @JsonKey(name: 'boost') required Boost boost,
    @JsonKey(name: 'boost_amount') required int amount,
  }) = _BoostReward;

  factory BoostReward.fromJson(Map<String, dynamic> json) => _$BoostRewardFromJson(json);
}