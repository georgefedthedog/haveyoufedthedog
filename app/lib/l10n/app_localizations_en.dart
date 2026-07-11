// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Have You Fed The Dog?';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get confirmByTypingWord => 'DELETE';

  @override
  String confirmByTypingHint(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get passwordFieldShow => 'Show password';

  @override
  String get passwordFieldHide => 'Hide password';

  @override
  String get profileLanguageLabel => 'Language';

  @override
  String get profileLanguageSystemDefault => 'System default';

  @override
  String get authWelcomeBack => 'Welcome back!';

  @override
  String get authJoinFamily => 'Join the family';

  @override
  String get authLoginTagline => 'Log in to keep your pup happy and well-fed.';

  @override
  String get authSignupTagline =>
      'Sign up and never wonder who fed the dog again.';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authLoginFailed => 'Login failed';

  @override
  String authLoginFailedDetails(String details) {
    return 'Login failed: $details';
  }

  @override
  String get authYourNameLabel => 'Your name';

  @override
  String get authNameHint => 'Seen by your housemates';

  @override
  String get authNameHintClaim => 'Leave blank to keep your current name';

  @override
  String get authPasswordRule => 'At least 8 characters';

  @override
  String get authChoosePasswordHint => 'Choose a password';

  @override
  String get authClaimCodeToggle => 'I have a claim code';

  @override
  String get authClaimCodeLabel => 'Claim code';

  @override
  String get authClaimCodeHint => 'Joining as an existing member?';

  @override
  String get authClaimAccount => 'Claim account';

  @override
  String get authCouldNotClaim => 'Could not claim account';

  @override
  String get authSignupFailed => 'Signup failed';

  @override
  String authSignupFailedDetails(String details) {
    return 'Signup failed: $details';
  }

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authResetIntro =>
      'No worries - it happens to the best of us.\nWe\'ll email you a link to set a new one.';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authCheckInbox => 'Check your inbox!';

  @override
  String authResetSent(String email) {
    return 'If there\'s an account for $email, a reset link is on its way. Follow it to set a new password, then log in here.';
  }

  @override
  String authResetEmailFailed(String details) {
    return 'Could not send the reset email: $details';
  }

  @override
  String get authBackToLogin => 'Back to log in';

  @override
  String get startupErrorTitle => 'We couldn\'t start up';

  @override
  String get startupErrorBody => 'Check your connection and try again.';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String commonCouldNotSave(String details) {
    return 'Could not save: $details';
  }

  @override
  String commonCouldNotDelete(String details) {
    return 'Could not delete: $details';
  }

  @override
  String commonDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String commonErrorDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get homeErrorTitle => 'Hmm, something went sideways';

  @override
  String homeErrorBody(String details) {
    return 'Could not load your things. $details';
  }

  @override
  String get homeNothingDueToday => 'Nothing due today 🎉';

  @override
  String get homeTodaysChores => 'Today\'s chores';

  @override
  String get homeTapToComplete => 'Tap to complete';

  @override
  String get homeSummaryAllDone => 'All chores done today!';

  @override
  String get homeSummaryStart => 'Let\'s get started!';

  @override
  String get homeSummaryKeepUp => 'Good progress. Keep it up!';

  @override
  String homeSummaryCount(int done, int total) {
    return '$done of $total completed';
  }

  @override
  String get subjectsEmptyTitle => 'No things yet';

  @override
  String get subjectsEmptyBody =>
      'Add a dog, cat, plant, or whatever else needs looking after.';

  @override
  String get subjectsAddThing => 'Add a thing';

  @override
  String get subjectsTabTitle => 'Things';

  @override
  String get subjectsTabSubtitle =>
      'Sometimes friends, often just stuff. These are the things you look after or don\'t want to forget.';

  @override
  String subjectsLoadFailed(String details) {
    return 'Could not load things: $details';
  }

  @override
  String get subjectNothingDueToday => 'Nothing due today';

  @override
  String get subjectNoChoresYet => 'No chores yet';

  @override
  String subjectDoneToday(int done, int total) {
    return '$done of $total done today';
  }

  @override
  String subjectStreakDays(int count) {
    return '$count-day streak';
  }

  @override
  String get subjectNfcTagWritten => 'NFC tag written';

  @override
  String get subjectManageChoresLink => 'Manage chores →';

  @override
  String get subjectCompletedChores => 'Completed chores';

  @override
  String get subjectSeeAll => 'See all →';

  @override
  String subjectHistoryLoadFailed(String details) {
    return 'Could not load history: $details';
  }

  @override
  String get subjectNoCompletions => 'No completions logged yet.';

  @override
  String editSubjectTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get editSubjectNewTitle => 'New thing';

  @override
  String get editSubjectDeleteTooltip => 'Delete thing';

  @override
  String get editSubjectDeleteBody =>
      'All chores and history for this thing will be permanently removed. This cannot be undone.';

  @override
  String get editSubjectNameLabel => 'Name';

  @override
  String get editSubjectNameHint => 'e.g. Kiko';

  @override
  String get editSubjectAdd => 'Add thing';

  @override
  String get editSubjectManageChores => 'Manage chores';

  @override
  String get editSubjectDeleteChoreBody =>
      'Its schedule and reminders go with it. Past completions stay in the history.';

  @override
  String get editSubjectTagWritten => 'Tag written';

  @override
  String get editSubjectNoTag => 'No tag yet';

  @override
  String get editSubjectTapCompletes =>
      'On this phone, a tap ticks off the current chore. Change this in';

  @override
  String get editSubjectTapOpens =>
      'On this phone, a tap opens this thing\'s page. Change this in';

  @override
  String get editSubjectEditProfileLink => 'Edit Profile';

  @override
  String get editSubjectWriteTagPrompt =>
      'Write a tag so a tap logs this thing.';

  @override
  String get editSubjectWriteTag => 'Write an NFC tag';

  @override
  String get editSubjectWriteAnotherTag => 'Write another NFC tag';

  @override
  String get editSubjectForgetTag => 'Forget tag';

  @override
  String editSubjectSaveTagFailed(String details) {
    return 'Could not save tag: $details';
  }

  @override
  String editSubjectForgetTagFailed(String details) {
    return 'Could not forget: $details';
  }

  @override
  String get browseMoreCharacters => 'Get more characters →';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String scheduleDaily(String time) {
    return 'Every day at $time';
  }

  @override
  String scheduleWeeklyAt(String days, String time) {
    return '$days at $time';
  }

  @override
  String get scheduleNever => 'Never';

  @override
  String scheduleFortnightly(String days, String time, String phase) {
    return 'Fortnightly on $days at $time · $phase';
  }

  @override
  String get scheduleThisWeek => 'this week';

  @override
  String get scheduleNextWeek => 'next week';

  @override
  String scheduleMonthlyOnDayAt(String day, String time) {
    return 'Monthly on the $day at $time';
  }

  @override
  String scheduleMonthlyLastDayAt(String time) {
    return 'Monthly on the last day at $time';
  }

  @override
  String scheduleMonthlyOnWeekdayAt(
    String position,
    String weekday,
    String time,
  ) {
    return 'Monthly on the $position $weekday at $time';
  }

  @override
  String get schedulePositionFirst => 'first';

  @override
  String get schedulePositionSecond => 'second';

  @override
  String get schedulePositionThird => 'third';

  @override
  String get schedulePositionFourth => 'fourth';

  @override
  String get schedulePositionLast => 'last';

  @override
  String scheduleOnceAt(String time) {
    return 'One time at $time';
  }

  @override
  String scheduleOnceOn(String date, String time) {
    return 'One time on $date at $time';
  }

  @override
  String overdueMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes overdue',
      one: '1 minute overdue',
    );
    return '$_temp0';
  }

  @override
  String overdueHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'over $count hours overdue',
      one: '1 hour overdue',
    );
    return '$_temp0';
  }

  @override
  String get dueIn => 'Due in';

  @override
  String dueInUnitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hrs',
      one: 'hour',
    );
    return '$_temp0';
  }

  @override
  String dueInUnitMins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mins',
      one: 'min',
    );
    return '$_temp0';
  }

  @override
  String get editChorePickDate => 'Pick a date';

  @override
  String editChoreMonthDayItem(String day) {
    return 'The $day';
  }

  @override
  String get editChoreLastDay => 'The last day';

  @override
  String get commonYou => 'You';

  @override
  String get commonSomeone => 'Someone';

  @override
  String choreCouldNotLog(String details) {
    return 'Could not log: $details';
  }

  @override
  String choreCouldNotUndo(String details) {
    return 'Could not undo: $details';
  }

  @override
  String choreRemoved(String name) {
    return 'Removed: $name';
  }

  @override
  String get choreUndoNotAllowed =>
      'Switch to whoever logged this (or ask an owner) to undo it.';

  @override
  String undoDialogTitle(String name) {
    return 'Undo \"$name\"?';
  }

  @override
  String get undoDialogBody =>
      'This marks the chore as not done again, and the rest of the household is told.';

  @override
  String get undoDialogAction => 'Undo it';

  @override
  String get choreUsuallyDoneAround => 'Usually done around';

  @override
  String get choreOneTimePill => 'One-time';

  @override
  String choreCompletedBy(String name) {
    return 'Completed by $name';
  }

  @override
  String get editChoreTitle => 'Edit chore';

  @override
  String get editChoreNewTitle => 'New chore';

  @override
  String get editChoreDeleteTooltip => 'Delete chore';

  @override
  String get editChoreDeleteBody =>
      'All completion history for this chore will be permanently removed. This cannot be undone.';

  @override
  String get editChoreNameLabel => 'Name';

  @override
  String get editChoreNameHint => 'e.g. Breakfast';

  @override
  String get editChoreScheduleLabel => 'Schedule';

  @override
  String get editChoreRepeats => 'Repeats';

  @override
  String get editChoreOneTime => 'One time';

  @override
  String get editChoreFrequencyLabel => 'Frequency';

  @override
  String get editChoreFreqDaily => 'Every day';

  @override
  String get editChoreFreqWeekly => 'Some days';

  @override
  String get editChoreFreqMonthly => 'Monthly';

  @override
  String get editChoreOnTheseDays => 'On these days';

  @override
  String get editChorePickOneDay => 'Pick at least one day.';

  @override
  String get editChoreHowOften => 'How often';

  @override
  String get editChoreEveryWeek => 'Every week';

  @override
  String get editChoreFortnightly => 'Fortnightly';

  @override
  String get editChoreStarting => 'Starting';

  @override
  String get editChoreThisWeek => 'This week';

  @override
  String get editChoreNextWeek => 'Next week';

  @override
  String get editChoreOnThe => 'On the';

  @override
  String get editChoreExactDay => 'Exact Day';

  @override
  String get editChorePosFirst => 'First';

  @override
  String get editChorePosSecond => 'Second';

  @override
  String get editChorePosThird => 'Third';

  @override
  String get editChorePosFourth => 'Fourth';

  @override
  String get editChorePosLast => 'Last';

  @override
  String get editChoreDayLabel => 'Day';

  @override
  String get editChoreWeekdayLabel => 'Weekday';

  @override
  String get editChoreOnDateLabel => 'On';

  @override
  String get editChoreAtTimeLabel => 'At';

  @override
  String get editChoreAddChore => 'Add chore';

  @override
  String get timelineLogged => 'Logged';

  @override
  String get historyAwardsTitle => 'Awards';

  @override
  String get historyDayStreak => 'Day streak';

  @override
  String get historyThisWeek => 'This week';

  @override
  String historyCleanSweeps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clean sweeps',
      one: 'Clean sweep',
    );
    return '$_temp0';
  }

  @override
  String get historyAllActivity => 'All activity';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyEmptyTitle => 'Nothing here yet!';

  @override
  String get historyEmptyBody => 'Be the first one to complete a chore.';

  @override
  String get leaderboardEmpty => 'No chores completed yet this week!';

  @override
  String leaderboardYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get awardsBadges => 'Badges';

  @override
  String get awardsTeamEffort => 'Team Effort';

  @override
  String get awardsTeamEffortDesc =>
      'Everyone pulled their weight - the load was shared fairly';

  @override
  String get awardsUnclaimed => 'Unclaimed';

  @override
  String get awardsLastWeeksWinner => 'LAST WEEK\'S WINNER';

  @override
  String awardsSubjectPossessive(String name) {
    return '$name\'s';
  }

  @override
  String awardsNoWinnerYet(String name) {
    return 'No winner last week - do the most of $name\'s chores to take it next time!';
  }

  @override
  String awardsChoreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chores',
      one: '$count chore',
    );
    return '$_temp0';
  }

  @override
  String get commonLogOut => 'Log out';

  @override
  String get householdTitle => 'Household';

  @override
  String get householdNoLonger =>
      'You\'re no longer a member of this household.';

  @override
  String get householdDeleteTooltip => 'Delete household';

  @override
  String get householdDeleteBody =>
      'All subjects, chores and history for this household will be permanently removed for everyone in it. This cannot be undone.';

  @override
  String householdLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get householdLeaveBody =>
      'You won\'t see this household\'s chores or completions any more. You can re-join later with an invite code.';

  @override
  String get householdLeave => 'Leave';

  @override
  String householdDeleteManagedBody(String name) {
    return '$name is a managed member and this removes them completely. Their past completions still count but will show as \"Someone\".';
  }

  @override
  String get browseMoreHomes => 'Get more homes →';

  @override
  String get browseMoreAvatars => 'Get more avatars →';

  @override
  String get householdNameLabel => 'Household name';

  @override
  String get householdNameHint => 'e.g. \"Paihia House\" or \"Home\"';

  @override
  String get householdResidentsLabel => 'Who lives here?';

  @override
  String get householdResidentsHint => 'The Goodchilds';

  @override
  String householdTimezone(String tz) {
    return 'Timezone: $tz';
  }

  @override
  String get householdUsePhoneTz => 'Use this phone\'s';

  @override
  String get householdMembersFallback => 'Members';

  @override
  String get householdSaveFailed => 'Save failed';

  @override
  String get householdRoleOwner => 'owner';

  @override
  String get householdRoleMember => 'member';

  @override
  String get addSomeoneTitle => 'Add someone';

  @override
  String get addInviteTitle => 'Invite someone with a login';

  @override
  String get addInviteSubtitle =>
      'Family or flatmates who sign in on their own phone. They join with a code and log their own chores.';

  @override
  String get addManagedTitle => 'Add someone without a login';

  @override
  String get addManagedSubtitle =>
      'For anyone without their own login. You manage their profile, and log their chores by switching to them with \'Whose turn?\' on the You tab.';

  @override
  String get inviteSomeone => 'Invite someone';

  @override
  String get inviteSubtitle => 'Invite family or flatmates';

  @override
  String get invitesOn => 'Invites are on';

  @override
  String get invitesOff => 'Invites are off';

  @override
  String get inviteLiveUntil => 'Live until you turn invites off';

  @override
  String get shareCode => 'Share code';

  @override
  String get generateNewCode => 'Generate new code';

  @override
  String inviteShareText(String code) {
    return 'Join our household on Have You Fed The Dog?\nhttps://haveyoufedthedog.com/join?code=$code\n\nIf the link doesn\'t open the app, open it and enter invite code $code';
  }

  @override
  String get inviteShareSubject => 'Have You Fed The Dog? - household invite';

  @override
  String membersLoadFailed(String details) {
    return 'Could not load members: $details';
  }

  @override
  String memberRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String memberRemoveBody(String name) {
    return '$name will lose access to this household immediately. They can re-join later with an invite code.';
  }

  @override
  String get memberRemove => 'Remove';

  @override
  String get memberOwner => 'Owner';

  @override
  String get editMemberTitle => 'Edit member';

  @override
  String get addMemberTitle => 'Add member';

  @override
  String get deleteMemberTooltip => 'Delete member';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get memberNameHint => 'How this member appears to everyone';

  @override
  String get claimLoginTitle => 'Give them their own login';

  @override
  String get claimLoginSubtitle =>
      'Let them claim this account and sign in themselves';

  @override
  String get claimCodeInfo =>
      'They enter this on Sign up. Live until you turn it off.';

  @override
  String claimShareText(String code) {
    return 'Claim your account on Have You Fed The Dog?\nhttps://haveyoufedthedog.com/claim?code=$code\n\nIf the link doesn\'t open the app, open it, tap Sign up, and enter claim code $code';
  }

  @override
  String get claimShareSubject => 'Have You Fed The Dog? - claim your account';

  @override
  String get householdsYourTitle => 'Your households';

  @override
  String get menuTooltip => 'Menu';

  @override
  String get menuEditProfile => 'Edit profile';

  @override
  String get householdsEmpty =>
      'You\'re not in any households yet. Create one or join with an invite code below.';

  @override
  String get householdsCreateNew => 'Create a new household';

  @override
  String get householdsJoinWithCode => 'Join with invite code';

  @override
  String get createHouseholdTitle => 'Create household';

  @override
  String get createHouseholdFailed => 'Could not create';

  @override
  String get createHouseholdIntro =>
      'Start a new household - for your family, flatmates, or anyone you share chores with.';

  @override
  String get joinHouseholdTitle => 'Join household';

  @override
  String get joinHouseholdFailed => 'Could not join';

  @override
  String get joinIntro =>
      'Got a code from a family member? Paste it here to join their household.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteCodeHint => 'e.g. KIKO-7H4P';

  @override
  String get youTabTitle => 'You';

  @override
  String get youNoName => '(no name set)';

  @override
  String get movingDay => 'Moving day?';

  @override
  String get switchHousehold => 'Switch household';

  @override
  String get whoseTurn => 'Whose turn?';

  @override
  String get whoseTurnSubtitle => 'Log chores on behalf of another member';

  @override
  String actingTurn(String name) {
    return '$name\'s turn';
  }

  @override
  String get myTurnAgain => 'My turn again';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get deleteAccountTooltip => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account and signs you out. Chores you completed stay with your household, without your name on them. Households left with nobody in them are deleted entirely.\n\nThis cannot be undone.';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String couldNotDeleteAccount(String details) {
    return 'Could not delete account: $details';
  }

  @override
  String get profileNameHint => 'How others in your household see you';

  @override
  String get emailCantChange => 'Email can\'t be changed.';

  @override
  String get nfcCompleteOnTap => 'Complete chore on tap';

  @override
  String get nfcTapCompletesDesc =>
      'Tapping a tag completes the current chore.';

  @override
  String get nfcTapOpensDesc => 'Tapping a tag opens the thing\'s page.';

  @override
  String get avatarDragOrTap => 'Drag or tap';

  @override
  String get avatarSurpriseMe => 'Surprise me';

  @override
  String get navHome => 'Home';

  @override
  String get navThings => 'Things';

  @override
  String get navAwards => 'Awards';

  @override
  String get navAddChore => 'Add a chore';

  @override
  String get navAddChoreFor => 'Add a chore for…';

  @override
  String get storeTitle => 'Image packs';

  @override
  String get storeRestoreTooltip => 'Restore purchases';

  @override
  String storeLoadFailed(String details) {
    return 'Couldn\'t load the shop.\n$details';
  }

  @override
  String get storeNoPacks => 'No packs available yet.\nCheck back soon!';

  @override
  String get storeSupportNote =>
      'Made by one man and his dog. No ads. No subscriptions. Packs support the app.';

  @override
  String get storeAppliesTo =>
      'Packs you buy or redeem and rewards are unlocked for all members of';

  @override
  String get storeRedeemTitle => 'Redeem a code';

  @override
  String get storeRedeemSubtitle => 'Unlock a pack with a gift code';

  @override
  String get storePackCodeLabel => 'Pack code';

  @override
  String get storePackCodeHint => 'WOOF-2026';

  @override
  String get storeApplyPack => 'Apply pack';

  @override
  String storeApplied(String name) {
    return '$name applied!';
  }

  @override
  String storeAlreadyApplied(String name) {
    return '$name is already applied.';
  }

  @override
  String get storeCodeFailed => 'Could not apply that code';

  @override
  String get storeWorking => 'Working…';

  @override
  String storeBuy(String price) {
    return 'Buy  $price';
  }

  @override
  String get storeOwned => 'Owned';

  @override
  String get purchaseCouldNotStart => 'Couldn\'t start the purchase.';

  @override
  String get purchaseFailed => 'The purchase failed.';

  @override
  String get purchaseNeedHousehold => 'Choose a household before buying packs.';

  @override
  String get purchaseVerifyFailed => 'Couldn\'t verify that purchase.';

  @override
  String purchaseUnlocked(String name) {
    return '$name unlocked!';
  }

  @override
  String purchaseAlreadyUnlocked(String name) {
    return '$name is already unlocked.';
  }

  @override
  String get rewardsTitle => 'Free rewards';

  @override
  String get rewardsCharacters => 'Characters';

  @override
  String get rewardsHouses => 'Houses';

  @override
  String rewardsStreakToClaim(int streak, int threshold) {
    return 'Streak $streak / $threshold to claim';
  }

  @override
  String get rewardsNothingToClaim => 'Nothing to claim';

  @override
  String get rewardsClaim => 'Claim';

  @override
  String get rewardsChooseCharacter => 'Choose a character';

  @override
  String get rewardsChooseHouse => 'Choose a house';

  @override
  String get rewardsAllUnlocked =>
      'You\'ve unlocked everything here - more art lands over time.';

  @override
  String get rewardsYourCollection => 'Your Collection';

  @override
  String get rewardsCollectionEmpty =>
      'Nothing yet - build a streak and claim your first.';

  @override
  String rewardsAlreadyYours(String name) {
    return '$name is already yours.';
  }

  @override
  String get rewardsClaimFailed => 'Could not claim that reward.';

  @override
  String get rewardsClaimYourReward => 'Claim your reward below!';

  @override
  String get rewardsYourStreak => 'Your reward streak';

  @override
  String get rewardsRedeemedToday =>
      'Congratulations! Start again and earn another reward.';

  @override
  String get rewardsPickReward => 'Pick a reward to add it to your collection.';

  @override
  String get rewardsKeepStreak =>
      'Keep your daily streak going to earn a free character or house.';

  @override
  String get rewardsCantWait => 'Can\'t wait?';

  @override
  String get rewardsGetMoreHere => 'Get more here';

  @override
  String get rewardsUnlockedBang => 'Unlocked!';

  @override
  String get rewardsViewCollection => 'View Collection';

  @override
  String get rewardsBarAvailable => 'Free reward available!';

  @override
  String get rewardsBarStreak => 'Free reward streak';

  @override
  String get nfcWriteTagTitle => 'Write NFC tag';

  @override
  String get nfcHoldTag => 'Hold a tag to the top of your phone…';

  @override
  String get nfcUnavailable =>
      'NFC is off or unavailable on this device. Turn NFC on and try again.';

  @override
  String get nfcNotMemberHousehold =>
      'You\'re not a member of this tag\'s household.';

  @override
  String get nfcTagNotInHousehold =>
      'That tag points to something that isn\'t in this household.';

  @override
  String get nfcSignInFirst => 'Sign in and pick a household to use NFC tags.';

  @override
  String nfcLogFailed(String details) {
    return 'NFC log failed: $details';
  }

  @override
  String celebrationChoreDone(String name) {
    return '$name\nAll done!';
  }

  @override
  String get celebrationStreakStarted => '🔥 Streak started!';

  @override
  String celebrationStreakDays(int count) {
    return '🔥 $count day streak!';
  }

  @override
  String celebrationLoggedBy(String name) {
    return 'Logged by $name';
  }

  @override
  String get celebrationNice => 'Nice!';

  @override
  String get dayCelebrationBody => 'The whole house is happy. Nice work, team!';

  @override
  String get dayCelebrationThanks => 'Thanks!';

  @override
  String get dayCelebrationSeeAwards => 'See awards';

  @override
  String get claimSignedInTitle => 'You\'re already signed in';

  @override
  String get claimSignedInBody =>
      'Claim links set up a brand-new sign-in for a member someone created for you. They can\'t be added to an account you\'re already signed in to - we don\'t merge accounts.';

  @override
  String get claimSignedInIfForYou => 'If this code is for you:';

  @override
  String get claimSignedInKeepOption =>
      '• Keep this account - stay signed in as you, and ask whoever sent the link for a household join link instead.';

  @override
  String get claimSignedInBecomeOption =>
      '• Become that member - delete this account, then the claim opens automatically. Your completed chores stay with the household.';

  @override
  String get claimKeepAccount => 'Keep my account';

  @override
  String get claimDeleteAndClaim => 'Delete account & claim';

  @override
  String get claimDeleteBody =>
      'This permanently deletes your account and signs you out, then opens the claim sign-up. Chores you completed stay with your household, without your name on them.\n\nThis cannot be undone.';

  @override
  String get awardComebackKidTitle => 'Comeback Kid';

  @override
  String get awardComebackKidDesc => 'Biggest improvement on last week';

  @override
  String get awardEarlyBirdTitle => 'Early Bird';

  @override
  String get awardEarlyBirdDesc => 'Most chores done before 9am';

  @override
  String get awardNightOwlTitle => 'Night Owl';

  @override
  String get awardNightOwlDesc => 'Most chores done after 8pm';

  @override
  String get awardOnTheDotTitle => 'On the Dot';

  @override
  String get awardOnTheDotDesc =>
      'Most chores done within 15 minutes of schedule';

  @override
  String get awardWeekendWarriorTitle => 'Weekend Warrior';

  @override
  String get awardWeekendWarriorDesc =>
      'Most chores done on Saturday and Sunday';

  @override
  String get awardTagChampionTitle => 'Tag Champion';

  @override
  String get awardTagChampionDesc => 'Most chores logged with an NFC tap';

  @override
  String get characterAwardTitleDog => 'Best Human 🩵';

  @override
  String get characterAwardTitleCat => 'Least Disappointing Human';

  @override
  String get characterAwardTitlePlant => 'Greenest Thumb';

  @override
  String get characterAwardTitleBin => 'Lord of the Kerb';

  @override
  String get characterAwardTitleFish => 'Keeper of the Tank';

  @override
  String get characterAwardTitleGeneric => 'Star Helper';

  @override
  String get characterAwardThanksDog =>
      'Thanks for being paws-itively amazing last week!';

  @override
  String get characterAwardThanksCat =>
      'Gracious enough to accept your service last week.';

  @override
  String get characterAwardThanksPlant =>
      'Thanks for keeping things growing last week!';

  @override
  String get characterAwardThanksBin =>
      'Thanks for keeping things rolling last week!';

  @override
  String get characterAwardThanksFish =>
      'Thanks for making a splash last week!';

  @override
  String get characterAwardThanksGeneric =>
      'Thanks for being amazing last week!';

  @override
  String get serverNotSignedIn => 'You must be signed in.';

  @override
  String get serverNotMember => 'You are not a member of that household.';

  @override
  String get serverOwnerOnly => 'Only the household owner can do that.';

  @override
  String get serverNameRequired => 'A name is required.';

  @override
  String get serverPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String get serverClaimCodeInvalid => 'That claim code isn\'t valid.';

  @override
  String get serverEmailInUse => 'That email is already in use.';

  @override
  String get serverNoSuchMember => 'No such member.';

  @override
  String get serverInviteCodeInvalid => 'No open household with that code.';

  @override
  String get serverPackCodeInvalid => 'No pack with that code.';

  @override
  String get serverPackGone => 'That pack is no longer available to redeem.';

  @override
  String get serverUnknownProduct => 'Unknown product.';

  @override
  String get serverVerifyFailed => 'We couldn\'t verify that purchase.';

  @override
  String get serverVerifyUnavailable =>
      'Purchase verification is temporarily unavailable.';

  @override
  String get serverRewardUnavailable => 'That item isn\'t available to unlock.';

  @override
  String get serverStreakCheckFailed =>
      'Couldn\'t check your streak just now - try again shortly.';

  @override
  String serverStreakTooLow(int threshold, int streak) {
    return 'You need a streak of $threshold to unlock this - you\'re on $streak.';
  }

  @override
  String get notifChannelName => 'Chore completions';

  @override
  String get notifChannelDesc => 'When someone in your household logs a chore.';
}
