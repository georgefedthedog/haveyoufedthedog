/// Managed ("phone-less") household member endpoints.
///
/// A managed member is a real-but-loginless `users` record: a synthetic
/// `{id}@haveyoufedthedogyet.com` email, a random password nobody knows, and
/// `managed = true`. It exists so a person without a phone can earn credit,
/// awards and leaderboard standing - everything keys off `completed_by` (a user
/// id), so a managed user flows through the whole pipeline with no extra
/// plumbing. Someone with a phone logs chores for them via "Act as".
///
/// These run with elevated server privileges because:
///   - an owner can't create a `household_members` row for a user other than
///     themselves (`household_members.createRule` is `user = @request.auth.id`);
///   - an owner can't edit a managed user's name/avatar
///     (`users.updateRule` is `id = @request.auth.id`, and nobody can log in as
///     a managed user).
///
/// A managed member can later be **claimed** - converted into a real login on
/// the same user id, so all their history/awards carry over. The owner sets a
/// one-time claim code; the person enters it on Sign Up with their own email +
/// password (see claim-account below).
///
/// POST   /api/custom/managed-member                       { householdId, name, avatar? }
/// PATCH  /api/custom/managed-member/{userId}              { name?, avatar? }
/// DELETE /api/custom/managed-member/{userId}
/// POST   /api/custom/managed-member/{userId}/claim-code   { code }   (owner) open / close
///        (empty code closes; the current code is read off the members view)
/// POST   /api/custom/claim-account   { code, email, password, name? }   (public -
///        the claimer isn't signed in yet, so the one-time code is the credential)

// --- create -----------------------------------------------------------------
routerAdd("POST", "/api/custom/managed-member", e => {
  const auth = e.auth;
  if (!auth) {
    return e.json(401, { message: "You must be signed in." });
  }

  const info = e.requestInfo();
  const body = (info && info.body) || {};
  const householdId = String(body.householdId || "").trim();
  const name = String(body.name || "").trim();
  const avatar = String(body.avatar || "").trim();

  if (!householdId) return e.json(400, { message: "householdId is required." });
  if (!name) return e.json(400, { message: "A name is required." });

  // Caller must be the OWNER of the target household.
  let ownerMembership;
  try {
    ownerMembership = $app.findFirstRecordByFilter(
      "household_members",
      "user = {:user} && household = {:hh} && role = 'owner'",
      { user: auth.id, hh: householdId },
    );
  } catch (_) {
    return e.json(403, { message: "Only the household owner can add members." });
  }
  if (!ownerMembership) {
    return e.json(403, { message: "Only the household owner can add members." });
  }

  // Mint the loginless user. Email must be unique + present on first save, so
  // start with a random local part, then rewrite it to the canonical
  // `{id}@...` once PocketBase has assigned the id.
  const users = $app.findCollectionByNameOrId("users");
  const user = new Record(users);
  user.set("email", $security.randomString(20).toLowerCase() + "@haveyoufedthedogyet.com");
  user.set("emailVisibility", false);
  user.set("verified", true);
  user.set("managed", true);
  user.set("name", name);
  if (avatar) user.set("avatar", avatar);
  user.setPassword($security.randomString(40));
  $app.save(user);

  // Canonicalise the email to {id}@... (cosmetic; best-effort).
  try {
    user.set("email", user.id + "@haveyoufedthedogyet.com");
    $app.save(user);
  } catch (err) {
    console.warn("[managed-member] email canonicalise failed:", err);
  }

  // Join them to the household.
  const members = $app.findCollectionByNameOrId("household_members");
  const member = new Record(members);
  member.set("household", householdId);
  member.set("user", user.id);
  member.set("role", "member");
  $app.save(member);

  return e.json(200, {
    userId: user.id,
    membershipId: member.id,
    name: name,
    avatar: avatar,
  });
});

