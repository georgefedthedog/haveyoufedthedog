// Per-timezone overdue-chore checker.
//
// Once a minute, for each distinct household timezone, this works out
// that zone's just-finished minute and asks PocketBase for active chores
// scheduled at exactly that wall-clock time. Chores still uncompleted
// since their household's local midnight get a push to every member.
//
// Lives in the Node service (not a PB hook) because chore times are
// stored as wall-clock values with no timezone - converting "18:30 in
// America/New_York" to an instant needs a tz database, which Node's
// Intl has and PB's Goja runtime doesn't.
//
// Needs a PB superuser login (env: PB_SUPERUSER_EMAIL / _PASSWORD) to
// read across households. Without them the cron stays disabled and the
// service still relays hook-driven pushes as before.

const DEFAULT_TZ = "Europe/London";
const WEEKDAY_BIT = { Mon: 1, Tue: 2, Wed: 4, Thu: 8, Fri: 16, Sat: 32, Sun: 64 };
const HOUSEHOLDS_CACHE_MS = 5 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;

/// Monday (UTC midnight epoch) of the week containing UTC-midnight epoch `ms`.
function utcMondayMs(ms) {
  const dow = new Date(ms).getUTCDay(); // 0=Sun .. 6=Sat
  return ms - ((dow + 6) % 7) * DAY_MS;
}

/// Whether a chore's week cadence is "on" for the local calendar date
/// `dateMs` (a UTC-midnight epoch). Mirrors ScheduleRule._isOnWeek in the
/// app: no start anchor = always on; otherwise gate on the start date and,
/// for fortnightly+, the Mon→Sun week parity from the anchor week.
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

