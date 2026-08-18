import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
abstract class Team with _$Team {
  const Team._();

  const factory Team({
    @JsonKey(name: 'team_id') required int id,
    @JsonKey(name: 'team_name') required String name,
    @JsonKey(name: 'team_description') required String description,
    @JsonKey(name: 'team_color') required int color,
    @JsonKey(name: 'is_public') required bool isPublic,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
}