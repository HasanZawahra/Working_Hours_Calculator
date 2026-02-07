import '../models/interval.dart';

class CsvParseResult {
  final List<Interval> intervals;
  final int absenceCount;
  const CsvParseResult({
    required this.intervals,
    required this.absenceCount,
  });
}