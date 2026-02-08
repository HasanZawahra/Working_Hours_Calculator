// dart
// File: `lib/services/calculator.dart`
import '../models/interval.dart';

class WorkCalcResult {
  final double normalMinutes;
  final double overtimeMinutes;
  final double normalHourlyRate;
  final double normalPay;
  final double overtimePay;
  final double totalPay;
  final Map<String, double> perDayMinutes;
  const WorkCalcResult({
    required this.normalMinutes,
    required this.overtimeMinutes,
    required this.normalHourlyRate,
    required this.normalPay,
    required this.overtimePay,
    required this.totalPay,
    required this.perDayMinutes,
  });
}

class Calculator {
  WorkCalcResult compute({
    required List<Interval> intervals,
    required double salary,
    required double workingDays,
    required double hoursPerShift,
    required double overtimeRate,
    required bool payOvertimeSeparately,
  }) {
    final byDate = <String, double>{};
    for (final i in intervals) {
      byDate.update(i.date, (v) => v + i.minutes, ifAbsent: () => i.minutes);
    }

    final normalPerDayMinutes = hoursPerShift * 60.0;
    double normalMinutes = 0;
    double overtimeMinutes = 0;

    for (final worked in byDate.values) {
      final normal = worked.clamp(0, normalPerDayMinutes);
      final overtime = (worked - normalPerDayMinutes).clamp(0, double.infinity);
      normalMinutes += normal;
      overtimeMinutes += overtime;
    }

    final normalHourlyRate = (salary / workingDays) / hoursPerShift;
    final normalHours = normalMinutes / 60.0;
    final overtimeHours = overtimeMinutes / 60.0;

    double normalPay;
    double overtimePay;

    if (payOvertimeSeparately && overtimeRate > 0) {
      normalPay = normalHours * normalHourlyRate;
      overtimePay = overtimeHours * overtimeRate;
    } else {
      normalPay = (normalHours + overtimeHours) * normalHourlyRate;
      overtimePay = 0.0;
    }

    final totalPay = normalPay + overtimePay;

    return WorkCalcResult(
      normalMinutes: normalMinutes,
      overtimeMinutes: overtimeMinutes,
      normalHourlyRate: normalHourlyRate,
      normalPay: normalPay,
      overtimePay: overtimePay,
      totalPay: totalPay,
      perDayMinutes: byDate,
    );
  }
}
