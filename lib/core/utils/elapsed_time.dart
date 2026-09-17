/// Seconds elapsed between [start] and [now] (defaults to [DateTime.now]).
///
/// Computed from wall-clock time rather than counted ticks so the result is
/// correct even after a [Timer] has been throttled or missed ticks while the
/// app was backgrounded (e.g. the screen was turned off).
int elapsedSecondsSince(DateTime start, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(start).inSeconds;
  return diff < 0 ? 0 : diff;
}
