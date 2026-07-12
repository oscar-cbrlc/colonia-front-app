import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

enum UsernameValidationError { none, empty, invalidFormat }

class CreateUsernameViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  String _email = '';
  String _pass = '';
  String _username = '';
  bool _isLoading = false;
  bool _isSocialAuth = false;
  String? _errorMessage;

  UsernameValidationError _error = UsernameValidationError.none;

  UsernameValidationError get error => _error;
  bool get isLoading => _isLoading;
  bool get isSocialAuth => _isSocialAuth;
  String? get errorMessage => _errorMessage;
  String get username => _username;

  CreateUsernameViewModel(this._authRepository);

  void setSocialAuth(bool value) {
    _isSocialAuth = value;
  }

  // 4 to 16 chars, letters, digits, -, _, !, ?
  final passRegex = RegExp(
    r"^(?=.{4,16}$)[a-zA-Z0-9_\-\!\?]+$",
  );

  bool get hasLengthCharacters => _username.length >= 4 && _username.length <= 16;
  bool get hasOnlyValidChars => RegExp(r'^[a-zA-Z0-9_\-\!\?]+$').hasMatch(_username);

  void setEmail(String email) {
    _email = email;
  }

  void setPass(String pass) {
    _pass = pass;
  }

  void setUsername(String username) {
    _username = username.trim();
    validateUsername(_username);
    notifyListeners();
  }

  void validateUsername(String username) {
    if (username.isEmpty) {
      _error = UsernameValidationError.empty;
    } else if (!passRegex.hasMatch(username)) {
      _error = UsernameValidationError.invalidFormat;
    } else {
      _error = UsernameValidationError.none;
    }
    notifyListeners();
  }

  void clearError() {
    _error = UsernameValidationError.none;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submitRegistrationAndLogin() async {
    validateUsername(_username);
    
    if (_error != UsernameValidationError.none) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.registerUser(
          email: _email,
          username: _username,
          password: _pass,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error during registration',
        error: e,
        stackTrace: stackTrace,
        name: 'CreateUsernameViewModel',
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



