// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginOrSignUp => 'Iniciar sesión o registrarse';

  @override
  String get continueWithEmail => 'Continuar con Email';

  @override
  String get selectYourAuthPref =>
      'Selecciona tu método de preferencia para iniciar tu cuenta';

  @override
  String get ifCreatingNewAccount => 'Si estás creando una nueva cuenta, ';

  @override
  String get termsAndConditions => 'Términos y Condiciones';

  @override
  String get and => 'y';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get willApply => 'se aplicarán';

  @override
  String get pleaseValidEmail =>
      'Por favor ingresa un correo electrónico válido.';

  @override
  String get enterYourEmail =>
      'Ingresa tu email para iniciar sesión o crear una cuenta.';

  @override
  String get emailAddress => 'Dirección email';

  @override
  String get continueM => 'Continuar';
}
