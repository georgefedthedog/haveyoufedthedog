// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Have You Fed The Dog?';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonRequired => 'Pflichtfeld';

  @override
  String get commonTryAgain => 'Nochmal versuchen';

  @override
  String get confirmByTypingWord => 'LÖSCHEN';

  @override
  String confirmByTypingHint(String word) {
    return 'Tippe $word zum Bestätigen';
  }

  @override
  String get passwordFieldLabel => 'Passwort';

  @override
  String get passwordFieldShow => 'Passwort anzeigen';

  @override
  String get passwordFieldHide => 'Passwort verbergen';

  @override
  String get profileLanguageLabel => 'Sprache';

  @override
  String get profileLanguageSystemDefault => 'Systemsprache';

  @override
  String get authWelcomeBack => 'Schön, dass du wieder da bist!';

  @override
  String get authJoinFamily => 'Werde Teil der Familie';

  @override
  String get authLoginTagline =>
      'Melde dich an und halte deinen Vierbeiner glücklich und satt.';

  @override
  String get authSignupTagline =>
      'Registriere dich und frag dich nie wieder, wer den Hund gefüttert hat.';

  @override
  String get authNoAccount => 'Noch kein Konto?';

  @override
  String get authHaveAccount => 'Schon ein Konto?';

  @override
  String get authLogIn => 'Anmelden';

  @override
  String get authSignUp => 'Registrieren';

  @override
  String get authEmailLabel => 'E-Mail';

  @override
  String get authEmailHint => 'Gib deine E-Mail ein';

  @override
  String get authEmailInvalid => 'Gib eine gültige E-Mail ein';

  @override
  String get authPasswordHint => 'Gib dein Passwort ein';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authLoginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String authLoginFailedDetails(String details) {
    return 'Anmeldung fehlgeschlagen: $details';
  }

  @override
  String get authYourNameLabel => 'Dein Name';

  @override
  String get authNameHint => 'Sichtbar für deine Mitbewohner';

  @override
  String get authNameHintClaim =>
      'Leer lassen, um deinen aktuellen Namen zu behalten';

  @override
  String get authPasswordRule => 'Mindestens 8 Zeichen';

  @override
  String get authChoosePasswordHint => 'Wähle ein Passwort';

  @override
  String get authClaimCodeToggle => 'Ich habe einen Übernahmecode';

  @override
  String get authClaimCodeLabel => 'Übernahmecode';

  @override
  String get authClaimCodeHint => 'Trittst du als bestehendes Mitglied bei?';

  @override
  String get authClaimAccount => 'Konto übernehmen';

  @override
  String get authCouldNotClaim => 'Konto konnte nicht übernommen werden';

  @override
  String get authSignupFailed => 'Registrierung fehlgeschlagen';

  @override
  String authSignupFailedDetails(String details) {
    return 'Registrierung fehlgeschlagen: $details';
  }

  @override
  String get authResetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get authResetIntro =>
      'Kein Stress - passiert den Besten.\nWir schicken dir einen Link für ein neues.';

  @override
  String get authSendResetLink => 'Link senden';

  @override
  String get authCheckInbox => 'Schau in dein Postfach!';

  @override
  String authResetSent(String email) {
    return 'Falls es ein Konto für $email gibt, ist ein Link zum Zurücksetzen unterwegs. Folge ihm, wähle ein neues Passwort und melde dich dann hier an.';
  }

  @override
  String authResetEmailFailed(String details) {
    return 'E-Mail konnte nicht gesendet werden: $details';
  }

  @override
  String get authBackToLogin => 'Zurück zur Anmeldung';

  @override
  String get startupErrorTitle => 'Start fehlgeschlagen';

  @override
  String get startupErrorBody =>
      'Prüfe deine Verbindung und versuch es nochmal.';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonSaveChanges => 'Speichern';

  @override
  String commonCouldNotSave(String details) {
    return 'Speichern fehlgeschlagen: $details';
  }

  @override
  String commonCouldNotDelete(String details) {
    return 'Löschen fehlgeschlagen: $details';
  }

  @override
  String commonDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String commonErrorDetails(String details) {
    return 'Fehler: $details';
  }

  @override
  String get homeErrorTitle => 'Hmm, da ist was schiefgelaufen';

  @override
  String homeErrorBody(String details) {
    return 'Deine Schützlinge konnten nicht geladen werden. $details';
  }

  @override
  String get homeNothingDueToday => 'Heute steht nichts an 🎉';

  @override
  String get homeTodaysChores => 'Aufgaben für heute';

  @override
  String get homeTapToComplete => 'Zum Abhaken tippen';

  @override
  String get homeSummaryAllDone => 'Alle Aufgaben für heute erledigt!';

  @override
  String get homeSummaryStart => 'Los geht\'s!';

  @override
  String get homeSummaryKeepUp => 'Läuft gut. Weiter so!';

  @override
  String homeSummaryCount(int done, int total) {
    return '$done von $total erledigt';
  }

  @override
  String get subjectsEmptyTitle => 'Noch keine Schützlinge';

  @override
  String get subjectsEmptyBody =>
      'Füg einen Hund, eine Katze, eine Pflanze hinzu - oder was sonst Pflege braucht.';

  @override
  String get subjectsAddThing => 'Schützling hinzufügen';

  @override
  String get subjectsTabTitle => 'Schützlinge';

  @override
  String get subjectsTabSubtitle =>
      'Mal Freunde, mal einfach Zeug. Alles, worum du dich kümmerst oder was du nicht vergessen willst.';

  @override
  String subjectsLoadFailed(String details) {
    return 'Schützlinge konnten nicht geladen werden: $details';
  }

  @override
  String get subjectNothingDueToday => 'Heute steht nichts an';

  @override
  String get subjectNoChoresYet => 'Noch keine Aufgaben';

  @override
  String subjectDoneToday(int done, int total) {
    return '$done von $total heute erledigt';
  }

  @override
  String subjectStreakDays(int count) {
    return '$count-Tage-Serie';
  }

  @override
  String get subjectNfcTagWritten => 'NFC-Tag beschrieben';

  @override
  String get subjectManageChoresLink => 'Aufgaben verwalten →';

  @override
  String get subjectCompletedChores => 'Erledigte Aufgaben';

  @override
  String get subjectSeeAll => 'Alle ansehen →';

  @override
  String subjectHistoryLoadFailed(String details) {
    return 'Verlauf konnte nicht geladen werden: $details';
  }

  @override
  String get subjectNoCompletions => 'Noch nichts eingetragen.';

  @override
  String editSubjectTitle(String name) {
    return '$name bearbeiten';
  }

  @override
  String get editSubjectNewTitle => 'Neuer Schützling';

  @override
  String get editSubjectDeleteTooltip => 'Schützling löschen';

  @override
  String get editSubjectDeleteBody =>
      'Alle Aufgaben und der Verlauf dieses Schützlings werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get editSubjectNameLabel => 'Name';

  @override
  String get editSubjectNameHint => 'z. B. Kiko';

  @override
  String get editSubjectAdd => 'Schützling hinzufügen';

  @override
  String get editSubjectManageChores => 'Aufgaben verwalten';

  @override
  String get editSubjectDeleteChoreBody =>
      'Zeitplan und Erinnerungen gehen mit. Bereits Erledigtes bleibt im Verlauf.';

  @override
  String get editSubjectTagWritten => 'Tag beschrieben';

  @override
  String get editSubjectNoTag => 'Noch kein Tag';

  @override
  String get editSubjectTapCompletes =>
      'Auf diesem Handy hakt ein Tipp die aktuelle Aufgabe ab. Ändern kannst du das unter';

  @override
  String get editSubjectTapOpens =>
      'Auf diesem Handy öffnet ein Tipp die Seite des Schützlings. Ändern kannst du das unter';

  @override
  String get editSubjectEditProfileLink => 'Profil bearbeiten';

  @override
  String get editSubjectWriteTagPrompt =>
      'Beschreibe einen Tag, um per Tipp einzutragen.';

  @override
  String get editSubjectWriteTag => 'NFC-Tag beschreiben';

  @override
  String get editSubjectWriteAnotherTag => 'Weiteren NFC-Tag beschreiben';

  @override
  String get editSubjectForgetTag => 'Tag vergessen';

  @override
  String editSubjectSaveTagFailed(String details) {
    return 'Tag konnte nicht gespeichert werden: $details';
  }

  @override
  String editSubjectForgetTagFailed(String details) {
    return 'Vergessen fehlgeschlagen: $details';
  }

  @override
  String get browseMoreCharacters => 'Mehr Charaktere →';

  @override
  String get commonToday => 'Heute';

  @override
  String get commonYesterday => 'Gestern';

  @override
  String scheduleDaily(String time) {
    return 'Jeden Tag um $time';
  }

  @override
  String scheduleWeeklyAt(String days, String time) {
    return '$days um $time';
  }

  @override
  String get scheduleNever => 'Nie';

  @override
  String scheduleFortnightly(String days, String time, String phase) {
    return 'Alle zwei Wochen am $days um $time · $phase';
  }

  @override
  String get scheduleThisWeek => 'diese Woche';

  @override
  String get scheduleNextWeek => 'nächste Woche';

  @override
  String scheduleMonthlyOnDayAt(String day, String time) {
    return 'Monatlich am $day um $time';
  }

  @override
  String scheduleMonthlyLastDayAt(String time) {
    return 'Monatlich am letzten Tag um $time';
  }

  @override
  String scheduleMonthlyOnWeekdayAt(
    String position,
    String weekday,
    String time,
  ) {
    return 'Monatlich am $position $weekday um $time';
  }

  @override
  String get schedulePositionFirst => 'ersten';

  @override
  String get schedulePositionSecond => 'zweiten';

  @override
  String get schedulePositionThird => 'dritten';

  @override
  String get schedulePositionFourth => 'vierten';

  @override
  String get schedulePositionLast => 'letzten';

  @override
  String scheduleOnceAt(String time) {
    return 'Einmalig um $time';
  }

  @override
  String scheduleOnceOn(String date, String time) {
    return 'Einmalig am $date um $time';
  }

  @override
  String overdueMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten überfällig',
      one: '1 Minute überfällig',
    );
    return '$_temp0';
  }

  @override
  String overdueHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'über $count Stunden überfällig',
      one: '1 Stunde überfällig',
    );
    return '$_temp0';
  }

  @override
  String get dueIn => 'Fällig in';

  @override
  String dueInUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Std.',
      one: 'Stunde',
    );
    return '$_temp0';
  }

  @override
  String dueInUnitMins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Min.',
      one: 'Min.',
    );
    return '$_temp0';
  }

  @override
  String get editChorePickDate => 'Wähle ein Datum';

  @override
  String editChoreMonthDayItem(String day) {
    return 'Am $day';
  }

  @override
  String get editChoreLastDay => 'Am letzten Tag';

  @override
  String get commonYou => 'Du';

  @override
  String get commonSomeone => 'Jemand';

  @override
  String choreCouldNotLog(String details) {
    return 'Eintragen fehlgeschlagen: $details';
  }

  @override
  String choreCouldNotUndo(String details) {
    return 'Zurücknehmen fehlgeschlagen: $details';
  }

  @override
  String choreRemoved(String name) {
    return 'Zurückgenommen: $name';
  }

  @override
  String get choreUndoNotAllowed =>
      'Wechsle zu der Person, die es eingetragen hat (oder frag den Besitzer), um es zurückzunehmen.';

  @override
  String undoDialogTitle(String name) {
    return '„$name“ zurücknehmen?';
  }

  @override
  String get undoDialogBody =>
      'Die Aufgabe gilt wieder als offen, und der Rest des Haushalts wird informiert.';

  @override
  String get undoDialogAction => 'Zurücknehmen';

  @override
  String get choreUsuallyDoneAround => 'Meist erledigt gegen';

  @override
  String get choreOneTimePill => 'Einmalig';

  @override
  String choreCompletedBy(String name) {
    return 'Erledigt von $name';
  }

  @override
  String get editChoreTitle => 'Aufgabe bearbeiten';

  @override
  String get editChoreNewTitle => 'Neue Aufgabe';

  @override
  String get editChoreDeleteTooltip => 'Aufgabe löschen';

  @override
  String get editChoreDeleteBody =>
      'Der gesamte Verlauf dieser Aufgabe wird endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get editChoreNameLabel => 'Name';

  @override
  String get editChoreNameHint => 'z. B. Frühstück';

  @override
  String get editChoreScheduleLabel => 'Zeitplan';

  @override
  String get editChoreRepeats => 'Wiederholt sich';

  @override
  String get editChoreOneTime => 'Einmalig';

  @override
  String get editChoreFrequencyLabel => 'Häufigkeit';

  @override
  String get editChoreFreqDaily => 'Jeden Tag';

  @override
  String get editChoreFreqWeekly => 'Bestimmte Tage';

  @override
  String get editChoreFreqMonthly => 'Monatlich';

  @override
  String get editChoreOnTheseDays => 'An diesen Tagen';

  @override
  String get editChorePickOneDay => 'Wähle mindestens einen Tag.';

  @override
  String get editChoreHowOften => 'Wie oft';

  @override
  String get editChoreEveryWeek => 'Jede Woche';

  @override
  String get editChoreFortnightly => 'Alle zwei Wochen';

  @override
  String get editChoreStarting => 'Ab';

  @override
  String get editChoreThisWeek => 'Diese Woche';

  @override
  String get editChoreNextWeek => 'Nächste Woche';

  @override
  String get editChoreOnThe => 'Am';

  @override
  String get editChoreExactDay => 'Festen Tag';

  @override
  String get editChorePosFirst => 'Ersten';

  @override
  String get editChorePosSecond => 'Zweiten';

  @override
  String get editChorePosThird => 'Dritten';

  @override
  String get editChorePosFourth => 'Vierten';

  @override
  String get editChorePosLast => 'Letzten';

  @override
  String get editChoreDayLabel => 'Tag';

  @override
  String get editChoreWeekdayLabel => 'Wochentag';

  @override
  String get editChoreOnDateLabel => 'Am';

  @override
  String get editChoreAtTimeLabel => 'Um';

  @override
  String get editChoreAddChore => 'Aufgabe hinzufügen';

  @override
  String get timelineLogged => 'Eingetragen';

  @override
  String get historyAwardsTitle => 'Trophäen';

  @override
  String get historyDayStreak => 'Tage-Serie';

  @override
  String get historyThisWeek => 'Diese Woche';

  @override
  String historyCleanSweeps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Perfekte Tage',
      one: 'Perfekter Tag',
    );
    return '$_temp0';
  }

  @override
  String get historyAllActivity => 'Alle Aktivitäten';

  @override
  String get historyFilterAll => 'Alle';

  @override
  String get historyEmptyTitle => 'Hier ist noch nichts!';

  @override
  String get historyEmptyBody => 'Sei der Erste, der eine Aufgabe erledigt.';

  @override
  String get leaderboardEmpty =>
      'Diese Woche wurde noch keine Aufgabe erledigt!';

  @override
  String leaderboardYouSuffix(String name) {
    return '$name (du)';
  }

  @override
  String get awardsBadges => 'Abzeichen';

  @override
  String get awardsTeamEffort => 'Teamgeist';

  @override
  String get awardsTeamEffortDesc =>
      'Alle haben mit angepackt - die Last war fair verteilt';

  @override
  String get awardsUnclaimed => 'Unvergeben';

  @override
  String get awardsLastWeeksWinner => 'SIEGER DER LETZTEN WOCHE';

  @override
  String awardsSubjectPossessive(String name) {
    return '${name}s';
  }

  @override
  String awardsNoWinnerYet(String name) {
    return 'Letzte Woche kein Sieger - erledige die meisten Aufgaben von $name und hol dir den Titel nächstes Mal!';
  }

  @override
  String awardsChoreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben',
      one: '$count Aufgabe',
    );
    return '$_temp0';
  }

  @override
  String get commonLogOut => 'Abmelden';

  @override
  String get householdTitle => 'Haushalt';

  @override
  String get householdNoLonger =>
      'Du bist kein Mitglied dieses Haushalts mehr.';

  @override
  String get householdDeleteTooltip => 'Haushalt löschen';

  @override
  String get householdDeleteBody =>
      'Alle Schützlinge, Aufgaben und der Verlauf dieses Haushalts werden für alle Mitglieder endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String householdLeaveTitle(String name) {
    return '$name verlassen?';
  }

  @override
  String get householdLeaveBody =>
      'Du siehst die Aufgaben und Aktivitäten dieses Haushalts dann nicht mehr. Mit einem Einladungscode kannst du später wieder beitreten.';

  @override
  String get householdLeave => 'Verlassen';

  @override
  String householdDeleteManagedBody(String name) {
    return '$name ist ein verwaltetes Mitglied - das entfernt es komplett. Erledigte Aufgaben zählen weiter, erscheinen aber als „Jemand“.';
  }

  @override
  String get browseMoreHomes => 'Mehr Häuser →';

  @override
  String get browseMoreAvatars => 'Mehr Avatare →';

  @override
  String get householdNameLabel => 'Name des Haushalts';

  @override
  String get householdNameHint => 'z. B. „Villa Kunterbunt“ oder „Zuhause“';

  @override
  String get householdResidentsLabel => 'Wer wohnt hier?';

  @override
  String get householdResidentsHint => 'Die Musterfamilie';

  @override
  String householdTimezone(String tz) {
    return 'Zeitzone: $tz';
  }

  @override
  String get householdUsePhoneTz => 'Die vom Handy nehmen';

  @override
  String get householdMembersFallback => 'Mitglieder';

  @override
  String get householdSaveFailed => 'Speichern fehlgeschlagen';

  @override
  String get householdRoleOwner => 'Besitzer';

  @override
  String get householdRoleMember => 'Mitglied';

  @override
  String get addSomeoneTitle => 'Jemanden hinzufügen';

  @override
  String get addInviteTitle => 'Jemanden mit eigenem Konto einladen';

  @override
  String get addInviteSubtitle =>
      'Familie oder Mitbewohner, die sich auf ihrem eigenen Handy anmelden. Sie treten mit einem Code bei und tragen ihre Aufgaben selbst ein.';

  @override
  String get addManagedTitle => 'Jemanden ohne Konto hinzufügen';

  @override
  String get addManagedSubtitle =>
      'Für alle ohne eigenes Konto. Du verwaltest ihr Profil und trägst ihre Aufgaben ein, indem du mit „Wer ist dran?“ im Du-Tab zu ihnen wechselst.';

  @override
  String get inviteSomeone => 'Jemanden einladen';

  @override
  String get inviteSubtitle => 'Lade Familie oder Mitbewohner ein';

  @override
  String get invitesOn => 'Einladungen offen';

  @override
  String get invitesOff => 'Einladungen geschlossen';

  @override
  String get inviteLiveUntil => 'Gültig, bis du Einladungen schließt';

  @override
  String get shareCode => 'Code teilen';

  @override
  String get generateNewCode => 'Neuen Code erzeugen';

  @override
  String inviteShareText(String code) {
    return 'Tritt unserem Haushalt bei auf Have You Fed The Dog?\nhttps://haveyoufedthedog.com/join?code=$code\n\nFalls der Link die App nicht öffnet: öffne sie und gib den Einladungscode $code ein';
  }

  @override
  String get inviteShareSubject =>
      'Have You Fed The Dog? - Einladung zum Haushalt';

  @override
  String membersLoadFailed(String details) {
    return 'Mitglieder konnten nicht geladen werden: $details';
  }

  @override
  String memberRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String memberRemoveBody(String name) {
    return '$name verliert sofort den Zugriff auf diesen Haushalt. Mit einem Einladungscode ist ein späterer Beitritt wieder möglich.';
  }

  @override
  String get memberRemove => 'Entfernen';

  @override
  String get memberOwner => 'Besitzer';

  @override
  String get editMemberTitle => 'Mitglied bearbeiten';

  @override
  String get addMemberTitle => 'Mitglied hinzufügen';

  @override
  String get deleteMemberTooltip => 'Mitglied löschen';

  @override
  String get displayNameLabel => 'Anzeigename';

  @override
  String get memberNameHint => 'So sehen die anderen dieses Mitglied';

  @override
  String get claimLoginTitle => 'Eigenes Konto ermöglichen';

  @override
  String get claimLoginSubtitle =>
      'So kann dieses Mitglied das Konto übernehmen und sich selbst anmelden';

  @override
  String get claimCodeInfo =>
      'Wird bei der Registrierung eingegeben. Gültig, bis du es abschaltest.';

  @override
  String claimShareText(String code) {
    return 'Übernimm dein Konto auf Have You Fed The Dog?\nhttps://haveyoufedthedog.com/claim?code=$code\n\nFalls der Link die App nicht öffnet: öffne sie, tippe auf Registrieren und gib den Übernahmecode $code ein';
  }

  @override
  String get claimShareSubject => 'Have You Fed The Dog? - übernimm dein Konto';

  @override
  String get householdsYourTitle => 'Deine Haushalte';

  @override
  String get menuTooltip => 'Menü';

  @override
  String get menuEditProfile => 'Profil bearbeiten';

  @override
  String get householdsEmpty =>
      'Du bist noch in keinem Haushalt. Erstelle unten einen oder tritt mit einem Einladungscode bei.';

  @override
  String get householdsCreateNew => 'Neuen Haushalt erstellen';

  @override
  String get householdsJoinWithCode => 'Mit Einladungscode beitreten';

  @override
  String get createHouseholdTitle => 'Haushalt erstellen';

  @override
  String get createHouseholdFailed => 'Erstellen fehlgeschlagen';

  @override
  String get createHouseholdIntro =>
      'Starte einen neuen Haushalt - für deine Familie, deine WG oder alle, mit denen du dir Aufgaben teilst.';

  @override
  String get joinHouseholdTitle => 'Haushalt beitreten';

  @override
  String get joinHouseholdFailed => 'Beitritt fehlgeschlagen';

  @override
  String get joinIntro =>
      'Hast du einen Code aus der Familie bekommen? Füg ihn hier ein und tritt dem Haushalt bei.';

  @override
  String get inviteCodeLabel => 'Einladungscode';

  @override
  String get inviteCodeHint => 'z. B. KIKO-7H4P';

  @override
  String get youTabTitle => 'Du';

  @override
  String get youNoName => '(kein Name)';

  @override
  String get movingDay => 'Umzugstag?';

  @override
  String get switchHousehold => 'Haushalt wechseln';

  @override
  String get whoseTurn => 'Wer ist dran?';

  @override
  String get whoseTurnSubtitle => 'Trage Aufgaben für ein anderes Mitglied ein';

  @override
  String actingTurn(String name) {
    return '$name ist dran';
  }

  @override
  String get myTurnAgain => 'Wieder ich';

  @override
  String get editProfileTitle => 'Profil bearbeiten';

  @override
  String get deleteAccountTooltip => 'Konto löschen';

  @override
  String get deleteAccountTitle => 'Dein Konto löschen?';

  @override
  String get deleteAccountBody =>
      'Dein Konto wird endgültig gelöscht und du wirst abgemeldet. Deine erledigten Aufgaben bleiben im Haushalt, ohne deinen Namen. Haushalte, in denen niemand mehr ist, werden komplett gelöscht.\n\nDas lässt sich nicht rückgängig machen.';

  @override
  String get deleteForever => 'Endgültig löschen';

  @override
  String couldNotDeleteAccount(String details) {
    return 'Konto konnte nicht gelöscht werden: $details';
  }

  @override
  String get profileNameHint => 'So sehen dich die anderen im Haushalt';

  @override
  String get emailCantChange => 'Die E-Mail lässt sich nicht ändern.';

  @override
  String get nfcCompleteOnTap => 'Aufgabe per Tipp abhaken';

  @override
  String get nfcTapCompletesDesc =>
      'Ein Tipp auf einen Tag hakt die aktuelle Aufgabe ab.';

  @override
  String get nfcTapOpensDesc =>
      'Ein Tipp auf einen Tag öffnet die Seite des Schützlings.';

  @override
  String get avatarDragOrTap => 'Ziehen oder tippen';

  @override
  String get avatarSurpriseMe => 'Überrasch mich';

  @override
  String get navHome => 'Start';

  @override
  String get navThings => 'Schützlinge';

  @override
  String get navAwards => 'Trophäen';

  @override
  String get navAddChore => 'Aufgabe hinzufügen';

  @override
  String get navAddChoreFor => 'Eine Aufgabe für…';

  @override
  String get storeTitle => 'Bildpakete';

  @override
  String get storeRestoreTooltip => 'Käufe wiederherstellen';

  @override
  String storeLoadFailed(String details) {
    return 'Der Shop konnte nicht geladen werden.\n$details';
  }

  @override
  String get storeNoPacks =>
      'Noch keine Pakete verfügbar.\nSchau bald wieder rein!';

  @override
  String get storeSupportNote =>
      'Gemacht von einem Mann und seinem Hund. Keine Werbung. Kein Abo. Pakete unterstützen die App.';

  @override
  String get storeAppliesTo =>
      'Gekaufte oder eingelöste Pakete und Belohnungen werden freigeschaltet für alle Mitglieder von';

  @override
  String get storeRedeemTitle => 'Code einlösen';

  @override
  String get storeRedeemSubtitle =>
      'Schalte ein Paket mit einem Geschenkcode frei';

  @override
  String get storePackCodeLabel => 'Paketcode';

  @override
  String get storePackCodeHint => 'WOOF-2026';

  @override
  String get storeApplyPack => 'Paket aktivieren';

  @override
  String storeApplied(String name) {
    return '$name aktiviert!';
  }

  @override
  String storeAlreadyApplied(String name) {
    return '$name ist schon aktiviert.';
  }

  @override
  String get storeCodeFailed => 'Der Code hat nicht funktioniert';

  @override
  String get storeWorking => 'Einen Moment…';

  @override
  String storeBuy(String price) {
    return 'Kaufen  $price';
  }

  @override
  String get storeOwned => 'Gekauft';

  @override
  String get purchaseCouldNotStart => 'Der Kauf konnte nicht gestartet werden.';

  @override
  String get purchaseFailed => 'Der Kauf ist fehlgeschlagen.';

  @override
  String get purchaseNeedHousehold =>
      'Wähle zuerst einen Haushalt, bevor du Pakete kaufst.';

  @override
  String get purchaseVerifyFailed => 'Der Kauf konnte nicht überprüft werden.';

  @override
  String purchaseUnlocked(String name) {
    return '$name freigeschaltet!';
  }

  @override
  String purchaseAlreadyUnlocked(String name) {
    return '$name ist schon freigeschaltet.';
  }

  @override
  String get rewardsTitle => 'Gratis-Belohnungen';

  @override
  String get rewardsCharacters => 'Charaktere';

  @override
  String get rewardsHouses => 'Häuser';

  @override
  String rewardsStreakToClaim(int streak, int threshold) {
    return 'Serie $streak / $threshold zum Einlösen';
  }

  @override
  String get rewardsNothingToClaim => 'Nichts einzulösen';

  @override
  String get rewardsClaim => 'Einlösen';

  @override
  String get rewardsChooseCharacter => 'Wähle einen Charakter';

  @override
  String get rewardsChooseHouse => 'Wähle ein Haus';

  @override
  String get rewardsAllUnlocked =>
      'Du hast hier alles freigeschaltet - mit der Zeit kommt neue Kunst dazu.';

  @override
  String get rewardsYourCollection => 'Deine Sammlung';

  @override
  String get rewardsCollectionEmpty =>
      'Noch nichts - halte deine Serie und lös deine erste Belohnung ein.';

  @override
  String rewardsAlreadyYours(String name) {
    return '$name gehört dir schon.';
  }

  @override
  String get rewardsClaimFailed =>
      'Die Belohnung konnte nicht eingelöst werden.';

  @override
  String get rewardsClaimYourReward => 'Lös unten deine Belohnung ein!';

  @override
  String get rewardsYourStreak => 'Deine Belohnungsserie';

  @override
  String get rewardsRedeemedToday =>
      'Glückwunsch! Starte neu und verdiene die nächste Belohnung.';

  @override
  String get rewardsPickReward => 'Wähle eine Belohnung für deine Sammlung.';

  @override
  String get rewardsKeepStreak =>
      'Halte deine tägliche Serie und verdiene einen Charakter oder ein Haus gratis.';

  @override
  String get rewardsCantWait => 'Zu ungeduldig?';

  @override
  String get rewardsGetMoreHere => 'Hier gibt\'s mehr';

  @override
  String get rewardsUnlockedBang => 'Freigeschaltet!';

  @override
  String get rewardsViewCollection => 'Sammlung ansehen';

  @override
  String get rewardsBarAvailable => 'Gratis-Belohnung verfügbar!';

  @override
  String get rewardsBarStreak => 'Gratis-Belohnungsserie';

  @override
  String get nfcWriteTagTitle => 'NFC-Tag beschreiben';

  @override
  String get nfcHoldTag => 'Halte einen Tag oben ans Handy…';

  @override
  String get nfcUnavailable =>
      'NFC ist aus oder auf diesem Gerät nicht verfügbar. Schalte NFC ein und versuch es nochmal.';

  @override
  String get nfcNotMemberHousehold =>
      'Du bist kein Mitglied des Haushalts dieses Tags.';

  @override
  String get nfcTagNotInHousehold =>
      'Dieser Tag zeigt auf etwas, das nicht in diesem Haushalt ist.';

  @override
  String get nfcSignInFirst =>
      'Melde dich an und wähle einen Haushalt, um NFC-Tags zu nutzen.';

  @override
  String nfcLogFailed(String details) {
    return 'NFC-Eintrag fehlgeschlagen: $details';
  }

  @override
  String celebrationChoreDone(String name) {
    return '$name\nErledigt!';
  }

  @override
  String get celebrationStreakStarted => '🔥 Serie gestartet!';

  @override
  String celebrationStreakDays(int count) {
    return '🔥 $count-Tage-Serie!';
  }

  @override
  String celebrationLoggedBy(String name) {
    return 'Eingetragen von $name';
  }

  @override
  String get celebrationNice => 'Stark!';

  @override
  String get dayCelebrationBody =>
      'Das ganze Haus ist glücklich. Starke Teamleistung!';

  @override
  String get dayCelebrationThanks => 'Danke!';

  @override
  String get dayCelebrationSeeAwards => 'Trophäen ansehen';

  @override
  String get claimSignedInTitle => 'Du bist schon angemeldet';

  @override
  String get claimSignedInBody =>
      'Übernahme-Links richten einen ganz neuen Zugang für ein Mitglied ein, das jemand für dich angelegt hat. Sie lassen sich nicht mit einem bereits angemeldeten Konto verbinden - Konten werden nicht zusammengeführt.';

  @override
  String get claimSignedInIfForYou => 'Wenn dieser Code für dich ist:';

  @override
  String get claimSignedInKeepOption =>
      '• Dieses Konto behalten - bleib als du angemeldet und bitte stattdessen um einen Einladungslink zum Haushalt.';

  @override
  String get claimSignedInBecomeOption =>
      '• Dieses Mitglied werden - lösche dieses Konto, danach öffnet sich die Übernahme automatisch. Deine erledigten Aufgaben bleiben im Haushalt.';

  @override
  String get claimKeepAccount => 'Konto behalten';

  @override
  String get claimDeleteAndClaim => 'Löschen & übernehmen';

  @override
  String get claimDeleteBody =>
      'Dein Konto wird endgültig gelöscht und du wirst abgemeldet, danach öffnet sich die Übernahme-Registrierung. Deine erledigten Aufgaben bleiben im Haushalt, ohne deinen Namen.\n\nDas lässt sich nicht rückgängig machen.';

  @override
  String get awardComebackKidTitle => 'Comeback-Kid';

  @override
  String get awardComebackKidDesc =>
      'Größte Steigerung gegenüber letzter Woche';

  @override
  String get awardEarlyBirdTitle => 'Früher Vogel';

  @override
  String get awardEarlyBirdDesc => 'Die meisten Aufgaben vor 9 Uhr';

  @override
  String get awardNightOwlTitle => 'Nachteule';

  @override
  String get awardNightOwlDesc => 'Die meisten Aufgaben nach 20 Uhr';

  @override
  String get awardOnTheDotTitle => 'Auf den Punkt';

  @override
  String get awardOnTheDotDesc => 'Die meisten Aufgaben auf 15 Minuten genau';

  @override
  String get awardWeekendWarriorTitle => 'Wochenend-Held';

  @override
  String get awardWeekendWarriorDesc =>
      'Die meisten Aufgaben am Samstag und Sonntag';

  @override
  String get awardTagChampionTitle => 'Tag-Champion';

  @override
  String get awardTagChampionDesc => 'Die meisten Aufgaben per NFC-Tipp';

  @override
  String get characterAwardTitleDog => 'Bester Mensch 🩵';

  @override
  String get characterAwardTitleCat => 'Am wenigsten enttäuschender Mensch';

  @override
  String get characterAwardTitlePlant => 'Grünster Daumen';

  @override
  String get characterAwardTitleBin => 'König des Bordsteins';

  @override
  String get characterAwardTitleFish => 'Hüter des Aquariums';

  @override
  String get characterAwardTitleGeneric => 'Held des Haushalts';

  @override
  String get characterAwardThanksDog =>
      'Danke, dass du letzte Woche pfoten-tastisch warst!';

  @override
  String get characterAwardThanksCat =>
      'Hat letzte Woche gnädig deine Dienste angenommen.';

  @override
  String get characterAwardThanksPlant =>
      'Danke, dass letzte Woche alles gewachsen und gediehen ist!';

  @override
  String get characterAwardThanksBin =>
      'Danke, dass letzte Woche alles wie geschmiert gerollt ist!';

  @override
  String get characterAwardThanksFish =>
      'Danke, dass du letzte Woche Wellen geschlagen hast!';

  @override
  String get characterAwardThanksGeneric =>
      'Danke, dass du letzte Woche großartig warst!';

  @override
  String get serverNotSignedIn => 'Du musst angemeldet sein.';

  @override
  String get serverNotMember => 'Du bist kein Mitglied dieses Haushalts.';

  @override
  String get serverOwnerOnly => 'Das kann nur der Besitzer des Haushalts.';

  @override
  String get serverNameRequired => 'Ein Name ist erforderlich.';

  @override
  String get serverPasswordTooShort =>
      'Das Passwort braucht mindestens 8 Zeichen.';

  @override
  String get serverClaimCodeInvalid => 'Dieser Übernahmecode ist ungültig.';

  @override
  String get serverEmailInUse => 'Diese E-Mail wird schon verwendet.';

  @override
  String get serverNoSuchMember => 'Mitglied nicht gefunden.';

  @override
  String get serverInviteCodeInvalid =>
      'Kein offener Haushalt mit diesem Code.';

  @override
  String get serverPackCodeInvalid => 'Kein Paket mit diesem Code.';

  @override
  String get serverPackGone => 'Dieses Paket ist nicht mehr einlösbar.';

  @override
  String get serverUnknownProduct => 'Unbekanntes Produkt.';

  @override
  String get serverVerifyFailed => 'Der Kauf konnte nicht überprüft werden.';

  @override
  String get serverVerifyUnavailable =>
      'Die Kaufprüfung ist gerade nicht verfügbar.';

  @override
  String get serverRewardUnavailable =>
      'Dieses Element lässt sich nicht freischalten.';

  @override
  String get serverStreakCheckFailed =>
      'Deine Serie lässt sich gerade nicht prüfen - versuch es gleich nochmal.';

  @override
  String serverStreakTooLow(int threshold, int streak) {
    return 'Du brauchst eine Serie von $threshold, um das freizuschalten - du bist bei $streak.';
  }

  @override
  String get notifChannelName => 'Erledigte Aufgaben';

  @override
  String get notifChannelDesc =>
      'Wenn jemand in deinem Haushalt eine Aufgabe einträgt.';
}
