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

// POST /notify
// Body: { tokens: string[], title: string, body: string, data?: object }
app.post("/notify", async (req, res) => {
  const { tokens, title, body, data = {} } = req.body;

  if (!tokens || !tokens.length || !title || !body) {
    return res.status(400).json({ error: "tokens, title and body are required" });
  }

  const validTokens = tokens.filter(Boolean);
  if (!validTokens.length) {
    return res.json({ success: true, sent: 0 });
  }

  try {
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

    res.json({ success: true, sent: response.successCount, failed: response.failureCount });
  } catch (err) {
    console.error("FCM error:", err);
    res.status(500).json({ error: err.message });
  }
});

app.get("/health", (_, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 3055;
app.listen(PORT, "127.0.0.1", () => {
  console.log(`push-notifier listening on 127.0.0.1:${PORT}`);
});
