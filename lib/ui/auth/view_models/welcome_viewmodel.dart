import 'package:colonia_front_app/data/models/firebase_auth_result.dart';
import 'package:colonia_front_app/data/repositories/firebase_auth_repository.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

enum WelcomeState { idle, loading, success, error }

class WelcomeViewModel extends ChangeNotifier {
  final FirebaseAuthRepository _firebaseAuthRepository;

  WelcomeViewModel(this._firebaseAuthRepository);

  WelcomeState _state = WelcomeState.idle;
  String _errorMessage = '';
  FirebaseAuthResult? _authResult;

  WelcomeState get state => _state;
  String get errorMessage => _errorMessage;
  FirebaseAuthResult? get authResult => _authResult;

  bool get isLoading => _state == WelcomeState.loading;

  void _setState(WelcomeState state) {
    _state = state;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    _setState(WelcomeState.loading);
    try {
      _authResult = await _firebaseAuthRepository.signInWithGoogle();
      _setState(WelcomeState.success);
    } catch (e, stackTrace) {
      developer.log('Google login error', error: e, stackTrace: stackTrace, name: 'WelcomeViewModel');
      _handleError('Google authentication failed. Please try again.');
    }
  }

  Future<void> loginWithApple() async {
    _setState(WelcomeState.loading);
    try {
      _authResult = await _firebaseAuthRepository.signInWithApple();
      _setState(WelcomeState.success);
    } catch (e, stackTrace) {
      developer.log('Apple login error', error: e, stackTrace: stackTrace, name: 'WelcomeViewModel');
      _handleError('Apple authentication failed. Please try again.');
    }
  }

  void _handleError(String message) {
    _errorMessage = message;
    _setState(WelcomeState.error);
  }

  void clearError() {
    _errorMessage = '';
    _authResult = null;
    _setState(WelcomeState.idle);
  }
}
