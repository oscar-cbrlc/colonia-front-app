import 'package:flutter/material.dart';

enum PassValidationError { none, empty, invalidFormat,  }

class NewPasswordViewModel extends ChangeNotifier {
  //final l10n = AppLocalizations.of(context);
  String _pass = '';
  String? _errorMessage;
  bool _isLoading = false;


  PassValidationError _error = PassValidationError.none;
  PassValidationError get error => _error;


  String get pass => _pass;
  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // 8 caracteres, 1 mayuscula, 1 minuscula, 1 especial, 1 digito
  final passRegex = RegExp(
    r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-.,]).{8,}$",
  );


  bool get has8Characters => _pass.length >= 8;
  bool get hasUppercase => _pass.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => _pass.contains(RegExp(r'[a-z]'));
  bool get hasDigit => _pass.contains(RegExp(r'[0-9]'));
  bool get hasSpecial => _pass.contains(RegExp(r'[#?!@$%^&*-.,]'));

  void validatePass(String pass) {
    _pass = pass;
    if (pass.isEmpty) {
      _error = PassValidationError.empty;
    } else if (!passRegex.hasMatch(pass)) {
      _error = PassValidationError.invalidFormat;
    } else {
      _error = PassValidationError.none;
    }
    notifyListeners();
  }

  void setPass(String value) {
    _pass = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> registerUser() async {
    validatePass(_pass);
    if (_error != PassValidationError.none) return false;
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
