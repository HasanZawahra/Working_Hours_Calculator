// `lib/models/interval.dart`
// dart
class Interval {
  final String date;
  final String? start;
  final String? end;
  final double minutes;
  const Interval(
      this.date,
      this.minutes, {
        this.start,
        this.end,
      });
}
