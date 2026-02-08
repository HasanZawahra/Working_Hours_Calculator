// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Working Hours Calculator';

  @override
  String get selectCsv => 'Select CSV';

  @override
  String selectedCsv(Object file) {
    return 'Selected: $file';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get salaryPerMonth => 'Salary per month';

  @override
  String get workingDaysPerMonth => 'Working days per month';

  @override
  String get hoursPerShift => 'Hours per shift (normal working hours)';

  @override
  String get overtimePayPerHour => 'Overtime pay per hour';

  @override
  String get useOvertimeRate => 'Use overtime rate';

  @override
  String get calculate => 'Calculate';

  @override
  String get normalHours => 'Normal hours';

  @override
  String get overtimeHours => 'Overtime hours';

  @override
  String get normalPay => 'Normal pay';

  @override
  String get overtimePay => 'Overtime pay';

  @override
  String get totalPay => 'Total pay';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';

  @override
  String get pleaseSelectCsv => 'Please select a CSV file.';

  @override
  String get invalidNumbers => 'Please enter valid numeric values.';

  @override
  String get negativeValue => 'Please enter non-negative values.';

  @override
  String get reportTitle => 'Working Hours Report';

  @override
  String get csvLabel => 'CSV';

  @override
  String get perDayBreakdown => 'Per-day breakdown:';

  @override
  String get workingDaysMonth => 'Working days/month';

  @override
  String get hoursPerShiftNormal => 'Hours per shift (normal)';

  @override
  String useOvertimeRateYesNo(Object yesNo) {
    return 'Use overtime rate: $yesNo';
  }

  @override
  String get overtimeRateLabel => 'Overtime pay rate';

  @override
  String get overtimeMerged => 'Overtime merged into normal pay';

  @override
  String get close => 'Close';

  @override
  String get toggleLanguage => 'Arabic';

  @override
  String get totalHours => 'Total hours';

  @override
  String get normalHourlyPayRate => 'Normal hourly pay rate';

  @override
  String get invalidWorkingDaysNumbers =>
      'Please enter valid numeric values for working days.';

  @override
  String get invalidHoursPerShiftNumbers =>
      'Please enter valid numeric values for hours per shift.';

  @override
  String get absences => 'Absences';

  @override
  String get downloadReport => 'Download report';

  @override
  String get date => 'Date';

  @override
  String get hours => 'Hours';

  @override
  String get hourlyRates => 'Hourly rates';

  @override
  String get pay => 'Pay';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get fileName => 'File name';

  @override
  String get enter => 'Enter';
}
