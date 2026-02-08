// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حاسبة ساعات العمل';

  @override
  String get selectCsv => 'اختر ملف CSV';

  @override
  String selectedCsv(Object file) {
    return 'المحدد: $file';
  }

  @override
  String get clearSelection => 'إزالة التحديد';

  @override
  String get salaryPerMonth => 'الراتب الشهري';

  @override
  String get workingDaysPerMonth => 'أيام العمل شهرياً';

  @override
  String get hoursPerShift => 'ساعات الدوام (الساعات العادية)';

  @override
  String get overtimePayPerHour => 'أجرة الساعة الإضافية';

  @override
  String get useOvertimeRate => 'استخدام أجر الساعات الإضافية';

  @override
  String get calculate => 'احسب';

  @override
  String get normalHours => 'الساعات العادية';

  @override
  String get overtimeHours => 'ساعات إضافية';

  @override
  String get normalPay => 'الأجر العادي';

  @override
  String get overtimePay => 'أجر الساعات الإضافية';

  @override
  String get totalPay => 'الإجمالي';

  @override
  String get error => 'خطأ';

  @override
  String get ok => 'موافق';

  @override
  String get pleaseSelectCsv => 'يرجى اختيار ملف CSV.';

  @override
  String get invalidNumbers => 'يرجى إدخال قيم رقمية صحيحة.';

  @override
  String get negativeValue => 'يرجى إدخال قيم رقمية غير سالبة.';

  @override
  String get reportTitle => 'تقرير ساعات العمل';

  @override
  String get csvLabel => 'CSV';

  @override
  String get perDayBreakdown => 'تفصيل حسب اليوم:';

  @override
  String get workingDaysMonth => 'أيام العمل/شهر';

  @override
  String get hoursPerShiftNormal => 'ساعات الدوام (العادية)';

  @override
  String useOvertimeRateYesNo(Object yesNo) {
    return 'استخدام أجر الساعات الإضافية: $yesNo';
  }

  @override
  String get overtimeRateLabel => 'معدل أجر الساعات الإضافية';

  @override
  String get overtimeMerged => 'تم دمج الساعات الإضافية ضمن الأجر العادي';

  @override
  String get close => 'إغلاق';

  @override
  String get toggleLanguage => 'English';

  @override
  String get totalHours => 'إجمالي الساعات';

  @override
  String get normalHourlyPayRate => 'معدل الأجر العادي لكل ساعة';

  @override
  String get invalidWorkingDaysNumbers =>
      'يرجى إدخال قيم رقمية صحيحة لأيام العمل.';

  @override
  String get invalidHoursPerShiftNumbers =>
      'يرجى إدخال قيم رقمية صحيحة لساعات الدوام.';

  @override
  String get absences => 'الغيابات';

  @override
  String get downloadReport => 'تحميل التقرير';

  @override
  String get date => 'التاريخ';

  @override
  String get hours => 'الساعات';

  @override
  String get hourlyRates => 'معدلات الأجر لكل ساعة';

  @override
  String get pay => 'الأجر';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get fileName => 'اسم الملف';

  @override
  String get enter => 'أدخل';
}
