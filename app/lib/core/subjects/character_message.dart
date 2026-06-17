import 'dart:math';

import 'character.dart';

/// How the subject is doing today. Drives both the friendly status line
/// under the character hero AND the character's facial expression. Mood
/// detection lives in `subject_mood_controller.dart::subjectMood`.
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

/// One status line for the subject hero: a punchy [title] statement and a
/// quieter [body] subtext underneath.
typedef CharacterLine = ({String title, String body});

/// Returns a personality-flavoured (title, body) pair for the given
/// character at the given mood. Multiple variants per (character × mood)
/// cell - picks one randomly so repeat visits don't feel scripted.
///
/// Substitutes `{name}` with [subjectName] in both parts.
CharacterLine characterLine({
  required Character character,
  required SubjectMood mood,
  required String subjectName,
}) {
  // Per-slot override: a pack character's custom lines for this mood win,
  // else the bundled table for this character, else the generic table.
  final lines =
      character.messages?.lines[mood.name] ??
      _table[character.id]?[mood] ??
      _table['generic']![mood] ??
      const <CharacterLine>[(title: '{name}', body: 'Doing fine.')];
  final pick = lines[_rand.nextInt(lines.length)];
  return (
    title: pick.title.replaceAll('{name}', subjectName),
    body: pick.body.replaceAll('{name}', subjectName),
  );
}

final _rand = Random();

