import 'dart:math';

import 'character.dart';

/// How the subject is doing today. Drives both the friendly status line
/// under the character hero AND the character's facial expression. Mood
/// detection lives in `subject_detail_screen.dart::_moodFor`.
///
/// Priority on collision (highest wins): overdue > upcoming > happyForNow.
/// `allDone` and `none` are checked before any pending-vs-time logic.
enum SubjectMood {
  /// No chores due today at all.
  none,

  /// Every chore due today is logged.
  allDone,

  /// At least one unlogged chore is past its scheduled time.
  overdue,

  /// At least one unlogged chore is due within the next 60 minutes
  /// (and none is overdue).
  upcoming,

  /// Chores still pending today, all >60 minutes away, none overdue.
  happyForNow,
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
    SubjectMood.overdue: [
      '{name} is giving you the eyes 👀',
      'Tail wags pending. Get to it!',
      '{name} keeps checking the bowl…',
    ],
    SubjectMood.upcoming: [
      '{name} just heard the cupboard open 🐾',
      'Tail wags incoming — {name} can feel it.',
      '{name} is sitting nicely by the bowl.',
    ],
    SubjectMood.happyForNow: [
      '{name} is having a chilled one. All good.',
      'Tail at half-mast — {name} is content.',
      '{name} is on the rug, dreaming of dinner.',
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
    SubjectMood.overdue: [
      '{name} is judging you from the couch.',
      'You forgot something. {name} is sure of it.',
      'The bowl is empty. {name} is making it known.',
    ],
    SubjectMood.upcoming: [
      '{name} is on the counter. Coincidence?',
      '{name} appeared in the kitchen at exactly the right moment.',
      'Tail flicking. {name} senses food approaching.',
    ],
    SubjectMood.happyForNow: [
      '{name} is loafing peacefully. All is well.',
      'No emergencies. {name} is purring softly.',
      '{name} is asleep in the patch of sun.',
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
    SubjectMood.overdue: [
      '{name} is looking a bit thirsty.',
      'Leaves are drooping. {name} needs a hand.',
    ],
    SubjectMood.upcoming: [
      '{name} senses the watering can nearby 🌱',
      '{name} is leaning toward the tap.',
    ],
    SubjectMood.happyForNow: [
      '{name} is photosynthesising in peace.',
      'Leaves up, vibes good. {name} is fine.',
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
    SubjectMood.overdue: [
      '{name} is overflowing… it\'s time.',
      'Collection day looms. {name} is nervous.',
    ],
    SubjectMood.upcoming: [
      'Truck inbound. {name} is rolling itself to the kerb.',
      '{name} is mentally preparing.',
    ],
    SubjectMood.happyForNow: [
      '{name} is having a quiet sit-down. No rush.',
      'Lid closed, vibes calm. {name} waits.',
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
    SubjectMood.overdue: [
      '{name} is at the surface, expectant.',
      'Feeding time! {name} is watching.',
    ],
    SubjectMood.upcoming: [
      '{name} is hovering near the top, just in case.',
      'Fins flicking. {name} senses food.',
    ],
    SubjectMood.happyForNow: [
      '{name} is doing slow laps. All chill.',
      'Bubbles drifting. {name} is fine.',
    ],
    SubjectMood.none: [
      'A quiet day in the tank for {name}.',
    ],
  },
  'generic': {
    SubjectMood.allDone: [
      '{name} is happy and looked after! 🎉',
      'All done for {name} today. Nice work.',
    ],
    SubjectMood.overdue: [
      '{name} is waiting on you…',
      'Bits left to do for {name}.',
    ],
    SubjectMood.upcoming: [
      'Coming up soon for {name}.',
      '{name} has something on the schedule shortly.',
    ],
    SubjectMood.happyForNow: [
      '{name} is fine for now — later today.',
      'All good with {name} at the moment.',
    ],
    SubjectMood.none: [
      'Nothing on {name}\'s list today.',
    ],
  },
};
