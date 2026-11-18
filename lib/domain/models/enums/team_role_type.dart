import 'package:colonia_front_app/l10n/app_localizations.dart';

enum TeamRoleType {
  leader,
  moderator,
  member;

  String get name => toString().split('.').last;

  String getLocaleName(AppLocalizations locale) {
    switch (this) {
      case leader:
        return locale.teamRoleLeader;
      case moderator:
        return locale.teamRoleModerator;
      case member:
        return locale.teamRoleMember;
    }
  }

  static TeamRoleType fromString(String role) {
    return TeamRoleType.values.firstWhere(
      (e) => e.name.toLowerCase() == role.toLowerCase(),
      orElse: () => TeamRoleType.member,
    );
  }
}
