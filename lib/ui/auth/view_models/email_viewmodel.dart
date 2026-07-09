import 'package:flutter/material.dart';

enum EmailValidationError { none, empty, invalidFormat }

class EmailViewModel extends ChangeNotifier {
  //final l10n = AppLocalizations.of(context);
  String _email = '';
  bool _isLoading = false;

  EmailValidationError _error = EmailValidationError.none;
  EmailValidationError get error => _error;


  String get email => _email;
  bool get isLoading => _isLoading;

  final emailRegex = RegExp(
    r"^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$",
  );


  void validateEmail(String email) {
    _email = email;
    if (_email.isEmpty) {
      _error = EmailValidationError.empty;

    } else if (!emailRegex.hasMatch(_email)) {
      _error = EmailValidationError.invalidFormat;
    } else {
      _error = EmailValidationError.none;

    }
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value.trim();
    notifyListeners();
  }

  void clearError() {
    _error = EmailValidationError.none;
    notifyListeners();
  }

  Future<bool> continueWithEmail(String email) async {
    setEmail(email);
    validateEmail(_email);
    if (_error != EmailValidationError.none) return false;
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