function startOverdueCron({ pbUrl, identity, password, sendPush }) {
  let token = null;
  let householdsCache = { at: 0, timezones: [] };
  let lastLoggedTimezones = null;
  let running = false;

  async function authenticate() {
    const res = await fetch(`${pbUrl}/api/collections/_superusers/auth-with-password`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ identity, password }),
    });
    if (!res.ok) throw new Error(`PB superuser auth failed: ${res.status}`);
    token = (await res.json()).token;
  }

  async function pbGet(path, retried = false) {
    if (!token) await authenticate();
    const res = await fetch(`${pbUrl}${path}`, { headers: { Authorization: token } });
    if (res.status === 401 && !retried) {
      token = null;
      return pbGet(path, true);
    }
    if (!res.ok) throw new Error(`PB ${res.status} for ${path}`);
    return res.json();
  }

  /// Distinct household timezones, empty mapped to the default. Cached -
  /// the set changes about never.
  async function distinctTimezones() {
    if (Date.now() - householdsCache.at < HOUSEHOLDS_CACHE_MS) {
      return householdsCache.timezones;
    }
    const data = await pbGet(`/api/collections/households/records?perPage=500&fields=id,timezone`);
    const set = new Set((data.items || []).map(h => h.timezone || DEFAULT_TZ));
    householdsCache = { at: Date.now(), timezones: [...set] };
    // Log only when the set changes - it "changes about never", so a
    // per-refresh print would just be 288 redundant lines a day.
    const fingerprint = [...set].sort().join(",");
    if (fingerprint !== lastLoggedTimezones) {
      console.log("[overdue] polling timezones:", householdsCache.timezones);
      lastLoggedTimezones = fingerprint;
    }
    return householdsCache.timezones;
  }

  /// Wall-clock parts of `date` in `timeZone`.
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
    const get = t => parts.find(p => p.type === t)?.value;
    return {
      weekdayBit: WEEKDAY_BIT[get("weekday")] || 0,
      // Some engines render midnight as "24" with hour12:false.
      hour: Number(get("hour")) % 24,
      minute: Number(get("minute")),
      second: Number(get("second")),
      // The chore's local calendar date as a UTC-midnight epoch, so the
      // week-cadence math matches the app (ScheduleRule normalises to UTC
      // dates too).
      dateMs: Date.UTC(
        Number(get("year")),
        Number(get("month")) - 1,
        Number(get("day")),
      ),
    };
  }

  /// "completed since the household's local midnight" cutoff, as a PB
  /// datetime literal. Derived by rolling the target instant back by its
  /// own local time-of-day; off by an hour on DST-change days, which is
  /// an acceptable wobble for a nudge.
  function sinceLocalMidnight(target, p) {
    const sinceMs = target.getTime() - (p.hour * 3600 + p.minute * 60 + p.second) * 1000;
    return new Date(sinceMs).toISOString().replace("T", " ");
  }

  async function checkZone(tz, target) {
    const p = zonedParts(target, tz);

    // The default zone also owns households with no timezone set.
    const tzMatch = tz === DEFAULT_TZ ? `(subject.household.timezone = '${tz}' || subject.household.timezone = '')` : `subject.household.timezone = '${tz}'`;
    const filter = encodeURIComponent(`active = true && hour = ${p.hour} && minute = ${p.minute} && ${tzMatch}`);
    const chores = await pbGet(`/api/collections/chores/records?perPage=200&filter=${filter}&expand=subject`);

    const clock = `${String(p.hour).padStart(2, "0")}:${String(p.minute).padStart(2, "0")}`;
    if ((chores.items || []).length) {
      console.log(`[overdue] ${tz} ${clock} matched ${chores.items.length} chore(s)`);
    }

    for (const chore of chores.items || []) {
      try {
        const mask = chore.weekday_mask || 127;
        if ((mask & p.weekdayBit) === 0) {
          console.log(`[overdue] skip "${chore.name}" - weekday mask ${mask} excludes bit ${p.weekdayBit}`);
          continue;
        }

        if (!isOnWeek(chore, p.dateMs)) {
          console.log(`[overdue] skip "${chore.name}" - off-week (interval ${chore.week_interval || 1}, start ${chore.start_date || "none"})`);
          continue;
        }

        const subject = chore.expand?.subject;
        if (!subject) {
          console.log(`[overdue] skip "${chore.name}" - subject not expanded`);
          continue;
        }

        const since = sinceLocalMidnight(target, p);
        const doneFilter = encodeURIComponent(`chore = '${chore.id}' && completed_at >= "${since}"`);
        const done = await pbGet(`/api/collections/completions/records?perPage=1&filter=${doneFilter}`);
        if ((done.items || []).length) {
          console.log(`[overdue] skip "${chore.name}" - already completed since ${since}`);
          continue;
        }

        const memberFilter = encodeURIComponent(`household = '${subject.household}'`);
        const members = await pbGet(`/api/collections/household_members/records?perPage=100&filter=${memberFilter}&expand=user`);
        const tokens = (members.items || []).map(m => m.expand?.user?.fcm_token).filter(Boolean);
        if (!tokens.length) {
          console.log(`[overdue] skip "${chore.name}" - no fcm_tokens among ${(members.items || []).length} member(s)`);
          continue;
        }

        const result = await sendPush({
          tokens,
          title: subject.name || "Someone",
          body: `${chore.name || "A chore"} is overdue - ${subject.name || "someone"} is waiting!`,
          data: { subjectId: subject.id, type: "overdue" },
        });
        console.log(`[overdue] sent "${chore.name}" to ${tokens.length} token(s):`, result);
      } catch (err) {
        console.error("[overdue] chore", chore.id, "error:", err.message);
      }
    }
  }

  async function tick() {
    if (running) return; // never overlap slow ticks
    running = true;
    try {
      // The minute that just finished - the :05-past tick at 18:31
      // checks 18:30, so each chore fires exactly once, right after
      // its time passes.
      const target = new Date(Date.now() - 60 * 1000);
      for (const tz of await distinctTimezones()) {
        try {
          await checkZone(tz, target);
        } catch (err) {
          console.error("[overdue] zone", tz, "error:", err.message);
        }
      }
    } catch (err) {
      console.error("[overdue] tick error:", err.message);
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
  console.log("[overdue] cron armed (default tz:", DEFAULT_TZ + ")");
}

module.exports = { startOverdueCron };
