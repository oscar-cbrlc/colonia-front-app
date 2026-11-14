import 'dart:convert';
import 'dart:io';
import 'package:colonia_front_app/env/env.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import '../services/api/auth_service.dart';
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
          serverClientId: Env.googleServerClientId,
        );
        _googleSignInInitialized = true;
      }

      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final fb_auth.AuthCredential credential = fb_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final fb_auth.UserCredential userCredential =
          await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);

      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Google sign in was cancelled or failed to provide Firebase idToken');
      }
      return await _authenticateWithBackend(firebaseIdToken);
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

      final fb_auth.AuthCredential credential = fb_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
      );

      final fb_auth.UserCredential userCredential =
          await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);

      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Apple sign in was cancelled or failed to provide Firebase idToken');
      }

      return await _authenticateWithBackend(firebaseIdToken);
    } catch (e) {
      rethrow;
    }
  }

  Future<FirebaseAuthResult> _authenticateWithBackend(String firebaseIdToken) async {
    try {
      var response = await _authService.sessionLoginFirebase(idToken: firebaseIdToken);

      if (response.statusCode == 404) {
        response = await _authService.registerFirebase(idToken: firebaseIdToken);
      }

      if (response.statusCode == 404) {
        response = await _authService.firebaseAuth(idToken: firebaseIdToken);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);
        final result = FirebaseAuthResult.fromJson(jsonMap);

        if (result.user != null && result.accessToken != null && result.refreshToken != null) {
          await _authRepository.completeSocialLogin(
            user: result.user!,
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
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
