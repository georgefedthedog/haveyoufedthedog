// Helper for the managed-member edit/delete handlers in members.pb.js. Lives in
// a non-`.pb.js` file so PocketBase doesn't auto-load it as a hook.
//
// PB runs each hook handler in its own Goja runtime, so top-level declarations
// in members.pb.js aren't in scope when handlers fire - we share via require().

// Resolves and authorises the {userId} path param for edit/delete: the caller
// must OWN a household the target is in, and the target must be a managed
// member. Returns the target `users` record, or writes an error response on
// `e` and returns null.
function ownedManagedTarget(e) {
  const auth = e.auth;
  if (!auth) {
    e.json(401, { message: "You must be signed in." });
    return null;
  }

  const userId = String(e.request.pathValue("userId") || "").trim();
  if (!userId) {
    e.json(400, { message: "Member id is required." });
    return null;
  }

  let target;
  try {
    target = $app.findRecordById("users", userId);
  } catch (_) {
    e.json(404, { message: "No such member." });
    return null;
  }
  if (!target || !target.getBool("managed")) {
    e.json(404, { message: "No such managed member." });
    return null;
  }

  // The target must be in some household the caller OWNS.
  const memberships = $app.findRecordsByFilter(
    "household_members", "user = {:u}", "", 0, 0, { u: userId },
  );
  for (let i = 0; i < memberships.length; i++) {
    const hh = memberships[i].get("household");
    let owner = null;
    try {
      owner = $app.findFirstRecordByFilter(
        "household_members",
        "user = {:c} && household = {:hh} && role = 'owner'",
        { c: auth.id, hh: hh },
      );
    } catch (_) { /* not owner of this one */ }
    if (owner) return target;
  }

  e.json(403, { message: "Only the household owner can manage this member." });
  return null;
}

module.exports = { ownedManagedTarget };
