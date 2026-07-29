import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @loginOrSignUp.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión o registrarse'**
  String get loginOrSignUp;

  /// No description provided for @continueWithEmail.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Email'**
  String get continueWithEmail;

  /// No description provided for @selectYourAuthPref.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu método de preferencia para iniciar tu cuenta'**
  String get selectYourAuthPref;

  /// No description provided for @ifCreatingNewAccount.
  ///
  /// In es, this message translates to:
  /// **'Si estás creando una nueva cuenta, '**
  String get ifCreatingNewAccount;

  /// No description provided for @termsAndConditions.
  ///
  /// In es, this message translates to:
  /// **'Términos y Condiciones'**
  String get termsAndConditions;

  /// No description provided for @and.
  ///
  /// In es, this message translates to:
  /// **'y'**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get privacyPolicy;

  /// No description provided for @willApply.
  ///
  /// In es, this message translates to:
  /// **'se aplicarán'**
  String get willApply;

  /// No description provided for @notValidInput.
  ///
  /// In es, this message translates to:
  /// **'No es una entrada válida'**
  String get notValidInput;

  /// No description provided for @enterYourEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu email para iniciar sesión o crear una cuenta'**
  String get enterYourEmail;

  /// No description provided for @emailAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección email'**
  String get emailAddress;

  /// No description provided for @continueM.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueM;

  /// No description provided for @createPass.
  ///
  /// In es, this message translates to:
  /// **'Crear contraseña'**
  String get createPass;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get register;

  /// No description provided for @yourPasswordMustInclude.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña debe incluir:'**
  String get yourPasswordMustInclude;

  /// No description provided for @atLeast8Characters.
  ///
  /// In es, this message translates to:
  /// **'Al menos 8 caracteres'**
  String get atLeast8Characters;

  /// No description provided for @oneUppercaseLetter.
  ///
  /// In es, this message translates to:
  /// **'Una letra mayúscula'**
  String get oneUppercaseLetter;

  /// No description provided for @oneLowercaseLetter.
  ///
  /// In es, this message translates to:
  /// **'Una letra minúscula'**
  String get oneLowercaseLetter;

  /// No description provided for @oneNumber.
  ///
  /// In es, this message translates to:
  /// **'Un número'**
  String get oneNumber;

  /// No description provided for @oneSpecialCharacter.
  ///
  /// In es, this message translates to:
  /// **'Un carácter especial'**
  String get oneSpecialCharacter;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get passwordHint;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginButton;

  /// No description provided for @errorEmptyPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no puede estar vacía'**
  String get errorEmptyPassword;

  /// No description provided for @createUsername.
  ///
  /// In es, this message translates to:
  /// **'Crea tu nombre de usuario'**
  String get createUsername;

  /// No description provided for @usernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In es, this message translates to:
  /// **'Cataglyphis-Maximus-99'**
  String get usernameHint;

  /// No description provided for @usernameGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía de nombre:'**
  String get usernameGuide;

  /// No description provided for @beBetween4and16Chars.
  ///
  /// In es, this message translates to:
  /// **'Entre 4-16 characters'**
  String get beBetween4and16Chars;

  /// No description provided for @onlyContainUsernameChars.
  ///
  /// In es, this message translates to:
  /// **'Se permiten letras, números, -, _, ?, !'**
  String get onlyContainUsernameChars;

  /// No description provided for @createANameToIdentifyYou.
  ///
  /// In es, this message translates to:
  /// **'Crea un nombre para que otros te identifiquen'**
  String get createANameToIdentifyYou;

  /// No description provided for @map.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get map;

  /// No description provided for @team.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get team;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @startActivity.
  ///
  /// In es, this message translates to:
  /// **'Empezar actividad'**
  String get startActivity;

  /// No description provided for @walk.
  ///
  /// In es, this message translates to:
  /// **'Caminar'**
  String get walk;

  /// No description provided for @run.
  ///
  /// In es, this message translates to:
  /// **'Correr'**
  String get run;

  /// No description provided for @bike.
  ///
  /// In es, this message translates to:
  /// **'Bicicleta'**
  String get bike;

  /// No description provided for @activity.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get activity;

  /// No description provided for @training.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get training;

  /// No description provided for @free.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get free;

  /// No description provided for @distance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get distance;

  /// No description provided for @time.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get time;

  /// No description provided for @pace.
  ///
  /// In es, this message translates to:
  /// **'Ritmo'**
  String get pace;

  /// No description provided for @timeTrial.
  ///
  /// In es, this message translates to:
  /// **'Contrarreloj'**
  String get timeTrial;

  /// No description provided for @setObjective.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get setObjective;

  /// No description provided for @km.
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @meters.
  ///
  /// In es, this message translates to:
  /// **'metros'**
  String get meters;

  /// No description provided for @hours.
  ///
  /// In es, this message translates to:
  /// **'horas'**
  String get hours;

  /// No description provided for @min.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @sec.
  ///
  /// In es, this message translates to:
  /// **'seg'**
  String get sec;

  /// No description provided for @targetPace.
  ///
  /// In es, this message translates to:
  /// **'Ritmo objetivo (min/km)'**
  String get targetPace;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @pause.
  ///
  /// In es, this message translates to:
  /// **'Pausa'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get stop;

  /// No description provided for @resume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get resume;

  /// No description provided for @finish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get finish;

  /// No description provided for @setUpActivity.
  ///
  /// In es, this message translates to:
  /// **'Configurar actividad'**
  String get setUpActivity;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'Iniciar'**
  String get start;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