// --- edit name / avatar ------------------------------------------------------
routerAdd("PATCH", "/api/custom/managed-member/{userId}", e => {
  const { ownedManagedTarget } = require(`${__hooks}/_members_helper.js`);
  const target = ownedManagedTarget(e);
  if (!target) return; // guard already wrote the response

  const info = e.requestInfo();
  const body = (info && info.body) || {};

  if (body.name !== undefined) {
    const name = String(body.name || "").trim();
    if (!name) return e.json(400, { message: "A name is required." });
    target.set("name", name);
  }
  if (body.avatar !== undefined) {
    target.set("avatar", String(body.avatar || "").trim());
  }
  $app.save(target);

  return e.json(200, {
    userId: target.id,
    name: target.getString("name"),
    avatar: target.getString("avatar"),
  });
});

// --- delete ------------------------------------------------------------------
// Deleting the user cascades the household_members row. Completions retain a
// dangling `completed_by` (relation is cascadeDelete:false) and render as
// "Someone" - we deliberately keep their contribution in history/streaks.
routerAdd("DELETE", "/api/custom/managed-member/{userId}", e => {
  const { ownedManagedTarget } = require(`${__hooks}/_members_helper.js`);
  const target = ownedManagedTarget(e);
  if (!target) return; // guard already wrote the response

  $app.delete(target);
  return e.json(200, { userId: target.id, deleted: true });
});

// --- open / close claiming (owner) -------------------------------------------
// Sets the claim code on a managed member: the app sends a fresh code (same
// XXXX-YYYY format as a household invite) to open claiming, or "" to close it
// (the old code then stops working). One write, mirroring setInvitesOpen; the
// current code is read off the household_member_details view, not here.
routerAdd("POST", "/api/custom/managed-member/{userId}/claim-code", e => {
  const { ownedManagedTarget } = require(`${__hooks}/_members_helper.js`);
  const target = ownedManagedTarget(e);
  if (!target) return; // guard already wrote the response

  const info = e.requestInfo();
  const body = (info && info.body) || {};
  const code = String(body.code || "").trim().toUpperCase();

  target.set("claim_code", code);
  $app.save(target);

  return e.json(200, { userId: target.id, code: code });
});

// --- claim account -----------------------------------------------------------
// PUBLIC (the claimer isn't signed in yet - the one-time code is the credential).
// Converts the managed user the code belongs to into a real login: sets the
// chosen email + password, clears `managed` and the code. The user id is
// unchanged, so the member's history / awards / household membership carry over
// with no migration. A failed save (almost always the unique-email index)
// leaves the account untouched and still claimable.
routerAdd("POST", "/api/custom/claim-account", e => {
  const info = e.requestInfo();
  const body = (info && info.body) || {};
  const code = String(body.code || "").trim().toUpperCase();
  const email = String(body.email || "").trim();
  const password = String(body.password || "");
  const name = String(body.name || "").trim();

  if (!code) return e.json(400, { message: "A claim code is required." });
  if (!email) return e.json(400, { message: "An email is required." });
  if (password.length < 8) {
    return e.json(400, { message: "Password must be at least 8 characters." });
  }

  // Resolve the managed account the code belongs to. A non-empty code never
  // matches a regular user (managed = false, blank claim_code).
  let user;
  try {
    user = $app.findFirstRecordByFilter(
      "users",
      "claim_code = {:code} && managed = true",
      { code: code },
    );
  } catch (_) {
    return e.json(404, { message: "That claim code isn't valid." });
  }
  if (!user) return e.json(404, { message: "That claim code isn't valid." });

  user.set("email", email);
  user.set("emailVisibility", false);
  user.set("verified", true);
  user.set("managed", false);
  user.set("claim_code", "");
  if (name) user.set("name", name);
  user.setPassword(password);
  try {
    $app.save(user);
  } catch (err) {
    console.warn("[claim-account] save failed:", err);
    return e.json(409, { message: "That email is already in use." });
  }

  return e.json(200, { userId: user.id });
});
