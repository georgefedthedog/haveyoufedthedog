// Firebase Cloud Messaging relay - the service's original job. Owns Firebase
// Admin initialisation and the push fan-out shared by the /notify route (which
// PB hooks call) and the overdue cron.

const admin = require("firebase-admin");
const path = require("path");

// Initialise Firebase Admin with the service account key. The file is
// gitignored and deployed separately via the deploy script.
function initFirebase() {
  const serviceAccountPath =
    process.env.FIREBASE_SERVICE_ACCOUNT ||
    path.join(__dirname, "firebase-service-account.json");
  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
  });
}

// Shared FCM fan-out - used by the /notify route and the overdue cron alike.
async function sendPush({ tokens, title, body, data = {} }) {
  const validTokens = (tokens || []).filter(Boolean);
  if (!validTokens.length) return { sent: 0, failed: 0 };

  const response = await admin.messaging().sendEachForMulticast({
    tokens: validTokens,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: {
      priority: "high",
      notification: { channelId: "chore_completions" },
    },
  });

  const failed = response.responses
    .map((r, i) =>
      r.success ? null : { token: validTokens[i], error: r.error?.message }
    )
    .filter(Boolean);
  if (failed.length) {
    console.warn("Some FCM sends failed:", failed);
  }
  return { sent: response.successCount, failed: response.failureCount };
}

// Express handler. POST /notify - Body: { tokens, title, body, data? }.
async function notifyHandler(req, res) {
  const { tokens, title, body, data = {} } = req.body;

  if (!tokens || !tokens.length || !title || !body) {
    return res
      .status(400)
      .json({ error: "tokens, title and body are required" });
  }

  try {
    const result = await sendPush({ tokens, title, body, data });
    res.json({ success: true, ...result });
  } catch (err) {
    console.error("FCM error:", err);
    res.status(500).json({ error: err.message });
  }
}

module.exports = { initFirebase, sendPush, notifyHandler };
