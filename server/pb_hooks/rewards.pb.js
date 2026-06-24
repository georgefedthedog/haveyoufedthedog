/// Free streak-unlock claim endpoint.
///
/// POST /api/custom/claim-streak-reward
///   { "householdId": "abc123", "kind": "character", "slug": "schnauzer" }
///
/// Grants a single catalog character or picture to a household for free once
/// it has built a long enough reward streak. The streak itself is recomputed
/// authoritatively by the Node worker (timezone-aware, which Goja can't do);
/// this hook holds the auth context and does the entitlement write, the same
/// split as verify-purchase.
///
/// Flow: confirm the caller is a member, resolve the slug to a *resolvable*
/// catalog row (so vaulted/disabled art can't be earned), ask the worker for
/// the household's current reward streak, require it to clear the household's
/// `reward_streak_threshold` (default 28), then append the slug to the
/// household's `unlocked_characters` / `unlocked_pictures` and stamp
/// `last_free_redemption` = now. That anchor re-zeros the streak counter, so
/// each free unlock costs a fresh run of due-days.
///
/// Idempotent: re-claiming an already-unlocked slug returns
/// `{ alreadyUnlocked: true }` without re-checking the streak or moving the
/// anchor. Any member of the household may claim (entitlement is
/// household-scoped, like redeem-pack-code).
routerAdd("POST", "/api/custom/claim-streak-reward", e => {
  const auth = e.auth;
  if (!auth) {
    return e.json(401, { message: "You must be signed in to claim a reward." });
  }

  const info = e.requestInfo();
  const body = (info && info.body) || {};
  const householdId = String(body.householdId || "").trim();
  const kind = String(body.kind || "").trim().toLowerCase();
  const slug = String(body.slug || "").trim();

  if (!householdId) return e.json(400, { message: "householdId is required." });
  if (kind !== "character" && kind !== "picture") {
    return e.json(400, { message: "kind must be 'character' or 'picture'." });
  }
  if (!slug) return e.json(400, { message: "slug is required." });

  const collection = kind === "character" ? "catalog_characters" : "catalog_pictures";
  const field = kind === "character" ? "unlocked_characters" : "unlocked_pictures";

  // Caller must be a member of the target household.
  let membership;
  try {
    membership = $app.findFirstRecordByFilter("household_members", "user = {:user} && household = {:hh}", { user: auth.id, hh: householdId });
  } catch (_) {
    return e.json(403, { message: "You are not a member of that household." });
  }
  if (!membership) {
    return e.json(403, { message: "You are not a member of that household." });
  }

  // Resolve the slug to a row that is actually resolvable - in no pack
  // (general catalog) or an enabled pack. This is the same visibility filter
  // the app's catalog fetch uses, so a streak can't unlock vaulted art.
  let row;
  try {
    row = $app.findFirstRecordByFilter(
      collection,
      "slug = {:slug} && (packs:length = 0 || packs.enabled ?= true)",
      { slug: slug },
    );
  } catch (_) {
    return e.json(404, { message: "That item isn't available to unlock." });
  }
  if (!row) {
    return e.json(404, { message: "That item isn't available to unlock." });
  }

  const household = $app.findRecordById("households", householdId);

  // Already unlocked? Idempotent no-op. Rebuild the relation as a plain array -
  // Goja-wrapped Go slices lack the full JS Array API (same as verify-purchase).
  const current = household.getStringSlice(field);
  const next = [];
  let already = false;
  for (let i = 0; i < current.length; i++) {
    if (current[i] === slug) already = true;
    next.push(current[i]);
  }
  if (already) {
    return e.json(200, { kind: kind, slug: slug, alreadyUnlocked: true });
  }

  // Authoritative streak from the Node worker (timezone-aware recompute).
  let streak;
  try {
    const resp = $http.send({
      method: "POST",
      url: "http://127.0.0.1:3055/reward-streak",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ householdId: householdId }),
      timeout: 20,
    });
    const data = JSON.parse(resp.raw || "{}");
    if (resp.statusCode !== 200 || typeof data.streak !== "number") {
      console.warn("[claim-streak-reward] worker streak failed", resp.statusCode, resp.raw);
      return e.json(503, { message: "Couldn't check your streak just now - try again shortly." });
    }
    streak = data.streak;
  } catch (err) {
    console.error("[claim-streak-reward] worker unreachable:", err);
    return e.json(503, { message: "Couldn't check your streak just now - try again shortly." });
  }

  // Threshold is admin-set per household; empty/0 means the default of 28
  // (mirrors Household.rewardStreakThreshold in the app).
  let threshold = 28;
  const t = household.getFloat("reward_streak_threshold");
  if (t && t > 0) threshold = Math.round(t);

  if (streak < threshold) {
    return e.json(403, {
      message: `You need a streak of ${threshold} to unlock this - you're on ${streak}.`,
      streak: streak,
      threshold: threshold,
    });
  }

  // Grant: append the slug and re-anchor so the counter starts over. The
  // anchor is stored in PB's datetime layout (UTC), matching how the worker
  // buckets it back to a local date.
  next.push(slug);
  household.set(field, next);
  household.set("last_free_redemption", new Date().toISOString().replace("T", " "));
  $app.save(household);

  return e.json(200, { kind: kind, slug: slug, streak: streak, threshold: threshold });
});
