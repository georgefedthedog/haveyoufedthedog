// Hourly one-off retirement sweep.
//
// A one-time chore (schedule_type = "once") carries over as overdue until it's
// done, then should drop off for good. The app hides a finished one-off
// immediately (client-side), but the durable retirement lives here: once an
// hour, for each household, this flips `active = false` on any one-off whose
// latest completion is on a *prior* local day (in the household's timezone). A
// one-off completed *today* is left active so it still shows as "done" through
// its completion day; an outstanding (never-completed) one stays active too, so
// it keeps carrying over.
//
// Runs hourly (~2 minutes past the hour, UTC) rather than per-minute - the
// client filter already makes the timing invisible, so this is just durable
// cleanup. Half-hour-offset timezones need no special cadence: each household's
// local midnight is computed in its own zone, so running hourly catches every
// zone within an hour of its rollover.
//
// Shared PB-client / timezone / scheduler plumbing lives in pb-cron.js.

const { DEFAULT_TZ, createPbClient, zonedParts, makeHouseholdsByZone, everyMinute } = require("./pb-cron");

function startRetireCron({ pbUrl, identity, password }) {
  const pb = createPbClient({ pbUrl, identity, password });
  const householdsByZone = makeHouseholdsByZone(pb, "[retire]");

  /// UTC instant of the household's local midnight (start of today), as a PB
  /// datetime literal - `target` rolled back by its own local time-of-day.
  /// Off by an hour on DST-change days, an acceptable wobble for cleanup.
  function localMidnightLit(target, p) {
    const ms = target.getTime() - (p.hour * 3600 + p.minute * 60 + p.second) * 1000;
    return new Date(ms).toISOString().replace("T", " ");
  }

  async function sweepHousehold(hid, since) {
    const filter = encodeURIComponent(`subject.household = '${hid}' && active = true && schedule_type = 'once'`);
    const chores = await pb.get(`/api/collections/chores/records?perPage=200&filter=${filter}&fields=id,name`);
    for (const chore of chores.items || []) {
      try {
        // Completed on a prior local day = a completion strictly before today's
        // local midnight. A completion at/after `since` is "today", so it stays
        // active and keeps showing as done.
        const doneFilter = encodeURIComponent(`chore = '${chore.id}' && completed_at < "${since}"`);
        const done = await pb.get(`/api/collections/completions/records?perPage=1&filter=${doneFilter}`);
        if (!(done.items || []).length) continue;
        await pb.update(`/api/collections/chores/records/${chore.id}`, { active: false });
        console.log(`[retire] retired one-off "${chore.name}" (${chore.id}) in ${hid}`);
      } catch (err) {
        console.error(`[retire] chore ${chore.id} error:`, err.message);
      }
    }
  }

  everyMinute(async target => {
    // Hourly, ~2 past the hour: everyMinute fires ~5s past the minute with
    // `target` = the just-finished minute, so target minute 1 fires once an
    // hour at about HH:02:05.
    if (target.getUTCMinutes() !== 1) return;
    const byZone = await householdsByZone();
    for (const [tz, hids] of Object.entries(byZone)) {
      try {
        const p = zonedParts(target, tz);
        const since = localMidnightLit(target, p);
        for (const hid of hids) {
          try {
            await sweepHousehold(hid, since);
          } catch (err) {
            console.error("[retire] household", hid, "error:", err.message);
          }
        }
      } catch (err) {
        console.error("[retire] zone", tz, "error:", err.message);
      }
    }
  });
  console.log(`[retire] cron armed (hourly one-off sweep, default tz: ${DEFAULT_TZ})`);
}

module.exports = { startRetireCron };
