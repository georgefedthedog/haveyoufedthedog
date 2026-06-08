// Helper used by both completion hooks in notify.pb.js. Lives in a
// non-`.pb.js` file so PocketBase doesn't auto-load it as a hook.
//
// Why this isn't inlined into notify.pb.js: PB runs each hook handler in
// its own Goja runtime — top-level function declarations in the source
// file aren't in scope when handlers fire. So we share via `require()`.

function notifyHousehold(record, action) {
  const subjectId = record.get("subject");
  if (!subjectId) return;

  try {
    const subject = $app.findRecordById("subjects", subjectId);
    const householdId = subject.get("household");
    if (!householdId) return;

    // The completion's `completed_by` is the original logger. For undo, if
    // they're undoing their own log, this correctly excludes them. If an
    // owner is deleting someone else's completion, the original logger DOES
    // get a "your completion was undone" push, and so does the owner —
    // minor noise we accept for hook simplicity.
    const completedById = record.get("completed_by");

    const members = $app.findAllRecords(
      "household_members",
      $dbx.exp("household = {:hh}", { hh: householdId })
    );

    const tokens = [];
    for (const m of members) {
      const userId = m.get("user");
      if (!userId || userId === completedById) continue;
      try {
        const user = $app.findRecordById("_pb_users_auth_", userId);
        const token = user.get("fcm_token");
        if (token) tokens.push(token);
      } catch (_) {}
    }

    if (!tokens.length) return;

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
        return subject.get("name");
      } catch (_) {
        return "Someone";
      }
    })();

    const whoName = (() => {
      try {
        const user = $app.findRecordById("_pb_users_auth_", completedById);
        return user.get("name") || "Someone";
      } catch (_) {
        return "Someone";
      }
    })();

    const title = subjectName;
    let body;
    if (action === "created") {
      body = choreName
        ? `${choreName} done by ${whoName}`
        : `${whoName} logged a completion`;
    } else {
      body = choreName
        ? `${choreName} undone by ${whoName}`
        : `${whoName} removed a completion`;
    }

    const resp = $http.send({
      method: "POST",
      url: "http://127.0.0.1:3055/notify",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tokens, title, body, data: { subjectId } }),
      timeout: 5,
    });

    if (resp.statusCode !== 200) {
      console.error(
        "[notify hook] push-notifier returned",
        resp.statusCode,
        resp.raw
      );
    }
  } catch (err) {
    console.error("[notify hook] error:", err);
  }
}

module.exports = { notifyHousehold };