/// (character.id → mood → candidate lines). Titles are short, punchy
/// statements; bodies are quieter one-liners underneath.
const Map<String, Map<SubjectMood, List<CharacterLine>>> _table = {
  'dog': {
    SubjectMood.allDone: [
      (title: 'Full, happy, snoozing.', body: '{name} had a great day 🐶'),
      (
        title: 'Belly rubs were earned.',
        body: 'Good job looking after {name}.',
      ),
      (title: 'Best human ever.', body: "That's what {name} thinks of you 🩵"),
    ],
    SubjectMood.overdue: [
      (title: 'Tail wags pending.', body: 'Get to it! 🐾'),
      (title: "You're getting the eyes.", body: '{name} is staring at you 👀'),
      (title: 'The bowl is empty.', body: '{name} keeps checking it…'),
    ],
    SubjectMood.upcoming: [
      (title: 'Ears up!', body: '{name} just heard the cupboard open 🐾'),
      (title: 'Tail wags incoming.', body: '{name} can feel it.'),
      (title: 'Sitting nicely.', body: '{name} is waiting by the bowl.'),
    ],
    SubjectMood.happyForNow: [
      (title: 'All chill.', body: '{name} is having a relaxed one.'),
      (title: 'Tail at half-mast.', body: '{name} is content for now.'),
      (title: 'Dreaming of dinner.', body: '{name} is curled up on the rug.'),
    ],
    SubjectMood.none: [
      (title: 'Day off!', body: '{name} approves 🐶'),
      (title: 'Do not disturb.', body: '{name} is napping on the rug.'),
    ],
  },
  'cat': {
    SubjectMood.allDone: [
      (title: 'Unimpressed but well fed.', body: '{name} will allow it 🐱'),
      (title: 'Acknowledged.', body: '{name} will tolerate you today.'),
      (title: 'Purring. Slightly.', body: 'High praise from {name}.'),
    ],
    SubjectMood.overdue: [
      (title: 'You are being judged.', body: '{name} watches from the couch.'),
      (title: 'You forgot something.', body: '{name} is sure of it.'),
      (title: 'The bowl is empty.', body: '{name} is making it known.'),
    ],
    SubjectMood.upcoming: [
      (
        title: 'On the counter. Waiting.',
        body: 'Coincidence? {name} thinks not.',
      ),
      (
        title: 'Perfect timing.',
        body: '{name} appeared in the kitchen just now.',
      ),
      (title: 'Tail flicking.', body: '{name} senses food approaching.'),
    ],
    SubjectMood.happyForNow: [
      (title: 'Loafing peacefully.', body: 'All is well with {name}.'),
      (title: 'No emergencies.', body: '{name} is purring softly.'),
      (title: 'Sun patch secured.', body: '{name} is asleep in it.'),
    ],
    SubjectMood.none: [
      (title: 'Not required today.', body: '{name} dismisses you. Carry on.'),
      (title: 'A day of rest.', body: '{name} approves silently.'),
    ],
  },
  'plant': {
    SubjectMood.allDone: [
      (title: 'Thriving.', body: '{name} is loving life 🌿'),
      (title: 'Leaves are perky.', body: '{name} is watered and happy.'),
      (title: 'Growth spurt incoming.', body: '{name} feels faster already.'),
    ],
    SubjectMood.overdue: [
      (title: 'Feeling thirsty.', body: '{name} could use a drink.'),
      (title: 'Leaves are drooping.', body: '{name} needs a hand.'),
    ],
    SubjectMood.upcoming: [
      (
        title: 'Something in the air.',
        body: '{name} senses the watering can 🌱',
      ),
      (title: 'Leaning toward the tap.', body: '{name} is ready when you are.'),
    ],
    SubjectMood.happyForNow: [
      (title: 'Photosynthesising in peace.', body: 'No fuss from {name}.'),
      (title: 'Leaves up, vibes good.', body: '{name} is doing fine.'),
    ],
    SubjectMood.none: [
      (title: 'No watering today.', body: '{name} is content.'),
    ],
  },
  'bin': {
    SubjectMood.allDone: [
      (title: 'Empty and proud.', body: '{name} salutes you 🗑️'),
      (title: 'Out on time.', body: 'World saved, bins out.'),
    ],
    SubjectMood.overdue: [
      (title: "It's time.", body: '{name} is overflowing…'),
      (title: 'Collection day looms.', body: '{name} is getting nervous.'),
    ],
    SubjectMood.upcoming: [
      (title: 'Truck inbound.', body: '{name} is rolling to the kerb.'),
      (title: 'Mentally preparing.', body: '{name} knows what\'s coming.'),
    ],
    SubjectMood.happyForNow: [
      (title: 'Quiet sit-down.', body: 'No rush for {name} today.'),
      (title: 'Lid closed, vibes calm.', body: '{name} waits patiently.'),
    ],
    SubjectMood.none: [
      (title: 'No collection today.', body: '{name} naps by the gate.'),
    ],
  },
  'fish': {
    SubjectMood.allDone: [
      (title: 'Gliding around, well fed.', body: '{name} blubs in approval 🐟'),
      (title: 'Tank life is good.', body: '{name} is doing happy laps.'),
    ],
    SubjectMood.overdue: [
      (title: 'At the surface. Expectant.', body: '{name} is watching you.'),
      (title: 'Feeding time!', body: '{name} has noticed the delay.'),
    ],
    SubjectMood.upcoming: [
      (title: 'Hovering near the top.', body: 'Just in case. {name} is ready.'),
      (title: 'Fins flicking.', body: '{name} senses food.'),
    ],
    SubjectMood.happyForNow: [
      (title: 'Slow laps.', body: '{name} is all chill.'),
      (title: 'Bubbles drifting.', body: '{name} is doing fine.'),
    ],
    SubjectMood.none: [
      (title: 'A quiet day in the tank.', body: 'Nothing on for {name}.'),
    ],
  },
  'generic': {
    SubjectMood.allDone: [
      (title: 'All done!', body: '{name} is happy and looked after 🎉'),
      (title: 'Nice work.', body: 'Everything done for {name} today.'),
    ],
    SubjectMood.overdue: [
      (title: 'Waiting on you…', body: '{name} has bits left to do.'),
      (title: 'Still outstanding.', body: '{name} needs a hand.'),
    ],
    SubjectMood.upcoming: [
      (title: 'Coming up soon.', body: '{name} has something on the schedule.'),
      (title: 'Nearly time.', body: 'Something shortly for {name}.'),
    ],
    SubjectMood.happyForNow: [
      (title: 'Fine for now.', body: '{name} has things later today.'),
      (title: 'All good.', body: 'Nothing urgent for {name}.'),
    ],
    SubjectMood.none: [
      (title: 'Nothing on the list.', body: 'A free day for {name}.'),
    ],
  },
};
