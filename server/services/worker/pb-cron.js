// Shared plumbing for the worker's per-timezone crons (overdue-cron.js,
// award-cron.js). Both authenticate as a PB superuser, poll PocketBase once
// a minute, and slice work by household timezone - this module owns the bits
// that would otherwise be copy-pasted between them. It's part of the Node
// service (not a PB hook), so plain require() sharing is fine.

const DEFAULT_TZ = "Europe/London";
const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;
const HOUSEHOLDS_CACHE_MS = 5 * 60 * 1000;
const FETCH_TIMEOUT_MS = 10 * 1000;

/// `fetch` with a hard timeout. A request with no timeout can hang forever -
/// and because the per-minute tick has a `running` guard, one hung request
/// wedges the whole cron until the process restarts (it once went dark for
/// days that way). On timeout this rejects, so the tick's catch resets
/// `running` and the next minute retries cleanly.
async function fetchWithTimeout(url, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } catch (err) {
    if (err.name === "AbortError") {
      throw new Error(`PB request timed out after ${FETCH_TIMEOUT_MS}ms: ${url}`);
    }
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

// Sun=0 .. Sat=6 (matches Date.getUTCDay), and the Mon=1 … Sun=64 weekday
// mask bits the app stores on chores.
const WEEKDAY = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
const WEEKDAY_BIT = { Mon: 1, Tue: 2, Wed: 4, Thu: 8, Fri: 16, Sat: 32, Sun: 64 };

/// An authenticated PocketBase client for a superuser. `get` does one
/// request (re-authing once on a 401); `list` follows pagination to return
/// every record from a list endpoint (PB caps perPage at 500).
function createPbClient({ pbUrl, identity, password }) {
  let token = null;

  async function authenticate() {
    const res = await fetchWithTimeout(`${pbUrl}/api/collections/_superusers/auth-with-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identity, password }),
    });
    if (!res.ok) throw new Error(`PB superuser auth failed: ${res.status}`);
    token = (await res.json()).token;
  }

  async function get(path, retried = false) {
    if (!token) await authenticate();
    const res = await fetchWithTimeout(`${pbUrl}${path}`, { headers: { Authorization: token } });
    if (res.status === 401 && !retried) {
      token = null;
      return get(path, true);
    }
    if (!res.ok) throw new Error(`PB ${res.status} for ${path}`);
    return res.json();
  }

  async function list(pathBase) {
    const out = [];
    let page = 1;
    for (;;) {
      const sep = pathBase.includes("?") ? "&" : "?";
      const data = await get(`${pathBase}${sep}perPage=500&page=${page}`);
      const items = data.items || [];
      out.push(...items);
      if (items.length < 500 || page >= (data.totalPages || page)) break;
      page += 1;
    }
    return out;
  }

  async function update(path, body, retried = false) {
    if (!token) await authenticate();
    const res = await fetchWithTimeout(`${pbUrl}${path}`, {
      method: "PATCH",
      headers: { Authorization: token, "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (res.status === 401 && !retried) {
      token = null;
      return update(path, body, true);
    }
    if (!res.ok) throw new Error(`PB ${res.status} for PATCH ${path}`);
    return res.json();
  }

  return { get, list, update };
}

/// Wall-clock parts of `date` in `timeZone`: the weekday (Sun=0..Sat=6) and
/// its app weekday-mask bit, the time of day, and the local calendar date as
/// a UTC-midnight epoch (so week-cadence math matches the app, which
/// normalises to UTC dates).
function zonedParts(date, timeZone) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    hour12: false,
    weekday: "short",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(date);
  const get = (t) => parts.find((p) => p.type === t)?.value;
  const wd = get("weekday");
  return {
    weekday: WEEKDAY[wd] ?? -1,
    weekdayBit: WEEKDAY_BIT[wd] || 0,
    // Some engines render midnight as "24" with hour12:false.
    hour: Number(get("hour")) % 24,
    minute: Number(get("minute")),
    second: Number(get("second")),
    dateMs: Date.UTC(Number(get("year")), Number(get("month")) - 1, Number(get("day"))),
  };
}

// ---------------------------------------------------------------------------
// Schedule due-date logic. The single server-side mirror of the app's
// ScheduleRule (lib/core/chores/schedule_rule.dart). All cadence decisions go
// through isChoreDueOn; if you change the app's isDueOn / weeksSinceEpoch /
// monthly math, change this to match.
// ---------------------------------------------------------------------------

// First Monday of the Unix epoch - the fixed anchor for fortnightly parity,
// identical to ScheduleRule._weekEpoch.
const WEEK_EPOCH_MS = Date.UTC(1970, 0, 5);

/// Monday (UTC midnight epoch) of the week containing UTC-midnight epoch `ms`.
function utcMondayMs(ms) {
  const dow = new Date(ms).getUTCDay(); // 0=Sun .. 6=Sat
  return ms - ((dow + 6) % 7) * DAY_MS;
}

/// Whole weeks from WEEK_EPOCH_MS to the Monday of `dateMs`'s week. Both ends
/// are UTC-midnight Mondays so the division is exact. Mirrors
/// ScheduleRule.weeksSinceEpoch.
function weeksSinceEpoch(dateMs) {
  return Math.round((utcMondayMs(dateMs) - WEEK_EPOCH_MS) / WEEK_MS);
}

/// App weekday-mask bit (Mon=1 .. Sun=64) for a UTC-midnight-epoch date.
function weekdayBit(dateMs) {
  const dow = new Date(dateMs).getUTCDay(); // 0=Sun .. 6=Sat
  return dow === 0 ? 64 : 1 << (dow - 1);
}

/// Number of days in the month containing `dateMs` (UTC-midnight epoch).
function daysInMonth(dateMs) {
  const d = new Date(dateMs);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
}

/// `YYYY-MM-DD` for a UTC-midnight-epoch date - the local calendar date, in the
/// same text shape as the app's `chores.due_date`, so the once carryover below
/// is a plain string compare (ISO dates sort chronologically).
function ymd(dateMs) {
  const d = new Date(dateMs);
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${d.getUTCFullYear()}-${m}-${day}`;
}

/// Whether `chore` is due on the local calendar date `dateMs` (a UTC-midnight
/// epoch). Mirrors ScheduleRule.isDueOn: daily = always; weekly = weekday mask
/// plus fortnightly phase; monthly = a fixed date or an Nth/last weekday.
function isChoreDueOn(chore, dateMs) {
  const type = chore.schedule_type || "daily";
  if (type === "weekly") {
    const mask = Number(chore.weekday_mask) || 127;
    if ((mask & weekdayBit(dateMs)) === 0) return false;
    const interval = Number(chore.week_interval) || 1;
    if (interval <= 1) return true;
    const phase = Number(chore.week_phase) || 0;
    return weeksSinceEpoch(dateMs) % interval === phase;
  }
  if (type === "monthly") return isChoreDueMonthly(chore, dateMs);
  if (type === "once") {
    // Carryover: due on its date and every day after, until it's done (mirrors
    // ScheduleRule.isDueOn). An empty/missing date is never due.
    const due = chore.due_date;
    return due ? ymd(dateMs) >= due : false;
  }
  return true; // daily (and any unknown type) - every day
}

/// Monthly arm of isChoreDueOn. `last` (-1) means the last day / last weekday
/// of the month, matching ScheduleRule.last.
function isChoreDueMonthly(chore, dateMs) {
  const d = new Date(dateMs);
  const dom = d.getUTCDate();
  const dim = daysInMonth(dateMs);
  if ((chore.month_mode || "day") === "weekday") {
    const iso = d.getUTCDay() === 0 ? 7 : d.getUTCDay(); // ISO Mon=1 .. Sun=7
    if (iso !== (Number(chore.month_weekday) || 1)) return false;
    const ord = Number(chore.month_ordinal) || 1;
    if (ord === -1) return dom + 7 > dim; // last occurrence: none later
    return Math.floor((dom - 1) / 7) + 1 === ord; // Nth occurrence
  }
  const md = Number(chore.month_day) || 1;
  if (md === -1) return dom === dim; // last day of the month
  return dom === md;
}

/// Household ids grouped by timezone (empty -> default), cached for
/// HOUSEHOLDS_CACHE_MS - the set "changes about never". Logs the timezone
/// list under `logPrefix` only when it changes. Returns a function; call it
/// to get `{ [tz]: [householdId, ...] }` (overdue derives its distinct-tz
/// list from `Object.keys`).
function makeHouseholdsByZone(client, logPrefix) {
  let cache = { at: 0, byZone: {} };
  let lastLogged = null;
  return async function householdsByZone() {
    if (Date.now() - cache.at < HOUSEHOLDS_CACHE_MS) return cache.byZone;
    const items = await client.list(`/api/collections/households/records?fields=id,timezone`);

    // An empty result is almost always a transient (a PB restart caught
    // mid-request, a momentary auth blip), not "every household is gone".
    // Caching it would silence the crons for HOUSEHOLDS_CACHE_MS, so keep the
    // last good set and retry next minute. Don't bump cache.at, so the retry
    // isn't throttled. Warn each time so a genuine empty period is visible.
    if (!items.length) {
      console.warn(`${logPrefix} households fetch returned empty - keeping last good (${Object.keys(cache.byZone).length} tz)`);
      return cache.byZone;
    }

    const byZone = {};
    for (const h of items) {
      const tz = h.timezone || DEFAULT_TZ;
      (byZone[tz] = byZone[tz] || []).push(h.id);
    }
    cache = { at: Date.now(), byZone };
    const fingerprint = Object.keys(byZone).sort().join(",");
    if (fingerprint !== lastLogged) {
      console.log(`${logPrefix} polling timezones:`, Object.keys(byZone));
      lastLogged = fingerprint;
    }
    return byZone;
  };
}

/// Runs `fn(target)` about 5s past every minute, where `target` is the
/// minute that just finished (now - 60s) - so a chore/cutoff at HH:MM fires
/// exactly once, right after it passes. Ticks never overlap: a slow run
/// causes the next tick to be skipped rather than stacking.
function everyMinute(fn) {
  let running = false;
  let runningSince = 0;
  async function tick() {
    if (running) {
      // A tick still "running" minutes later means a wedged await - the
      // failure mode that once silenced the crons for days looked exactly
      // like normal quiet in the logs. Surface it so the silence is visible.
      const stuckMs = Date.now() - runningSince;
      if (stuckMs > 2 * 60 * 1000) {
        console.warn(`[cron] tick skipped - previous run still going after ${Math.round(stuckMs / 1000)}s`);
      }
      return;
    }
    running = true;
    runningSince = Date.now();
    try {
      await fn(new Date(Date.now() - 60 * 1000));
    } catch (err) {
      console.error("[cron] tick error:", err.message);
    } finally {
      running = false;
    }
  }
  // Align to ~5s past each minute, then run every 60s.
  const msToNext = 60000 - (Date.now() % 60000) + 5000;
  setTimeout(() => {
    tick();
    setInterval(tick, 60000);
  }, msToNext);
}

module.exports = {
  DEFAULT_TZ,
  DAY_MS,
  WEEK_MS,
  HOUSEHOLDS_CACHE_MS,
  WEEKDAY,
  WEEKDAY_BIT,
  createPbClient,
  zonedParts,
  makeHouseholdsByZone,
  everyMinute,
  weekdayBit,
  isChoreDueOn,
};
