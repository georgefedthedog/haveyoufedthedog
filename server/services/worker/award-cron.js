// Weekly character-award presenter.
//
// Once a minute, for each distinct household timezone, this checks whether
// that zone has just crossed the Sunday award cutoff (AWARD_HOUR:00 local).
// When it has, it settles that zone's just-finished award week - the seven
// days ending at the cutoff - and works out, per subject, which member did
// the most of that subject's chores. The unique top scorer wins that
// subject's "Best Human" award (ties win nobody, matching the app). Each
// winning member gets ONE push, however many subjects they topped.
//
// Award weeks run Sunday AWARD_HOUR:00 -> next Sunday AWARD_HOUR:00, so the
// winner locked here is exactly what the app shows via
// WeekWindow.settledAward (app: awardPresentationHour). Completions after
// the cutoff count toward next week's trophy.
//
// Lives in the Node service (not a PB hook) for the same reason as the
// overdue cron: resolving "Sunday 6pm in America/New_York" to an instant
// needs a tz database, which Node's Intl has and PB's Goja runtime doesn't.

const DEFAULT_TZ = "Europe/London";
const WEEKDAY = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
const HOUSEHOLDS_CACHE_MS = 5 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;

// Sunday hour (local, 24h) when awards present. Must match the app's
// awardPresentationHour in stats_controller.dart.
const AWARD_HOUR = 18;

// Character-voiced award titles per subject icon - mirrors
// characterAwardTitles in awards_controller.dart so the push reads the same
// as the card the winner will see.
const AWARD_TITLES = {
  dog: "Best Human 🩵",
  cat: "Least Disappointing Human",
  plant: "Greenest Thumb",
  bin: "Lord of the Kerb",
  fish: "Keeper of the Tank",
  generic: "Star Helper",
};
const titleFor = (icon) => AWARD_TITLES[icon] || AWARD_TITLES.generic;

/// Unique top scorer of a userId->count map, or null on a tie / no entries
/// / all-zero. Mirrors _uniqueMax in awards_controller.dart.
function uniqueMax(tallies) {
  let bestUser = null;
  let best = 0;
  let tied = false;
  for (const [userId, value] of tallies) {
    if (value > best) {
      best = value;
      bestUser = userId;
      tied = false;
    } else if (value === best && value > 0) {
      tied = true;
    }
  }
  if (!bestUser || best === 0 || tied) return null;
  return bestUser;
}

