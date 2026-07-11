import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

enum LoginValidationError { none, empty }

class LoginPasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  String _email = '';
  String _pass = '';
  bool _isLoading = false;
  String? _errorMessage;

  LoginValidationError _error = LoginValidationError.none;
  LoginValidationError get error => _error;

  String get email => _email;
  String get password => _pass;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LoginPasswordViewModel(this._authRepository);

  void setEmail(String email) {
    _email = email;
    notifyListeners();
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
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.loginUser(email: _email, password: _pass);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error during login',
        error: e,
        stackTrace: stackTrace,
        name: 'LoginPasswordViewModel',
      );
      _isLoading = false;
      if (e is Exception) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }
}