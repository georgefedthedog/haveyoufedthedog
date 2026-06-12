/// Pushes FCM notifications to a household when a completion is logged
/// or removed. Receivers invalidate their local providers so chip / history
/// state catches up without a manual refresh.
///
/// The shared `notifyHousehold` logic lives in _notify_helper.js and is
/// `require`d inside each handler - PB runs each handler in its own fresh
/// Goja runtime, so file-level declarations don't carry over.

onRecordAfterCreateSuccess(e => {
  if (!e.record) return;
  const { notifyHousehold } = require(`${__hooks}/_notify_helper.js`);
  notifyHousehold(e.record, "created");
}, "completions");

onRecordAfterDeleteSuccess(e => {
  if (!e.record) return;
  const { notifyHousehold } = require(`${__hooks}/_notify_helper.js`);
  notifyHousehold(e.record, "undone");
}, "completions");
