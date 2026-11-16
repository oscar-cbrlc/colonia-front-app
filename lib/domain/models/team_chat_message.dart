import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:colonia_front_app/domain/models/enums/message_type.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';

part 'team_chat_message.freezed.dart';
part 'team_chat_message.g.dart';

@freezed
abstract class TeamChatMessage with _$TeamChatMessage {
  const TeamChatMessage._();

  const factory TeamChatMessage({
    @JsonKey(name: "message_id") required int id,
    @JsonKey(name: 'chat_message') required String message,
    @JsonKey(name: 'message_date') String? date,
    @JsonKey(name: 'message_type') String? type,
    @JsonKey(name: 'user') TeamChatMessageUser? user,
    @JsonKey(name: 'user_trigger') String? userTrigger,
  }) = _TeamChatMessage;

  factory TeamChatMessage.fromJson(Map<String, dynamic> json) =>
      _$TeamChatMessageFromJson(json);

  bool get isUserMessage =>
      type == null ||
      type == 'user_message' ||
      type == MessageType.user_message.name;

  String getLocalizedSystemMessage(AppLocalizations locale) {
    final username = user?.name ?? 'User';
    final trigger = userTrigger ?? 'User';
    switch (type) {
      case 'team_join':
        return locale.teamJoin(username);
      case 'team_exit':
        return locale.teamExit(username);
      case 'team_kick':
        return locale.teamKick(trigger, username);
      case 'team_accept':
        return locale.teamAccept(trigger, username);
      case 'team_promote':
        return locale.teamPromote(trigger, username);
      case 'team_demote':
        return locale.teamDemote(trigger, username);
      default:
        return message;
    }
  }
}

@freezed
abstract class TeamChatMessageUser with _$TeamChatMessageUser {
  const factory TeamChatMessageUser({
    @JsonKey(name: 'user_id') required int id,
    @JsonKey(name: 'user_thumbnail') String? thumbnail,
    @JsonKey(name: 'username') required String name,
    @JsonKey(name: 'role') String? role,
  }) = _TeamChatMessageUser;

  factory TeamChatMessageUser.fromJson(Map<String, dynamic> json) =>
      _$TeamChatMessageUserFromJson(json);
}
