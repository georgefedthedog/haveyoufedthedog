/// All route paths the app knows about. Single source of truth.
class Routes {
  Routes._();

  /// Shown while auth/membership state is being resolved. The router's
  /// redirect logic sends users away as soon as the state settles.
  static const splash = '/splash';

  /// Login + signup tabs. For unauthenticated users.
  static const auth = '/auth';

  /// Authenticated but the user has no household memberships yet.
  /// Offers Create / Join.
  static const householdSetup = '/household-setup';

  /// Authenticated, 2+ memberships, no current household selected.
  /// Lists households for the user to pick.
  static const householdPicker = '/household-picker';

  /// Authenticated with a current household resolved.
  static const home = '/';
}
