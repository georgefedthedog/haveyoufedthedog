// Helper used by both completion hooks in notify.pb.js. Lives in a
// non-`.pb.js` file so PocketBase doesn't auto-load it as a hook.
//
// Why this isn't inlined into notify.pb.js: PB runs each hook handler in
// its own Goja runtime - top-level function declarations in the source
// file aren't in scope when handlers fire. So we share via `require()`.

function notifyHousehold(record, action) {
  const subjectId = record.get("subject");
  if (!subjectId) return;

  try {
    // Localized templates; recipients group by users.locale (empty =
    // English, so pre-i18n clients keep today's strings). Required inside
    // the try so a load failure is contained like any other push error.
    const { t, lang } = require(`${__hooks}/_l10n_helper.js`);

    const subject = $app.findRecordById("subjects", subjectId);
    const householdId = subject.get("household");
    if (!householdId) return;

    // The completion's `completed_by` is the original logger. For undo, if
    // they're undoing their own log, this correctly excludes them. If an
    // owner is deleting someone else's completion, the original logger DOES
    // get a "your completion was undone" push, and so does the owner -
    // minor noise we accept for hook simplicity.
    const completedById = record.get("completed_by");

    const members = $app.findAllRecords("household_members", $dbx.exp("household = {:hh}", { hh: householdId }));

    // language -> tokens; one push per language group.
    const tokensByLang = {};
    let total = 0;
    for (const m of members) {
      const userId = m.get("user");
      if (!userId || userId === completedById) continue;
      try {
        const user = $app.findRecordById("_pb_users_auth_", userId);
        const token = user.get("fcm_token");
        if (!token) continue;
        // mute_completions: the per-user "Chores logged" switch (covers both
        // done and undone pushes); missing = false = send.
        if (user.get("mute_completions")) continue;
        const l = lang(user.get("locale"));
        (tokensByLang[l] = tokensByLang[l] || []).push(token);
        total += 1;
      } catch (_) {}
    }

    if (!total) return;

    const choreName = (() => {
      try {
        const choreId = record.get("chore");
        if (!choreId) return null;
        const chore = $app.findRecordById("chores", choreId);
        return chore.get("name");
      } catch (_) {
        return null;
      }
    })();

    const subjectName = (() => {
      try {
        return subject.get("name") || null;
      } catch (_) {
        return null;
      }
    })();

    const whoName = (() => {
      try {
        const user = $app.findRecordById("_pb_users_auth_", completedById);
        return user.get("name") || null;
      } catch (_) {
        return null;
      }
    })();

    for (const l of Object.keys(tokensByLang)) {
      const who = whoName || t(l, "someone");
      const title = subjectName || t(l, "someone");
      let body;
      if (action === "created") {
        body = choreName ? t(l, "doneBody", { chore: choreName, who: who }) : t(l, "doneFallback", { who: who });
      } else {
        body = choreName ? t(l, "undoneBody", { chore: choreName, who: who }) : t(l, "undoneFallback", { who: who });
      }

      const resp = $http.send({
        method: "POST",
        url: "http://127.0.0.1:3055/notify",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tokens: tokensByLang[l], title, body, data: { subjectId, type: "subject" } }),
        timeout: 5,
      });

      if (resp.statusCode !== 200) {
        console.error("[notify hook] worker returned", resp.statusCode, resp.raw);
      }
    }
  } catch (err) {
    console.error("[notify hook] error:", err);
  }
}

module.exports = { notifyHousehold };
