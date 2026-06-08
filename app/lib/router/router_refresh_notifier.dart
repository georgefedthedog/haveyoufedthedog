import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing_phase.dart';

/// `ChangeNotifier` that bridges Riverpod state changes into GoRouter's
/// `refreshListenable`.
///
/// Listens **only** to [routingPhaseProvider] — a derived value whose
/// equality is by enum identity. Deep household / chore / completion
/// state can churn freely without bouncing the user off the page they're
/// on, because none of that affects which phase the router is in.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(routingPhaseProvider, (_, _) => notifyListeners());
  }
}
