/// All route paths the app knows about. Single source of truth.
class Routes {
  Routes._();

  /// Shown while auth/membership state is being resolved. The router's
  /// redirect logic sends users away as soon as the state settles.
  static const splash = '/splash';

  /// Login + signup tabs. For unauthenticated users.
  static const auth = '/auth';

  /// Authenticated but the user has no household memberships yet.
  /// Forced landing: Create / Join only, nothing else to do.
  static const householdSetup = '/household-setup';

  /// List of the user's households. Forced when 2+ memberships and no current
  /// selection; voluntary when invoked from the home screen's "switch" button.
  static const householdPicker = '/household-picker';

  /// Standalone Create-a-new-household form, reachable from the picker.
  static const householdCreate = '/household-create';

  /// Standalone Join-by-invite-code form, reachable from the picker.
  static const householdJoin = '/household-join';

  /// View/edit a single household. Path parameter `id` is the household id.
  static const householdDetailsPattern = '/household/:id';
  static String householdDetails(String id) => '/household/$id';

  /// Authenticated with a current household resolved.
  static const home = '/';
}
