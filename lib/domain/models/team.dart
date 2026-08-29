import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
abstract class Team with _$Team {
  const factory Team({
    @JsonKey(name: 'team_id') required int id,
    @JsonKey(name: 'team_name') required String name,
    @JsonKey(name: 'team_description') String? description,
    @JsonKey(name: 'team_color') required int color,
    @JsonKey(name: 'is_public') required bool isPublic,
    TeamStats? stats,
    List<TeamMemberSummary>? members,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) =>
      _$TeamFromJson(json);
}

@freezed
abstract class TeamStats with _$TeamStats {
  const factory TeamStats({
    @JsonKey(name: 'member_count') required int memberCount,
    @JsonKey(name: 'territories_controlled') required int territoriesControlled,
    @JsonKey(name: 'total_defense_points') required double totalDefensePoints,
  }) = _TeamStats;

  factory TeamStats.fromJson(Map<String, dynamic> json) =>
      _$TeamStatsFromJson(json);
}

@freezed
abstract class TeamMemberSummary with _$TeamMemberSummary {
  const factory TeamMemberSummary({
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'user_name') required String userName,
    @JsonKey(name: 'user_thumbnail') String? userThumbnail,
    @JsonKey(name: 'team_role') required String role,
  }) = _TeamMemberSummary;

  factory TeamMemberSummary.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberSummaryFromJson(json);
}