function startAwardCron({ pbUrl, identity, password, sendPush }) {
  let token = null;
  let householdsCache = { at: 0, byZone: {} };
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

  /// Every record across a paginated list endpoint (PB caps perPage at 500).
  async function pbList(pathBase) {
    const out = [];
    let page = 1;
    for (;;) {
      const sep = pathBase.includes("?") ? "&" : "?";
      const data = await pbGet(`${pathBase}${sep}perPage=500&page=${page}`);
      const items = data.items || [];
      out.push(...items);
      if (items.length < 500 || page >= (data.totalPages || page)) break;
      page += 1;
    }
    return out;
  }

  /// Household ids grouped by timezone (empty -> default). Cached; the set
  /// changes about never.
  async function householdsByZone() {
    if (Date.now() - householdsCache.at < HOUSEHOLDS_CACHE_MS) {
      return householdsCache.byZone;
    }
    const items = await pbList(`/api/collections/households/records?fields=id,timezone`);
    const byZone = {};
    for (const h of items) {
      const tz = h.timezone || DEFAULT_TZ;
      (byZone[tz] = byZone[tz] || []).push(h.id);
    }
    householdsCache = { at: Date.now(), byZone };
    const fingerprint = Object.keys(byZone).sort().join(",");
    if (fingerprint !== lastLoggedTimezones) {
      console.log("[awards] polling timezones:", Object.keys(byZone));
      lastLoggedTimezones = fingerprint;
    }
    return byZone;
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
    const get = (t) => parts.find((p) => p.type === t)?.value;
    return {
      weekday: WEEKDAY[get("weekday")] ?? -1,
      // Some engines render midnight as "24" with hour12:false.
      hour: Number(get("hour")) % 24,
      minute: Number(get("minute")),
      second: Number(get("second")),
    };
  }

  /// PB datetime literal (UTC) for an epoch-ms instant.
  const pbDate = (ms) => new Date(ms).toISOString().replace("T", " ");

  /// Settle one household's award week and push to its winners.
  async function presentHousehold(hid, startLit, endLit) {
    const subjects = await pbList(
      `/api/collections/subjects/records?filter=${encodeURIComponent(
        `household = '${hid}'`
      )}&fields=id,name,icon`
    );
    if (!subjects.length) return;

    const completions = await pbList(
      `/api/collections/completions/records?filter=${encodeURIComponent(
        `subject.household = '${hid}' && completed_at >= "${startLit}" && completed_at < "${endLit}"`
      )}&fields=subject,completed_by`
    );
    if (!completions.length) return;

    // subjectId -> (userId -> count). Unattributed completions don't count.
    const bySubject = new Map();
    for (const c of completions) {
      const uid = c.completed_by;
      if (!uid) continue;
      let m = bySubject.get(c.subject);
      if (!m) {
        m = new Map();
        bySubject.set(c.subject, m);
      }
      m.set(uid, (m.get(uid) || 0) + 1);
    }

    // userId -> [{ subjectName, title }] of the awards they won.
    const wins = new Map();
    for (const s of subjects) {
      const winner = uniqueMax(bySubject.get(s.id) || new Map());
      if (!winner) continue;
      const list = wins.get(winner) || [];
      list.push({ subjectName: s.name, title: titleFor(s.icon) });
      wins.set(winner, list);
    }
    if (!wins.size) return;

    const members = await pbList(
      `/api/collections/household_members/records?filter=${encodeURIComponent(
        `household = '${hid}'`
      )}&expand=user`
    );
    const tokenByUser = {};
    for (const m of members) {
      const u = m.expand?.user;
      if (u?.fcm_token) tokenByUser[m.user] = u.fcm_token;
    }

    for (const [userId, awards] of wins) {
      const tkn = tokenByUser[userId];
      if (!tkn) {
        console.log(`[awards] ${hid} winner ${userId} has no fcm_token - skip`);
        continue;
      }
      const first = awards[0];
      const single = awards.length === 1;
      const title = single ? "🏆 You won an award!" : `🏆 You won ${awards.length} awards!`;
      const body = single
        ? `${first.subjectName} crowned you their ${first.title} for last week!`
        : `You won ${awards.length} awards last week - open to see who crowned you!`;
      try {
        const result = await sendPush({
          tokens: [tkn],
          title,
          body,
          data: { type: "award" },
        });
        console.log(`[awards] ${hid} -> ${userId} (${awards.length} award(s)):`, result);
      } catch (err) {
        console.error(`[awards] ${hid} push to ${userId} failed:`, err.message);
      }
    }
  }

  async function tick() {
    if (running) return; // never overlap slow ticks
    running = true;
    try {
      // The minute that just finished - the :05-past tick at 18:01 checks
      // 18:00, so each Sunday cutoff fires exactly once.
      const target = new Date(Date.now() - 60 * 1000);
      const byZone = await householdsByZone();
      for (const [tz, hids] of Object.entries(byZone)) {
        try {
          const p = zonedParts(target, tz);
          if (p.weekday !== WEEKDAY.Sun || p.hour !== AWARD_HOUR || p.minute !== 0) {
            continue;
          }
          // The cutoff instant (AWARD_HOUR:00:00 local) as a UTC epoch -
          // roll `target` back by its own seconds within the minute. The
          // window start is exactly seven days (absolute) earlier, matching
          // the app's settledAward (both subtract a flat 7 days).
          const endMs = target.getTime() - p.second * 1000;
          const startLit = pbDate(endMs - WEEK_MS);
          const endLit = pbDate(endMs);
          console.log(
            `[awards] ${tz} presenting week ${startLit} -> ${endLit} for ${hids.length} household(s)`
          );
          for (const hid of hids) {
            try {
              await presentHousehold(hid, startLit, endLit);
            } catch (err) {
              console.error("[awards] household", hid, "error:", err.message);
            }
          }
        } catch (err) {
          console.error("[awards] zone", tz, "error:", err.message);
        }
      }
    } catch (err) {
      console.error("[awards] tick error:", err.message);
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
  console.log(`[awards] cron armed (presents Sun ${AWARD_HOUR}:00, default tz: ${DEFAULT_TZ})`);
}

module.exports = { startAwardCron };
