/// Keeps households sane after a membership disappears (a member leaving
/// in-app, or memberships cascade-deleted when a user account is deleted):
///
///   - last member gone  -> delete the household; cascades wipe
///                          subjects -> chores -> completions.
///   - owner gone, other members remain -> promote the longest-standing
///                          member to owner, so the household is never
///                          left unmanageable (owners can't leave in-app,
///                          so account deletion is the only path here).

onRecordAfterDeleteSuccess(e => {
  if (!e.record) return;
  const householdId = e.record.get("household");
  if (!householdId) return;

  // If the household itself was just deleted, its memberships cascade
  // through this hook - the lookup throws and there's nothing to do.
  try {
    $app.findRecordById("households", householdId);
  } catch (_) {
    return;
  }

  const remaining = $app.findRecordsByFilter(
    "household_members",
    "household = {:id}",
    "created", // oldest first - first entry is the longest-standing member
    200,
    0,
    { id: householdId },
  );

  if (remaining.length === 0) {
    $app.delete($app.findRecordById("households", householdId));
    return;
  }

  const hasOwner = remaining.some(m => m.get("role") === "owner");
  if (!hasOwner) {
    const successor = remaining[0];
    successor.set("role", "owner");
    $app.save(successor);
  }
}, "household_members");
