// Server-side purchase verification for the in-app store.
//
// The PB hook (purchases.pb.js) holds the auth context and does the
// entitlement write; this module does the heavy lifting it can't: calling
// the store's API with a signed service-account token. Android first; iOS
// (App Store Server API) slots in alongside verifyAndroid later.
//
// Verification is config-gated like the overdue cron - if the Play
// credentials aren't present the service still boots for FCM/cron and just
// rejects Android verification requests.

const { google } = require("googleapis");
const path = require("path");

let androidPublisher = null;
let playPackageName = null;

// Called once at startup. Safe to call without Play creds - leaves Android
// verification disabled.
function initPlayVerifier() {
  playPackageName = process.env.ANDROID_PACKAGE_NAME || "";
  const keyPath =
    process.env.PLAY_SERVICE_ACCOUNT ||
    path.join(__dirname, "play-service-account.json");

  if (!playPackageName) {
    console.warn(
      "[verify] ANDROID_PACKAGE_NAME not set - Android verification disabled"
    );
    return;
  }

  let credentials;
  try {
    credentials = require(keyPath);
  } catch (_) {
    console.warn(
      `[verify] Play service account not found at ${keyPath} - Android verification disabled`
    );
    return;
  }

  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  androidPublisher = google.androidpublisher({ version: "v3", auth });
  console.log("[verify] Android purchase verification enabled");
}

// Verifies a Google Play product purchase via purchases.products.get.
// Returns { valid, ... } - never throws for an invalid purchase.
async function verifyAndroid({ sku, purchaseToken }) {
  if (!androidPublisher) {
    return { valid: false, error: "Android verification not configured" };
  }
  if (!sku || !purchaseToken) {
    return { valid: false, error: "sku and purchaseToken are required" };
  }

  let data;
  try {
    const res = await androidPublisher.purchases.products.get({
      packageName: playPackageName,
      productId: sku,
      token: purchaseToken,
    });
    data = res.data;
  } catch (err) {
    // 400/410 from Google => the token is invalid, malformed or expired.
    const status = err.code || (err.response && err.response.status);
    console.warn(`[verify] Play lookup failed (${status}):`, err.message);
    return { valid: false, error: `Play lookup failed: ${err.message}` };
  }

  // purchaseState: 0 = purchased, 1 = canceled, 2 = pending.
  if (data.purchaseState !== 0) {
    return { valid: false, error: `purchaseState=${data.purchaseState}` };
  }

  // Acknowledge so Google doesn't auto-refund after 3 days. The client also
  // acknowledges via completePurchase, but doing it here too protects against
  // the client dying between verify and complete. acknowledgementState 1 =
  // already acknowledged. Best-effort: a failure here doesn't void a valid buy.
  if (data.acknowledgementState === 0) {
    try {
      await androidPublisher.purchases.products.acknowledge({
        packageName: playPackageName,
        productId: sku,
        token: purchaseToken,
      });
    } catch (err) {
      console.warn("[verify] acknowledge failed (continuing):", err.message);
    }
  }

  return {
    valid: true,
    platform: "android",
    sku,
    // Non-consumable products have no separate "original" txn; orderId is the
    // stable unique id we key the purchases ledger on.
    transactionId: data.orderId,
    originalTransactionId: data.orderId,
    raw: data,
  };
}

// Express handler. Body: { platform, sku, purchaseToken }.
// 200 = verified, 422 = a well-formed request that failed verification,
// 400 = bad request, 500 = unexpected error.
async function verifyPurchaseHandler(req, res) {
  const { platform, sku, purchaseToken } = req.body || {};

  try {
    let result;
    if (platform === "android") {
      result = await verifyAndroid({ sku, purchaseToken });
    } else {
      return res
        .status(400)
        .json({ valid: false, error: `Unsupported platform: ${platform}` });
    }

    if (!result.valid) return res.status(422).json(result);
    res.json(result);
  } catch (err) {
    console.error("[verify] error:", err);
    res.status(500).json({ valid: false, error: err.message });
  }
}

module.exports = { initPlayVerifier, verifyPurchaseHandler, verifyAndroid };
