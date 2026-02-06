// dart
// File: 'lib/services/csv_parser.dart'
import '../models/interval.dart';

class CsvParser {
  List<Interval> parse(String content) {
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    // Detect 3-row (date,start,end) sheet-like format
    final firstCells = _splitCsvLine(lines[0]);
    if (lines.length == 3 && firstCells.length > 1) {
      final dates = firstCells.map((c) => c.trim()).toList();
      final starts = _splitCsvLine(lines[1]).map((c) => c.trim()).toList();
      final ends = _splitCsvLine(lines[2]).map((c) => c.trim()).toList();

      final count = [dates.length, starts.length, ends.length].reduce((a, b) => a < b ? a : b);
      final intervals = <Interval>[];
      for (var i = 0; i < count; i++) {
        final date = dates[i].isEmpty ? 'col_${i + 1}' : dates[i];
        final start = _parseHhMm(starts[i]);
        final end = _parseHhMm(ends[i]);
        if (start == null || end == null) continue;

        final minutes = _diffMinutesAcrossMidnight(start, end);
        if (minutes <= 0) continue;

        intervals.add(Interval(date, minutes.toDouble()));
      }
      return intervals;
    }

    // Fallback: row-per-shift formats (existing behavior)
    final intervals = <Interval>[];
    int startIdx = 0;
    if (lines.isNotEmpty) {
      final headerCells = firstCells.map((p) => p.trim().toLowerCase()).toList();
      final looksLikeHeader = headerCells.any((c) => c == 'date' || c == 'time' || c.contains('start') || c.contains('end'));
      if (looksLikeHeader) startIdx = 1;
    }

    for (var i = startIdx; i < lines.length; i++) {
      final cells = _splitCsvLine(lines[i]).map((p) => p.trim()).toList();

      String? date;
      String? startStr;
      String? endStr;

      if (cells.length >= 3) {
        date = cells[0];
        startStr = cells[1];
        endStr = cells[2];
      } else if (cells.length == 2) {
        date = cells[0];
        final pair = _splitTimePair(cells[1]);
        startStr = pair.$1;
        endStr = pair.$2;
      } else if (cells.length == 1) {
        final pair = _splitTimePair(cells[0]);
        startStr = pair.$1;
        endStr = pair.$2;
      } else {
        continue;
      }

      if (startStr == null || endStr == null) continue;

      final start = _parseHhMm(startStr);
      final end = _parseHhMm(endStr);
      if (start == null || end == null) continue;

      final minutes = _diffMinutesAcrossMidnight(start, end);
      if (minutes <= 0) continue;

      final dateKey = (date == null || date.isEmpty) ? 'row_${i - startIdx + 1}' : date;
      intervals.add(Interval(dateKey, minutes.toDouble()));
    }
    return intervals;
  }

  // Calculates duration, supporting overnight (end < start) by wrapping across midnight.
  int _diffMinutesAcrossMidnight(int startMinutes, int endMinutes) {
    return endMinutes >= startMinutes
        ? (endMinutes - startMinutes)
        : ((24 * 60 - startMinutes) + endMinutes);
  }

  List<String> _splitCsvLine(String line) => line.split(',').map((p) => p.trim()).toList();

  (String?, String?) _splitTimePair(String cell) {
    final parts = cell.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length != 2) return (null, null);
    return (parts[0], parts[1]);
  }

  int? _parseHhMm(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h < 0 || h > 23 || min < 0 || min > 59) return null;
    return h * 60 + min;
  }
}
