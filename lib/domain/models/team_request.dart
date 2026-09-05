import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_request.freezed.dart';
part 'team_request.g.dart';

@freezed
abstract class TeamRequest with _$TeamRequest {
  const factory TeamRequest({
    @JsonKey(name: 'request_timestamp') required String requestTimestamp,
    @JsonKey(name: 'user') TeamRequestUser? user,
    @JsonKey(name: 'team') TeamRequestTeam? team,
  }) = _TeamRequest;

  factory TeamRequest.fromJson(Map<String, dynamic> json) =>
      _$TeamRequestFromJson(json);
}

@freezed
abstract class TeamRequestUser with _$TeamRequestUser {
  const factory TeamRequestUser({
    @JsonKey(name: 'user_id') required int id,
    @JsonKey(name: 'user_name') required String name,
    @JsonKey(name: 'user_thumbnail') String? thumbnail,
  }) = _TeamRequestUser;

  factory TeamRequestUser.fromJson(Map<String, dynamic> json) =>
      _$TeamRequestUserFromJson(json);
}

@freezed
abstract class TeamRequestTeam with _$TeamRequestTeam {
  const factory TeamRequestTeam({
    @JsonKey(name: 'team_id') required int id,
    @JsonKey(name: 'team_name') required String name,
    @JsonKey(name: 'team_color') required int color,
  }) = _TeamRequestTeam;

  factory TeamRequestTeam.fromJson(Map<String, dynamic> json) =>
      _$TeamRequestTeamFromJson(json);
}
