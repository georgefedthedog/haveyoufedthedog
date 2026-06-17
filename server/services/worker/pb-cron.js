// Shared plumbing for the worker's per-timezone crons (overdue-cron.js,
// award-cron.js). Both authenticate as a PB superuser, poll PocketBase once
// a minute, and slice work by household timezone - this module owns the bits
// that would otherwise be copy-pasted between them. It's part of the Node
// service (not a PB hook), so plain require() sharing is fine.

const DEFAULT_TZ = "Europe/London";
const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;
const HOUSEHOLDS_CACHE_MS = 5 * 60 * 1000;

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
    const res = await fetch(`${pbUrl}/api/collections/_superusers/auth-with-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identity, password }),
    });
    if (!res.ok) throw new Error(`PB superuser auth failed: ${res.status}`);
    token = (await res.json()).token;
  }

  async function get(path, retried = false) {
    if (!token) await authenticate();
    const res = await fetch(`${pbUrl}${path}`, { headers: { Authorization: token } });
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

  return { get, list };
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
  async function tick() {
    if (running) return;
    running = true;
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
};
