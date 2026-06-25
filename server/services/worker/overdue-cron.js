// Per-timezone overdue-chore checker.
//
// Once a minute, for each distinct household timezone, this works out that
// zone's just-finished minute and asks PocketBase for active chores
// scheduled at exactly that wall-clock time. Chores still uncompleted since
// their household's local midnight get a push to every member.
//
// Lives in the Node service (not a PB hook) because chore times are stored
// as wall-clock values with no timezone - converting "18:30 in
// America/New_York" to an instant needs a tz database, which Node's Intl has
// and PB's Goja runtime doesn't.
//
// Shared PB-client / timezone / scheduler plumbing lives in pb-cron.js;
// what's here is overdue-specific (the week-cadence + since-midnight math
// and the per-minute chore scan).
//
// Needs a PB superuser login (env: PB_SUPERUSER_EMAIL / _PASSWORD) to read
// across households. Without them the cron stays disabled and the service
// still relays hook-driven pushes as before.

const {
  DEFAULT_TZ,
  createPbClient,
  zonedParts,
  makeHouseholdsByZone,
  everyMinute,
  isChoreDueOn,
} = require("./pb-cron");

function startOverdueCron({ pbUrl, identity, password, sendPush }) {
  const pb = createPbClient({ pbUrl, identity, password });
  const householdsByZone = makeHouseholdsByZone(pb, "[overdue]");

  /// "completed since the household's local midnight" cutoff, as a PB
  /// datetime literal. Derived by rolling the target instant back by its own
  /// local time-of-day; off by an hour on DST-change days, which is an
  /// acceptable wobble for a nudge.
  function sinceLocalMidnight(target, p) {
    const sinceMs = target.getTime() - (p.hour * 3600 + p.minute * 60 + p.second) * 1000;
    return new Date(sinceMs).toISOString().replace("T", " ");
  }

  async function checkZone(tz, target) {
    const p = zonedParts(target, tz);

    // The default zone also owns households with no timezone set.
    const tzMatch = tz === DEFAULT_TZ ? `(subject.household.timezone = '${tz}' || subject.household.timezone = '')` : `subject.household.timezone = '${tz}'`;
    const filter = encodeURIComponent(`active = true && hour = ${p.hour} && minute = ${p.minute} && ${tzMatch}`);
    const chores = await pb.get(`/api/collections/chores/records?perPage=200&filter=${filter}&expand=subject`);

    const clock = `${String(p.hour).padStart(2, "0")}:${String(p.minute).padStart(2, "0")}`;
    if ((chores.items || []).length) {
      console.log(`[overdue] ${tz} ${clock} matched ${chores.items.length} chore(s)`);
    }

    for (const chore of chores.items || []) {
      try {
        if (!isChoreDueOn(chore, p.dateMs)) {
          console.log(`[overdue] skip "${chore.name}" - not due today (${chore.schedule_type || "daily"})`);
          continue;
        }

        const subject = chore.expand?.subject;
        if (!subject) {
          console.log(`[overdue] skip "${chore.name}" - subject not expanded`);
          continue;
        }

        const since = sinceLocalMidnight(target, p);
        const doneFilter = encodeURIComponent(`chore = '${chore.id}' && completed_at >= "${since}"`);
        const done = await pb.get(`/api/collections/completions/records?perPage=1&filter=${doneFilter}`);
        if ((done.items || []).length) {
          console.log(`[overdue] skip "${chore.name}" - already completed since ${since}`);
          continue;
        }

        const memberFilter = encodeURIComponent(`household = '${subject.household}'`);
        const members = await pb.get(`/api/collections/household_members/records?perPage=100&filter=${memberFilter}&expand=user`);
        const tokens = (members.items || []).map(m => m.expand?.user?.fcm_token).filter(Boolean);
        if (!tokens.length) {
          console.log(`[overdue] skip "${chore.name}" - no fcm_tokens among ${(members.items || []).length} member(s)`);
          continue;
        }

        const result = await sendPush({
          tokens,
          title: subject.name || "Someone",
          body: `${chore.name || "A chore"} is overdue - ${subject.name || "someone"} is waiting!`,
          data: { subjectId: subject.id, type: "subject" },
        });
        console.log(`[overdue] sent "${chore.name}" to ${tokens.length} token(s):`, result);
      } catch (err) {
        console.error("[overdue] chore", chore.id, "error:", err.message);
      }
    }
  }

  everyMinute(async (target) => {
    for (const tz of Object.keys(await householdsByZone())) {
      try {
        await checkZone(tz, target);
      } catch (err) {
        console.error("[overdue] zone", tz, "error:", err.message);
      }
    }
  });
  console.log("[overdue] cron armed (default tz:", DEFAULT_TZ + ")");
}

module.exports = { startOverdueCron };
