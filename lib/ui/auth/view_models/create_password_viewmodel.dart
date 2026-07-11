import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

enum PassValidationError { none, empty, invalidFormat }

class CreatePasswordViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  String _email = '';
  String _pass = '';
  bool _isLoading = false;

  // 8 caracteres, 1 mayuscula, 1 minuscula, 1 especial, 1 digito
  final passRegex = RegExp(
    r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-.,]).{8,}$",
  );

  PassValidationError _error = PassValidationError.none;
  PassValidationError get error => _error;
  bool get isLoading => _isLoading;

  String get email => _email;
  String get pass => _pass;

  CreatePasswordViewModel(this._authRepository);

  bool get has8Characters => _pass.length >= 8;
  bool get hasUppercase => _pass.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => _pass.contains(RegExp(r'[a-z]'));
  bool get hasDigit => _pass.contains(RegExp(r'[0-9]'));
  bool get hasSpecial => _pass.contains(RegExp(r'[#?!@$%^&*-.,]'));

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
      _error = PassValidationError.empty;
    } else if (!passRegex.hasMatch(pass)) {
      _error = PassValidationError.invalidFormat;
    } else {
      _error = PassValidationError.none;
    }
    notifyListeners();
  }

  void clearError() {
    _error = PassValidationError.none;
    notifyListeners();
  }
}
