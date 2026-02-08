import 'dart:io';
import '../services/csv_parser.dart';
import '../services/calculator.dart';
import '../models/work_day_row.dart';

// dart
class WorkingHoursState {
  final String? csvPath;
  final double normalMinutes;
  final double overtimeMinutes;
  final double normalHourlyRate;
  final double normalPay;
  final double overtimePay;
  final double totalPay;
  final List<MapEntry<String, double>> perDayHours;
  final List<WorkDayRow> workDayRows; // NEW: detailed rows for the report
  final bool payOvertimeSeparately;
  final int absenceCount;

  const WorkingHoursState({
    this.csvPath,
    this.normalMinutes = 0,
    this.overtimeMinutes = 0,
    this.normalHourlyRate = 0,
    this.normalPay = 0,
    this.overtimePay = 0,
    this.totalPay = 0,
    this.perDayHours = const [],
    this.workDayRows = const [],
    this.payOvertimeSeparately = true,
    this.absenceCount = 0,
  });

  WorkingHoursState copyWith({
    Object? csvPath = _noValue,
    double? normalMinutes,
    double? overtimeMinutes,
    double? normalHourlyRate,
    double? normalPay,
    double? overtimePay,
    double? totalPay,
    List<MapEntry<String, double>>? perDayHours,
    List<WorkDayRow>? workDayRows,
    bool? payOvertimeSeparately,
    int? absenceCount,
  }) {
    return WorkingHoursState(
      csvPath: identical(csvPath, _noValue) ? this.csvPath : csvPath as String?,
      normalMinutes: normalMinutes ?? this.normalMinutes,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      normalHourlyRate: normalHourlyRate ?? this.normalHourlyRate,
      normalPay: normalPay ?? this.normalPay,
      overtimePay: overtimePay ?? this.overtimePay,
      totalPay: totalPay ?? this.totalPay,
      perDayHours: perDayHours ?? this.perDayHours,
      workDayRows: workDayRows ?? this.workDayRows,
      payOvertimeSeparately: payOvertimeSeparately ?? this.payOvertimeSeparately,
      absenceCount: absenceCount ?? this.absenceCount,
    );
  }
}

const _noValue = Object();

class WorkingHoursController {
  final _parser = CsvParser();
  final _calculator = Calculator();

  WorkingHoursState state = const WorkingHoursState();

  void setCsvPath(String? path) {
    state = state.copyWith(csvPath: path);
  }

  void setOvertimeSeparately(bool v) {
    state = state.copyWith(payOvertimeSeparately: v);
  }

  Future<WorkingHoursState> compute({
    required double salary,
    required double workingDays,
    required double hoursPerShift,
    required double overtimeRate,
  }) async {
    if (state.csvPath == null) {
      throw StateError('CSV path is null');
    }
    final content = await File(state.csvPath!).readAsString();
    final parsed = _parser.parse(content);

    final result = _calculator.compute(
      intervals: parsed.intervals,
      salary: salary,
      workingDays: workingDays,
      hoursPerShift: hoursPerShift,
      overtimeRate: overtimeRate,
      payOvertimeSeparately: state.payOvertimeSeparately,
    );

    DateTime? _tryParseDate(String s) {
      final v = s.trim();
      if (v.isEmpty) return null;

      // 2026-01-31
      final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
      if (iso != null) {
        final y = int.parse(iso.group(1)!);
        final mo = int.parse(iso.group(2)!);
        final d = int.parse(iso.group(3)!);
        return DateTime(y, mo, d);
      }

      // 1/31/2026 or 01/31/2026 (M/d/yyyy)  <-- your case
      final mdy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(v);
      if (mdy != null) {
        final mo = int.parse(mdy.group(1)!);
        final d = int.parse(mdy.group(2)!);
        final y = int.parse(mdy.group(3)!);
        return DateTime(y, mo, d);
      }

      // 31/01/2026 (d/M/yyyy)
      final dmySlashes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(v);
      if (dmySlashes != null) {
        final d = int.parse(dmySlashes.group(1)!);
        final mo = int.parse(dmySlashes.group(2)!);
        final y = int.parse(dmySlashes.group(3)!);
        return DateTime(y, mo, d);
      }

      // 31-01-2026 (d-M-yyyy)
      final dmyDashes = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(v);
      if (dmyDashes != null) {
        final d = int.parse(dmyDashes.group(1)!);
        final mo = int.parse(dmyDashes.group(2)!);
        final y = int.parse(dmyDashes.group(3)!);
        return DateTime(y, mo, d);
      }

      // 31.01.2026 (d.M.yyyy)
      final dmyDots = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(v);
      if (dmyDots != null) {
        final d = int.parse(dmyDots.group(1)!);
        final mo = int.parse(dmyDots.group(2)!);
        final y = int.parse(dmyDots.group(3)!);
        return DateTime(y, mo, d);
      }

      return null;
    }

    final perDay = result.perDayMinutes.entries
        .map((e) => MapEntry(e.key, (e.value / 60.0)))
        .toList()
      ..sort((a, b) {
        final da = _tryParseDate(a.key);
        final db = _tryParseDate(b.key);
        if (da != null && db != null) return da.compareTo(db);
        if (da != null) return -1;
        if (db != null) return 1;
        return a.key.compareTo(b.key);
      });

    // Build detailed rows (merge multiple intervals on same date if needed)
    final byDate = <String, _Agg>{};
    for (final i in parsed.intervals) {
      final key = i.date;
      final agg = byDate.putIfAbsent(key, () => _Agg(dateRaw: key, date: _tryParseDate(key)));
      agg.totalMinutes += i.minutes;

      if (i.start != null) agg.starts.add(i.start!);
      if (i.end != null) agg.ends.add(i.end!);
    }

    final workDayRows = byDate.values
        .map((a) => WorkDayRow(
              dateRaw: a.dateRaw,
              date: a.date,
              start: (a.starts.isEmpty) ? '-' : (a.starts..sort()).first,
              end: (a.ends.isEmpty) ? '-' : (a.ends..sort()).last,
              workedHours: a.totalMinutes / 60.0,
            ))
        .toList()
      ..sort((x, y) {
        if (x.date != null && y.date != null) return x.date!.compareTo(y.date!);
        if (x.date != null) return -1;
        if (y.date != null) return 1;
        return x.dateRaw.compareTo(y.dateRaw);
      });

    state = state.copyWith(
      normalMinutes: result.normalMinutes,
      overtimeMinutes: result.overtimeMinutes,
      normalHourlyRate: result.normalHourlyRate,
      normalPay: result.normalPay,
      overtimePay: result.overtimePay,
      totalPay: result.totalPay,
      perDayHours: perDay,
      workDayRows: workDayRows,
      absenceCount: parsed.absenceCount,
    );

    return state;
  }
}

class _Agg {
  final String dateRaw;
  final DateTime? date;
  double totalMinutes = 0;

  final List<String> starts = [];
  final List<String> ends = [];

  _Agg({required this.dateRaw, required this.date});
}
