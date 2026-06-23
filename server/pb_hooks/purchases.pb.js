/// Custom in-app-purchase verification + entitlement endpoint.
///
/// POST /api/custom/verify-purchase
///   { "platform": "android", "sku": "pack_farmyard",
///     "purchaseToken": "...", "householdId": "abc123" }
///
/// Confirms the caller is a member of the household, resolves the SKU to an
/// enabled `catalog_products` row, asks the internal Node verifier
/// (the worker service on :3055) to validate the receipt with the store, records
/// the transaction in `purchases`, then appends the product's granted packs to
/// the household's `packs` relation - the same household-scoped entitlement
/// that redeem-pack-code writes.
///
/// Idempotent on the store transaction id (unique index on
/// purchases.store_transaction_id): re-verifying the same purchase - e.g. a
/// Restore, or a retried request - returns `{ alreadyApplied: true }` with the
/// same packIds and never double-writes.
///
/// Known v1 limitation: entitlement is bound to the household the purchase was
/// made in. Restoring the same transaction from a *different* household returns
/// alreadyApplied but does not re-grant to the new household (ownership is
/// household-scoped by design). Revisit if we move to buyer-travels ownership.
routerAdd("POST", "/api/custom/verify-purchase", e => {
  const auth = e.auth;
  if (!auth) {
    return e.json(401, { message: "You must be signed in to make a purchase." });
  }

  const info = e.requestInfo();
  const body = (info && info.body) || {};
  const platform = String(body.platform || "").trim().toLowerCase();
  const sku = String(body.sku || "").trim();
  const purchaseToken = String(body.purchaseToken || "").trim();
  const householdId = String(body.householdId || "").trim();

  if (platform !== "android" && platform !== "ios") {
    return e.json(400, { message: "platform must be 'android' or 'ios'." });
  }
  if (!sku) return e.json(400, { message: "sku is required." });
  if (!purchaseToken) return e.json(400, { message: "purchaseToken is required." });
  if (!householdId) return e.json(400, { message: "householdId is required." });

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

  // Resolve the SKU to an enabled product before spending a store API call.
  let product;
  try {
    product = $app.findFirstRecordByFilter("catalog_products", "sku = {:sku} && enabled = true", { sku: sku });
  } catch (_) {
    return e.json(404, { message: "Unknown product." });
  }
  if (!product) {
    return e.json(404, { message: "Unknown product." });
  }

  // Verify the receipt with the store via the internal Node service. A
  // generous timeout: the Google Play API can be slow on a cold token.
  let verified;
  try {
    const resp = $http.send({
      method: "POST",
      url: "http://127.0.0.1:3055/verify-purchase",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ platform, sku, purchaseToken }),
      timeout: 20,
    });
    verified = JSON.parse(resp.raw || "{}");
    if (resp.statusCode !== 200 || !verified.valid) {
      console.warn("[verify-purchase] verification failed", resp.statusCode, resp.raw);
      return e.json(402, { message: "We couldn't verify that purchase." });
    }
  } catch (err) {
    console.error("[verify-purchase] verifier unreachable:", err);
    return e.json(503, { message: "Purchase verification is temporarily unavailable." });
  }

  const txnId = String(verified.transactionId || "").trim();
  if (!txnId) {
    console.error("[verify-purchase] verifier returned no transactionId");
    return e.json(502, { message: "We couldn't verify that purchase." });
  }

  // Packs this product grants. Goja-wrapped Go slices lack the full JS Array
  // API, so rebuild as a plain array (same pattern as redeem-pack-code).
  const grants = product.getStringSlice("grants");
  const packIds = [];
  for (let i = 0; i < grants.length; i++) packIds.push(grants[i]);

  const result = {
    productId: product.id,
    name: product.getString("name"),
    packIds: packIds,
  };

  // Idempotency: a Restore (or retried request) re-verifies the same
  // transaction. If it's already recorded, return the same grants untouched.
  let existing = null;
  try {
    existing = $app.findFirstRecordByFilter("purchases", "store_transaction_id = {:t}", { t: txnId });
  } catch (_) {}
  if (existing) {
    result.alreadyApplied = true;
    return e.json(200, result);
  }

  // Record the verified transaction. The unique index on store_transaction_id
  // is the real guard against double-grant under a race; a violation here means
  // a concurrent request beat us to it, so treat it as alreadyApplied.
  const purchasesCol = $app.findCollectionByNameOrId("purchases");
  const purchase = new Record(purchasesCol);
  purchase.set("user", auth.id);
  purchase.set("household", householdId);
  purchase.set("product", product.id);
  purchase.set("platform", verified.platform || platform);
  purchase.set("store_transaction_id", txnId);
  if (verified.originalTransactionId) {
    purchase.set("original_transaction_id", String(verified.originalTransactionId));
  }
  if (verified.raw) purchase.set("raw", verified.raw);
  try {
    $app.save(purchase);
  } catch (err) {
    console.warn("[verify-purchase] purchase save failed (treating as duplicate):", err);
    result.alreadyApplied = true;
    return e.json(200, result);
  }

  // Append the granted packs to the household, deduped - same shape as
  // redeem-pack-code so the app patches its cache identically.
  const household = $app.findRecordById("households", householdId);
  const current = household.getStringSlice("packs");
  const next = [];
  const seen = {};
  for (let i = 0; i < current.length; i++) {
    next.push(current[i]);
    seen[current[i]] = true;
  }
  for (let i = 0; i < packIds.length; i++) {
    if (!seen[packIds[i]]) {
      next.push(packIds[i]);
      seen[packIds[i]] = true;
    }
  }
  household.set("packs", next);
  $app.save(household);

  return e.json(200, result);
});
