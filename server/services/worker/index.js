// Composition root for the haveyoufedthedog backend service. It wires
// together focused modules - each owning one concern - and listens on
// 127.0.0.1:3055 (internal only; the PB hooks on the same host call in):
//   - notify.js        FCM push relay (POST /notify) + shared sendPush
//   - verify.js        in-app-purchase verification (POST /verify-purchase)
//   - overdue-cron.js  per-timezone overdue-chore nudges
//
// Both integrations are config-gated and fail soft: missing Firebase or Play
// credentials disable only their own feature, the rest of the service still
// runs.

const express = require("express");

const { initFirebase, sendPush, notifyHandler } = require("./notify");
const { initPlayVerifier, verifyPurchaseHandler } = require("./verify");
const { startOverdueCron } = require("./overdue-cron");

const app = express();
app.use(express.json());

initFirebase();
initPlayVerifier();

app.post("/notify", notifyHandler);
app.post("/verify-purchase", verifyPurchaseHandler);
app.get("/health", (_, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 3055;
app.listen(PORT, "127.0.0.1", () => {
  console.log(`service listening on 127.0.0.1:${PORT}`);
});

// Overdue-chore cron - needs PB superuser credentials (see .env.example).
// Without them the service still relays pushes; it just logs that the cron
// is off.
const pbUrl = process.env.PB_URL || "http://127.0.0.1:8090";
if (process.env.PB_SUPERUSER_EMAIL && process.env.PB_SUPERUSER_PASSWORD) {
  startOverdueCron({
    pbUrl,
    identity: process.env.PB_SUPERUSER_EMAIL,
    password: process.env.PB_SUPERUSER_PASSWORD,
    sendPush,
  });
} else {
  console.warn(
    "[overdue] PB_SUPERUSER_EMAIL/_PASSWORD not set - overdue cron disabled"
  );
}
