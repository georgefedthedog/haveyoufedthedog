/// Fires after a completion is created and sends an FCM push notification
/// to all other household members via the local push-notifier service.
onRecordAfterCreateSuccess((e) => {
  const record = e.record;
  if (!record) return;

  const subjectId = record.get('subject');
  if (!subjectId) return;

  try {
    // Look up the subject to get the household.
    const subject = $app.findRecordById('subjects', subjectId);
    const householdId = subject.get('household');
    if (!householdId) return;

    // Who logged this?
    const completedById = record.get('completed_by');

    // Get all household members except the person who just logged.
    const members = $app.findAllRecords('household_members',
      $dbx.exp('household = {:hh}', { hh: householdId })
    );

    // Collect FCM tokens for all OTHER members.
    const tokens = [];
    for (const m of members) {
      const userId = m.get('user');
      if (!userId || userId === completedById) continue;
      try {
        const user = $app.findRecordById('_pb_users_auth_', userId);
        const token = user.get('fcm_token');
        if (token) tokens.push(token);
      } catch (_) {}
    }

    if (!tokens.length) return;

    // Build notification text.
    const choreName = (() => {
      try {
        const choreId = record.get('chore');
        if (!choreId) return null;
        const chore = $app.findRecordById('chores', choreId);
        return chore.get('name');
      } catch (_) { return null; }
    })();

    const subjectName = (() => {
      try { return subject.get('name'); } catch (_) { return 'Someone'; }
    })();

    const whoName = (() => {
      try {
        const user = $app.findRecordById('_pb_users_auth_', completedById);
        return user.get('name') || 'Someone';
      } catch (_) { return 'Someone'; }
    })();

    const title = subjectName;
    const body = choreName
      ? `${choreName} done by ${whoName}`
      : `${whoName} logged a completion`;

    // Call the local push-notifier service.
    const resp = $http.send({
      method: 'POST',
      url: 'http://127.0.0.1:3055/notify',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tokens, title, body }),
      timeout: 5,
    });

    if (resp.statusCode !== 200) {
      console.error('[notify hook] push-notifier returned', resp.statusCode, resp.raw);
    }
  } catch (err) {
    console.error('[notify hook] error:', err);
  }
}, 'completions');
