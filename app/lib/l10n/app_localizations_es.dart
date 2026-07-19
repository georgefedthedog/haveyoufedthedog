// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Have You Fed The Dog?';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonRequired => 'Obligatorio';

  @override
  String get commonTryAgain => 'Reintentar';

  @override
  String get confirmByTypingWord => 'ELIMINAR';

  @override
  String confirmByTypingHint(String word) {
    return 'Escribe $word para confirmar';
  }

  @override
  String get passwordFieldLabel => 'Contraseña';

  @override
  String get passwordFieldShow => 'Mostrar contraseña';

  @override
  String get passwordFieldHide => 'Ocultar contraseña';

  @override
  String get profileLanguageSystemDefault => 'Idioma del sistema';

  @override
  String get profileNotificationsTitle => 'Notificaciones';

  @override
  String get profileNotifyReminders => 'Recordatorios';

  @override
  String get profileNotifyRemindersDesc =>
      'Un toque cuando una tarea está atrasada.';

  @override
  String get profileNotifyCompletions => 'Tareas registradas';

  @override
  String get profileNotifyCompletionsDesc =>
      'Cuando alguien de tu hogar registra o deshace una tarea.';

  @override
  String get profileNotifyAwards => 'Premios';

  @override
  String get profileNotifyAwardsDesc => 'Cuando ganas un premio semanal.';

  @override
  String get authWelcomeBack => '¡Qué bueno verte de nuevo!';

  @override
  String get authJoinFamily => 'Únete a la familia';

  @override
  String get authLoginTagline =>
      'Inicia sesión y mantén a tu perrete feliz y bien alimentado.';

  @override
  String get authSignupTagline =>
      'Regístrate y no vuelvas a preguntarte quién dio de comer al perro.';

  @override
  String get authNoAccount => '¿Aún no tienes cuenta?';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authLogIn => 'Iniciar sesión';

  @override
  String get authSignUp => 'Registrarse';

  @override
  String get authEmailLabel => 'Correo';

  @override
  String get authEmailHint => 'Escribe tu correo';

  @override
  String get authEmailInvalid => 'Escribe un correo válido';

  @override
  String get authPasswordHint => 'Escribe tu contraseña';

  @override
  String get authForgotPassword => '¿Olvidaste la contraseña?';

  @override
  String get authLoginFailed => 'No se pudo iniciar sesión';

  @override
  String authLoginFailedDetails(String details) {
    return 'No se pudo iniciar sesión: $details';
  }

  @override
  String get authYourNameLabel => 'Tu nombre';

  @override
  String get authNameHint => 'Visible para los miembros de tu hogar';

  @override
  String get authNameHintClaim =>
      'Déjalo vacío para conservar tu nombre actual';

  @override
  String get authPasswordRule => 'Al menos 8 caracteres';

  @override
  String get authChoosePasswordHint => 'Elige una contraseña';

  @override
  String get authClaimCodeToggle => 'Tengo un código de traspaso';

  @override
  String get authClaimCodeLabel => 'Código de traspaso';

  @override
  String get authClaimCodeHint => '¿Te unes como miembro existente?';

  @override
  String get authClaimAccount => 'Reclamar cuenta';

  @override
  String get authCouldNotClaim => 'No se pudo reclamar la cuenta';

  @override
  String get authSignupFailed => 'No se pudo completar el registro';

  @override
  String authSignupFailedDetails(String details) {
    return 'No se pudo completar el registro: $details';
  }

  @override
  String get authResetPasswordTitle => 'Restablecer contraseña';

  @override
  String get authResetIntro =>
      'Tranquilo - le pasa a cualquiera.\nTe enviaremos un enlace para elegir una nueva.';

  @override
  String get authSendResetLink => 'Enviar enlace';

  @override
  String get authCheckInbox => '¡Revisa tu correo!';

  @override
  String authResetSent(String email) {
    return 'Si existe una cuenta para $email, un enlace va de camino. Síguelo para elegir una nueva contraseña y luego inicia sesión aquí.';
  }

  @override
  String authResetEmailFailed(String details) {
    return 'No se pudo enviar el correo: $details';
  }

  @override
  String get authBackToLogin => 'Volver a iniciar sesión';

  @override
  String get startupErrorTitle => 'No pudimos arrancar';

  @override
  String get startupErrorBody => 'Comprueba tu conexión y reinténtalo.';

  @override
  String get commonAdd => 'Añadir';

  @override
  String get commonSaveChanges => 'Guardar';

  @override
  String commonCouldNotSave(String details) {
    return 'No se pudo guardar: $details';
  }

  @override
  String commonCouldNotDelete(String details) {
    return 'No se pudo eliminar: $details';
  }

  @override
  String commonDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String commonErrorDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get homeErrorTitle => 'Hmm, algo salió torcido';

  @override
  String homeErrorBody(String details) {
    return 'No se pudieron cargar tus protegidos. $details';
  }

  @override
  String get homeNothingDueToday => 'Nada pendiente hoy 🎉';

  @override
  String get homeTodaysChores => 'Tareas de hoy';

  @override
  String get homeTapToComplete => 'Toca para completar';

  @override
  String get homeSummaryAllDone => '¡Todas las tareas de hoy están hechas!';

  @override
  String get homeSummaryStart => '¡Vamos allá!';

  @override
  String get homeSummaryKeepUp => 'Buen ritmo. ¡Sigue así!';

  @override
  String homeSummaryCount(int done, int total) {
    return '$done de $total completadas';
  }

  @override
  String get subjectsEmptyTitle => 'Aún no hay protegidos';

  @override
  String get subjectsEmptyBody =>
      'Añade un perro, un gato, una planta o lo que necesite cuidados.';

  @override
  String get subjectsAddThing => 'Añadir un protegido';

  @override
  String get subjectsTabTitle => 'Protegidos';

  @override
  String get subjectsTabSubtitle =>
      'A veces amigos, a veces solo cosas. Todo lo que cuidas o no quieres olvidar.';

  @override
  String subjectsLoadFailed(String details) {
    return 'No se pudieron cargar los protegidos: $details';
  }

  @override
  String get subjectNothingDueToday => 'Nada pendiente hoy';

  @override
  String get subjectNoChoresYet => 'Aún sin tareas';

  @override
  String subjectDoneToday(int done, int total) {
    return '$done de $total hechas hoy';
  }

  @override
  String subjectStreakDays(int count) {
    return 'Racha de $count días';
  }

  @override
  String get subjectNfcTagWritten => 'Etiqueta NFC escrita';

  @override
  String get subjectManageChoresLink => 'Gestionar tareas →';

  @override
  String get subjectCompletedChores => 'Tareas completadas';

  @override
  String get subjectSeeAll => 'Ver todo →';

  @override
  String subjectHistoryLoadFailed(String details) {
    return 'No se pudo cargar el historial: $details';
  }

  @override
  String get subjectNoCompletions => 'Aún no hay nada registrado.';

  @override
  String editSubjectTitle(String name) {
    return 'Editar $name';
  }

  @override
  String get editSubjectNewTitle => 'Nuevo protegido';

  @override
  String get editSubjectDeleteTooltip => 'Eliminar protegido';

  @override
  String get editSubjectDeleteBody =>
      'Todas las tareas y el historial de este protegido se eliminarán para siempre. No se puede deshacer.';

  @override
  String get editSubjectNameLabel => 'Nombre';

  @override
  String get editSubjectNameHint => 'p. ej. Kiko';

  @override
  String get editSubjectAdd => 'Añadir protegido';

  @override
  String get editSubjectManageChores => 'Gestionar tareas';

  @override
  String get editSubjectDeleteChoreBody =>
      'Su horario y recordatorios se van con ella. Lo ya completado se queda en el historial.';

  @override
  String get editSubjectTagWritten => 'Etiqueta escrita';

  @override
  String get editSubjectNoTag => 'Aún sin etiqueta';

  @override
  String get editSubjectTapCompletes =>
      'En este teléfono, un toque marca la tarea actual. Cámbialo en';

  @override
  String get editSubjectTapOpens =>
      'En este teléfono, un toque abre la página del protegido. Cámbialo en';

  @override
  String get editSubjectYouTabLink => 'la pestaña Tú';

  @override
  String get editSubjectWriteTagPrompt =>
      'Escribe una etiqueta para registrar con un toque.';

  @override
  String get editSubjectWriteTag => 'Escribir etiqueta NFC';

  @override
  String get editSubjectWriteAnotherTag => 'Escribir otra etiqueta NFC';

  @override
  String get editSubjectForgetTag => 'Olvidar etiqueta';

  @override
  String editSubjectSaveTagFailed(String details) {
    return 'No se pudo guardar la etiqueta: $details';
  }

  @override
  String editSubjectForgetTagFailed(String details) {
    return 'No se pudo olvidar: $details';
  }

  @override
  String get browseMoreCharacters => 'Más personajes →';

  @override
  String get commonToday => 'Hoy';

  @override
  String get commonYesterday => 'Ayer';

  @override
  String scheduleDaily(String time) {
    return 'Todos los días a las $time';
  }

  @override
  String scheduleWeeklyAt(String days, String time) {
    return '$days a las $time';
  }

  @override
  String get scheduleNever => 'Nunca';

  @override
  String scheduleFortnightly(String days, String time, String phase) {
    return 'Cada dos semanas: $days a las $time · $phase';
  }

  @override
  String get scheduleThisWeek => 'esta semana';

  @override
  String get scheduleNextWeek => 'la próxima semana';

  @override
  String scheduleMonthlyOnDayAt(String day, String time) {
    return 'Cada mes el día $day a las $time';
  }

  @override
  String scheduleMonthlyLastDayAt(String time) {
    return 'Cada mes el último día a las $time';
  }

  @override
  String scheduleMonthlyOnWeekdayAt(
    String position,
    String weekday,
    String time,
  ) {
    return 'Cada mes el $position $weekday a las $time';
  }

  @override
  String get schedulePositionFirst => 'primer';

  @override
  String get schedulePositionSecond => 'segundo';

  @override
  String get schedulePositionThird => 'tercer';

  @override
  String get schedulePositionFourth => 'cuarto';

  @override
  String get schedulePositionLast => 'último';

  @override
  String scheduleOnceAt(String time) {
    return 'Una vez a las $time';
  }

  @override
  String scheduleOnceOn(String date, String time) {
    return 'Una vez el $date a las $time';
  }

  @override
  String overdueMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos de retraso',
      one: '1 minuto de retraso',
    );
    return '$_temp0';
  }

  @override
  String overdueHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'más de $count horas de retraso',
      one: '1 hora de retraso',
    );
    return '$_temp0';
  }

  @override
  String get dueIn => 'Vence en';

  @override
  String dueInUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'h',
      one: 'hora',
    );
    return '$_temp0';
  }

  @override
  String dueInUnitMins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'min',
      one: 'min',
    );
    return '$_temp0';
  }

  @override
  String get editChorePickDate => 'Elige una fecha';

  @override
  String editChoreMonthDayItem(String day) {
    return 'El día $day';
  }

  @override
  String get editChoreLastDay => 'El último día';

  @override
  String get commonYou => 'Tú';

  @override
  String get commonSomeone => 'Alguien';

  @override
  String choreCouldNotLog(String details) {
    return 'No se pudo registrar: $details';
  }

  @override
  String choreCouldNotUndo(String details) {
    return 'No se pudo quitar: $details';
  }

  @override
  String choreRemoved(String name) {
    return 'Quitada: $name';
  }

  @override
  String get choreUndoNotAllowed =>
      'Cambia a quien la registró (o pide al propietario) para quitarla.';

  @override
  String undoDialogTitle(String name) {
    return '¿Quitar «$name»?';
  }

  @override
  String get undoDialogBody =>
      'La tarea vuelve a quedar pendiente, y se avisa al resto del hogar.';

  @override
  String get undoDialogAction => 'Quitar';

  @override
  String get choreUsuallyDoneAround => 'Suele hacerse hacia';

  @override
  String get choreOneTimePill => 'Única';

  @override
  String choreCompletedBy(String name) {
    return 'Completada por $name';
  }

  @override
  String get editChoreTitle => 'Editar tarea';

  @override
  String get editChoreNewTitle => 'Nueva tarea';

  @override
  String get editChoreDeleteTooltip => 'Eliminar tarea';

  @override
  String get editChoreDeleteBody =>
      'Todo el historial de esta tarea se eliminará para siempre. No se puede deshacer.';

  @override
  String get editChoreNameLabel => 'Nombre';

  @override
  String get editChoreNameHint => 'p. ej. Desayuno';

  @override
  String get editChoreScheduleLabel => 'Programación';

  @override
  String get editChoreRepeats => 'Se repite';

  @override
  String get editChoreOneTime => 'Una vez';

  @override
  String get editChoreFrequencyLabel => 'Frecuencia';

  @override
  String get editChoreFreqDaily => 'Todos los días';

  @override
  String get editChoreFreqWeekly => 'Algunos días';

  @override
  String get editChoreFreqMonthly => 'Cada mes';

  @override
  String get editChoreOnTheseDays => 'Estos días';

  @override
  String get editChorePickOneDay => 'Elige al menos un día.';

  @override
  String get editChoreHowOften => 'Cada cuánto';

  @override
  String get editChoreEveryWeek => 'Cada semana';

  @override
  String get editChoreFortnightly => 'Cada dos semanas';

  @override
  String get editChoreStarting => 'A partir de';

  @override
  String get editChoreThisWeek => 'Esta semana';

  @override
  String get editChoreNextWeek => 'La próxima semana';

  @override
  String get editChoreOnThe => 'El';

  @override
  String get editChoreExactDay => 'Día exacto';

  @override
  String get editChorePosFirst => 'Primero';

  @override
  String get editChorePosSecond => 'Segundo';

  @override
  String get editChorePosThird => 'Tercero';

  @override
  String get editChorePosFourth => 'Cuarto';

  @override
  String get editChorePosLast => 'Último';

  @override
  String get editChoreDayLabel => 'Día';

  @override
  String get editChoreWeekdayLabel => 'Día de la semana';

  @override
  String get editChoreOnDateLabel => 'El';

  @override
  String get editChoreAtTimeLabel => 'A las';

  @override
  String get editChoreAddChore => 'Añadir tarea';

  @override
  String get timelineLogged => 'Registrado';

  @override
  String get historyAwardsTitle => 'Trofeos';

  @override
  String get historyDayStreak => 'Días de racha';

  @override
  String get historyThisWeek => 'Esta semana';

  @override
  String historyCleanSweeps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Plenos',
      one: 'Pleno',
    );
    return '$_temp0';
  }

  @override
  String get historyAllActivity => 'Toda la actividad';

  @override
  String get historyFilterAll => 'Todos';

  @override
  String get historyEmptyTitle => '¡Aquí no hay nada todavía!';

  @override
  String get historyEmptyBody => 'Sé el primero en completar una tarea.';

  @override
  String get leaderboardEmpty =>
      '¡Aún no se ha completado ninguna tarea esta semana!';

  @override
  String leaderboardYouSuffix(String name) {
    return '$name (tú)';
  }

  @override
  String get awardsBadges => 'Insignias';

  @override
  String get awardsTeamEffort => 'Trabajo en equipo';

  @override
  String get awardsTeamEffortDesc =>
      'Todos arrimaron el hombro - la carga se repartió bien';

  @override
  String get awardsUnclaimed => 'Sin dueño';

  @override
  String get awardsLastWeeksWinner => 'GANADOR DE LA SEMANA PASADA';

  @override
  String awardsSubjectPossessive(String name) {
    return '$name';
  }

  @override
  String awardsNoWinnerYet(String name) {
    return 'La semana pasada no hubo ganador - haz la mayoría de las tareas de $name y llévatelo la próxima.';
  }

  @override
  String awardsChoreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '$count tarea',
    );
    return '$_temp0';
  }

  @override
  String get commonLogOut => 'Cerrar sesión';

  @override
  String get householdTitle => 'Hogar';

  @override
  String get householdNoLonger => 'Ya no eres miembro de este hogar.';

  @override
  String get householdDeleteTooltip => 'Eliminar hogar';

  @override
  String get householdDeleteBody =>
      'Todos los protegidos, tareas e historial de este hogar se eliminarán para siempre para todos sus miembros. No se puede deshacer.';

  @override
  String householdLeaveTitle(String name) {
    return '¿Salir de $name?';
  }

  @override
  String get householdLeaveBody =>
      'Dejarás de ver las tareas y la actividad de este hogar. Podrás volver más adelante con un código de invitación.';

  @override
  String get householdLeave => 'Salir';

  @override
  String householdDeleteManagedBody(String name) {
    return '$name es un miembro gestionado: esto lo elimina por completo. Sus tareas pasadas siguen contando, pero aparecerán como «Alguien».';
  }

  @override
  String get browseMoreHomes => 'Más casas →';

  @override
  String get browseMoreAvatars => 'Más avatares →';

  @override
  String get householdNameLabel => 'Nombre del hogar';

  @override
  String get householdNameHint => 'p. ej. «Casa Paihia» u «Hogar»';

  @override
  String get householdResidentsLabel => '¿Quién vive aquí?';

  @override
  String get householdResidentsHint => 'Los García';

  @override
  String householdTimezone(String tz) {
    return 'Zona horaria: $tz';
  }

  @override
  String get householdUsePhoneTz => 'Usar la del teléfono';

  @override
  String get householdMembersFallback => 'Miembros';

  @override
  String get householdSaveFailed => 'No se pudo guardar';

  @override
  String get householdRoleOwner => 'propietario';

  @override
  String get householdRoleMember => 'miembro';

  @override
  String get addSomeoneTitle => 'Añadir a alguien';

  @override
  String get addInviteTitle => 'Invitar a alguien con su propia cuenta';

  @override
  String get addInviteSubtitle =>
      'Familia o compañeros de piso que inician sesión en su propio teléfono. Se unen con un código y registran sus propias tareas.';

  @override
  String get addManagedTitle => 'Añadir a alguien sin cuenta';

  @override
  String get addManagedSubtitle =>
      'Para quienes no tienen cuenta propia. Tú gestionas su perfil y registras sus tareas cambiando a ellos con «¿A quién le toca?» en la pestaña Tú.';

  @override
  String get inviteSomeone => 'Invitar a alguien';

  @override
  String get inviteSubtitle => 'Invita a tu familia o compañeros de piso';

  @override
  String get invitesOn => 'Invitaciones abiertas';

  @override
  String get invitesOff => 'Invitaciones cerradas';

  @override
  String get inviteLiveUntil => 'Válido hasta que cierres las invitaciones';

  @override
  String get shareCode => 'Compartir código';

  @override
  String get generateNewCode => 'Generar nuevo código';

  @override
  String inviteShareText(String code) {
    return 'Únete a nuestro hogar en Have You Fed The Dog?\nhttps://haveyoufedthedog.com/join?code=$code\n\nSi el enlace no abre la app, ábrela y escribe el código de invitación $code';
  }

  @override
  String get inviteShareSubject =>
      'Have You Fed The Dog? - invitación al hogar';

  @override
  String membersLoadFailed(String details) {
    return 'No se pudieron cargar los miembros: $details';
  }

  @override
  String memberRemoveTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String memberRemoveBody(String name) {
    return '$name perderá el acceso a este hogar de inmediato. Podrá volver más adelante con un código de invitación.';
  }

  @override
  String get memberRemove => 'Quitar';

  @override
  String get memberOwner => 'Propietario';

  @override
  String get editMemberTitle => 'Editar miembro';

  @override
  String get addMemberTitle => 'Añadir miembro';

  @override
  String get deleteMemberTooltip => 'Eliminar miembro';

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get memberNameHint => 'Cómo ven los demás a este miembro';

  @override
  String get claimLoginTitle => 'Dale su propia cuenta';

  @override
  String get claimLoginSubtitle =>
      'Podrá reclamar esta cuenta e iniciar sesión por su cuenta';

  @override
  String get claimCodeInfo =>
      'Se introduce al registrarse. Válido hasta que lo desactives.';

  @override
  String claimShareText(String code) {
    return 'Reclama tu cuenta en Have You Fed The Dog?\nhttps://haveyoufedthedog.com/claim?code=$code\n\nSi el enlace no abre la app, ábrela, toca Registrarse y escribe el código de traspaso $code';
  }

  @override
  String get claimShareSubject => 'Have You Fed The Dog? - reclama tu cuenta';

  @override
  String get householdsYourTitle => 'Tus hogares';

  @override
  String get menuTooltip => 'Menú';

  @override
  String get menuEditProfile => 'Editar perfil';

  @override
  String get householdsEmpty =>
      'Todavía no estás en ningún hogar. Crea uno o únete con un código de invitación aquí abajo.';

  @override
  String get householdsCreateNew => 'Crear un nuevo hogar';

  @override
  String get householdsJoinWithCode => 'Unirse con código';

  @override
  String get createHouseholdTitle => 'Crear hogar';

  @override
  String get createHouseholdFailed => 'No se pudo crear';

  @override
  String get createHouseholdIntro =>
      'Crea un nuevo hogar: para tu familia, tus compañeros de piso o cualquiera con quien compartas tareas.';

  @override
  String get joinHouseholdTitle => 'Unirse a un hogar';

  @override
  String get joinHouseholdFailed => 'No se pudo unir';

  @override
  String get joinIntro =>
      '¿Alguien de la familia te dio un código? Pégalo aquí para unirte a su hogar.';

  @override
  String get inviteCodeLabel => 'Código de invitación';

  @override
  String get inviteCodeHint => 'p. ej. KIKO-7H4P';

  @override
  String get youTabTitle => 'Tú';

  @override
  String get youNoName => '(sin nombre)';

  @override
  String get movingDay => '¿Día de mudanza?';

  @override
  String get switchHousehold => 'Cambiar de hogar';

  @override
  String get whoseTurn => '¿A quién le toca?';

  @override
  String get whoseTurnSubtitle => 'Registra tareas en nombre de otro miembro';

  @override
  String actingTurn(String name) {
    return 'Le toca a $name';
  }

  @override
  String get myTurnAgain => 'Vuelvo yo';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get deleteAccountTooltip => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountBody =>
      'Tu cuenta se eliminará para siempre y se cerrará tu sesión. Las tareas que completaste se quedan en tu hogar, sin tu nombre. Los hogares que queden vacíos se eliminan por completo.\n\nNo se puede deshacer.';

  @override
  String get deleteForever => 'Eliminar para siempre';

  @override
  String couldNotDeleteAccount(String details) {
    return 'No se pudo eliminar la cuenta: $details';
  }

  @override
  String get profileNameHint => 'Cómo te ven los demás en tu hogar';

  @override
  String get emailCantChange => 'El correo no se puede cambiar.';

  @override
  String get nfcCompleteOnTap => 'Completar tarea con un toque NFC';

  @override
  String get nfcTapCompletesDesc =>
      'Tocar una etiqueta NFC completa la tarea actual.';

  @override
  String get nfcTapOpensDesc =>
      'Tocar una etiqueta NFC abre la página del protegido.';

  @override
  String get avatarDragOrTap => 'Arrastra o toca';

  @override
  String get avatarSurpriseMe => 'Sorpréndeme';

  @override
  String get navHome => 'Inicio';

  @override
  String get navThings => 'Protegidos';

  @override
  String get navAwards => 'Trofeos';

  @override
  String get navAddChore => 'Añadir una tarea';

  @override
  String get navAddChoreFor => 'Una tarea para…';

  @override
  String get storeTitle => 'Packs de imágenes';

  @override
  String get storeRestoreTooltip => 'Restaurar compras';

  @override
  String storeLoadFailed(String details) {
    return 'No se pudo cargar la tienda.\n$details';
  }

  @override
  String get storeNoPacks => 'Aún no hay packs disponibles.\n¡Vuelve pronto!';

  @override
  String get storeSupportNote =>
      'Hecho por un hombre y su perro. Sin anuncios. Sin suscripciones. Los packs mantienen la app.';

  @override
  String get storeAppliesTo =>
      'Los packs comprados o canjeados y las recompensas se desbloquean para todos los miembros de';

  @override
  String get storeRedeemTitle => 'Canjear un código';

  @override
  String get storeRedeemSubtitle => 'Desbloquea un pack con un código regalo';

  @override
  String get storePackCodeLabel => 'Código del pack';

  @override
  String get storePackCodeHint => 'WOOF-2026';

  @override
  String get storeApplyPack => 'Activar pack';

  @override
  String storeApplied(String name) {
    return '¡$name activado!';
  }

  @override
  String storeAlreadyApplied(String name) {
    return '$name ya está activado.';
  }

  @override
  String get storeCodeFailed => 'Ese código no funcionó';

  @override
  String get storeWorking => 'Un momento…';

  @override
  String storeBuy(String price) {
    return 'Comprar  $price';
  }

  @override
  String get storeOwned => 'Comprado';

  @override
  String get purchaseCouldNotStart => 'No se pudo iniciar la compra.';

  @override
  String get purchaseFailed => 'La compra falló.';

  @override
  String get purchaseNeedHousehold => 'Elige un hogar antes de comprar packs.';

  @override
  String get purchaseVerifyFailed => 'No se pudo verificar la compra.';

  @override
  String purchaseUnlocked(String name) {
    return '¡$name desbloqueado!';
  }

  @override
  String purchaseAlreadyUnlocked(String name) {
    return '$name ya está desbloqueado.';
  }

  @override
  String get rewardsTitle => 'Recompensas gratis';

  @override
  String get rewardsCharacters => 'Personajes';

  @override
  String get rewardsHouses => 'Casas';

  @override
  String rewardsStreakToClaim(int streak, int threshold) {
    return 'Racha $streak / $threshold para canjear';
  }

  @override
  String get rewardsNothingToClaim => 'Nada que canjear';

  @override
  String get rewardsClaim => 'Canjear';

  @override
  String get rewardsChooseCharacter => 'Elige un personaje';

  @override
  String get rewardsChooseHouse => 'Elige una casa';

  @override
  String get rewardsAllUnlocked =>
      'Ya lo has desbloqueado todo: con el tiempo llega más arte.';

  @override
  String get rewardsYourCollection => 'Tu colección';

  @override
  String get rewardsCollectionEmpty =>
      'Nada todavía: mantén la racha y canjea tu primera recompensa.';

  @override
  String rewardsAlreadyYours(String name) {
    return '$name ya es tuyo.';
  }

  @override
  String get rewardsClaimFailed => 'No se pudo canjear esa recompensa.';

  @override
  String get rewardsClaimYourReward => '¡Canjea tu recompensa aquí abajo!';

  @override
  String get rewardsYourStreak => 'Tu racha de recompensa';

  @override
  String get rewardsRedeemedToday =>
      '¡Enhorabuena! Empieza de nuevo y gana otra recompensa.';

  @override
  String get rewardsPickReward =>
      'Elige una recompensa para añadirla a tu colección.';

  @override
  String get rewardsKeepStreak =>
      'Mantén tu racha diaria y gana un personaje o una casa gratis.';

  @override
  String get rewardsCantWait => '¿No puedes esperar?';

  @override
  String get rewardsGetMoreHere => 'Consigue más aquí';

  @override
  String get rewardsUnlockedBang => '¡Desbloqueado!';

  @override
  String get rewardsViewCollection => 'Ver colección';

  @override
  String get rewardsBarAvailable => '¡Recompensa gratis disponible!';

  @override
  String get rewardsBarStreak => 'Racha de recompensa gratis';

  @override
  String get nfcWriteTagTitle => 'Escribir etiqueta NFC';

  @override
  String get nfcHoldTag =>
      'Acerca una etiqueta a la parte de arriba del teléfono…';

  @override
  String get nfcUnavailable =>
      'El NFC está apagado o no disponible en este dispositivo. Actívalo y reinténtalo.';

  @override
  String get nfcNotMemberHousehold =>
      'No eres miembro del hogar de esta etiqueta.';

  @override
  String get nfcTagNotInHousehold =>
      'Esta etiqueta apunta a algo que no está en este hogar.';

  @override
  String get nfcSignInFirst =>
      'Inicia sesión y elige un hogar para usar etiquetas NFC.';

  @override
  String nfcLogFailed(String details) {
    return 'Falló el registro NFC: $details';
  }

  @override
  String celebrationChoreDone(String name) {
    return '$name\n¡Hecho!';
  }

  @override
  String get celebrationStreakStarted => '🔥 ¡Racha iniciada!';

  @override
  String celebrationStreakDays(int count) {
    return '🔥 ¡Racha de $count días!';
  }

  @override
  String celebrationLoggedBy(String name) {
    return 'Registrada por $name';
  }

  @override
  String get celebrationNice => '¡Genial!';

  @override
  String get dayCelebrationBody =>
      'Toda la casa está contenta. ¡Buen trabajo, equipo!';

  @override
  String get dayCelebrationThanks => '¡Gracias!';

  @override
  String get dayCelebrationSeeAwards => 'Ver trofeos';

  @override
  String get claimSignedInTitle => 'Ya tienes la sesión iniciada';

  @override
  String get claimSignedInBody =>
      'Los enlaces de traspaso crean un acceso totalmente nuevo para un miembro que alguien creó para ti. No se pueden añadir a una cuenta ya iniciada: no fusionamos cuentas.';

  @override
  String get claimSignedInIfForYou => 'Si este código es para ti:';

  @override
  String get claimSignedInKeepOption =>
      '• Conservar esta cuenta: sigue con tu sesión y pide mejor un enlace de invitación al hogar.';

  @override
  String get claimSignedInBecomeOption =>
      '• Convertirte en ese miembro: elimina esta cuenta y el traspaso se abrirá automáticamente. Tus tareas completadas se quedan en el hogar.';

  @override
  String get claimKeepAccount => 'Conservar mi cuenta';

  @override
  String get claimDeleteAndClaim => 'Eliminar y reclamar';

  @override
  String get claimDeleteBody =>
      'Tu cuenta se eliminará para siempre y se cerrará tu sesión; después se abrirá el registro de traspaso. Las tareas que completaste se quedan en tu hogar, sin tu nombre.\n\nNo se puede deshacer.';

  @override
  String get awardComebackKidTitle => 'Gran Remontada';

  @override
  String get awardComebackKidDesc =>
      'La mayor mejora respecto a la semana pasada';

  @override
  String get awardEarlyBirdTitle => 'Madrugador';

  @override
  String get awardEarlyBirdDesc => 'Más tareas hechas antes de las 9';

  @override
  String get awardNightOwlTitle => 'Búho nocturno';

  @override
  String get awardNightOwlDesc => 'Más tareas hechas después de las 20';

  @override
  String get awardOnTheDotTitle => 'Puntualísimo';

  @override
  String get awardOnTheDotDesc =>
      'Más tareas hechas con menos de 15 minutos de margen';

  @override
  String get awardWeekendWarriorTitle => 'Guerrero del finde';

  @override
  String get awardWeekendWarriorDesc =>
      'Más tareas hechas el sábado y el domingo';

  @override
  String get awardTagChampionTitle => 'Campeón del tag';

  @override
  String get awardTagChampionDesc => 'Más tareas registradas con un toque NFC';

  @override
  String get characterAwardTitleDog => 'Mejor Humano 🩵';

  @override
  String get characterAwardTitleCat => 'Humano Menos Decepcionante';

  @override
  String get characterAwardTitlePlant => 'Mano Más Verde';

  @override
  String get characterAwardTitleBin => 'Señor de la Acera';

  @override
  String get characterAwardTitleFish => 'Guardián del Acuario';

  @override
  String get characterAwardTitleGeneric => 'Estrella del Hogar';

  @override
  String get characterAwardThanksDog =>
      '¡Gracias por ser un humano guau-nífico la semana pasada!';

  @override
  String get characterAwardThanksCat =>
      'Tuvo a bien aceptar tus servicios la semana pasada.';

  @override
  String get characterAwardThanksPlant =>
      '¡Gracias por mantenerlo todo creciendo la semana pasada!';

  @override
  String get characterAwardThanksBin =>
      '¡Gracias por mantenerlo todo rodando la semana pasada!';

  @override
  String get characterAwardThanksFish =>
      '¡Gracias por hacer olas la semana pasada!';

  @override
  String get characterAwardThanksGeneric =>
      '¡Gracias por ser increíble la semana pasada!';

  @override
  String get serverNotSignedIn => 'Debes iniciar sesión.';

  @override
  String get serverNotMember => 'No eres miembro de ese hogar.';

  @override
  String get serverOwnerOnly =>
      'Solo el propietario del hogar puede hacer eso.';

  @override
  String get serverNameRequired => 'Se necesita un nombre.';

  @override
  String get serverPasswordTooShort =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get serverClaimCodeInvalid => 'Ese código de traspaso no es válido.';

  @override
  String get serverEmailInUse => 'Ese correo ya está en uso.';

  @override
  String get serverNoSuchMember => 'Miembro no encontrado.';

  @override
  String get serverInviteCodeInvalid =>
      'No hay ningún hogar abierto con ese código.';

  @override
  String get serverPackCodeInvalid => 'No hay ningún pack con ese código.';

  @override
  String get serverPackGone => 'Ese pack ya no está disponible.';

  @override
  String get serverUnknownProduct => 'Producto desconocido.';

  @override
  String get serverVerifyFailed => 'No se pudo verificar esa compra.';

  @override
  String get serverVerifyUnavailable =>
      'La verificación de compras no está disponible ahora mismo.';

  @override
  String get serverRewardUnavailable => 'Ese elemento no se puede desbloquear.';

  @override
  String get serverStreakCheckFailed =>
      'No se pudo comprobar tu racha ahora mismo - reinténtalo en un momento.';

  @override
  String serverStreakTooLow(int threshold, int streak) {
    return 'Necesitas una racha de $threshold para desbloquearlo - llevas $streak.';
  }

  @override
  String get notifChannelName => 'Tareas completadas';

  @override
  String get notifChannelDesc =>
      'Cuando alguien de tu hogar registra una tarea.';

  @override
  String get characterNameDog => 'Perro';

  @override
  String get characterNameCat => 'Gato';

  @override
  String get characterNamePlant => 'Planta';

  @override
  String get characterNameBin => 'Cubo de basura';

  @override
  String get characterNameFish => 'Pez';

  @override
  String get characterNameGeneric => 'Otro';
}
