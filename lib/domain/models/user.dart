import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    @JsonKey(name: 'user_id') required int id,
    required String email,
    required String username,
    @JsonKey(name: 'user_type') int? userType,
    @JsonKey(name: 'user_team') int? userTeam,
    @JsonKey(name: 'team_role') int? teamRole,
    @JsonKey(name: 'total_distance') @Default(0.0) double totalDistance,
    @JsonKey(name: 'total_time') @Default(0) int totalTime,
    @JsonKey(name: 'avatar_head') int? avatarHead,
    @JsonKey(name: 'avatar_neck') int? avatarNeck,
    @JsonKey(name: 'avatar_body') int? avatarBody,
    @JsonKey(name: 'avatar_footwear') int? avatarFootwear,
    @JsonKey(name: 'avatar_color') int? avatarColor,
    @JsonKey(name: 'user_thumbnail') int? userThumbnail,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool get isAdmin => userType == 1;
  bool get hasTeam => userTeam != null;
  bool get canModerateTeam => hasTeam && (teamRole == 1 || teamRole == 2);
  bool get isTeamOwner => hasTeam && teamRole == 2;

  bool get hasCustomAvatar =>
      avatarHead != null ||
      avatarNeck != null ||
      avatarBody != null ||
      avatarFootwear != null;
}

@freezed
abstract class LoginResult with _$LoginResult {
  const LoginResult._();

  const factory LoginResult({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'token_type') required String tokenType,
    required User user,
  }) = _LoginResult;

  factory LoginResult.fromJson(Map<String, dynamic> json) => _$LoginResultFromJson(json);
}