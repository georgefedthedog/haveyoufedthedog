// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Have You Fed The Dog?';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonRequired => 'Obligatoire';

  @override
  String get commonTryAgain => 'Réessayer';

  @override
  String get confirmByTypingWord => 'SUPPRIMER';

  @override
  String confirmByTypingHint(String word) {
    return 'Tape $word pour confirmer';
  }

  @override
  String get passwordFieldLabel => 'Mot de passe';

  @override
  String get passwordFieldShow => 'Afficher le mot de passe';

  @override
  String get passwordFieldHide => 'Masquer le mot de passe';

  @override
  String get profileLanguageLabel => 'Langue';

  @override
  String get profileLanguageSystemDefault => 'Langue du système';

  @override
  String get authWelcomeBack => 'Content de te revoir !';

  @override
  String get authJoinFamily => 'Rejoins la famille';

  @override
  String get authLoginTagline =>
      'Connecte-toi pour garder ton toutou heureux et bien nourri.';

  @override
  String get authSignupTagline =>
      'Inscris-toi et ne te demande plus jamais qui a nourri le chien.';

  @override
  String get authNoAccount => 'Pas encore de compte ?';

  @override
  String get authHaveAccount => 'Déjà un compte ?';

  @override
  String get authLogIn => 'Se connecter';

  @override
  String get authSignUp => 'S\'inscrire';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailHint => 'Saisis ton e-mail';

  @override
  String get authEmailInvalid => 'Saisis un e-mail valide';

  @override
  String get authPasswordHint => 'Saisis ton mot de passe';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authLoginFailed => 'Échec de la connexion';

  @override
  String authLoginFailedDetails(String details) {
    return 'Échec de la connexion : $details';
  }

  @override
  String get authYourNameLabel => 'Ton nom';

  @override
  String get authNameHint => 'Visible par les membres de ton foyer';

  @override
  String get authNameHintClaim => 'Laisse vide pour garder ton nom actuel';

  @override
  String get authPasswordRule => 'Au moins 8 caractères';

  @override
  String get authChoosePasswordHint => 'Choisis un mot de passe';

  @override
  String get authClaimCodeToggle => 'J\'ai un code de récupération';

  @override
  String get authClaimCodeLabel => 'Code de récupération';

  @override
  String get authClaimCodeHint => 'Tu rejoins comme membre existant ?';

  @override
  String get authClaimAccount => 'Récupérer le compte';

  @override
  String get authCouldNotClaim => 'Impossible de récupérer le compte';

  @override
  String get authSignupFailed => 'Échec de l\'inscription';

  @override
  String authSignupFailedDetails(String details) {
    return 'Échec de l\'inscription : $details';
  }

  @override
  String get authResetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get authResetIntro =>
      'Pas de panique - ça arrive aux meilleurs.\nOn t\'enverra un lien pour en choisir un nouveau.';

  @override
  String get authSendResetLink => 'Envoyer le lien';

  @override
  String get authCheckInbox => 'Va voir ta boîte mail !';

  @override
  String authResetSent(String email) {
    return 'S\'il existe un compte pour $email, un lien de réinitialisation est en route. Suis-le pour choisir un nouveau mot de passe, puis connecte-toi ici.';
  }

  @override
  String authResetEmailFailed(String details) {
    return 'Impossible d\'envoyer l\'e-mail : $details';
  }

  @override
  String get authBackToLogin => 'Retour à la connexion';

  @override
  String get startupErrorTitle => 'Impossible de démarrer';

  @override
  String get startupErrorBody => 'Vérifie ta connexion et réessaie.';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonSaveChanges => 'Enregistrer';

  @override
  String commonCouldNotSave(String details) {
    return 'Échec de l\'enregistrement : $details';
  }

  @override
  String commonCouldNotDelete(String details) {
    return 'Échec de la suppression : $details';
  }

  @override
  String commonDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String commonErrorDetails(String details) {
    return 'Erreur : $details';
  }

  @override
  String get homeErrorTitle => 'Hmm, quelque chose a coincé';

  @override
  String homeErrorBody(String details) {
    return 'Impossible de charger tes protégés. $details';
  }

  @override
  String get homeNothingDueToday => 'Rien à faire aujourd\'hui 🎉';

  @override
  String get homeTodaysChores => 'Les corvées du jour';

  @override
  String get homeTapToComplete => 'Touche pour valider';

  @override
  String get homeSummaryAllDone => 'Toutes les corvées du jour sont faites !';

  @override
  String get homeSummaryStart => 'C\'est parti !';

  @override
  String get homeSummaryKeepUp => 'Ça avance bien. Continue !';

  @override
  String homeSummaryCount(int done, int total) {
    return '$done sur $total faites';
  }

  @override
  String get subjectsEmptyTitle => 'Aucun protégé pour l\'instant';

  @override
  String get subjectsEmptyBody =>
      'Ajoute un chien, un chat, une plante, ou tout ce qui a besoin de soins.';

  @override
  String get subjectsAddThing => 'Ajouter un protégé';

  @override
  String get subjectsTabTitle => 'Protégés';

  @override
  String get subjectsTabSubtitle =>
      'Parfois des amis, parfois juste des trucs. Tout ce dont tu t\'occupes ou que tu ne veux pas oublier.';

  @override
  String subjectsLoadFailed(String details) {
    return 'Impossible de charger les protégés : $details';
  }

  @override
  String get subjectNothingDueToday => 'Rien à faire aujourd\'hui';

  @override
  String get subjectNoChoresYet => 'Pas encore de corvées';

  @override
  String subjectDoneToday(int done, int total) {
    return '$done sur $total faites aujourd\'hui';
  }

  @override
  String subjectStreakDays(int count) {
    return 'Série de $count jours';
  }

  @override
  String get subjectNfcTagWritten => 'Tag NFC écrit';

  @override
  String get subjectManageChoresLink => 'Gérer les corvées →';

  @override
  String get subjectCompletedChores => 'Corvées faites';

  @override
  String get subjectSeeAll => 'Tout voir →';

  @override
  String subjectHistoryLoadFailed(String details) {
    return 'Impossible de charger l\'historique : $details';
  }

  @override
  String get subjectNoCompletions => 'Rien d\'enregistré pour l\'instant.';

  @override
  String editSubjectTitle(String name) {
    return 'Modifier $name';
  }

  @override
  String get editSubjectNewTitle => 'Nouveau protégé';

  @override
  String get editSubjectDeleteTooltip => 'Supprimer le protégé';

  @override
  String get editSubjectDeleteBody =>
      'Toutes les corvées et l\'historique de ce protégé seront définitivement supprimés. C\'est irréversible.';

  @override
  String get editSubjectNameLabel => 'Nom';

  @override
  String get editSubjectNameHint => 'ex. Kiko';

  @override
  String get editSubjectAdd => 'Ajouter le protégé';

  @override
  String get editSubjectManageChores => 'Gérer les corvées';

  @override
  String get editSubjectDeleteChoreBody =>
      'Son horaire et ses rappels partent avec. Les corvées déjà faites restent dans l\'historique.';

  @override
  String get editSubjectTagWritten => 'Tag écrit';

  @override
  String get editSubjectNoTag => 'Pas encore de tag';

  @override
  String get editSubjectTapCompletes =>
      'Sur ce téléphone, un tap valide la corvée en cours. Modifiable dans';

  @override
  String get editSubjectTapOpens =>
      'Sur ce téléphone, un tap ouvre la page du protégé. Modifiable dans';

  @override
  String get editSubjectEditProfileLink => 'Modifier le profil';

  @override
  String get editSubjectWriteTagPrompt =>
      'Écris un tag pour valider d\'un simple tap.';

  @override
  String get editSubjectWriteTag => 'Écrire un tag NFC';

  @override
  String get editSubjectWriteAnotherTag => 'Écrire un autre tag NFC';

  @override
  String get editSubjectForgetTag => 'Oublier le tag';

  @override
  String editSubjectSaveTagFailed(String details) {
    return 'Impossible d\'enregistrer le tag : $details';
  }

  @override
  String editSubjectForgetTagFailed(String details) {
    return 'Impossible d\'oublier : $details';
  }

  @override
  String get browseMoreCharacters => 'Plus de personnages →';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonYesterday => 'Hier';

  @override
  String scheduleDaily(String time) {
    return 'Tous les jours à $time';
  }

  @override
  String scheduleWeeklyAt(String days, String time) {
    return '$days à $time';
  }

  @override
  String get scheduleNever => 'Jamais';

  @override
  String scheduleFortnightly(String days, String time, String phase) {
    return 'Une semaine sur deux le $days à $time · $phase';
  }

  @override
  String get scheduleThisWeek => 'cette semaine';

  @override
  String get scheduleNextWeek => 'la semaine prochaine';

  @override
  String scheduleMonthlyOnDayAt(String day, String time) {
    return 'Chaque mois le $day à $time';
  }

  @override
  String scheduleMonthlyLastDayAt(String time) {
    return 'Chaque mois le dernier jour à $time';
  }

  @override
  String scheduleMonthlyOnWeekdayAt(
    String position,
    String weekday,
    String time,
  ) {
    return 'Chaque mois le $position $weekday à $time';
  }

  @override
  String get schedulePositionFirst => 'premier';

  @override
  String get schedulePositionSecond => 'deuxième';

  @override
  String get schedulePositionThird => 'troisième';

  @override
  String get schedulePositionFourth => 'quatrième';

  @override
  String get schedulePositionLast => 'dernier';

  @override
  String scheduleOnceAt(String time) {
    return 'Une fois à $time';
  }

  @override
  String scheduleOnceOn(String date, String time) {
    return 'Une fois le $date à $time';
  }

  @override
  String overdueMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes de retard',
      one: '1 minute de retard',
    );
    return '$_temp0';
  }

  @override
  String overdueHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'plus de $count heures de retard',
      one: '1 heure de retard',
    );
    return '$_temp0';
  }

  @override
  String get dueIn => 'Dans';

  @override
  String dueInUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'h',
      one: 'heure',
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
  String get editChorePickDate => 'Choisis une date';

  @override
  String editChoreMonthDayItem(String day) {
    return 'Le $day';
  }

  @override
  String get editChoreLastDay => 'Le dernier jour';

  @override
  String get commonYou => 'Toi';

  @override
  String get commonSomeone => 'Quelqu\'un';

  @override
  String choreCouldNotLog(String details) {
    return 'Impossible d\'enregistrer : $details';
  }

  @override
  String choreCouldNotUndo(String details) {
    return 'Impossible de retirer : $details';
  }

  @override
  String choreRemoved(String name) {
    return 'Retiré : $name';
  }

  @override
  String get choreUndoNotAllowed =>
      'Passe sur la personne qui l\'a validée (ou demande au propriétaire) pour la retirer.';

  @override
  String undoDialogTitle(String name) {
    return 'Retirer « $name » ?';
  }

  @override
  String get undoDialogBody =>
      'La corvée redevient à faire, et le reste du foyer est prévenu.';

  @override
  String get undoDialogAction => 'Retirer';

  @override
  String get choreUsuallyDoneAround => 'Souvent faite vers';

  @override
  String get choreOneTimePill => 'Unique';

  @override
  String choreCompletedBy(String name) {
    return 'Faite par $name';
  }

  @override
  String get editChoreTitle => 'Modifier la corvée';

  @override
  String get editChoreNewTitle => 'Nouvelle corvée';

  @override
  String get editChoreDeleteTooltip => 'Supprimer la corvée';

  @override
  String get editChoreDeleteBody =>
      'Tout l\'historique de cette corvée sera définitivement supprimé. C\'est irréversible.';

  @override
  String get editChoreNameLabel => 'Nom';

  @override
  String get editChoreNameHint => 'ex. Petit-déj';

  @override
  String get editChoreScheduleLabel => 'Horaire';

  @override
  String get editChoreRepeats => 'Récurrente';

  @override
  String get editChoreOneTime => 'Une fois';

  @override
  String get editChoreFrequencyLabel => 'Fréquence';

  @override
  String get editChoreFreqDaily => 'Tous les jours';

  @override
  String get editChoreFreqWeekly => 'Certains jours';

  @override
  String get editChoreFreqMonthly => 'Chaque mois';

  @override
  String get editChoreOnTheseDays => 'Ces jours-là';

  @override
  String get editChorePickOneDay => 'Choisis au moins un jour.';

  @override
  String get editChoreHowOften => 'À quel rythme';

  @override
  String get editChoreEveryWeek => 'Chaque semaine';

  @override
  String get editChoreFortnightly => 'Une semaine sur deux';

  @override
  String get editChoreStarting => 'À partir de';

  @override
  String get editChoreThisWeek => 'Cette semaine';

  @override
  String get editChoreNextWeek => 'La semaine prochaine';

  @override
  String get editChoreOnThe => 'Le';

  @override
  String get editChoreExactDay => 'Jour précis';

  @override
  String get editChorePosFirst => 'Premier';

  @override
  String get editChorePosSecond => 'Deuxième';

  @override
  String get editChorePosThird => 'Troisième';

  @override
  String get editChorePosFourth => 'Quatrième';

  @override
  String get editChorePosLast => 'Dernier';

  @override
  String get editChoreDayLabel => 'Jour';

  @override
  String get editChoreWeekdayLabel => 'Jour de la semaine';

  @override
  String get editChoreOnDateLabel => 'Le';

  @override
  String get editChoreAtTimeLabel => 'À';

  @override
  String get editChoreAddChore => 'Ajouter la corvée';

  @override
  String get timelineLogged => 'Enregistré';

  @override
  String get historyAwardsTitle => 'Trophées';

  @override
  String get historyDayStreak => 'Jours de série';

  @override
  String get historyThisWeek => 'Cette semaine';

  @override
  String historyCleanSweeps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sans-faute',
      one: 'Sans-faute',
    );
    return '$_temp0';
  }

  @override
  String get historyAllActivity => 'Toute l\'activité';

  @override
  String get historyFilterAll => 'Tous';

  @override
  String get historyEmptyTitle => 'Rien ici pour l\'instant !';

  @override
  String get historyEmptyBody => 'Sois le premier à valider une corvée.';

  @override
  String get leaderboardEmpty =>
      'Aucune corvée faite cette semaine pour l\'instant !';

  @override
  String leaderboardYouSuffix(String name) {
    return '$name (toi)';
  }

  @override
  String get awardsBadges => 'Badges';

  @override
  String get awardsTeamEffort => 'Esprit d\'équipe';

  @override
  String get awardsTeamEffortDesc =>
      'Tout le monde a fait sa part - la charge a été bien répartie';

  @override
  String get awardsUnclaimed => 'À prendre';

  @override
  String get awardsLastWeeksWinner => 'GAGNANT DE LA SEMAINE DERNIÈRE';

  @override
  String awardsSubjectPossessive(String name) {
    return '$name';
  }

  @override
  String awardsNoWinnerYet(String name) {
    return 'Pas de gagnant la semaine dernière - fais le plus de corvées de $name pour le remporter la prochaine fois !';
  }

  @override
  String awardsChoreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count corvées',
      one: '$count corvée',
    );
    return '$_temp0';
  }

  @override
  String get commonLogOut => 'Se déconnecter';

  @override
  String get householdTitle => 'Foyer';

  @override
  String get householdNoLonger => 'Tu ne fais plus partie de ce foyer.';

  @override
  String get householdDeleteTooltip => 'Supprimer le foyer';

  @override
  String get householdDeleteBody =>
      'Tous les protégés, corvées et l\'historique de ce foyer seront définitivement supprimés pour tous ses membres. C\'est irréversible.';

  @override
  String householdLeaveTitle(String name) {
    return 'Quitter $name ?';
  }

  @override
  String get householdLeaveBody =>
      'Tu ne verras plus les corvées ni l\'activité de ce foyer. Tu pourras le rejoindre plus tard avec un code d\'invitation.';

  @override
  String get householdLeave => 'Quitter';

  @override
  String householdDeleteManagedBody(String name) {
    return '$name est un membre géré : cette action le supprime complètement. Ses corvées passées comptent toujours mais s\'afficheront comme « Quelqu\'un ».';
  }

  @override
  String get browseMoreHomes => 'Plus de maisons →';

  @override
  String get browseMoreAvatars => 'Plus d\'avatars →';

  @override
  String get householdNameLabel => 'Nom du foyer';

  @override
  String get householdNameHint => 'ex. « Chez nous » ou « Maison »';

  @override
  String get householdResidentsLabel => 'Qui vit ici ?';

  @override
  String get householdResidentsHint => 'Les Dupont';

  @override
  String householdTimezone(String tz) {
    return 'Fuseau horaire : $tz';
  }

  @override
  String get householdUsePhoneTz => 'Utiliser celui du téléphone';

  @override
  String get householdMembersFallback => 'Membres';

  @override
  String get householdSaveFailed => 'Échec de l\'enregistrement';

  @override
  String get householdRoleOwner => 'propriétaire';

  @override
  String get householdRoleMember => 'membre';

  @override
  String get addSomeoneTitle => 'Ajouter quelqu\'un';

  @override
  String get addInviteTitle => 'Inviter quelqu\'un avec son propre compte';

  @override
  String get addInviteSubtitle =>
      'Famille ou colocs qui se connectent sur leur propre téléphone. Ils rejoignent avec un code et valident leurs propres corvées.';

  @override
  String get addManagedTitle => 'Ajouter quelqu\'un sans compte';

  @override
  String get addManagedSubtitle =>
      'Pour ceux qui n\'ont pas de compte. Tu gères leur profil et valides leurs corvées en passant sur eux avec « À qui le tour ? » dans l\'onglet Toi.';

  @override
  String get inviteSomeone => 'Inviter quelqu\'un';

  @override
  String get inviteSubtitle => 'Invite ta famille ou tes colocs';

  @override
  String get invitesOn => 'Invitations ouvertes';

  @override
  String get invitesOff => 'Invitations fermées';

  @override
  String get inviteLiveUntil =>
      'Valable tant que les invitations sont ouvertes';

  @override
  String get shareCode => 'Partager le code';

  @override
  String get generateNewCode => 'Générer un nouveau code';

  @override
  String inviteShareText(String code) {
    return 'Rejoins notre foyer sur Have You Fed The Dog?\nhttps://haveyoufedthedog.com/join?code=$code\n\nSi le lien n\'ouvre pas l\'appli, ouvre-la et saisis le code d\'invitation $code';
  }

  @override
  String get inviteShareSubject =>
      'Have You Fed The Dog? - invitation au foyer';

  @override
  String membersLoadFailed(String details) {
    return 'Impossible de charger les membres : $details';
  }

  @override
  String memberRemoveTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String memberRemoveBody(String name) {
    return '$name perdra immédiatement l\'accès à ce foyer. Il pourra le rejoindre plus tard avec un code d\'invitation.';
  }

  @override
  String get memberRemove => 'Retirer';

  @override
  String get memberOwner => 'Propriétaire';

  @override
  String get editMemberTitle => 'Modifier le membre';

  @override
  String get addMemberTitle => 'Ajouter un membre';

  @override
  String get deleteMemberTooltip => 'Supprimer le membre';

  @override
  String get displayNameLabel => 'Nom affiché';

  @override
  String get memberNameHint => 'Comment ce membre apparaît aux autres';

  @override
  String get claimLoginTitle => 'Donne-lui son propre compte';

  @override
  String get claimLoginSubtitle =>
      'Il pourra récupérer ce compte et se connecter lui-même';

  @override
  String get claimCodeInfo =>
      'À saisir à l\'inscription. Valable jusqu\'à désactivation.';

  @override
  String claimShareText(String code) {
    return 'Récupère ton compte sur Have You Fed The Dog?\nhttps://haveyoufedthedog.com/claim?code=$code\n\nSi le lien n\'ouvre pas l\'appli, ouvre-la, touche S\'inscrire et saisis le code de récupération $code';
  }

  @override
  String get claimShareSubject => 'Have You Fed The Dog? - récupère ton compte';

  @override
  String get householdsYourTitle => 'Tes foyers';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get menuEditProfile => 'Modifier le profil';

  @override
  String get householdsEmpty =>
      'Tu n\'es dans aucun foyer pour l\'instant. Crées-en un ou rejoins-en un avec un code d\'invitation ci-dessous.';

  @override
  String get householdsCreateNew => 'Créer un nouveau foyer';

  @override
  String get householdsJoinWithCode => 'Rejoindre avec un code';

  @override
  String get createHouseholdTitle => 'Créer un foyer';

  @override
  String get createHouseholdFailed => 'Création impossible';

  @override
  String get createHouseholdIntro =>
      'Crée un nouveau foyer - pour ta famille, tes colocs, ou tous ceux avec qui tu partages les corvées.';

  @override
  String get joinHouseholdTitle => 'Rejoindre un foyer';

  @override
  String get joinHouseholdFailed => 'Impossible de rejoindre';

  @override
  String get joinIntro =>
      'Un membre de la famille t\'a donné un code ? Colle-le ici pour rejoindre son foyer.';

  @override
  String get inviteCodeLabel => 'Code d\'invitation';

  @override
  String get inviteCodeHint => 'ex. KIKO-7H4P';

  @override
  String get youTabTitle => 'Toi';

  @override
  String get youNoName => '(pas de nom)';

  @override
  String get movingDay => 'Jour de déménagement ?';

  @override
  String get switchHousehold => 'Changer de foyer';

  @override
  String get whoseTurn => 'À qui le tour ?';

  @override
  String get whoseTurnSubtitle =>
      'Valide des corvées au nom d\'un autre membre';

  @override
  String actingTurn(String name) {
    return 'Au tour de $name';
  }

  @override
  String get myTurnAgain => 'Repasser à moi';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get deleteAccountTooltip => 'Supprimer le compte';

  @override
  String get deleteAccountTitle => 'Supprimer ton compte ?';

  @override
  String get deleteAccountBody =>
      'Ton compte sera définitivement supprimé et tu seras déconnecté. Les corvées que tu as faites restent dans ton foyer, sans ton nom. Les foyers qui se retrouvent vides sont entièrement supprimés.\n\nC\'est irréversible.';

  @override
  String get deleteForever => 'Supprimer définitivement';

  @override
  String couldNotDeleteAccount(String details) {
    return 'Impossible de supprimer le compte : $details';
  }

  @override
  String get profileNameHint => 'Comment les autres membres te voient';

  @override
  String get emailCantChange => 'L\'e-mail ne peut pas être modifié.';

  @override
  String get nfcCompleteOnTap => 'Valider la corvée d\'un tap';

  @override
  String get nfcTapCompletesDesc => 'Taper un tag valide la corvée en cours.';

  @override
  String get nfcTapOpensDesc => 'Taper un tag ouvre la page du protégé.';

  @override
  String get avatarDragOrTap => 'Glisse ou touche';

  @override
  String get avatarSurpriseMe => 'Surprends-moi';

  @override
  String get navHome => 'Accueil';

  @override
  String get navThings => 'Protégés';

  @override
  String get navAwards => 'Trophées';

  @override
  String get navAddChore => 'Ajouter une corvée';

  @override
  String get navAddChoreFor => 'Une corvée pour…';

  @override
  String get storeTitle => 'Packs d\'images';

  @override
  String get storeRestoreTooltip => 'Restaurer les achats';

  @override
  String storeLoadFailed(String details) {
    return 'Impossible de charger la boutique.\n$details';
  }

  @override
  String get storeNoPacks =>
      'Aucun pack disponible pour l\'instant.\nReviens bientôt !';

  @override
  String get storeSupportNote =>
      'Fait par un homme et son chien. Pas de pub. Pas d\'abonnement. Les packs soutiennent l\'appli.';

  @override
  String get storeAppliesTo =>
      'Les packs achetés ou activés et les récompenses sont débloqués pour tous les membres de';

  @override
  String get storeRedeemTitle => 'Utiliser un code';

  @override
  String get storeRedeemSubtitle => 'Débloque un pack avec un code cadeau';

  @override
  String get storePackCodeLabel => 'Code du pack';

  @override
  String get storePackCodeHint => 'WOOF-2026';

  @override
  String get storeApplyPack => 'Activer le pack';

  @override
  String storeApplied(String name) {
    return '$name activé !';
  }

  @override
  String storeAlreadyApplied(String name) {
    return '$name est déjà activé.';
  }

  @override
  String get storeCodeFailed => 'Ce code n\'a pas fonctionné';

  @override
  String get storeWorking => 'En cours…';

  @override
  String storeBuy(String price) {
    return 'Acheter  $price';
  }

  @override
  String get storeOwned => 'Acquis';

  @override
  String get purchaseCouldNotStart => 'Impossible de démarrer l\'achat.';

  @override
  String get purchaseFailed => 'L\'achat a échoué.';

  @override
  String get purchaseNeedHousehold =>
      'Choisis un foyer avant d\'acheter des packs.';

  @override
  String get purchaseVerifyFailed => 'Impossible de vérifier cet achat.';

  @override
  String purchaseUnlocked(String name) {
    return '$name débloqué !';
  }

  @override
  String purchaseAlreadyUnlocked(String name) {
    return '$name est déjà débloqué.';
  }

  @override
  String get rewardsTitle => 'Récompenses gratuites';

  @override
  String get rewardsCharacters => 'Personnages';

  @override
  String get rewardsHouses => 'Maisons';

  @override
  String rewardsStreakToClaim(int streak, int threshold) {
    return 'Série $streak / $threshold pour réclamer';
  }

  @override
  String get rewardsNothingToClaim => 'Rien à réclamer';

  @override
  String get rewardsClaim => 'Réclamer';

  @override
  String get rewardsChooseCharacter => 'Choisis un personnage';

  @override
  String get rewardsChooseHouse => 'Choisis une maison';

  @override
  String get rewardsAllUnlocked =>
      'Tu as tout débloqué ici - de nouvelles images arrivent régulièrement.';

  @override
  String get rewardsYourCollection => 'Ta collection';

  @override
  String get rewardsCollectionEmpty =>
      'Rien pour l\'instant - garde ta série et réclame ta première récompense.';

  @override
  String rewardsAlreadyYours(String name) {
    return '$name est déjà à toi.';
  }

  @override
  String get rewardsClaimFailed => 'Impossible de réclamer cette récompense.';

  @override
  String get rewardsClaimYourReward => 'Réclame ta récompense ci-dessous !';

  @override
  String get rewardsYourStreak => 'Ta série de récompense';

  @override
  String get rewardsRedeemedToday =>
      'Félicitations ! Repars pour un tour et gagne une autre récompense.';

  @override
  String get rewardsPickReward =>
      'Choisis une récompense à ajouter à ta collection.';

  @override
  String get rewardsKeepStreak =>
      'Garde ta série quotidienne pour gagner un personnage ou une maison gratuits.';

  @override
  String get rewardsCantWait => 'Trop impatient ?';

  @override
  String get rewardsGetMoreHere => 'La boutique est ici';

  @override
  String get rewardsUnlockedBang => 'Débloqué !';

  @override
  String get rewardsViewCollection => 'Voir la collection';

  @override
  String get rewardsBarAvailable => 'Récompense gratuite dispo !';

  @override
  String get rewardsBarStreak => 'Série de récompense gratuite';

  @override
  String get nfcWriteTagTitle => 'Écrire un tag NFC';

  @override
  String get nfcHoldTag => 'Approche un tag du haut du téléphone…';

  @override
  String get nfcUnavailable =>
      'Le NFC est désactivé ou indisponible sur cet appareil. Active-le et réessaie.';

  @override
  String get nfcNotMemberHousehold => 'Tu n\'es pas membre du foyer de ce tag.';

  @override
  String get nfcTagNotInHousehold =>
      'Ce tag pointe vers quelque chose qui n\'est pas dans ce foyer.';

  @override
  String get nfcSignInFirst =>
      'Connecte-toi et choisis un foyer pour utiliser les tags NFC.';

  @override
  String nfcLogFailed(String details) {
    return 'Échec du tap NFC : $details';
  }

  @override
  String celebrationChoreDone(String name) {
    return '$name\nC\'est fait !';
  }

  @override
  String get celebrationStreakStarted => '🔥 Série lancée !';

  @override
  String celebrationStreakDays(int count) {
    return '🔥 Série de $count jours !';
  }

  @override
  String celebrationLoggedBy(String name) {
    return 'Validée par $name';
  }

  @override
  String get celebrationNice => 'Super !';

  @override
  String get dayCelebrationBody =>
      'Toute la maison est contente. Beau travail d\'équipe !';

  @override
  String get dayCelebrationThanks => 'Merci !';

  @override
  String get dayCelebrationSeeAwards => 'Voir les trophées';

  @override
  String get claimSignedInTitle => 'Tu es déjà connecté';

  @override
  String get claimSignedInBody =>
      'Un lien de récupération crée un tout nouvel accès pour un membre créé pour toi. Il ne peut pas s\'ajouter à un compte déjà connecté - on ne fusionne pas les comptes.';

  @override
  String get claimSignedInIfForYou => 'Si ce code est pour toi :';

  @override
  String get claimSignedInKeepOption =>
      '• Garder ce compte - reste connecté en tant que toi, et demande plutôt un lien d\'invitation au foyer.';

  @override
  String get claimSignedInBecomeOption =>
      '• Devenir ce membre - supprime ce compte, puis la récupération s\'ouvre automatiquement. Tes corvées faites restent dans le foyer.';

  @override
  String get claimKeepAccount => 'Garder mon compte';

  @override
  String get claimDeleteAndClaim => 'Supprimer et récupérer';

  @override
  String get claimDeleteBody =>
      'Ton compte sera définitivement supprimé et tu seras déconnecté, puis l\'inscription de récupération s\'ouvrira. Les corvées que tu as faites restent dans ton foyer, sans ton nom.\n\nC\'est irréversible.';

  @override
  String get awardComebackKidTitle => 'Grand Retour';

  @override
  String get awardComebackKidDesc =>
      'La plus grosse progression sur la semaine dernière';

  @override
  String get awardEarlyBirdTitle => 'Lève-tôt';

  @override
  String get awardEarlyBirdDesc => 'Le plus de corvées faites avant 9h';

  @override
  String get awardNightOwlTitle => 'Oiseau de nuit';

  @override
  String get awardNightOwlDesc => 'Le plus de corvées faites après 20h';

  @override
  String get awardOnTheDotTitle => 'Pile à l\'heure';

  @override
  String get awardOnTheDotDesc =>
      'Le plus de corvées faites à moins de 15 minutes de l\'horaire';

  @override
  String get awardWeekendWarriorTitle => 'Guerrier du week-end';

  @override
  String get awardWeekendWarriorDesc =>
      'Le plus de corvées faites le samedi et le dimanche';

  @override
  String get awardTagChampionTitle => 'Champion du tag';

  @override
  String get awardTagChampionDesc =>
      'Le plus de corvées validées d\'un tap NFC';

  @override
  String get characterAwardTitleDog => 'Meilleur Humain 🩵';

  @override
  String get characterAwardTitleCat => 'Humain le Moins Décevant';

  @override
  String get characterAwardTitlePlant => 'La Main la Plus Verte';

  @override
  String get characterAwardTitleBin => 'Seigneur du Trottoir';

  @override
  String get characterAwardTitleFish => 'Gardien de l\'Aquarium';

  @override
  String get characterAwardTitleGeneric => 'Étoile du Foyer';

  @override
  String get characterAwardThanksDog =>
      'Merci d\'avoir été wouf-midable la semaine dernière !';

  @override
  String get characterAwardThanksCat =>
      'A daigné accepter tes services la semaine dernière.';

  @override
  String get characterAwardThanksPlant =>
      'Merci d\'avoir fait pousser tout ça la semaine dernière !';

  @override
  String get characterAwardThanksBin =>
      'Merci d\'avoir fait rouler tout ça la semaine dernière !';

  @override
  String get characterAwardThanksFish =>
      'Merci d\'avoir fait des vagues la semaine dernière !';

  @override
  String get characterAwardThanksGeneric =>
      'Merci d\'avoir été génial la semaine dernière !';

  @override
  String get serverNotSignedIn => 'Tu dois être connecté.';

  @override
  String get serverNotMember => 'Tu n\'es pas membre de ce foyer.';

  @override
  String get serverOwnerOnly => 'Seul le propriétaire du foyer peut faire ça.';

  @override
  String get serverNameRequired => 'Un nom est requis.';

  @override
  String get serverPasswordTooShort =>
      'Le mot de passe doit faire au moins 8 caractères.';

  @override
  String get serverClaimCodeInvalid =>
      'Ce code de récupération n\'est pas valide.';

  @override
  String get serverEmailInUse => 'Cet e-mail est déjà utilisé.';

  @override
  String get serverNoSuchMember => 'Membre introuvable.';

  @override
  String get serverInviteCodeInvalid => 'Aucun foyer ouvert avec ce code.';

  @override
  String get serverPackCodeInvalid => 'Aucun pack avec ce code.';

  @override
  String get serverPackGone => 'Ce pack n\'est plus disponible.';

  @override
  String get serverUnknownProduct => 'Produit inconnu.';

  @override
  String get serverVerifyFailed => 'Impossible de vérifier cet achat.';

  @override
  String get serverVerifyUnavailable =>
      'La vérification des achats est momentanément indisponible.';

  @override
  String get serverRewardUnavailable =>
      'Cet élément ne peut pas être débloqué.';

  @override
  String get serverStreakCheckFailed =>
      'Impossible de vérifier ta série pour l\'instant - réessaie bientôt.';

  @override
  String serverStreakTooLow(int threshold, int streak) {
    return 'Il te faut une série de $threshold pour débloquer ça - tu en es à $streak.';
  }

  @override
  String get notifChannelName => 'Corvées validées';

  @override
  String get notifChannelDesc =>
      'Quand quelqu\'un de ton foyer valide une corvée.';

  @override
  String get characterNameDog => 'Chien';

  @override
  String get characterNameCat => 'Chat';

  @override
  String get characterNamePlant => 'Plante';

  @override
  String get characterNameBin => 'Poubelle';

  @override
  String get characterNameFish => 'Poisson';

  @override
  String get characterNameGeneric => 'Autre';
}
