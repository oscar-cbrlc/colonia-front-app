enum TeamRole {
  leader,
  moderator,
  member;

  String get name => toString().split('.').last;
}
