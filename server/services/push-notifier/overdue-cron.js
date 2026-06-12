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

function startOverdueCron({ pbUrl, identity, password, sendPush }) {
  let token = null;
  let householdsCache = { at: 0, timezones: [] };
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
    return householdsCache.timezones;
  }

  /// Wall-clock parts of `date` in `timeZone`.
  function zonedParts(date, timeZone) {
    const parts = new Intl.DateTimeFormat("en-GB", {
      timeZone,
      hour12: false,
      weekday: "short",
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

    for (const chore of chores.items || []) {
      try {
        const mask = chore.weekday_mask || 127;
        if ((mask & p.weekdayBit) === 0) continue;

        const subject = chore.expand?.subject;
        if (!subject) continue;

        const since = sinceLocalMidnight(target, p);
        const doneFilter = encodeURIComponent(`chore = '${chore.id}' && completed_at >= "${since}"`);
        const done = await pbGet(`/api/collections/completions/records?perPage=1&filter=${doneFilter}`);
        if ((done.items || []).length) continue;

        const memberFilter = encodeURIComponent(`household = '${subject.household}'`);
        const members = await pbGet(`/api/collections/household_members/records?perPage=100&filter=${memberFilter}&expand=user`);
        const tokens = (members.items || []).map(m => m.expand?.user?.fcm_token).filter(Boolean);
        if (!tokens.length) continue;

        await sendPush({
          tokens,
          title: subject.name || "Someone",
          body: `${chore.name || "A chore"} is overdue - ${subject.name || "someone"} is waiting!`,
          data: { subjectId: subject.id, type: "overdue" },
        });
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
