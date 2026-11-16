enum MessageType {
  user_message,
  team_join,
  team_exit,
  team_kick,
  team_accept,
  team_promote,
  team_demote;

  String get name => toString().split('.').last;
  static List<String> get systemTypeNames => values
      .where((type) => type != MessageType.user_message)
      .map((type) => type.name)
      .toList();
}
