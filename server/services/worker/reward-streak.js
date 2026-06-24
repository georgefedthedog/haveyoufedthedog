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

const { DEFAULT_TZ, DAY_MS, WEEK_MS, zonedParts } = require("./pb-cron");

/// Monday (UTC midnight epoch) of the week containing UTC-midnight epoch `ms`.
/// Twin of overdue-cron.js's helper - kept local to avoid disturbing the
/// deployed cron; the math is identical.
function utcMondayMs(ms) {
  const dow = new Date(ms).getUTCDay(); // 0=Sun .. 6=Sat
  return ms - ((dow + 6) % 7) * DAY_MS;
}

/// Whether a chore's week cadence is "on" for the local date `dateMs` (a
/// UTC-midnight epoch). Mirrors ScheduleRule._isOnWeek in the app and the twin
/// in overdue-cron.js: no start anchor = always on; otherwise gate on the
/// start date and, for fortnightly+, the Mon->Sun week parity.
function isOnWeek(chore, dateMs) {
  const raw = chore.start_date;
  if (!raw) return true;
  const sd = new Date(raw); // stored as UTC midnight
  const startMs = Date.UTC(sd.getUTCFullYear(), sd.getUTCMonth(), sd.getUTCDate());
  if (dateMs < startMs) return false; // not started yet
  const interval = Number(chore.week_interval) || 1;
  if (interval <= 1) return true;
  const weeks = Math.round((utcMondayMs(dateMs) - utcMondayMs(startMs)) / WEEK_MS);
  return weeks % interval === 0;
}

/// App weekday-mask bit (Mon=1 .. Sun=64) for a UTC-midnight-epoch local date.
function weekdayBit(dateMs) {
  const dow = new Date(dateMs).getUTCDay(); // 0=Sun .. 6=Sat
  return dow === 0 ? 64 : 1 << (dow - 1);
}

/// Pure streak count over already-fetched data. `chores` need only carry
/// weekday_mask / week_interval / start_date; `completions` only completed_at.
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

    const bit = weekdayBit(dayMs);
    const due = chores.some((ch) => {
      const mask = Number(ch.weekday_mask) || 127;
      return (mask & bit) !== 0 && isOnWeek(ch, dayMs);
    });
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
    `/api/collections/chores/records?filter=${choreFilter}&fields=weekday_mask,week_interval,start_date`,
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
