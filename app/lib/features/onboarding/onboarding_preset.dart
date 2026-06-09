import '../../core/chores/schedule_rule.dart';
import '../../core/chores/weekdays.dart';

/// A pre-baked chore template the onboarding flow can offer instead of
/// dropping the user into the full edit-chore screen. Each preset is a
/// friendly label plus the shape needed to call `createChore`.
class OnboardingPreset {
  final String label;
  final String choreName;
  final ScheduleType scheduleType;
  final int hour;
  final int minute;
  final int weekdayMask;

  const OnboardingPreset({
    required this.label,
    required this.choreName,
    required this.scheduleType,
    required this.hour,
    required this.minute,
    required this.weekdayMask,
  });

  static const List<OnboardingPreset> all = [
    OnboardingPreset(
      label: 'Twice a day',
      choreName: 'Feed',
      scheduleType: ScheduleType.daily,
      hour: 8,
      minute: 0,
      weekdayMask: Weekdays.all,
    ),
    OnboardingPreset(
      label: 'Once a day',
      choreName: 'Look after',
      scheduleType: ScheduleType.daily,
      hour: 8,
      minute: 0,
      weekdayMask: Weekdays.all,
    ),
    OnboardingPreset(
      label: 'Every other day',
      choreName: 'Check in',
      scheduleType: ScheduleType.weekly,
      hour: 9,
      minute: 0,
      weekdayMask:
          Weekdays.mon | Weekdays.wed | Weekdays.fri | Weekdays.sun,
    ),
    OnboardingPreset(
      label: 'Once a week',
      choreName: 'Take care of',
      scheduleType: ScheduleType.weekly,
      hour: 9,
      minute: 0,
      weekdayMask: Weekdays.mon,
    ),
  ];
}
