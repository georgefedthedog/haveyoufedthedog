// Composition root for the haveyoufedthedog backend service. It wires
// together focused modules - each owning one concern - and listens on
// 127.0.0.1:3055 (internal only; the PB hooks on the same host call in):
//   - notify.js        FCM push relay (POST /notify) + shared sendPush
//   - verify.js        in-app-purchase verification (POST /verify-purchase)
//   - overdue-cron.js  per-timezone overdue-chore nudges
//   - award-cron.js    per-timezone weekly character-award pushes (Sun 6pm)
//
// Both integrations are config-gated and fail soft: missing Firebase or Play
// credentials disable only their own feature, the rest of the service still
// runs.

const express = require("express");

const { initFirebase, sendPush, notifyHandler } = require("./notify");
const { initPlayVerifier, verifyPurchaseHandler } = require("./verify");
const { startOverdueCron } = require("./overdue-cron");
const { startAwardCron } = require("./award-cron");
const { createPbClient } = require("./pb-cron");
const { makeRewardStreakHandler } = require("./reward-streak");

const app = express();
app.use(express.json());

initFirebase();
initPlayVerifier();

// PB superuser client for endpoints that read across households (reward
// streaks). Created only when the cron credentials are present; without them
// the reward-streak endpoint replies 503, mirroring how the crons stay off.
const pbUrl = process.env.PB_URL || "http://127.0.0.1:8090";
const superuser =
  process.env.PB_SUPERUSER_EMAIL && process.env.PB_SUPERUSER_PASSWORD
    ? {
        pbUrl,
        identity: process.env.PB_SUPERUSER_EMAIL,
        password: process.env.PB_SUPERUSER_PASSWORD,
      }
    : null;

app.post("/notify", notifyHandler);
app.post("/verify-purchase", verifyPurchaseHandler);
app.post(
  "/reward-streak",
  superuser
    ? makeRewardStreakHandler(createPbClient(superuser))
    : (_, res) => res.status(503).json({ error: "reward streak unavailable (no PB superuser creds)" }),
);
app.get("/health", (_, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 3055;
app.listen(PORT, "127.0.0.1", () => {
  console.log(`service listening on 127.0.0.1:${PORT}`);
});

// Crons - both need PB superuser credentials (see .env.example). Without
// them the service still relays pushes; it just logs that the crons are off.
if (superuser) {
  const creds = { ...superuser, sendPush };
  startOverdueCron(creds);
  startAwardCron(creds);
} else {
  console.warn(
    "[cron] PB_SUPERUSER_EMAIL/_PASSWORD not set - overdue + award crons disabled"
  );
}
