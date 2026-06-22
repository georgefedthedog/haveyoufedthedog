/// Custom pack-code redemption endpoint.
///
/// POST /api/custom/redeem-pack-code  { "code": "WOOF-2026", "householdId": "abc123" }
///
/// Looks up an enabled `catalog_packs` row by code and appends it to the
/// household's `packs` relation. Any member of the household can redeem.
/// Idempotent - re-applying an already-applied pack returns
/// `{ alreadyApplied: true }`. Returns the pack name either way so the app
/// can show it in the snackbar.
///
/// Runs with elevated server privileges: `catalog_packs.code` is a hidden
/// field that clients can neither read nor filter on, so the code can only
/// be resolved here.
routerAdd("POST", "/api/custom/redeem-pack-code", e => {
  const auth = e.auth;
  if (!auth) {
    return e.json(401, { message: "You must be signed in to redeem a pack code." });
  }

  const info = e.requestInfo();
  const body = (info && info.body) || {};
  const code = String(body.code || "").trim().toUpperCase();
  const householdId = String(body.householdId || "").trim();
  if (!code) {
    return e.json(400, { message: "Pack code is required." });
  }
  if (!householdId) {
    return e.json(400, { message: "householdId is required." });
  }

  // Resolve the code against enabled packs.
  let pack;
  try {
    pack = $app.findFirstRecordByFilter("catalog_packs", "code = {:code} && enabled = true", { code: code });
  } catch (_) {
    return e.json(404, { message: "No pack with that code." });
  }
  if (!pack) {
    return e.json(404, { message: "No pack with that code." });
  }

  // Enabled but no longer redeemable = "limited edition" closed to new
  // households; existing ones keep serving its items. Distinct message so
  // latecomers know the code was real.
  if (!pack.getBool("redeemable")) {
    return e.json(410, { message: "That pack is no longer available to redeem." });
  }

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

  // Packs this code grants: the matched pack PLUS any packs it grants (a
  // "bundle" pack = pack-of-packs). One level only - a bundle's grants must be
  // leaf packs, not other bundles. Self-reference is skipped defensively.
  const grantIds = [pack.id];
  const grants = pack.getStringSlice("grants");
  for (let i = 0; i < grants.length; i++) {
    if (grants[i] && grants[i] !== pack.id && grantIds.indexOf(grants[i]) === -1) {
      grantIds.push(grants[i]);
    }
  }

  const household = $app.findRecordById("households", householdId);

  // Defensive copy of the relation - Goja-wrapped Go slices don't carry
  // the full JS Array API, so rebuild as a plain array.
  const current = household.getStringSlice("packs");
  const next = [];
  const seen = {};
  for (let i = 0; i < current.length; i++) {
    next.push(current[i]);
    seen[current[i]] = true;
  }

  // Idempotency keys off the matched (code's) pack, preserving the original
  // single-pack behaviour. packId stays for already-released clients; packIds
  // is the full expanded set for clients that understand bundles.
  if (seen[pack.id]) {
    return e.json(200, {
      packId: pack.id,
      packIds: grantIds,
      name: pack.getString("name"),
      alreadyApplied: true,
    });
  }

  for (let i = 0; i < grantIds.length; i++) {
    if (!seen[grantIds[i]]) {
      next.push(grantIds[i]);
      seen[grantIds[i]] = true;
    }
  }
  household.set("packs", next);
  $app.save(household);

  return e.json(200, {
    packId: pack.id,
    packIds: grantIds,
    name: pack.getString("name"),
  });
});
