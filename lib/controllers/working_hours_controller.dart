import 'dart:io';
import '../services/csv_parser.dart';
import '../services/calculator.dart';

class WorkingHoursState {
  final String? csvPath;
  final double normalMinutes;
  final double overtimeMinutes;
  final double normalHourlyRate;
  final double normalPay;
  final double overtimePay;
  final double totalPay;
  final List<MapEntry<String, double>> perDayHours;
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
    this.payOvertimeSeparately = true,
    this.absenceCount = 0,
  });

  WorkingHoursState copyWith({
    String? csvPath,
    double? normalMinutes,
    double? overtimeMinutes,
    double? normalHourlyRate,
    double? normalPay,
    double? overtimePay,
    double? totalPay,
    List<MapEntry<String, double>>? perDayHours,
    bool? payOvertimeSeparately,
    int? absenceCount,
  }) {
    return WorkingHoursState(
      csvPath: csvPath ?? this.csvPath,
      normalMinutes: normalMinutes ?? this.normalMinutes,
      overtimeMinutes: overtimeMinutes ?? this.overtimeMinutes,
      normalHourlyRate: normalHourlyRate ?? this.normalHourlyRate,
      normalPay: normalPay ?? this.normalPay,
      overtimePay: overtimePay ?? this.overtimePay,
      totalPay: totalPay ?? this.totalPay,
      perDayHours: perDayHours ?? this.perDayHours,
      payOvertimeSeparately: payOvertimeSeparately ?? this.payOvertimeSeparately,
      absenceCount: absenceCount ?? this.absenceCount,
    );
  }
}

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
      final formats = [
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$'),
        RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'),
        RegExp(r'^(\d{2})-(\d{2})-(\d{4})$'),
        RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$'),
        RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$'),
      ];
      for (final r in formats) {
        final m = r.firstMatch(s);
        if (m != null) {
          int y, mo, d;
          if (r.pattern.startsWith(r'^(\d{4})')) {
            y = int.parse(m.group(1)!);
            mo = int.parse(m.group(2)!);
            d = int.parse(m.group(3)!);
          } else if (r.pattern.contains('M/d')) {
            mo = int.parse(m.group(1)!);
            d = int.parse(m.group(2)!);
            final yy = int.parse(m.group(3)!);
            y = yy < 100 ? (2000 + yy) : yy;
          } else {
            d = int.parse(m.group(1)!);
            mo = int.parse(m.group(2)!);
            y = int.parse(m.group(3)!);
          }
          return DateTime(y, mo, d);
        }
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

    state = state.copyWith(
      normalMinutes: result.normalMinutes,
      overtimeMinutes: result.overtimeMinutes,
      normalHourlyRate: result.normalHourlyRate,
      normalPay: result.normalPay,
      overtimePay: result.overtimePay,
      totalPay: result.totalPay,
      perDayHours: perDay,
      absenceCount: parsed.absenceCount,
    );

    return state;
  }
}
