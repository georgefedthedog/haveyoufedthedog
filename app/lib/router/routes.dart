/// All route paths the app knows about. Single source of truth.
class Routes {
  Routes._();

  /// Shown while auth/membership state is being resolved. The router's
  /// redirect logic sends users away as soon as the state settles.
  static const splash = '/splash';

  /// Login + signup tabs. For unauthenticated users.
  static const auth = '/auth';

  /// List of the user's households. Forced landing when no current
  /// household is selected (zero memberships or 2+ with none persisted);
  /// voluntary when reached from the home screen's "Switch household" menu.
  static const householdPicker = '/household-picker';

  /// Standalone Create-a-new-household form, reachable from the picker.
  static const householdCreate = '/household-create';

  /// Standalone Join-by-invite-code form, reachable from the picker.
  static const householdJoin = '/household-join';

  /// View/edit a single household. Path parameter `id` is the household id.
  static const householdDetailsPattern = '/household/:id';
  static String householdDetails(String id) => '/household/$id';

  /// Invite-management screen — the hero / code / share UI.
  static const householdInvitePattern = '/household/:id/invite';
  static String householdInvite(String id) => '/household/$id/invite';

  /// Authenticated with a current household resolved. Inside the
  /// bottom-nav shell.
  static const home = '/';

  /// Bottom-nav tab paths (inside the shell). All four are siblings of
  /// [home] under the same `StatefulShellRoute`.
  static const subjectsTab = '/subjects';
  static const historyTab = '/history';
  static const youTab = '/you';

  /// Edit profile — full-screen edit pushed from outside the shell.
  static const profile = '/profile';

  /// Full-screen celebration overlay (confetti + character) shown after a
  /// completion is logged. Push with a `CelebrationArgs` instance in `extra`.
  static const celebration = '/celebration';

  /// Create a new subject in the current household.
  static const subjectNew = '/subject/new';

  /// View one subject — detail + history. Path parameter `id` is the
  /// subject id.
  static const subjectDetailPattern = '/subject/:id';
  static String subjectDetail(String id) => '/subject/$id';

  /// Edit an existing subject. Path parameter `id` is the subject id.
  static const subjectEditPattern = '/subject/:id/edit';
  static String subjectEdit(String id) => '/subject/$id/edit';

  /// Create a new chore against [subjectId].
  static const choreNewPattern = '/subject/:subjectId/chore/new';
  static String choreNew(String subjectId) => '/subject/$subjectId/chore/new';

  /// Edit an existing chore. Path parameter `id` is the chore id.
  static const choreEditPattern = '/chore/:id/edit';
  static String choreEdit(String id) => '/chore/$id/edit';
}
