/// Custom join-by-code endpoint.
///
/// POST /api/custom/join-household-by-code  { "code": "XXXX-YYYY" }
///
/// Looks up a household where `invite_code` matches AND `invites_open = true`.
/// On success, creates a `household_members` row joining the caller and
/// returns the household id. Idempotent - calling again for the same caller
/// returns `{ alreadyMember: true }`.
///
/// Runs with elevated server privileges so non-members can resolve the code
/// without us having to weaken the `households` collection's read rules.
routerAdd("POST", "/api/custom/join-household-by-code", e => {
  const auth = e.auth;
  if (!auth) {
    return e.json(401, { message: "You must be signed in to join." });
  }

  const info = e.requestInfo();
  const code = String((info && info.body && info.body.code) || "")
    .trim()
    .toUpperCase();
  if (!code) {
    return e.json(400, { message: "Invite code is required." });
  }

  // Find an open household with this code.
  let household;
  try {
    household = $app.findFirstRecordByFilter("households", "invite_code = {:code} && invites_open = true", { code: code });
  } catch (_) {
    return e.json(404, { message: "No open household with that code." });
  }
  if (!household) {
    return e.json(404, { message: "No open household with that code." });
  }

  // Already a member? Idempotent return.
  try {
    const existing = $app.findFirstRecordByFilter("household_members", "user = {:user} && household = {:hh}", { user: auth.id, hh: household.id });
    if (existing) {
      return e.json(200, {
        householdId: household.id,
        alreadyMember: true,
      });
    }
  } catch (_) {
    // not a member yet - fall through
  }

  // Create the membership.
  const members = $app.findCollectionByNameOrId("household_members");
  const member = new Record(members);
  member.set("household", household.id);
  member.set("user", auth.id);
  member.set("role", "member");
  $app.save(member);

  return e.json(200, { householdId: household.id });
});
