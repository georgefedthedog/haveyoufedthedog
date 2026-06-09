import 'dart:math';

import 'character.dart';

/// How the subject is doing today, from the chip / completion math on the
/// subject detail screen. Drives the friendly line we show under the
/// character hero.
enum SubjectMood {
  /// At least one chore due today and they're all logged.
  allDone,

  /// Some chores due today still outstanding (none overdue past their
  /// scheduled time, or we just don't care about "overdue" vs "pending").
  pendingSome,

  /// No chores due today at all.
  none,
}

/// Returns a personality-flavoured one-liner for the given character at
/// the given mood. Multiple variants per (character × mood) cell — picks
/// one randomly so repeat visits to the same screen don't feel scripted.
///
/// Substitutes `{name}` with [subjectName].
String characterMessage({
  required Character character,
  required SubjectMood mood,
  required String subjectName,
}) {
  final table = _table[character.id] ?? _table['generic']!;
  final lines = table[mood] ?? const ['{name} is doing fine.'];
  final pick = lines[_rand.nextInt(lines.length)];
  return pick.replaceAll('{name}', subjectName);
}

final _rand = Random();

/// (character.id → mood → candidate lines). Lines are intentionally short
/// so they fit a single line of body copy on the subject hero.
const Map<String, Map<SubjectMood, List<String>>> _table = {
  'dog': {
    SubjectMood.allDone: [
      '{name} is full, happy and snoozing 🐶',
      'Belly rubs were earned. Good job.',
      '{name} thinks you\'re the best human ever 🩵',
    ],
    SubjectMood.pendingSome: [
      '{name} is giving you the eyes 👀',
      'Tail wags pending. Get to it!',
      '{name} keeps checking the bowl…',
    ],
    SubjectMood.none: [
      'Day off! {name} approves.',
      '{name} is napping on the rug.',
    ],
  },
  'cat': {
    SubjectMood.allDone: [
      '{name} is unimpressed but well fed 🐱',
      'Acknowledged. {name} will tolerate you today.',
      '{name} is purring (slightly).',
    ],
    SubjectMood.pendingSome: [
      '{name} is judging you from the couch.',
      'You forgot something. {name} is sure of it.',
      'The bowl is empty. {name} is making it known.',
    ],
    SubjectMood.none: [
      '{name} does not require your attention today. Carry on.',
      'A day of rest. {name} approves silently.',
    ],
  },
  'plant': {
    SubjectMood.allDone: [
      '{name} is thriving 🌿',
      'Watered and happy. Leaves are perky.',
      '{name} is growing faster already.',
    ],
    SubjectMood.pendingSome: [
      '{name} is looking a bit thirsty.',
      'Leaves are drooping. {name} needs a hand.',
    ],
    SubjectMood.none: [
      '{name} is content. No watering today.',
    ],
  },
  'bin': {
    SubjectMood.allDone: [
      '{name} is empty and proud 🗑️',
      'Out on time. {name} salutes you.',
      'Bins out, world saved.',
    ],
    SubjectMood.pendingSome: [
      '{name} is overflowing… it\'s time.',
      'Collection day looms. {name} is nervous.',
    ],
    SubjectMood.none: [
      'No collection today. {name} naps.',
    ],
  },
  'fish': {
    SubjectMood.allDone: [
      '{name} is gliding around, well fed 🐟',
      'Tank life is good. {name} blubs in approval.',
    ],
    SubjectMood.pendingSome: [
      '{name} is at the surface, expectant.',
      'Feeding time! {name} is watching.',
    ],
    SubjectMood.none: [
      'A quiet day in the tank for {name}.',
    ],
  },
  'child': {
    SubjectMood.allDone: [
      '{name} is sorted for today 🎒',
      'Lunchbox, teeth, shoes — all done. You\'re a hero.',
    ],
    SubjectMood.pendingSome: [
      '{name} still has things to do!',
      'Quick — bits left on {name}\'s list.',
    ],
    SubjectMood.none: [
      '{name} has a clear day. Enjoy it.',
    ],
  },
  'generic': {
    SubjectMood.allDone: [
      '{name} is happy and looked after! 🎉',
      'All done for {name} today. Nice work.',
    ],
    SubjectMood.pendingSome: [
      '{name} is waiting on you…',
      'Bits left to do for {name}.',
    ],
    SubjectMood.none: [
      'Nothing on {name}\'s list today.',
    ],
  },
};
