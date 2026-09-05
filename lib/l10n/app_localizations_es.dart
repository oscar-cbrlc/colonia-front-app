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
  String get notValidInput => 'No es una entrada válida';

  @override
  String get enterYourEmail =>
      'Ingresa tu email para iniciar sesión o crear una cuenta';

  @override
  String get emailAddress => 'Dirección email';

  @override
  String get continueM => 'Continuar';

  @override
  String get createPass => 'Crear contraseña';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get register => 'Registrarse';

  @override
  String get yourPasswordMustInclude => 'Tu contraseña debe incluir:';

  @override
  String get atLeast8Characters => 'Al menos 8 caracteres';

  @override
  String get oneUppercaseLetter => 'Una letra mayúscula';

  @override
  String get oneLowercaseLetter => 'Una letra minúscula';

  @override
  String get oneNumber => 'Un número';

  @override
  String get oneSpecialCharacter => 'Un carácter especial';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Ingresa tu contraseña';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get errorEmptyPassword => 'La contraseña no puede estar vacía';

  @override
  String get createUsername => 'Crea tu nombre de usuario';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHint => 'Cataglyphis-Maximus-99';

  @override
  String get usernameGuide => 'Guía de nombre:';

  @override
  String get beBetween4and16Chars => 'Entre 4-16 characters';

  @override
  String get onlyContainUsernameChars =>
      'Se permiten letras, números, -, _, ?, !';

  @override
  String get createANameToIdentifyYou =>
      'Crea un nombre para que otros te identifiquen';

  @override
  String get map => 'Mapa';

  @override
  String get team => 'Equipo';

  @override
  String get profile => 'Perfil';

  @override
  String get startActivity => 'Empezar actividad';

  @override
  String get walk => 'Caminar';

  @override
  String get run => 'Correr';

  @override
  String get bike => 'Bicicleta';

  @override
  String get activity => 'Actividad';

  @override
  String get training => 'Entrenamiento';

  @override
  String get free => 'Libre';

  @override
  String get distance => 'Distancia';

  @override
  String get time => 'Tiempo';

  @override
  String get pace => 'Ritmo';

  @override
  String get timeTrial => 'Contrarreloj';

  @override
  String get setObjective => 'Objetivo';

  @override
  String get km => 'km';

  @override
  String get meters => 'metros';

  @override
  String get hours => 'horas';

  @override
  String get min => 'min';

  @override
  String get sec => 'seg';

  @override
  String get targetPace => 'Ritmo objetivo (min/km)';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get pause => 'Pausa';

  @override
  String get stop => 'Detener';

  @override
  String get resume => 'Reanudar';

  @override
  String get finish => 'Finalizar';

  @override
  String get setUpActivity => 'Configurar actividad';

  @override
  String get start => 'Iniciar';

  @override
  String get timeUp => 'Tiempo terminado';

  @override
  String get objectiveAchieved => 'Objetivo logrado';

  @override
  String get objectiveFailed => 'Objetivo no logrado';

  @override
  String get success => 'Éxito';

  @override
  String get remaining => 'Restante';

  @override
  String get failed => 'Fallido';

  @override
  String get trainingFinished => 'Entrenamiento terminado';

  @override
  String get activitySummary => 'Resumen de actividad';

  @override
  String get nextImpact => 'Próximo impacto';

  @override
  String get youNotHaveTeam => 'No eres miembro de una Colonia';

  @override
  String get createTeam => 'Crear una Colonia';

  @override
  String get joinTeam => 'Unirse a una Colonia';

  @override
  String get description => 'Descripción';

  @override
  String get teamMembers => 'Miembros de Colonia';

  @override
  String get name => 'Nombre';

  @override
  String get accessType => 'Tipo de acceso';

  @override
  String get location => 'Ubicación';

  @override
  String get private => 'Privado';

  @override
  String get public => 'Público';

  @override
  String get color => 'Color';

  @override
  String get info => 'Info';

  @override
  String teamJoin(String username) {
    return '$username se ha unido a la colonia';
  }

  @override
  String teamKick(String username) {
    return '$username ha sido exilidado de la colonia';
  }

  @override
  String teamExit(String username) {
    return '$username ha abandonado la colonia';
  }

  @override
  String get colonyChat => 'Chat de Colonia';

  @override
  String get noMessagesYet => 'No hay mensajes aún';

  @override
  String get typeMessage => 'Escribe un mensaje...';

  @override
  String get delete => 'Eliminar';

  @override
  String get memberKicked => 'Miembro expulsado de la colonia';

  @override
  String get leaderLeaveError =>
      'No puedes dejar la colonia como Líder. Por favor, promueve a otro miembro a Líder primero.';

  @override
  String get onlyMemberDeleteError =>
      'Eres el único miembro. Por favor, elimina la colonia en su lugar.';

  @override
  String get leaveColonyTitle => 'Dejar Colonia';

  @override
  String get leaveColonyConfirm =>
      '¿Estás seguro de que quieres dejar esta colonia?';

  @override
  String get leave => 'Dejar';

  @override
  String get leftColony => 'Has dejado la colonia';

  @override
  String get actionRequired => 'Acción Requerida';

  @override
  String get exploreColonies => 'EXPLORAR COLONIAS';

  @override
  String get searchByName => 'Buscar por nombre...';

  @override
  String get noColoniesFound => 'No se encontraron colonias';

  @override
  String get requestCancelled => 'Solicitud cancelada';

  @override
  String get viewSentRequests => 'VER SOLICITUDES ENVIADAS';

  @override
  String get joinRequests => 'SOLICITUDES DE UNIÓN';

  @override
  String get leaveColony => 'DEJAR COLONIA';

  @override
  String get ok => 'OK';

  @override
  String get colonyNotFound => 'Colonia no encontrada';

  @override
  String get requestRejected => 'Solicitud rechazada';

  @override
  String get requestPending => 'Solicitud pendiente';

  @override
  String get failedToCancelRequest => 'Error al cancelar la solicitud';

  @override
  String get declineRequest => 'Rechazar solicitud';

  @override
  String get successfullyJoinedColony =>
      'Te has unido a la colonia exitosamente';

  @override
  String get requestSentSuccessfully => 'Solicitud enviada exitosamente';

  @override
  String get requestToJoin => 'Solicitar unirse';

  @override
  String get memberPromotedToMod => 'Miembro promovido a moderador';

  @override
  String promoteToLeaderConfirm(String username) {
    return '¿Estás seguro de que quieres promover a $username a Líder? Perderás tus privilegios de Líder.';
  }

  @override
  String get leadershipTransferred => 'Liderazgo transferido';

  @override
  String get memberDemotedToMember => 'Miembro degradado a miembro';

  @override
  String kickMemberConfirm(String username) {
    return '¿Estás seguro de que quieres expulsar a $username de la colonia?';
  }

  @override
  String get colonyDeleted => 'Colonia eliminada';

  @override
  String get deleteColony => 'Eliminar colonia';

  @override
  String get deleteColonyConfirm =>
      '¿Estás seguro de que quieres eliminar esta colonia?';

  @override
  String get kickMember => 'Expulsar miembro';

  @override
  String get kick => 'Expulsar';

  @override
  String get promoteToModerator => 'Promover a moderador';

  @override
  String get promoteToLeader => 'Promover a líder';

  @override
  String get demote => 'Degradar';

  @override
  String get demoteToMember => 'Degradar a miembro';

  @override
  String get transferLeadership => 'Transferir Liderazgo';

  @override
  String get promote => 'Promover';

  @override
  String get cannotDelete => 'No se puede eliminar';

  @override
  String get cannotDeleteActiveMembers =>
      'No puedes eliminar una colonia con miembros activos';

  @override
  String get colonyUpdatedSuccessfully => 'Colonia actualizada exitosamente';

  @override
  String get colonyCreatedSuccessfully => 'Colonia creada exitosamente';

  @override
  String get accepted => 'aceptado';
}
