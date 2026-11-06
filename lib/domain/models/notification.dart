import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

enum NotificationType {
  global,
  join_team_request_accepted,
  join_team_request_denied,
  team_kick;

  String get name => toString().split('.').last;

  String getLocaleName(AppLocalizations locale, {String name = ''}) {
    switch (this) {
      case join_team_request_accepted:
        return locale.notification_join_team_request_accepted(name);
      case join_team_request_denied:
        return locale.notification_join_team_request_denied(name);
      case NotificationType.team_kick:
        return locale.notification_team_kick(name);
      case global:
        return locale.notification_event(name);
    }
  }
}

@freezed
abstract class Notification with _$Notification {
  const Notification._();
  const factory Notification({
    @JsonKey(name: 'notification_id') required int id,
    @JsonKey(name: 'notification_type') required String type,
    @JsonKey(name: 'notification_message') required String message,
    @JsonKey(name: 'notification_date') required String date
  }) = _Notification;
  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);

  String get eType {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.global,
    ).name;
  }

  String getLocaleMessage(AppLocalizations locale) {
    try {
      final enumValue = NotificationType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => NotificationType.global,
      );
      return enumValue.getLocaleName(locale, name: message);
    } catch (_) {
      return message;
    }
  }

  Map<String, String> getMessageParts(AppLocalizations locale) {
    try {
      final enumValue = NotificationType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => NotificationType.global,
      );
      const placeholder = '___PLACEHOLDER___';
      final fullTextWithPlaceholder = enumValue.getLocaleName(locale, name: placeholder);
      if (fullTextWithPlaceholder.contains(placeholder)) {
        final parts = fullTextWithPlaceholder.split(placeholder);
        return {
          'before': parts[0],
          'value': message,
          'after': parts.length > 1 ? parts[1] : '',
        };
      }
    } catch (_) {}
    return {
      'before': getLocaleMessage(locale),
      'value': '',
      'after': '',
    };
  }

  bool get isGlobal => type == 'global_notification' || type == NotificationType.global.name;
  bool get isPersonal => !isGlobal;
}