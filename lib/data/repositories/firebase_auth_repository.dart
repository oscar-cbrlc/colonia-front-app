import 'dart:convert';
import 'dart:io';
import 'package:colonia_front_app/env/env.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/firebase_auth_result.dart';
import 'auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthRepository extends ChangeNotifier {
  final AuthService _authService;
  final AuthRepository _authRepository;
  bool _googleSignInInitialized = false;

  FirebaseAuthRepository(this._authService, this._authRepository);

  Future<FirebaseAuthResult> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      if (!_googleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId: Env.googleServerClientId
        );
        _googleSignInInitialized = true;
        await googleSignIn.signOut();
      }

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google sign in was cancelled or failed to provide idToken');
      }
      return await _authenticateWithBackend(idToken);
    } catch (e) {
      rethrow;
    }
  }

  Future<FirebaseAuthResult> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final String idToken = appleCredential.identityToken!;
      return await _authenticateWithBackend(idToken);
    } catch (e) {
      rethrow;
    }
  }

  Future<FirebaseAuthResult> _authenticateWithBackend(String idToken) async {
    try {
      final response = await _authService.firebaseAuth(idToken: idToken);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        final result = FirebaseAuthResult.fromJson(jsonMap);

        if (!result.isNewUser && result.user != null && result.accessToken != null) {
          await _authRepository.completeSocialLogin(
            user: result.user!,
            token: result.accessToken!,
          );
        }
        
        return result;
      } else {
        final errorDetail = jsonDecode(response.body)['detail'] ?? 'Authentication failed';
        throw Exception(errorDetail);
      }
    } on SocketException {
      throw Exception('Network error');
    } catch (e) {
      rethrow;
    }
  }
}
