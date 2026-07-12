import 'package:colonia_front_app/domain/models/user.dart';

class FirebaseAuthResult {
  final bool isNewUser;
  final String email;
  final String? providerUid;
  final String? accessToken;
  final User? user;

  FirebaseAuthResult({
    required this.isNewUser,
    required this.email,
    this.providerUid,
    this.accessToken,
    this.user,
  });

  factory FirebaseAuthResult.fromJson(Map<String, dynamic> json) {
    return FirebaseAuthResult(
      isNewUser: json['is_new_user'] ?? false,
      email: json['email'] ?? '',
      providerUid: json['provider_uid'],
      accessToken: json['access_token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}