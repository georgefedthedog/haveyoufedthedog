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
/// POST   /api/custom/managed-member            { householdId, name, avatar? }
/// PATCH  /api/custom/managed-member/{userId}    { name?, avatar? }
/// DELETE /api/custom/managed-member/{userId}

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
