import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

@freezed
abstract class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    @JsonKey(name: 'achievement_id') required int id,
    @JsonKey(name: 'achievement_name') required String name,
    @JsonKey(name: 'achievement_type') required String type,
    @JsonKey(name: 'achievement_objective') required int objective,
    @JsonKey(name: 'achievement_acquisition_date') String? acquisitionDate  ,

  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
}