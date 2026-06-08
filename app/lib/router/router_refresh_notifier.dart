import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../core/household/current_household_controller.dart';
import '../core/household/household_memberships_controller.dart';

/// `ChangeNotifier` that bridges Riverpod state changes into GoRouter's
/// `refreshListenable`. Whenever auth, memberships, or the current household
/// change, we tell GoRouter to re-evaluate the redirect — without rebuilding
/// the GoRouter instance itself (which would reset history on every state
/// change).
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(
      householdMembershipsControllerProvider,
      (_, _) => notifyListeners(),
    );
    ref.listen(
      currentHouseholdControllerProvider,
      (_, _) => notifyListeners(),
    );
  }
}
