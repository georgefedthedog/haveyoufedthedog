// Household reward-streak computation for the free streak-unlock feature.
//
// The PB hook (rewards.pb.js) holds the auth context and does the entitlement
// write; this module does the heavy lifting it can't: counting a household's
// consecutive due-days *in the household's own timezone*. PB's Goja runtime
// has no tz database (the same reason the crons live here), so the streak is
// computed in Node where Intl carries the IANA zones.
//
// The app computes an approximate copy of this for its progress bar, but THIS
// is the authority: the hook only grants when this count clears the
// threshold, so a spoofed client can't earn art.
//
// Streak rules (mirrors subjectStreak in the app, generalised to a household
// and made lenient):
//   - Walk back from today, one local calendar day at a time.
//   - A day with no due chore (any subject) is skipped - neither counted nor
//     breaking, so a Tue-only chore doesn't reset the streak on Wed.
//   - A due day with ANY completion (any subject) -> +1. Lenient on purpose:
//     the household just has to feed *something* each due day.
//   - A due day with nothing breaks the streak. Exception: today gets a grace
//     pass, so an outstanding chore due today doesn't drop a carried streak.
//   - Days on or before last_free_redemption don't count, so each free unlock
//     costs a fresh run of due-days.

const { DEFAULT_TZ, DAY_MS, zonedParts, isChoreDueOn } = require("./pb-cron");

/// Pure streak count over already-fetched data. `chores` carry the schedule
/// fields isChoreDueOn reads; `completions` only completed_at.
function computeRewardStreak({ tz, lastFreeRedemption, chores, completions, now }) {
  if (!chores.length) return 0;

  // Local-date (UTC-midnight epoch) of every completion, deduped.
  const satisfied = new Set();
  let earliest = null;
  for (const c of completions) {
    if (!c.completed_at) continue;
    const d = zonedParts(new Date(c.completed_at), tz).dateMs;
    satisfied.add(d);
    if (earliest === null || d < earliest) earliest = d;
  }
  if (earliest === null) return 0;

  const todayMs = zonedParts(now, tz).dateMs;
  const anchorMs = lastFreeRedemption
    ? zonedParts(new Date(lastFreeRedemption), tz).dateMs
    : -Infinity;

  let streak = 0;
  for (let offset = 0; offset <= 366; offset++) {
    const dayMs = todayMs - offset * DAY_MS;
    if (dayMs < earliest) break; // nothing older is in our window
    if (dayMs <= anchorMs) break; // don't count the claim day or earlier

    // One-offs are deliberately generous toward the streak: completing one
    // still helps (it lands in `satisfied` like any completion), but a missed
    // one must never make a day "due" and break the run. So only recurring
    // chores count toward whether a day is due.
    const due = chores.some(
      (ch) => (ch.schedule_type || "daily") !== "once" && isChoreDueOn(ch, dayMs),
    );
    if (!due) continue;

    if (satisfied.has(dayMs)) {
      streak += 1;
    } else if (offset === 0) {
      continue; // grace: today's outstanding chore doesn't break a carried run
    } else {
      break;
    }
  }
  return streak;
}

/// Fetches a household's timezone + anchor, its active chores and recent
/// completions, and returns the reward streak. Bounded to the last 366 days so
/// an active household's completion list stays a single bounded page set.
async function computeRewardStreakForHousehold(pb, householdId) {
  const hh = await pb.get(
    `/api/collections/households/records/${householdId}?fields=id,timezone,last_free_redemption`,
  );
  const tz = hh.timezone || DEFAULT_TZ;

  const choreFilter = encodeURIComponent(`subject.household = '${householdId}' && active = true`);
  const chores = await pb.list(
    `/api/collections/chores/records?filter=${choreFilter}&fields=schedule_type,weekday_mask,week_interval,week_phase,month_mode,month_day,month_ordinal,month_weekday`,
  );
  if (!chores.length) return 0;

  const sinceLit = new Date(Date.now() - 366 * DAY_MS).toISOString().replace("T", " ");
  const compFilter = encodeURIComponent(
    `subject.household = '${householdId}' && completed_at >= "${sinceLit}"`,
  );
  const completions = await pb.list(
    `/api/collections/completions/records?filter=${compFilter}&fields=completed_at`,
  );

  return computeRewardStreak({
    tz,
    lastFreeRedemption: hh.last_free_redemption,
    chores,
    completions,
    now: new Date(),
  });
}

/// Express handler. Body: { householdId }. 200 -> { householdId, streak }.
/// Auth + membership are enforced by the calling PB hook, not here (this
/// endpoint is internal to 127.0.0.1, same as /verify-purchase).
function makeRewardStreakHandler(pb) {
  return async function rewardStreakHandler(req, res) {
    const householdId = String((req.body || {}).householdId || "").trim();
    if (!householdId) {
      return res.status(400).json({ error: "householdId is required" });
    }
    try {
      const streak = await computeRewardStreakForHousehold(pb, householdId);
      res.json({ householdId, streak });
    } catch (err) {
      console.error("[reward-streak] error:", err.message);
      res.status(500).json({ error: err.message });
    }
  };
}

module.exports = {
  computeRewardStreak,
  computeRewardStreakForHousehold,
  makeRewardStreakHandler,
};
