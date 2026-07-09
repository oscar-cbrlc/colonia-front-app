import 'package:flutter/material.dart';

enum LoginValidationError { none, empty }

class LoginPasswordViewModel extends ChangeNotifier {
  String _email = '';
  String _pass = '';
  bool _isLoading = false;

  LoginValidationError _error = LoginValidationError.none;
  LoginValidationError get error => _error;

  String get email => _email;
  String get password => _pass;
  bool get isLoading => _isLoading;

  void setEmail(String email) {
    _email = email;
  }

  void setPass(String pass) {
    _pass = pass;
    validatePass(pass);
    notifyListeners();
  }

  void validatePass(String pass) {
    if (pass.isEmpty) {
      _error = LoginValidationError.empty;
    }
    else {
      _error = LoginValidationError.none;
    }
    notifyListeners();
  }

  void clearError() {
    _error = LoginValidationError.none;
    notifyListeners();
  }

  Future<bool> login() async {
    validatePass(_pass);
    if (_error != LoginValidationError.none) return false;
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: send to back etc
      await Future.delayed(const Duration(milliseconds: 1200));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      //_errorMessage = 'Error de conexión. Inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }
}