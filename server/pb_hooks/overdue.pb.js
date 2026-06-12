/// Every minute: find chores that became overdue in the last minute and
/// push a nudge to the whole household.
///
/// TIMEZONE CONTRACT: chore `hour`/`minute` are family wall-clock values
/// (no timezone stored). This cron compares them against the SERVER's
/// local clock, so the server timezone must be the family's:
///
///   sudo timedatectl set-timezone Europe/London   # then restart PB
///
/// A chore "became overdue in the last minute" when its scheduled time
/// matches the minute before this tick (tick at 18:31 catches the 18:30
/// chore), today is one of its due days, and no completion has been
/// logged for it since local midnight. Each chore fires exactly one push.
cronAdd("overdue-chores", "* * * * *", () => {
  try {
    // The minute that just finished. Using it (rather than "now") also
    // keeps the midnight boundary honest: the 00:00 tick checks 23:59
    // of the previous day, with that day's weekday mask.
    const target = new Date(Date.now() - 60 * 1000);
    const hour = target.getHours();
    const minute = target.getMinutes();
    // JS getDay(): Sun=0..Sat=6 → app bitmask Mon=1<<0..Sun=1<<6.
    const weekdayBit = 1 << ((target.getDay() + 6) % 7);

    // Local midnight of the target day, as UTC ISO for the datetime
    // comparison against `completed_at`.
    const midnight = new Date(target.getFullYear(), target.getMonth(), target.getDate());
    const sinceUtc = midnight.toISOString().replace("T", " ");

    let chores;
    try {
      chores = $app.findAllRecords(
        "chores",
        $dbx.exp("hour = {:h} AND minute = {:m} AND active = true", {
          h: hour,
          m: minute,
        }),
      );
    } catch (_) {
      return; // no chores at this minute
    }

    for (const chore of chores) {
      try {
        // Weekly chores only fire on masked days; daily masks are all-1s.
        const mask = chore.getInt("weekday_mask") || 127;
        if ((mask & weekdayBit) === 0) continue;

        // Already done today? Then it never went overdue.
        let done = false;
        try {
          const existing = $app.findFirstRecordByFilter("completions", "chore = {:chore} && completed_at >= {:since}", { chore: chore.id, since: sinceUtc });
          done = !!existing;
        } catch (_) {
          // not found - still outstanding
        }
        if (done) continue;

        const subject = $app.findRecordById("subjects", chore.get("subject"));
        const householdId = subject.get("household");
        if (!householdId) continue;

        const members = $app.findAllRecords("household_members", $dbx.exp("household = {:hh}", { hh: householdId }));

        const tokens = [];
        for (const m of members) {
          const userId = m.get("user");
          if (!userId) continue;
          try {
            const user = $app.findRecordById("_pb_users_auth_", userId);
            const token = user.get("fcm_token");
            if (token) tokens.push(token);
          } catch (_) {}
        }
        if (!tokens.length) continue;

        const subjectName = subject.get("name") || "Someone";
        const choreName = chore.get("name") || "A chore";

        const resp = $http.send({
          method: "POST",
          url: "http://127.0.0.1:3055/notify",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            tokens,
            title: subjectName,
            body: `${choreName} is overdue - ${subjectName} is waiting!`,
            data: { subjectId: subject.id, type: "overdue" },
          }),
          timeout: 5,
        });
        if (resp.statusCode !== 200) {
          console.error("[overdue cron] push-notifier returned", resp.statusCode, resp.raw);
        }
      } catch (err) {
        console.error("[overdue cron] chore", chore.id, "error:", err);
      }
    }
  } catch (err) {
    console.error("[overdue cron] error:", err);
  }
});
