// Server-side purchase verification for the in-app store.
//
// The PB hook (purchases.pb.js) holds the auth context and does the
// entitlement write; this module does the heavy lifting it can't: validating
// the receipt with the store. Android goes through the Play Developer API;
// iOS through Apple's verifyReceipt endpoint (see verifyIos).
//
// Verification is config-gated like the overdue cron - if the Play
// credentials aren't present the service still boots for FCM/cron and just
// rejects Android verification requests.

const { google } = require("googleapis");
const path = require("path");

let androidPublisher = null;
let playPackageName = null;

// iOS App Store receipt verification is stateless - no credentials to load
// (unlike Android's service account), so there's no init step. We POST the
// base64 app receipt the client sends to Apple's verifyReceipt endpoint.
// NOTE: verifyReceipt is deprecated by Apple but still operational. Moving to
// StoreKit 2 + JWS / the App Store Server API would retire it - and would also
// need the client switched to StoreKit 2 (it currently sends a StoreKit 1
// receipt). See README -> "Selling packs".
const APPLE_VERIFY_PROD = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_VERIFY_SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt";
const IOS_BUNDLE_ID = process.env.IOS_BUNDLE_ID || "com.haveyoufedthedog.app";

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

// POSTs a base64 app receipt to Apple's verifyReceipt and returns the parsed
// JSON. Apple mandates trying production first; a 21007 status means the
// receipt is from the sandbox (TestFlight / a sandbox tester), so we retry the
// sandbox endpoint - this is what lets one build work in both environments.
async function appleVerifyReceipt(receiptData) {
  // No "password" field: that's only for auto-renewable subscriptions; our
  // packs are non-consumables, so it isn't needed.
  const body = JSON.stringify({ "receipt-data": receiptData });
  async function post(url) {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
    });
    return res.json();
  }

  let data = await post(APPLE_VERIFY_PROD);
  if (data.status === 21007) data = await post(APPLE_VERIFY_SANDBOX);
  return data;
}

// Verifies an iOS App Store purchase from the base64 app receipt the client
// sends as `purchaseToken`. Returns { valid, ... } - never throws for a bad
// receipt.
async function verifyIos({ sku, purchaseToken }) {
  if (!sku || !purchaseToken) {
    return { valid: false, error: "sku and purchaseToken are required" };
  }

  let data;
  try {
    data = await appleVerifyReceipt(purchaseToken);
  } catch (err) {
    console.warn("[verify] Apple verifyReceipt request failed:", err.message);
    return { valid: false, error: `verifyReceipt request failed: ${err.message}` };
  }

  // status 0 = valid receipt. Anything else => forged / malformed / expired.
  if (data.status !== 0) {
    return { valid: false, error: `verifyReceipt status=${data.status}` };
  }

  const receipt = data.receipt || {};
  if (receipt.bundle_id && receipt.bundle_id !== IOS_BUNDLE_ID) {
    return { valid: false, error: `bundle_id mismatch: ${receipt.bundle_id}` };
  }

  // The app receipt lists every transaction; pick the one for this product.
  // Non-consumables live in `in_app` (latest_receipt_info is for subs).
  const inApp = Array.isArray(receipt.in_app) ? receipt.in_app : [];
  const matches = inApp.filter(t => t.product_id === sku);
  if (matches.length === 0) {
    return { valid: false, error: `no transaction for product ${sku}` };
  }
  const txn = matches[matches.length - 1];

  // original_transaction_id is stable across restores of a non-consumable, so
  // it's the right idempotency key for the purchases ledger (mirrors how
  // Android keys on orderId).
  const txnId = txn.original_transaction_id || txn.transaction_id;
  return {
    valid: true,
    platform: "ios",
    sku,
    transactionId: txnId,
    originalTransactionId: txnId,
    // Keep the ledger's raw small: the full verifyReceipt response re-embeds
    // the entire receipt. Store just what's useful for debugging.
    raw: { status: data.status, environment: data.environment, transaction: txn },
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
    } else if (platform === "ios") {
      result = await verifyIos({ sku, purchaseToken });
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

module.exports = { initPlayVerifier, verifyPurchaseHandler, verifyAndroid, verifyIos };
