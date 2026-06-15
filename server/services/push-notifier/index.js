const express = require("express");
const admin = require("firebase-admin");
const path = require("path");

const app = express();
app.use(express.json());

// Initialise Firebase Admin with the service account key.
// File is gitignored - deployed separately via the deploy script.
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT || path.join(__dirname, "firebase-service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

// Shared FCM fan-out - used by the /notify endpoint (PB hooks) and the
// overdue cron alike.
async function sendPush({ tokens, title, body, data = {} }) {
  const validTokens = (tokens || []).filter(Boolean);
  if (!validTokens.length) return { sent: 0, failed: 0 };

  const response = await admin.messaging().sendEachForMulticast({
    tokens: validTokens,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    android: {
      priority: "high",
      notification: { channelId: "chore_completions" },
    },
  });

  const failed = response.responses.map((r, i) => (r.success ? null : { token: validTokens[i], error: r.error?.message })).filter(Boolean);
  if (failed.length) {
    console.warn("Some FCM sends failed:", failed);
  }
  return { sent: response.successCount, failed: response.failureCount };
}

// POST /notify
// Body: { tokens: string[], title: string, body: string, data?: object }
app.post("/notify", async (req, res) => {
  const { tokens, title, body, data = {} } = req.body;

  if (!tokens || !tokens.length || !title || !body) {
    return res.status(400).json({ error: "tokens, title and body are required" });
  }

  try {
    const result = await sendPush({ tokens, title, body, data });
    res.json({ success: true, ...result });
  } catch (err) {
    console.error("FCM error:", err);
    res.status(500).json({ error: err.message });
  }
});

// POST /verify-purchase - called by the purchases.pb.js hook (internal only).
// Body: { platform, sku, purchaseToken }. Verifies with the store; the hook
// does the entitlement write.
const { initPlayVerifier, verifyPurchaseHandler } = require("./verify");
initPlayVerifier();
app.post("/verify-purchase", verifyPurchaseHandler);

app.get("/health", (_, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 3055;
app.listen(PORT, "127.0.0.1", () => {
  console.log(`push-notifier listening on 127.0.0.1:${PORT}`);
});

// Overdue-chore cron - needs PB superuser credentials (see .env.example).
// Without them the service still relays hook pushes; it just logs that
// the cron is off.
const { startOverdueCron } = require("./overdue-cron");
const pbUrl = process.env.PB_URL || "http://127.0.0.1:8090";
if (process.env.PB_SUPERUSER_EMAIL && process.env.PB_SUPERUSER_PASSWORD) {
  startOverdueCron({
    pbUrl,
    identity: process.env.PB_SUPERUSER_EMAIL,
    password: process.env.PB_SUPERUSER_PASSWORD,
    sendPush,
  });
} else {
  console.warn("[overdue] PB_SUPERUSER_EMAIL/_PASSWORD not set - overdue cron disabled");
}
