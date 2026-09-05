enum UserType {
  player,
  admin;

  String get name  => toString().split('.').last;
}