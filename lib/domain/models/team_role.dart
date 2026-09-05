import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_role.freezed.dart';
part 'team_role.g.dart';

@freezed
abstract class TeamRole with _$TeamRole {
  const TeamRole._();

  const factory TeamRole({
    @JsonKey(name: 'team_role_id') required int id,
    @JsonKey(name: 'role_name') required String name,
    String? description,
  }) = _TeamRole;

  factory TeamRole.fromJson(Map<String, dynamic> json) => _$TeamRoleFromJson(json);
}