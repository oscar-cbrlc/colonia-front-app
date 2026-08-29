import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_chat_message.freezed.dart';
part 'team_chat_message.g.dart';

@freezed
abstract class TeamChatMessage with _$TeamChatMessage {
  const factory TeamChatMessage({
    @JsonKey(name: 'chat_message') required String message,
    @JsonKey(name: 'chat_date') required String date,
    @JsonKey(name: 'chat_user') required TeamChatMessageUser user,
  }) = _TeamChatMessage;

  factory TeamChatMessage.fromJson(Map<String, dynamic> json) =>
      _$TeamChatMessageFromJson(json);
}

@freezed
abstract class TeamChatMessageUser with _$TeamChatMessageUser {
  const factory TeamChatMessageUser({
    @JsonKey(name: 'user_id') required int id,
    @JsonKey(name: 'user_thumbnail') required String thumbnail,
    @JsonKey(name: 'user_name') required String name,
    @JsonKey(name: 'role') required String role,
  }) = _TeamChatMessageUser;

  factory TeamChatMessageUser.fromJson(Map<String, dynamic> json) =>
      _$TeamChatMessageUserFromJson(json);
}