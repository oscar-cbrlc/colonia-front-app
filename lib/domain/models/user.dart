import 'package:colonia_front_app/domain/models/enums/team_role.dart';
import 'package:colonia_front_app/domain/models/enums/user_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    @JsonKey(name: 'user_id') required int id,
    @JsonKey(name: 'user_name') required String username,
    String? email,
    @JsonKey(name: 'user_type') String? userType,
    @JsonKey(name: 'coin_amount') int? coinAmount,
    UserAvatar? avatar,
    UserStats? stats,
    UserTeam? team,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool get isAdmin => userType?.toLowerCase() == UserType.admin.name.toLowerCase();
  bool get hasTeam => team != null;
  
  bool get canModerateTeam {
    if (!hasTeam) return false;
    final role = team!.role.toLowerCase();
    return role == TeamRole.moderator.name.toLowerCase() || 
           role == TeamRole.leader.name.toLowerCase();
  }

  bool get isTeamLeader => hasTeam && team?.role.toLowerCase() == TeamRole.leader.name.toLowerCase();
  bool get isTeamMod => hasTeam && team?.role.toLowerCase() == TeamRole.moderator.name.toLowerCase();

  bool get hasCustomAvatar =>
      avatar?.head != null ||
      avatar?.neck != null ||
      avatar?.body != null ||
      avatar?.footwear != null;
}

@freezed
abstract class UserAvatar with _$UserAvatar {
  const factory UserAvatar({
    @JsonKey(name: 'user_thumbnail') String? thumbnailUrl,
    @JsonKey(name: 'model_url') String? modelUrl,
    @JsonKey(name: 'avatar_head') int? head,
    @JsonKey(name: 'avatar_neck') int? neck,
    @JsonKey(name: 'avatar_body') int? body,
    @JsonKey(name: 'avatar_footwear') int? footwear,
    @JsonKey(name: 'avatar_color') int? color,
  }) = _UserAvatar;

  factory UserAvatar.fromJson(Map<String, dynamic> json) => _$UserAvatarFromJson(json);
}

@freezed
abstract class UserStats with _$UserStats {
  const factory UserStats({
    @JsonKey(name: 'total_time') @Default(0.0) double totalTime,
    @JsonKey(name: 'total_distance') @Default(0.0) double totalDistance,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
}

@freezed
abstract class UserTeam with _$UserTeam {
  const factory UserTeam({
    @JsonKey(name: 'team_id') required int id,
    @JsonKey(name: 'team_name') required String name,
    @JsonKey(name: 'team_role') required String role,
    @JsonKey(name: 'team_color') required int color,
  }) = _UserTeam;

  factory UserTeam.fromJson(Map<String, dynamic> json) => _$UserTeamFromJson(json);
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

  String get authorizationHeader => '$tokenType $accessToken';
}