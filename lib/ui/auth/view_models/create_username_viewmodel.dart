import 'package:flutter/material.dart';

enum UsernameValidationError { none, empty, invalidFormat }

class CreateUsernameViewModel extends ChangeNotifier {
  //final l10n = AppLocalizations.of(context);
  String _email = '';
  String _pass = '';
  String _username = '';
  bool _isLoading = false;


  UsernameValidationError _error = UsernameValidationError.none;
  UsernameValidationError get error => _error;

  bool get isLoading => _isLoading;

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
    notifyListeners();
  }

  Future<bool> submitRegistration() async {
    validateUsername(_username);
    
    if (_error != UsernameValidationError.none) return false;

    _isLoading = true;
    notifyListeners();

    // TODO: Implement API call to save new user
    try {
      await Future.delayed(const Duration(seconds: 1));
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



