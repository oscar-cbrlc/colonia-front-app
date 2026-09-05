enum MessageType {
  user_message,
  team_join,
  team_exit,
  team_kick;

  String get name => toString().split('.').last;
  static List<String> get systemTypeNames => values
      .where((type) => type != MessageType.user_message)
      .map((type) => type.name)
      .toList();
}
