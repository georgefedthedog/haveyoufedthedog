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
// Shared PB-client / timezone / scheduler plumbing lives in pb-cron.js;
// what's here is award-specific (the settle window, the unique-winner tally,
// and the per-winner push).

const { DEFAULT_TZ, WEEK_MS, WEEKDAY, createPbClient, zonedParts, makeHouseholdsByZone, everyMinute } = require("./pb-cron");
const { t } = require("./l10n");

// Sunday hour (local, 24h) when awards present. Must match the app's
// awardPresentationHour in stats_controller.dart.
const AWARD_HOUR = 18;

// The push intentionally does NOT name the award - the title lives only in
// the app (and is customizable per pack character via catalog_characters.
// messages), so the notification just says who has an award and lets the
// winner tap through to see it.

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
  const pb = createPbClient({ pbUrl, identity, password });
  const householdsByZone = makeHouseholdsByZone(pb, "[awards]");

  /// PB datetime literal (UTC) for an epoch-ms instant.
  const pbDate = ms => new Date(ms).toISOString().replace("T", " ");

  /// Settle one household's award week and push to its winners.
  async function presentHousehold(hid, startLit, endLit) {
    const subjects = await pb.list(`/api/collections/subjects/records?filter=${encodeURIComponent(`household = '${hid}'`)}&fields=id,name,icon`);
    if (!subjects.length) return;

    const completions = await pb.list(
      `/api/collections/completions/records?filter=${encodeURIComponent(
        `subject.household = '${hid}' && completed_at >= "${startLit}" && completed_at < "${endLit}"`,
      )}&fields=subject,completed_by`,
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

    // userId -> [{ subjectName }] of the awards they won.
    const wins = new Map();
    for (const s of subjects) {
      const winner = uniqueMax(bySubject.get(s.id) || new Map());
      if (!winner) continue;
      const list = wins.get(winner) || [];
      list.push({ subjectName: s.name });
      wins.set(winner, list);
    }
    if (!wins.size) return;

    const members = await pb.list(`/api/collections/household_members/records?filter=${encodeURIComponent(`household = '${hid}'`)}&expand=user`);
    // Winner pushes are per-user, so each one renders in that user's own
    // language (users.locale; empty = en keeps today's English strings).
    const tokenByUser = {};
    for (const m of members) {
      const u = m.expand?.user;
      if (u?.fcm_token) tokenByUser[m.user] = { token: u.fcm_token, locale: u.locale || "" };
    }

    for (const [userId, awards] of wins) {
      const rec = tokenByUser[userId];
      if (!rec) {
        console.log(`[awards] ${hid} winner ${userId} has no fcm_token - skip`);
        continue;
      }
      const first = awards[0];
      const single = awards.length === 1;
      const title = single ? t(rec.locale, "awardSingleTitle") : t(rec.locale, "awardMultiTitle", { count: awards.length });
      const body = single ? t(rec.locale, "awardSingleBody", { subject: first.subjectName }) : t(rec.locale, "awardMultiBody", { count: awards.length });
      try {
        const result = await sendPush({
          tokens: [rec.token],
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

  everyMinute(async target => {
    const byZone = await householdsByZone();
    for (const [tz, hids] of Object.entries(byZone)) {
      try {
        const p = zonedParts(target, tz);
        if (p.weekday !== WEEKDAY.Sun || p.hour !== AWARD_HOUR || p.minute !== 0) {
          continue;
        }
        // The cutoff instant (AWARD_HOUR:00:00 local) as a UTC epoch - roll
        // `target` back by its own seconds within the minute. The window
        // start is exactly seven days (absolute) earlier, matching the
        // app's settledAward (both subtract a flat 7 days).
        const endMs = target.getTime() - p.second * 1000;
        const startLit = pbDate(endMs - WEEK_MS);
        const endLit = pbDate(endMs);
        console.log(`[awards] ${tz} presenting week ${startLit} -> ${endLit} for ${hids.length} household(s)`);
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
  });
  console.log(`[awards] cron armed (presents Sun ${AWARD_HOUR}:00, default tz: ${DEFAULT_TZ})`);
}

module.exports = { startAwardCron };
