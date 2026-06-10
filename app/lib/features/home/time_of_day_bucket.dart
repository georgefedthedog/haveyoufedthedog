/// Time-of-day buckets used to pick the right household picture variant.
///
/// Each household picture has five PNG variants — one per bucket — living
/// at `assets/households/<id>/<name>.png`.
enum TimeOfDayBucket {
  morning,
  midday,
  afternoon,
  evening,
  night;

  /// Filename (without extension) used for the on-disk variant.
  String get fileName => name;
}

/// Picks the right bucket for the supplied local time. Buckets:
/// - **morning** 06–11
/// - **midday** 11–14
/// - **afternoon** 14–17
/// - **evening** 17–20
/// - **night** 20–06
TimeOfDayBucket bucketFor(DateTime t) {
  final h = t.hour;
  if (h < 6 || h >= 20) return TimeOfDayBucket.night;
  if (h < 11) return TimeOfDayBucket.morning;
  if (h < 14) return TimeOfDayBucket.midday;
  if (h < 17) return TimeOfDayBucket.afternoon;
  return TimeOfDayBucket.evening;
}
