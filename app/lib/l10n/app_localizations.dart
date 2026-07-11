import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// App title shown in the OS task switcher. Brand name - keep in English in every locale.
  ///
  /// In en, this message translates to:
  /// **'Have You Fed The Dog?'**
  String get appTitle;

  /// Primary button label to save changes on an edit form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Button label to dismiss a dialog without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Button label confirming a destructive delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Button label to close a completed flow.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Validation message under an empty form field that must be filled in.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// Button label to retry a failed action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// The word the user must type to confirm an irreversible delete. ALL CAPS. Translate to the local equivalent of DELETE (e.g. German LÖSCHEN).
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get confirmByTypingWord;

  /// Hint inside the type-to-confirm text field. {word} is confirmByTypingWord.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String confirmByTypingHint(String word);

  /// Default label above a password input field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldLabel;

  /// Tooltip on the eye icon that reveals the typed password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordFieldShow;

  /// Tooltip on the eye icon that masks the typed password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordFieldHide;

  /// Label above the app-language dropdown on the Edit Profile screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageLabel;

  /// Dropdown option meaning: follow the phone's language setting. The language names themselves (English, Deutsch, ...) are endonyms and never translated.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get profileLanguageSystemDefault;

  /// Headline over the login form.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authWelcomeBack;

  /// Headline over the signup form.
  ///
  /// In en, this message translates to:
  /// **'Join the family'**
  String get authJoinFamily;

  /// Playful subtitle under the login headline. Dog-themed brand voice.
  ///
  /// In en, this message translates to:
  /// **'Log in to keep your pup happy and well-fed.'**
  String get authLoginTagline;

  /// Playful subtitle under the signup headline. References the app name's joke (did anyone feed the dog?).
  ///
  /// In en, this message translates to:
  /// **'Sign up and never wonder who fed the dog again.'**
  String get authSignupTagline;

  /// Text before the Sign up link at the foot of the login form.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// Text before the Log in link at the foot of the signup form.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// Login submit button, and the footer link that switches to the login form.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// Signup submit button, and the footer link that switches to the signup form.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// Label above the email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Hint inside the email field; also the validation message when it's empty on login.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// Validation message for a malformed email address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// Hint inside the login password field; also its empty-field validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// Link under the login password field to the reset-password screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// Snackbar when login fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get authLoginFailed;

  /// Snackbar when login fails unexpectedly. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {details}'**
  String authLoginFailedDetails(String details);

  /// Label above the display-name field on signup.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authYourNameLabel;

  /// Hint inside the signup name field: this name is visible to other household members.
  ///
  /// In en, this message translates to:
  /// **'Seen by your housemates'**
  String get authNameHint;

  /// Hint inside the name field when claiming an existing managed member, whose name is already set.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep your current name'**
  String get authNameHintClaim;

  /// Password requirement, shown as helper text under the field and as its validation message.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordRule;

  /// Hint inside the signup password field.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get authChoosePasswordHint;

  /// Disclosure button on signup that reveals the claim-code field. A claim code lets someone take over a managed (loginless) household member.
  ///
  /// In en, this message translates to:
  /// **'I have a claim code'**
  String get authClaimCodeToggle;

  /// Label above the claim-code field.
  ///
  /// In en, this message translates to:
  /// **'Claim code'**
  String get authClaimCodeLabel;

  /// Hint inside the claim-code field.
  ///
  /// In en, this message translates to:
  /// **'Joining as an existing member?'**
  String get authClaimCodeHint;

  /// Submit button label when signing up with a claim code.
  ///
  /// In en, this message translates to:
  /// **'Claim account'**
  String get authClaimAccount;

  /// Snackbar when claiming fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Could not claim account'**
  String get authCouldNotClaim;

  /// Snackbar when signup fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Signup failed'**
  String get authSignupFailed;

  /// Snackbar when signup fails unexpectedly. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Signup failed: {details}'**
  String authSignupFailedDetails(String details);

  /// App bar title of the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordTitle;

  /// Reassuring intro on the forgot-password screen. Keep the line break.
  ///
  /// In en, this message translates to:
  /// **'No worries - it happens to the best of us.\nWe\'ll email you a link to set a new one.'**
  String get authResetIntro;

  /// Submit button on the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// Headline after the reset email was requested.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox!'**
  String get authCheckInbox;

  /// Confirmation text after requesting a password reset. Deliberately does not confirm whether the account exists.
  ///
  /// In en, this message translates to:
  /// **'If there\'s an account for {email}, a reset link is on its way. Follow it to set a new password, then log in here.'**
  String authResetSent(String email);

  /// Snackbar when requesting the reset email fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not send the reset email: {details}'**
  String authResetEmailFailed(String details);

  /// Button returning from the reset-sent confirmation to the login screen.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get authBackToLogin;

  /// Headline when the app fails to reach the server at startup.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t start up'**
  String get startupErrorTitle;

  /// Body text under the startup error headline.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get startupErrorBody;

  /// Short label under the dashed add-slot chip.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Primary button that saves edits on a form screen.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get commonSaveChanges;

  /// Snackbar when saving fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {details}'**
  String commonCouldNotSave(String details);

  /// Snackbar when deleting fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {details}'**
  String commonCouldNotDelete(String details);

  /// Confirm-dialog title for deleting a named item (a thing, a chore, a member). {name} is user content.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String commonDeleteTitle(String name);

  /// Bare error line when a screen can't load. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String commonErrorDetails(String details);

  /// Empty-state headline when the home screen fails to load the things list.
  ///
  /// In en, this message translates to:
  /// **'Hmm, something went sideways'**
  String get homeErrorTitle;

  /// Empty-state body under homeErrorTitle. {details} is a raw technical error, untranslated. 'Things' are the pets/plants/objects being cared for.
  ///
  /// In en, this message translates to:
  /// **'Could not load your things. {details}'**
  String homeErrorBody(String details);

  /// Celebration line when no chores are scheduled today. Keep the emoji.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today 🎉'**
  String get homeNothingDueToday;

  /// Section header over the list of chores due today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s chores'**
  String get homeTodaysChores;

  /// Hint under the Today's chores header: tapping a row logs the chore as done.
  ///
  /// In en, this message translates to:
  /// **'Tap to complete'**
  String get homeTapToComplete;

  /// Summary-card title when every chore today is complete.
  ///
  /// In en, this message translates to:
  /// **'All chores done today!'**
  String get homeSummaryAllDone;

  /// Summary-card title when no chores are done yet today.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started!'**
  String get homeSummaryStart;

  /// Summary-card title when some but not all chores are done.
  ///
  /// In en, this message translates to:
  /// **'Good progress. Keep it up!'**
  String get homeSummaryKeepUp;

  /// Progress line on the summary card, e.g. '2 of 5 completed'.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} completed'**
  String homeSummaryCount(int done, int total);

  /// Empty-state headline when the household has no things (pets/plants/objects) yet.
  ///
  /// In en, this message translates to:
  /// **'No things yet'**
  String get subjectsEmptyTitle;

  /// Empty-state body inviting the user to add their first thing.
  ///
  /// In en, this message translates to:
  /// **'Add a dog, cat, plant, or whatever else needs looking after.'**
  String get subjectsEmptyBody;

  /// Button that opens the new-thing form. 'Thing' is the app's word for a pet/plant/object being cared for.
  ///
  /// In en, this message translates to:
  /// **'Add a thing'**
  String get subjectsAddThing;

  /// Title of the Things tab.
  ///
  /// In en, this message translates to:
  /// **'Things'**
  String get subjectsTabTitle;

  /// Playful subtitle under the Things tab title.
  ///
  /// In en, this message translates to:
  /// **'Sometimes friends, often just stuff. These are the things you look after or don\'t want to forget.'**
  String get subjectsTabSubtitle;

  /// Error line when the things list fails to load. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not load things: {details}'**
  String subjectsLoadFailed(String details);

  /// Status line on a thing's card when it has chores, but none due today.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get subjectNothingDueToday;

  /// Status line on a thing's card when it has no chores at all.
  ///
  /// In en, this message translates to:
  /// **'No chores yet'**
  String get subjectNoChoresYet;

  /// Progress line on a thing's card, e.g. '1 of 3 done today'.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done today'**
  String subjectDoneToday(int done, int total);

  /// Streak pill on the thing's page, e.g. '5-day streak'. Only shown for 3+.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String subjectStreakDays(int count);

  /// Tooltip on the NFC icon showing this thing has a physical tag.
  ///
  /// In en, this message translates to:
  /// **'NFC tag written'**
  String get subjectNfcTagWritten;

  /// Link from a thing's page to the chore-management section on its edit page. Keep the arrow.
  ///
  /// In en, this message translates to:
  /// **'Manage chores →'**
  String get subjectManageChoresLink;

  /// Section header over a thing's recent completion history.
  ///
  /// In en, this message translates to:
  /// **'Completed chores'**
  String get subjectCompletedChores;

  /// Link to the full activity feed filtered to this thing. Keep the arrow.
  ///
  /// In en, this message translates to:
  /// **'See all →'**
  String get subjectSeeAll;

  /// Error line when a thing's history fails to load. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not load history: {details}'**
  String subjectHistoryLoadFailed(String details);

  /// Placeholder when a thing has no completion history.
  ///
  /// In en, this message translates to:
  /// **'No completions logged yet.'**
  String get subjectNoCompletions;

  /// App bar title when editing a thing. {name} is the thing's name.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editSubjectTitle(String name);

  /// App bar title when creating a thing.
  ///
  /// In en, this message translates to:
  /// **'New thing'**
  String get editSubjectNewTitle;

  /// Tooltip on the delete icon in the edit-thing app bar.
  ///
  /// In en, this message translates to:
  /// **'Delete thing'**
  String get editSubjectDeleteTooltip;

  /// Body of the type-to-confirm dialog when deleting a thing.
  ///
  /// In en, this message translates to:
  /// **'All chores and history for this thing will be permanently removed. This cannot be undone.'**
  String get editSubjectDeleteBody;

  /// Label above the thing's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editSubjectNameLabel;

  /// Hint inside the thing's name field - an example pet name. Swap for a name common in the locale.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kiko'**
  String get editSubjectNameHint;

  /// Submit button when creating a thing.
  ///
  /// In en, this message translates to:
  /// **'Add thing'**
  String get editSubjectAdd;

  /// Header of the chore-chip section on the edit-thing page.
  ///
  /// In en, this message translates to:
  /// **'Manage chores'**
  String get editSubjectManageChores;

  /// Body of the confirm dialog when deleting a chore.
  ///
  /// In en, this message translates to:
  /// **'Its schedule and reminders go with it. Past completions stay in the history.'**
  String get editSubjectDeleteChoreBody;

  /// NFC card status when a physical tag exists for this thing.
  ///
  /// In en, this message translates to:
  /// **'Tag written'**
  String get editSubjectTagWritten;

  /// NFC card status when no tag has been written for this thing.
  ///
  /// In en, this message translates to:
  /// **'No tag yet'**
  String get editSubjectNoTag;

  /// NFC card subtitle (tap-completes mode). Followed by a tappable 'Edit Profile' link and a period, so end mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'On this phone, a tap ticks off the current chore. Change this in'**
  String get editSubjectTapCompletes;

  /// NFC card subtitle (tap-opens mode). Followed by a tappable 'Edit Profile' link and a period, so end mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'On this phone, a tap opens this thing\'s page. Change this in'**
  String get editSubjectTapOpens;

  /// The tappable link text inside the NFC card subtitle. Should match the Edit Profile screen's name.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editSubjectEditProfileLink;

  /// NFC card subtitle when no tag exists yet.
  ///
  /// In en, this message translates to:
  /// **'Write a tag so a tap logs this thing.'**
  String get editSubjectWriteTagPrompt;

  /// Button starting the NFC tag write flow.
  ///
  /// In en, this message translates to:
  /// **'Write an NFC tag'**
  String get editSubjectWriteTag;

  /// Button label when a tag already exists and the user wants to write an additional one.
  ///
  /// In en, this message translates to:
  /// **'Write another NFC tag'**
  String get editSubjectWriteAnotherTag;

  /// Button clearing the 'tag written' marker for this thing.
  ///
  /// In en, this message translates to:
  /// **'Forget tag'**
  String get editSubjectForgetTag;

  /// Snackbar when recording the written NFC tag fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not save tag: {details}'**
  String editSubjectSaveTagFailed(String details);

  /// Snackbar when clearing the NFC tag marker fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not forget: {details}'**
  String editSubjectForgetTagFailed(String details);

  /// Link under the character picker to the store's character packs. Keep the arrow.
  ///
  /// In en, this message translates to:
  /// **'Get more characters →'**
  String get browseMoreCharacters;

  /// Day header for today in the history timeline.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// Day header for yesterday in the history timeline.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// Schedule line for a daily chore. {time} is a pre-formatted clock like '6:30 pm' or '18:30'.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String scheduleDaily(String time);

  /// Schedule line for a weekly chore. {days} is a comma-joined list of short weekday names like 'Mon, Wed'.
  ///
  /// In en, this message translates to:
  /// **'{days} at {time}'**
  String scheduleWeeklyAt(String days, String time);

  /// Schedule line for a weekly chore with no weekdays selected.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get scheduleNever;

  /// Schedule line for an every-two-weeks chore. {phase} is scheduleThisWeek or scheduleNextWeek. Keep the middle dot separator or use a natural equivalent.
  ///
  /// In en, this message translates to:
  /// **'Fortnightly on {days} at {time} · {phase}'**
  String scheduleFortnightly(String days, String time, String phase);

  /// Fortnightly phase suffix: the chore is due in the current calendar week. Lowercase, mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get scheduleThisWeek;

  /// Fortnightly phase suffix: the chore is due next calendar week. Lowercase, mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'next week'**
  String get scheduleNextWeek;

  /// Schedule line for a monthly chore on a fixed day. {day} is a pre-formatted ordinal like '1st' / '1.' / '1er'.
  ///
  /// In en, this message translates to:
  /// **'Monthly on the {day} at {time}'**
  String scheduleMonthlyOnDayAt(String day, String time);

  /// Schedule line for a monthly chore on the last day of the month.
  ///
  /// In en, this message translates to:
  /// **'Monthly on the last day at {time}'**
  String scheduleMonthlyLastDayAt(String time);

  /// Schedule line for a monthly chore on the Nth weekday. {position} is one of the schedulePosition* words; {weekday} is a short weekday name.
  ///
  /// In en, this message translates to:
  /// **'Monthly on the {position} {weekday} at {time}'**
  String scheduleMonthlyOnWeekdayAt(
    String position,
    String weekday,
    String time,
  );

  /// Ordinal word used only inside scheduleMonthlyOnWeekdayAt ('the first Mon'). Inflect to fit that sentence.
  ///
  /// In en, this message translates to:
  /// **'first'**
  String get schedulePositionFirst;

  /// See schedulePositionFirst.
  ///
  /// In en, this message translates to:
  /// **'second'**
  String get schedulePositionSecond;

  /// See schedulePositionFirst.
  ///
  /// In en, this message translates to:
  /// **'third'**
  String get schedulePositionThird;

  /// See schedulePositionFirst.
  ///
  /// In en, this message translates to:
  /// **'fourth'**
  String get schedulePositionFourth;

  /// See schedulePositionFirst - 'the last Mon' of the month.
  ///
  /// In en, this message translates to:
  /// **'last'**
  String get schedulePositionLast;

  /// Schedule line for a one-off task with no date set.
  ///
  /// In en, this message translates to:
  /// **'One time at {time}'**
  String scheduleOnceAt(String time);

  /// Schedule line for a one-off task. {date} is a pre-formatted short date like '30 Jun'.
  ///
  /// In en, this message translates to:
  /// **'One time on {date} at {time}'**
  String scheduleOnceOn(String date, String time);

  /// Red status line on a chore row that is under an hour late.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute overdue} other{{count} minutes overdue}}'**
  String overdueMinutes(int count);

  /// Red status line on a chore row that is an hour or more late. The 'other' form deliberately reads 'over N hours'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour overdue} other{over {count} hours overdue}}'**
  String overdueHours(int count);

  /// Top line of the small stacked 'Due in / 15 / mins' status on a chore row. Keep very short.
  ///
  /// In en, this message translates to:
  /// **'Due in'**
  String get dueIn;

  /// Bottom line of the stacked due-in status when counting hours. Abbreviate the plural if natural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{hour} other{hrs}}'**
  String dueInUnitHours(int count);

  /// Bottom line of the stacked due-in status when counting minutes. Abbreviated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{min} other{mins}}'**
  String dueInUnitMins(int count);

  /// Placeholder on the one-off date tile before a date is chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get editChorePickDate;

  /// Dropdown item for a monthly day-of-month. {day} is a pre-formatted ordinal like '15th'.
  ///
  /// In en, this message translates to:
  /// **'The {day}'**
  String editChoreMonthDayItem(String day);

  /// Dropdown item: the last day of the month.
  ///
  /// In en, this message translates to:
  /// **'The last day'**
  String get editChoreLastDay;

  /// Label for the signed-in user's own entries in the history timeline.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// Fallback display name when a member can't be resolved.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get commonSomeone;

  /// Snackbar when logging a completion fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not log: {details}'**
  String choreCouldNotLog(String details);

  /// Snackbar when undoing a completion fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not undo: {details}'**
  String choreCouldNotUndo(String details);

  /// Snackbar after undoing a completion. {name} is the chore's name.
  ///
  /// In en, this message translates to:
  /// **'Removed: {name}'**
  String choreRemoved(String name);

  /// Snackbar when trying to undo a completion logged by someone else. 'Switch to' refers to the Act-as picker.
  ///
  /// In en, this message translates to:
  /// **'Switch to whoever logged this (or ask an owner) to undo it.'**
  String get choreUndoNotAllowed;

  /// Confirm-dialog title before un-logging a completion. {name} is the chore's name.
  ///
  /// In en, this message translates to:
  /// **'Undo \"{name}\"?'**
  String undoDialogTitle(String name);

  /// Body of the undo-completion confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'This marks the chore as not done again, and the rest of the household is told.'**
  String get undoDialogBody;

  /// Destructive button confirming the undo.
  ///
  /// In en, this message translates to:
  /// **'Undo it'**
  String get undoDialogAction;

  /// Habit line on a chore row; followed by a clock time on the same row, so end mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'Usually done around'**
  String get choreUsuallyDoneAround;

  /// Small pill marking a one-off (non-recurring) chore. Keep short.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get choreOneTimePill;

  /// Footer of a completed chore row. {name} is the member who logged it.
  ///
  /// In en, this message translates to:
  /// **'Completed by {name}'**
  String choreCompletedBy(String name);

  /// App bar title when editing a chore.
  ///
  /// In en, this message translates to:
  /// **'Edit chore'**
  String get editChoreTitle;

  /// App bar title when creating a chore; also the preview card's placeholder name.
  ///
  /// In en, this message translates to:
  /// **'New chore'**
  String get editChoreNewTitle;

  /// Tooltip on the delete icon in the edit-chore app bar.
  ///
  /// In en, this message translates to:
  /// **'Delete chore'**
  String get editChoreDeleteTooltip;

  /// Body of the confirm dialog when deleting a chore from its edit screen.
  ///
  /// In en, this message translates to:
  /// **'All completion history for this chore will be permanently removed. This cannot be undone.'**
  String get editChoreDeleteBody;

  /// Label above the chore's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editChoreNameLabel;

  /// Hint inside the chore name field - an example chore. Swap for a natural example in the locale.
  ///
  /// In en, this message translates to:
  /// **'e.g. Breakfast'**
  String get editChoreNameHint;

  /// Label above the Repeats / One time toggle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get editChoreScheduleLabel;

  /// Toggle segment: the chore recurs.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get editChoreRepeats;

  /// Toggle segment: a single dated task.
  ///
  /// In en, this message translates to:
  /// **'One time'**
  String get editChoreOneTime;

  /// Label above the daily/weekly/monthly frequency segments.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get editChoreFrequencyLabel;

  /// Frequency segment: daily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get editChoreFreqDaily;

  /// Frequency segment: weekly on chosen days.
  ///
  /// In en, this message translates to:
  /// **'Some days'**
  String get editChoreFreqWeekly;

  /// Frequency segment: monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get editChoreFreqMonthly;

  /// Label above the weekday chips for a weekly chore.
  ///
  /// In en, this message translates to:
  /// **'On these days'**
  String get editChoreOnTheseDays;

  /// Validation line when no weekday is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get editChorePickOneDay;

  /// Label above the every-week / fortnightly segments.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get editChoreHowOften;

  /// Cadence segment: weekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get editChoreEveryWeek;

  /// Cadence segment: every two weeks.
  ///
  /// In en, this message translates to:
  /// **'Fortnightly'**
  String get editChoreFortnightly;

  /// Label above the this-week / next-week chips for a fortnightly chore.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get editChoreStarting;

  /// Chip: the fortnightly cadence starts this week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get editChoreThisWeek;

  /// Chip: the fortnightly cadence starts next week.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get editChoreNextWeek;

  /// Label above the monthly Exact Day / First / Second... chips - reads as 'On the [first Monday]'.
  ///
  /// In en, this message translates to:
  /// **'On the'**
  String get editChoreOnThe;

  /// Chip switching the monthly schedule to a fixed day of the month.
  ///
  /// In en, this message translates to:
  /// **'Exact Day'**
  String get editChoreExactDay;

  /// Monthly ordinal chip - 'the First [weekday] of the month'.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get editChorePosFirst;

  /// See editChorePosFirst.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get editChorePosSecond;

  /// See editChorePosFirst.
  ///
  /// In en, this message translates to:
  /// **'Third'**
  String get editChorePosThird;

  /// See editChorePosFirst.
  ///
  /// In en, this message translates to:
  /// **'Fourth'**
  String get editChorePosFourth;

  /// See editChorePosFirst - the last such weekday of the month.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get editChorePosLast;

  /// Label above the day-of-month dropdown.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get editChoreDayLabel;

  /// Label above the single-weekday picker for a monthly chore.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get editChoreWeekdayLabel;

  /// Label above the date tile for a one-off task - reads as 'On [Wed, 30 Jun]'.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get editChoreOnDateLabel;

  /// Label above the time tile - reads as 'At [6:30 pm]'.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get editChoreAtTimeLabel;

  /// Submit button when creating a chore.
  ///
  /// In en, this message translates to:
  /// **'Add chore'**
  String get editChoreAddChore;

  /// Fallback timeline entry name when the chore was deleted and no name was stored.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get timelineLogged;

  /// Title of the Awards tab.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get historyAwardsTitle;

  /// Stat label under the household's current daily streak count.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get historyDayStreak;

  /// Stat label under this week's completion count; also the leaderboard section header.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get historyThisWeek;

  /// Stat label under the count of days where every chore got done.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Clean sweep} other{Clean sweeps}}'**
  String historyCleanSweeps(int count);

  /// Header of the household-wide completion feed.
  ///
  /// In en, this message translates to:
  /// **'All activity'**
  String get historyAllActivity;

  /// Filter chip showing activity for every thing (no filter).
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// Empty-state headline for the activity feed.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet!'**
  String get historyEmptyTitle;

  /// Empty-state body for the activity feed.
  ///
  /// In en, this message translates to:
  /// **'Be the first one to complete a chore.'**
  String get historyEmptyBody;

  /// Placeholder card when the weekly leaderboard has no entries.
  ///
  /// In en, this message translates to:
  /// **'No chores completed yet this week!'**
  String get leaderboardEmpty;

  /// The signed-in user's own leaderboard entry - their name plus a 'that's you' marker.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String leaderboardYouSuffix(String name);

  /// Header of the badge cabinet section on the Awards tab.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get awardsBadges;

  /// Title of the household-wide fairness badge.
  ///
  /// In en, this message translates to:
  /// **'Team Effort'**
  String get awardsTeamEffort;

  /// Description under the Team Effort badge.
  ///
  /// In en, this message translates to:
  /// **'Everyone pulled their weight - the load was shared fairly'**
  String get awardsTeamEffortDesc;

  /// Footer of an award nobody has earned this week.
  ///
  /// In en, this message translates to:
  /// **'Unclaimed'**
  String get awardsUnclaimed;

  /// All-caps pill on the featured award card. Keep it shouty/celebratory.
  ///
  /// In en, this message translates to:
  /// **'LAST WEEK\'S WINNER'**
  String get awardsLastWeeksWinner;

  /// Possessive line stacked directly above the award title on the featured card - reads as e.g. "Kiko's / Best Human". Use the locale's natural possessive (German: {name}s, French: might invert to 'de {name}').
  ///
  /// In en, this message translates to:
  /// **'{name}\'s'**
  String awardsSubjectPossessive(String name);

  /// Featured award card body when nobody won. {name} is the thing/pet's name.
  ///
  /// In en, this message translates to:
  /// **'No winner last week - do the most of {name}\'s chores to take it next time!'**
  String awardsNoWinnerYet(String name);

  /// Winning tally under the featured award winner's name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} chore} other{{count} chores}}'**
  String awardsChoreCount(int count);

  /// Log-out action label (menu item and drop-target caption).
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get commonLogOut;

  /// Fallback app bar title when the household can't be shown.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdTitle;

  /// Full-screen message when opening a household you've been removed from.
  ///
  /// In en, this message translates to:
  /// **'You\'re no longer a member of this household.'**
  String get householdNoLonger;

  /// Tooltip on the delete icon in the household app bar (owner only).
  ///
  /// In en, this message translates to:
  /// **'Delete household'**
  String get householdDeleteTooltip;

  /// Body of the type-to-confirm dialog when deleting a household.
  ///
  /// In en, this message translates to:
  /// **'All subjects, chores and history for this household will be permanently removed for everyone in it. This cannot be undone.'**
  String get householdDeleteBody;

  /// Confirm-dialog title before leaving a household. {name} is the household's name.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String householdLeaveTitle(String name);

  /// Body of the leave-household confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see this household\'s chores or completions any more. You can re-join later with an invite code.'**
  String get householdLeaveBody;

  /// Leave-household action button; also the caption under the leave drop-target.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get householdLeave;

  /// Body of the type-to-confirm dialog when deleting a managed (loginless) member. "Someone" refers to the commonSomeone fallback name.
  ///
  /// In en, this message translates to:
  /// **'{name} is a managed member and this removes them completely. Their past completions still count but will show as \"Someone\".'**
  String householdDeleteManagedBody(String name);

  /// Link under the house-picture picker to the store. Keep the arrow.
  ///
  /// In en, this message translates to:
  /// **'Get more homes →'**
  String get browseMoreHomes;

  /// Link under the avatar picker to the store. Keep the arrow.
  ///
  /// In en, this message translates to:
  /// **'Get more avatars →'**
  String get browseMoreAvatars;

  /// Label above the household name field.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdNameLabel;

  /// Hint inside the household name field on the create form.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Paihia House\" or \"Home\"'**
  String get householdNameHint;

  /// Label above the optional residents line (a family nickname like 'The Goodchilds').
  ///
  /// In en, this message translates to:
  /// **'Who lives here?'**
  String get householdResidentsLabel;

  /// Example family nickname inside the residents field. Swap for a natural example in the locale.
  ///
  /// In en, this message translates to:
  /// **'The Goodchilds'**
  String get householdResidentsHint;

  /// Info line showing the household's IANA timezone id (untranslated technical value).
  ///
  /// In en, this message translates to:
  /// **'Timezone: {tz}'**
  String householdTimezone(String tz);

  /// Button applying this phone's timezone to the household. Short - sits at the end of the timezone row.
  ///
  /// In en, this message translates to:
  /// **'Use this phone\'s'**
  String get householdUsePhoneTz;

  /// Members-card header when no residents nickname is set.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get householdMembersFallback;

  /// Snackbar fallback when a save fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get householdSaveFailed;

  /// Role line on a household tile, lowercase.
  ///
  /// In en, this message translates to:
  /// **'owner'**
  String get householdRoleOwner;

  /// Role line on a household tile, lowercase.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get householdRoleMember;

  /// Title of the add-member chooser sheet.
  ///
  /// In en, this message translates to:
  /// **'Add someone'**
  String get addSomeoneTitle;

  /// Chooser option: invite a real member with their own account.
  ///
  /// In en, this message translates to:
  /// **'Invite someone with a login'**
  String get addInviteTitle;

  /// Explanation under addInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Family or flatmates who sign in on their own phone. They join with a code and log their own chores.'**
  String get addInviteSubtitle;

  /// Chooser option: create a managed (loginless) member.
  ///
  /// In en, this message translates to:
  /// **'Add someone without a login'**
  String get addManagedTitle;

  /// Explanation under addManagedTitle. 'Whose turn?' must match the whoseTurn key.
  ///
  /// In en, this message translates to:
  /// **'For anyone without their own login. You manage their profile, and log their chores by switching to them with \'Whose turn?\' on the You tab.'**
  String get addManagedSubtitle;

  /// Header of the invite-code card.
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get inviteSomeone;

  /// Subtitle under the invite-code card header.
  ///
  /// In en, this message translates to:
  /// **'Invite family or flatmates'**
  String get inviteSubtitle;

  /// Label next to the invite toggle when open.
  ///
  /// In en, this message translates to:
  /// **'Invites are on'**
  String get invitesOn;

  /// Label next to the invite toggle when closed.
  ///
  /// In en, this message translates to:
  /// **'Invites are off'**
  String get invitesOff;

  /// Note under the invite code: it stays valid while invites are on.
  ///
  /// In en, this message translates to:
  /// **'Live until you turn invites off'**
  String get inviteLiveUntil;

  /// Button opening the system share sheet with the invite/claim code.
  ///
  /// In en, this message translates to:
  /// **'Share code'**
  String get shareCode;

  /// Button rotating the invite/claim code, invalidating the old one.
  ///
  /// In en, this message translates to:
  /// **'Generate new code'**
  String get generateNewCode;

  /// Share-sheet text for a household invite. Keep the URL exactly as is; the app name stays in English.
  ///
  /// In en, this message translates to:
  /// **'Join our household on Have You Fed The Dog?\nhttps://haveyoufedthedog.com/join?code={code}\n\nIf the link doesn\'t open the app, open it and enter invite code {code}'**
  String inviteShareText(String code);

  /// Share-sheet subject line for a household invite. App name stays in English.
  ///
  /// In en, this message translates to:
  /// **'Have You Fed The Dog? - household invite'**
  String get inviteShareSubject;

  /// Error line when the member list fails to load. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not load members: {details}'**
  String membersLoadFailed(String details);

  /// Confirm-dialog title before kicking a member. {name} is their display name.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String memberRemoveTitle(String name);

  /// Body of the kick-member confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose access to this household immediately. They can re-join later with an invite code.'**
  String memberRemoveBody(String name);

  /// Kick-member action button; also the caption under the remove drop-target.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get memberRemove;

  /// Caption under the household owner's avatar in the members cloud.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get memberOwner;

  /// App bar title when editing a managed member.
  ///
  /// In en, this message translates to:
  /// **'Edit member'**
  String get editMemberTitle;

  /// App bar title when creating a managed member.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMemberTitle;

  /// Tooltip on the delete icon in the edit-member app bar.
  ///
  /// In en, this message translates to:
  /// **'Delete member'**
  String get deleteMemberTooltip;

  /// Label above a display-name field (profile and managed member).
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// Hint inside the managed member's name field.
  ///
  /// In en, this message translates to:
  /// **'How this member appears to everyone'**
  String get memberNameHint;

  /// Header of the claim-code card on the edit-member screen.
  ///
  /// In en, this message translates to:
  /// **'Give them their own login'**
  String get claimLoginTitle;

  /// Subtitle under claimLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Let them claim this account and sign in themselves'**
  String get claimLoginSubtitle;

  /// Note under the claim code. 'Sign up' refers to the signup screen.
  ///
  /// In en, this message translates to:
  /// **'They enter this on Sign up. Live until you turn it off.'**
  String get claimCodeInfo;

  /// Share-sheet text for a claim code. Keep the URL exactly as is; the app name stays in English.
  ///
  /// In en, this message translates to:
  /// **'Claim your account on Have You Fed The Dog?\nhttps://haveyoufedthedog.com/claim?code={code}\n\nIf the link doesn\'t open the app, open it, tap Sign up, and enter claim code {code}'**
  String claimShareText(String code);

  /// Share-sheet subject line for a claim code. App name stays in English.
  ///
  /// In en, this message translates to:
  /// **'Have You Fed The Dog? - claim your account'**
  String get claimShareSubject;

  /// App bar title of the household picker.
  ///
  /// In en, this message translates to:
  /// **'Your households'**
  String get householdsYourTitle;

  /// Tooltip on the overflow menu for users with no household.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// Overflow menu item opening the profile editor.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get menuEditProfile;

  /// Empty state on the household picker.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in any households yet. Create one or join with an invite code below.'**
  String get householdsEmpty;

  /// Button opening the create-household form.
  ///
  /// In en, this message translates to:
  /// **'Create a new household'**
  String get householdsCreateNew;

  /// Button opening the join-household form.
  ///
  /// In en, this message translates to:
  /// **'Join with invite code'**
  String get householdsJoinWithCode;

  /// App bar title and submit button of the create-household form.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get createHouseholdTitle;

  /// Snackbar fallback when creating a household fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Could not create'**
  String get createHouseholdFailed;

  /// Intro line on the create-household form.
  ///
  /// In en, this message translates to:
  /// **'Start a new household - for your family, flatmates, or anyone you share chores with.'**
  String get createHouseholdIntro;

  /// App bar title and submit button of the join-household form.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get joinHouseholdTitle;

  /// Snackbar fallback when joining fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Could not join'**
  String get joinHouseholdFailed;

  /// Intro line on the join-household form.
  ///
  /// In en, this message translates to:
  /// **'Got a code from a family member? Paste it here to join their household.'**
  String get joinIntro;

  /// Label above the invite-code field.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// Example invite code inside the field. Keep the format; the code itself is arbitrary.
  ///
  /// In en, this message translates to:
  /// **'e.g. KIKO-7H4P'**
  String get inviteCodeHint;

  /// Title of the You tab (the user's own profile page).
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youTabTitle;

  /// Placeholder on the You tab when the user has no display name.
  ///
  /// In en, this message translates to:
  /// **'(no name set)'**
  String get youNoName;

  /// Playful header over the switch-household / log-out drag card.
  ///
  /// In en, this message translates to:
  /// **'Moving day?'**
  String get movingDay;

  /// Caption under the switch-household drop-target.
  ///
  /// In en, this message translates to:
  /// **'Switch household'**
  String get switchHousehold;

  /// Header of the act-as picker. Must match the mention in addManagedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Whose turn?'**
  String get whoseTurn;

  /// Subtitle under the act-as header.
  ///
  /// In en, this message translates to:
  /// **'Log chores on behalf of another member'**
  String get whoseTurnSubtitle;

  /// Banner while acting as a managed member. Use the locale's natural possessive.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String actingTurn(String name);

  /// Button reverting the act-as picker back to yourself.
  ///
  /// In en, this message translates to:
  /// **'My turn again'**
  String get myTurnAgain;

  /// App bar title of the profile editor. Should match editSubjectEditProfileLink.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// Tooltip on the delete icon in the profile app bar.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTooltip;

  /// Title of the type-to-confirm dialog for account deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// Body of the account-deletion confirm dialog. Keep the blank line.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and signs you out. Chores you completed stay with your household, without your name on them. Households left with nobody in them are deleted entirely.\n\nThis cannot be undone.'**
  String get deleteAccountBody;

  /// Destructive button on the account-deletion dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// Snackbar when account deletion fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account: {details}'**
  String couldNotDeleteAccount(String details);

  /// Hint inside the profile display-name field.
  ///
  /// In en, this message translates to:
  /// **'How others in your household see you'**
  String get profileNameHint;

  /// Helper under the read-only email field.
  ///
  /// In en, this message translates to:
  /// **'Email can\'t be changed.'**
  String get emailCantChange;

  /// Title of the per-device NFC behaviour toggle.
  ///
  /// In en, this message translates to:
  /// **'Complete chore on tap'**
  String get nfcCompleteOnTap;

  /// Toggle subtitle when tap-completes is on.
  ///
  /// In en, this message translates to:
  /// **'Tapping a tag completes the current chore.'**
  String get nfcTapCompletesDesc;

  /// Toggle subtitle when tap-completes is off.
  ///
  /// In en, this message translates to:
  /// **'Tapping a tag opens the thing\'s page.'**
  String get nfcTapOpensDesc;

  /// Hint on the avatar picker tray.
  ///
  /// In en, this message translates to:
  /// **'Drag or tap'**
  String get avatarDragOrTap;

  /// Tooltip on the random shuffle button (avatar picker and rewards stage).
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get avatarSurpriseMe;

  /// Bottom-nav tab label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom-nav tab label - the pets/plants/objects being cared for.
  ///
  /// In en, this message translates to:
  /// **'Things'**
  String get navThings;

  /// Bottom-nav tab label.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get navAwards;

  /// Tooltip on the central + floating action button.
  ///
  /// In en, this message translates to:
  /// **'Add a chore'**
  String get navAddChore;

  /// Title of the pick-a-thing sheet opened by the + button. Keep the ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Add a chore for…'**
  String get navAddChoreFor;

  /// App bar title of the pack shop.
  ///
  /// In en, this message translates to:
  /// **'Image packs'**
  String get storeTitle;

  /// Tooltip on the restore-purchases icon.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get storeRestoreTooltip;

  /// Error when the product list fails to load. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the shop.\n{details}'**
  String storeLoadFailed(String details);

  /// Placeholder when the shop has no products. Keep the line break.
  ///
  /// In en, this message translates to:
  /// **'No packs available yet.\nCheck back soon!'**
  String get storeNoPacks;

  /// Warm supporter note at the top of the store. The app really is made by one person and their dog.
  ///
  /// In en, this message translates to:
  /// **'Made by one man and his dog. No ads. No subscriptions. Packs support the app.'**
  String get storeSupportNote;

  /// Scope note; followed by the bolded household name and a period, so end mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'Packs you buy or redeem and rewards are unlocked for all members of'**
  String get storeAppliesTo;

  /// Header of the gift-code accordion.
  ///
  /// In en, this message translates to:
  /// **'Redeem a code'**
  String get storeRedeemTitle;

  /// Subtitle under the redeem header.
  ///
  /// In en, this message translates to:
  /// **'Unlock a pack with a gift code'**
  String get storeRedeemSubtitle;

  /// Label above the gift-code field.
  ///
  /// In en, this message translates to:
  /// **'Pack code'**
  String get storePackCodeLabel;

  /// Example gift code inside the field. Keep as is - codes are arbitrary.
  ///
  /// In en, this message translates to:
  /// **'WOOF-2026'**
  String get storePackCodeHint;

  /// Caption under the drop-target circle the gift chip is dragged onto.
  ///
  /// In en, this message translates to:
  /// **'Apply pack'**
  String get storeApplyPack;

  /// Snackbar after redeeming a pack code. {name} is the pack's name.
  ///
  /// In en, this message translates to:
  /// **'{name} applied!'**
  String storeApplied(String name);

  /// Snackbar when the redeemed pack was already on the household.
  ///
  /// In en, this message translates to:
  /// **'{name} is already applied.'**
  String storeAlreadyApplied(String name);

  /// Snackbar fallback when redeeming fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Could not apply that code'**
  String get storeCodeFailed;

  /// Buy-button label while a purchase is in flight.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get storeWorking;

  /// Buy-button label. {price} is the store-formatted price (e.g. £1.99). Keep the double space.
  ///
  /// In en, this message translates to:
  /// **'Buy  {price}'**
  String storeBuy(String price);

  /// Pill replacing the Buy button once the household owns the product.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get storeOwned;

  /// Snackbar when the store refuses to open the purchase flow.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the purchase.'**
  String get purchaseCouldNotStart;

  /// Snackbar fallback when the store reports a purchase error without a message.
  ///
  /// In en, this message translates to:
  /// **'The purchase failed.'**
  String get purchaseFailed;

  /// Snackbar when buying with no active household to grant the pack to.
  ///
  /// In en, this message translates to:
  /// **'Choose a household before buying packs.'**
  String get purchaseNeedHousehold;

  /// Snackbar fallback when server-side receipt verification fails without a message.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify that purchase.'**
  String get purchaseVerifyFailed;

  /// Snackbar after a successful purchase. {name} is the product's name.
  ///
  /// In en, this message translates to:
  /// **'{name} unlocked!'**
  String purchaseUnlocked(String name);

  /// Snackbar when a purchase/restore re-granted something the household already had.
  ///
  /// In en, this message translates to:
  /// **'{name} is already unlocked.'**
  String purchaseAlreadyUnlocked(String name);

  /// App bar title of the streak-reward claim page.
  ///
  /// In en, this message translates to:
  /// **'Free rewards'**
  String get rewardsTitle;

  /// Segment: show claimable characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get rewardsCharacters;

  /// Segment: show claimable house pictures.
  ///
  /// In en, this message translates to:
  /// **'Houses'**
  String get rewardsHouses;

  /// Claim-button label while the streak is below the threshold.
  ///
  /// In en, this message translates to:
  /// **'Streak {streak} / {threshold} to claim'**
  String rewardsStreakToClaim(int streak, int threshold);

  /// Claim-button label when no art is left to earn.
  ///
  /// In en, this message translates to:
  /// **'Nothing to claim'**
  String get rewardsNothingToClaim;

  /// Claim-button label when a reward can be claimed.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get rewardsClaim;

  /// Header over the earnable characters tray.
  ///
  /// In en, this message translates to:
  /// **'Choose a character'**
  String get rewardsChooseCharacter;

  /// Header over the earnable house pictures tray.
  ///
  /// In en, this message translates to:
  /// **'Choose a house'**
  String get rewardsChooseHouse;

  /// Note when there's nothing left to earn in the current kind.
  ///
  /// In en, this message translates to:
  /// **'You\'ve unlocked everything here - more art lands over time.'**
  String get rewardsAllUnlocked;

  /// Header of the already-unlocked shelf.
  ///
  /// In en, this message translates to:
  /// **'Your Collection'**
  String get rewardsYourCollection;

  /// Note when nothing has been unlocked yet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet - build a streak and claim your first.'**
  String get rewardsCollectionEmpty;

  /// Snackbar when claiming something the household already unlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} is already yours.'**
  String rewardsAlreadyYours(String name);

  /// Snackbar fallback when a claim fails and the server gave no message.
  ///
  /// In en, this message translates to:
  /// **'Could not claim that reward.'**
  String get rewardsClaimFailed;

  /// Progress header when the streak has reached the threshold.
  ///
  /// In en, this message translates to:
  /// **'Claim your reward below!'**
  String get rewardsClaimYourReward;

  /// Progress header while the streak is still building.
  ///
  /// In en, this message translates to:
  /// **'Your reward streak'**
  String get rewardsYourStreak;

  /// Progress note on a day a reward was already claimed.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Start again and earn another reward.'**
  String get rewardsRedeemedToday;

  /// Progress note when a reward is claimable.
  ///
  /// In en, this message translates to:
  /// **'Pick a reward to add it to your collection.'**
  String get rewardsPickReward;

  /// Progress note while the streak builds.
  ///
  /// In en, this message translates to:
  /// **'Keep your daily streak going to earn a free character or house.'**
  String get rewardsKeepStreak;

  /// Prefix before the rewardsGetMoreHere store link, with a space between them.
  ///
  /// In en, this message translates to:
  /// **'Can\'t wait?'**
  String get rewardsCantWait;

  /// Underlined link to the pack shop, following rewardsCantWait.
  ///
  /// In en, this message translates to:
  /// **'Get more here'**
  String get rewardsGetMoreHere;

  /// Headline of the claim celebration splash.
  ///
  /// In en, this message translates to:
  /// **'Unlocked!'**
  String get rewardsUnlockedBang;

  /// Button dismissing the claim celebration.
  ///
  /// In en, this message translates to:
  /// **'View Collection'**
  String get rewardsViewCollection;

  /// Reward-streak bar title when a reward is claimable.
  ///
  /// In en, this message translates to:
  /// **'Free reward available!'**
  String get rewardsBarAvailable;

  /// Reward-streak bar title while the streak builds.
  ///
  /// In en, this message translates to:
  /// **'Free reward streak'**
  String get rewardsBarStreak;

  /// Title of the tag-writing dialog.
  ///
  /// In en, this message translates to:
  /// **'Write NFC tag'**
  String get nfcWriteTagTitle;

  /// Prompt while waiting for a tag during writing. Keep the ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Hold a tag to the top of your phone…'**
  String get nfcHoldTag;

  /// Shown when the device has no NFC or it's disabled.
  ///
  /// In en, this message translates to:
  /// **'NFC is off or unavailable on this device. Turn NFC on and try again.'**
  String get nfcUnavailable;

  /// Snackbar when a tapped tag belongs to a household the user isn't in.
  ///
  /// In en, this message translates to:
  /// **'You\'re not a member of this tag\'s household.'**
  String get nfcNotMemberHousehold;

  /// Snackbar when a tapped tag's thing can't be found.
  ///
  /// In en, this message translates to:
  /// **'That tag points to something that isn\'t in this household.'**
  String get nfcTagNotInHousehold;

  /// Snackbar when a tag is tapped while signed out / no household.
  ///
  /// In en, this message translates to:
  /// **'Sign in and pick a household to use NFC tags.'**
  String get nfcSignInFirst;

  /// Snackbar when an NFC-triggered log fails. {details} is a raw technical error, untranslated.
  ///
  /// In en, this message translates to:
  /// **'NFC log failed: {details}'**
  String nfcLogFailed(String details);

  /// Headline of the chore-complete celebration: the chore's name, then 'All done!' on a new line.
  ///
  /// In en, this message translates to:
  /// **'{name}\nAll done!'**
  String celebrationChoreDone(String name);

  /// Streak pill on the celebration for a 1-day streak. Keep the emoji.
  ///
  /// In en, this message translates to:
  /// **'🔥 Streak started!'**
  String get celebrationStreakStarted;

  /// Streak pill on the celebration. Keep the emoji.
  ///
  /// In en, this message translates to:
  /// **'🔥 {count} day streak!'**
  String celebrationStreakDays(int count);

  /// Attribution pill on the celebration when logging as someone else.
  ///
  /// In en, this message translates to:
  /// **'Logged by {name}'**
  String celebrationLoggedBy(String name);

  /// Button dismissing the chore-complete celebration.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get celebrationNice;

  /// Body of the all-chores-done-today celebration.
  ///
  /// In en, this message translates to:
  /// **'The whole house is happy. Nice work, team!'**
  String get dayCelebrationBody;

  /// Header over the avatars of everyone who completed chores today.
  ///
  /// In en, this message translates to:
  /// **'Thanks!'**
  String get dayCelebrationThanks;

  /// Button from the day celebration to the Awards tab.
  ///
  /// In en, this message translates to:
  /// **'See awards'**
  String get dayCelebrationSeeAwards;

  /// Dialog title when a signed-in user opens a claim link.
  ///
  /// In en, this message translates to:
  /// **'You\'re already signed in'**
  String get claimSignedInTitle;

  /// First paragraph of the claim-while-signed-in dialog.
  ///
  /// In en, this message translates to:
  /// **'Claim links set up a brand-new sign-in for a member someone created for you. They can\'t be added to an account you\'re already signed in to - we don\'t merge accounts.'**
  String get claimSignedInBody;

  /// Lead-in to the two bullet options.
  ///
  /// In en, this message translates to:
  /// **'If this code is for you:'**
  String get claimSignedInIfForYou;

  /// Bullet option one. Keep the leading bullet.
  ///
  /// In en, this message translates to:
  /// **'• Keep this account - stay signed in as you, and ask whoever sent the link for a household join link instead.'**
  String get claimSignedInKeepOption;

  /// Bullet option two. Keep the leading bullet.
  ///
  /// In en, this message translates to:
  /// **'• Become that member - delete this account, then the claim opens automatically. Your completed chores stay with the household.'**
  String get claimSignedInBecomeOption;

  /// Dialog button: keep the current account.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get claimKeepAccount;

  /// Dialog button: delete this account and proceed with the claim.
  ///
  /// In en, this message translates to:
  /// **'Delete account & claim'**
  String get claimDeleteAndClaim;

  /// Body of the type-to-confirm dialog when deleting the account to claim another. Keep the blank line.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and signs you out, then opens the claim sign-up. Chores you completed stay with your household, without your name on them.\n\nThis cannot be undone.'**
  String get claimDeleteBody;

  /// Personality badge title: biggest week-on-week improvement. Punchy two-or-three-word badge names - find a natural equivalent, not a literal translation.
  ///
  /// In en, this message translates to:
  /// **'Comeback Kid'**
  String get awardComebackKidTitle;

  /// How the Comeback Kid badge is won.
  ///
  /// In en, this message translates to:
  /// **'Biggest improvement on last week'**
  String get awardComebackKidDesc;

  /// Personality badge title: most chores before 9am.
  ///
  /// In en, this message translates to:
  /// **'Early Bird'**
  String get awardEarlyBirdTitle;

  /// How the Early Bird badge is won.
  ///
  /// In en, this message translates to:
  /// **'Most chores done before 9am'**
  String get awardEarlyBirdDesc;

  /// Personality badge title: most chores after 8pm.
  ///
  /// In en, this message translates to:
  /// **'Night Owl'**
  String get awardNightOwlTitle;

  /// How the Night Owl badge is won.
  ///
  /// In en, this message translates to:
  /// **'Most chores done after 8pm'**
  String get awardNightOwlDesc;

  /// Personality badge title: most chores done closest to schedule.
  ///
  /// In en, this message translates to:
  /// **'On the Dot'**
  String get awardOnTheDotTitle;

  /// How the On the Dot badge is won.
  ///
  /// In en, this message translates to:
  /// **'Most chores done within 15 minutes of schedule'**
  String get awardOnTheDotDesc;

  /// Personality badge title: most weekend chores.
  ///
  /// In en, this message translates to:
  /// **'Weekend Warrior'**
  String get awardWeekendWarriorTitle;

  /// How the Weekend Warrior badge is won.
  ///
  /// In en, this message translates to:
  /// **'Most chores done on Saturday and Sunday'**
  String get awardWeekendWarriorDesc;

  /// Personality badge title: most NFC-tap completions.
  ///
  /// In en, this message translates to:
  /// **'Tag Champion'**
  String get awardTagChampionTitle;

  /// How the Tag Champion badge is won.
  ///
  /// In en, this message translates to:
  /// **'Most chores logged with an NFC tap'**
  String get awardTagChampionDesc;

  /// The dog character's weekly award name, in its adoring voice. Keep the emoji.
  ///
  /// In en, this message translates to:
  /// **'Best Human 🩵'**
  String get characterAwardTitleDog;

  /// The cat character's weekly award name - dry, backhanded cat humour.
  ///
  /// In en, this message translates to:
  /// **'Least Disappointing Human'**
  String get characterAwardTitleCat;

  /// The plant character's weekly award name - use the locale's 'good gardener' idiom.
  ///
  /// In en, this message translates to:
  /// **'Greenest Thumb'**
  String get characterAwardTitlePlant;

  /// The wheelie bin character's weekly award name - mock-grandiose.
  ///
  /// In en, this message translates to:
  /// **'Lord of the Kerb'**
  String get characterAwardTitleBin;

  /// The fish character's weekly award name.
  ///
  /// In en, this message translates to:
  /// **'Keeper of the Tank'**
  String get characterAwardTitleFish;

  /// The fallback weekly award name for characters without their own voice.
  ///
  /// In en, this message translates to:
  /// **'Star Helper'**
  String get characterAwardTitleGeneric;

  /// The dog's thank-you line. The paws/positively pun need not survive - any warm dog pun works.
  ///
  /// In en, this message translates to:
  /// **'Thanks for being paws-itively amazing last week!'**
  String get characterAwardThanksDog;

  /// The cat's thank-you line - aloof, as if the human serves the cat.
  ///
  /// In en, this message translates to:
  /// **'Gracious enough to accept your service last week.'**
  String get characterAwardThanksCat;

  /// The plant's thank-you line.
  ///
  /// In en, this message translates to:
  /// **'Thanks for keeping things growing last week!'**
  String get characterAwardThanksPlant;

  /// The bin's thank-you line - a rolling-wheels pun if the locale has one.
  ///
  /// In en, this message translates to:
  /// **'Thanks for keeping things rolling last week!'**
  String get characterAwardThanksBin;

  /// The fish's thank-you line - a water pun if the locale has one.
  ///
  /// In en, this message translates to:
  /// **'Thanks for making a splash last week!'**
  String get characterAwardThanksFish;

  /// The fallback thank-you line.
  ///
  /// In en, this message translates to:
  /// **'Thanks for being amazing last week!'**
  String get characterAwardThanksGeneric;

  /// Server error code not_signed_in. Server errors arrive as stable codes; these keys are the localized rendering.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in.'**
  String get serverNotSignedIn;

  /// Server error code not_member.
  ///
  /// In en, this message translates to:
  /// **'You are not a member of that household.'**
  String get serverNotMember;

  /// Server error code owner_only.
  ///
  /// In en, this message translates to:
  /// **'Only the household owner can do that.'**
  String get serverOwnerOnly;

  /// Server error code name_required.
  ///
  /// In en, this message translates to:
  /// **'A name is required.'**
  String get serverNameRequired;

  /// Server error code password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get serverPasswordTooShort;

  /// Server error code claim_code_invalid.
  ///
  /// In en, this message translates to:
  /// **'That claim code isn\'t valid.'**
  String get serverClaimCodeInvalid;

  /// Server error code email_in_use.
  ///
  /// In en, this message translates to:
  /// **'That email is already in use.'**
  String get serverEmailInUse;

  /// Server error codes no_such_member / no_such_managed_member.
  ///
  /// In en, this message translates to:
  /// **'No such member.'**
  String get serverNoSuchMember;

  /// Server error code invite_code_invalid.
  ///
  /// In en, this message translates to:
  /// **'No open household with that code.'**
  String get serverInviteCodeInvalid;

  /// Server error code pack_code_invalid.
  ///
  /// In en, this message translates to:
  /// **'No pack with that code.'**
  String get serverPackCodeInvalid;

  /// Server error code pack_gone.
  ///
  /// In en, this message translates to:
  /// **'That pack is no longer available to redeem.'**
  String get serverPackGone;

  /// Server error code unknown_product.
  ///
  /// In en, this message translates to:
  /// **'Unknown product.'**
  String get serverUnknownProduct;

  /// Server error code verify_failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify that purchase.'**
  String get serverVerifyFailed;

  /// Server error code verify_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchase verification is temporarily unavailable.'**
  String get serverVerifyUnavailable;

  /// Server error code reward_unavailable.
  ///
  /// In en, this message translates to:
  /// **'That item isn\'t available to unlock.'**
  String get serverRewardUnavailable;

  /// Server error code streak_check_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check your streak just now - try again shortly.'**
  String get serverStreakCheckFailed;

  /// Server error code streak_too_low, rendered from its params.
  ///
  /// In en, this message translates to:
  /// **'You need a streak of {threshold} to unlock this - you\'re on {streak}.'**
  String serverStreakTooLow(int threshold, int streak);

  /// Android notification channel name, shown in the system notification settings.
  ///
  /// In en, this message translates to:
  /// **'Chore completions'**
  String get notifChannelName;

  /// Android notification channel description in system settings.
  ///
  /// In en, this message translates to:
  /// **'When someone in your household logs a chore.'**
  String get notifChannelDesc;

  /// Bundled character display name under its picker tile.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get characterNameDog;

  /// Bundled character display name under its picker tile.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get characterNameCat;

  /// Bundled character display name under its picker tile.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get characterNamePlant;

  /// Bundled character display name - the household rubbish bin on wheels.
  ///
  /// In en, this message translates to:
  /// **'Wheelie bin'**
  String get characterNameBin;

  /// Bundled character display name under its picker tile.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get characterNameFish;

  /// Bundled fallback character's display name - anything that isn't one of the named types.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get characterNameGeneric;
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
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
