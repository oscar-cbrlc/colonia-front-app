import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

enum EmailValidationError { none, empty, invalidFormat }
enum UserFoundState { found, notFound, error }

class EmailViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  String _email = '';
  bool _isLoading = false;
  String? _errorMessage;

  EmailValidationError _error = EmailValidationError.none;
  UserFoundState _userFoundState = UserFoundState.notFound;

  String? get errorMessage => _errorMessage;
  EmailValidationError get error => _error;
  UserFoundState get userFoundState => _userFoundState;

  EmailViewModel(this._authRepository);

  String get email => _email;
  bool get isLoading => _isLoading;

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void resetState() {
    _email = '';
    _isLoading = false;
    _errorMessage = null;
    _error = EmailValidationError.none;
    _userFoundState = UserFoundState.notFound;
    notifyListeners();
  }


  final emailRegex = RegExp(
    r"^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$",
  );


  void validateEmail(String email) {
    if (email.isEmpty) {
      _error = EmailValidationError.empty;
    } else if (!emailRegex.hasMatch(email)) {
      _error = EmailValidationError.invalidFormat;
    } else {
      _error = EmailValidationError.none;
    }
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value.trim();
    validateEmail(email);
    notifyListeners();
  }

  void clearError() {
    _error = EmailValidationError.none;
    notifyListeners();
  }

  Future<void> findUser() async {
    if (_isLoading || _error != EmailValidationError.none) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();


    try {
      await _authRepository.getUserByEmail(_email);
      _userFoundState = UserFoundState.found;
    } on UserNotFoundException {
      _userFoundState = UserFoundState.notFound;
    } catch (e, stackTrace) {
      developer.log(
        'Error finding user',
        error: e,
        stackTrace: stackTrace,
        name: 'EmailViewModel',
      );
      _userFoundState = UserFoundState.error;
      if (e is Exception) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
