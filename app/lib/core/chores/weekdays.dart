/// Weekday bitmask helpers. Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32,
/// Sun=64 - matching `1 << (DateTime.weekday - 1)`.
class Weekdays {
  Weekdays._();

  static const mon = 1;
  static const tue = 2;
  static const wed = 4;
  static const thu = 8;
  static const fri = 16;
  static const sat = 32;
  static const sun = 64;
  static const all = mon | tue | wed | thu | fri | sat | sun;

  /// Bit for a given calendar day's weekday.
  static int bitFor(DateTime day) => 1 << (day.weekday - 1);

  /// True if [mask] includes [day]'s weekday.
  static bool contains(int mask, DateTime day) => (mask & bitFor(day)) != 0;

  // Weekday display names come from `schedule_labels.dart`
  // (weekdayShort / weekdayFull) - they're locale-aware.
  static const bits = [mon, tue, wed, thu, fri, sat, sun];
}
