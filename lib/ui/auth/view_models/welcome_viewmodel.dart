import 'package:flutter/material.dart';

enum WelcomeState { idle, loading, success, error }

class WelcomeViewModel extends ChangeNotifier {
  WelcomeState _state = WelcomeState.idle;
  String _errorMessage = '';

  WelcomeState get state => _state;
  String get errorMessage => _errorMessage;

  bool get isLoading => _state == WelcomeState.loading;

  void _setState(WelcomeState state) {
    _state = state;
    notifyListeners();
  }

  Future<void> loginWithEmail() async {
    _setState(WelcomeState.loading);
    try {
      // TODO: Auth email
      await Future.delayed(const Duration(seconds: 1));
      _setStateSuccess();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> loginWithGoogle() async {
    _setState(WelcomeState.loading);
    try {
      // TODO: Auth Google
      await Future.delayed(const Duration(seconds: 1));
      _setState(WelcomeState.success);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> loginWithApple() async {
    _setState(WelcomeState.loading);
    try {
      // TODO: Auth Apple
      await Future.delayed(const Duration(seconds: 1));
      _setState(WelcomeState.success);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _setStateSuccess() {
    _setState(WelcomeState.success);
  }

  void _handleError(String message) {
    _errorMessage = message;
    _setState(WelcomeState.error);
  }

  void clearError() {
    _errorMessage = '';
    _setState(WelcomeState.idle);
  }
}
