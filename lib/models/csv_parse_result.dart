import '../models/interval.dart';

class CsvParseResult {
  final List<Interval> intervals;
  final int absenceCount;
  final List<String> absenceDates; // NEW: dates/keys that were absent

  const CsvParseResult({
    required this.intervals,
    required this.absenceCount,
    this.absenceDates = const [],
  });
}