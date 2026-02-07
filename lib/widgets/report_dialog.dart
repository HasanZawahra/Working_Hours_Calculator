import 'package:flutter/material.dart';
import '../services/l10n/app_localizations.dart';

typedef GeneratePdfCallback = Future<void> Function();

class ReportDialog extends StatelessWidget {
  final AppLocalizations t;
  final String? csvPath;
  final bool payOvertimeSeparately;
  final double normalHours;
  final double overtimeHours;
  final double normalPay;
  final double overtimePay;
  final double totalPay;
  final double workingDays;
  final double hoursPerShift;
  final double normalHourlyRate;
  final double overtimeRate;
  final List<MapEntry<String, double>> perDayHours;
  final int absenceCount;
  final GeneratePdfCallback onSavePdf;

  const ReportDialog({
    super.key,
    required this.t,
    required this.csvPath,
    required this.payOvertimeSeparately,
    required this.normalHours,
    required this.overtimeHours,
    required this.normalPay,
    required this.overtimePay,
    required this.totalPay,
    required this.workingDays,
    required this.hoursPerShift,
    required this.normalHourlyRate,
    required this.overtimeRate,
    required this.perDayHours,
    required this.absenceCount,
    required this.onSavePdf,
  });

  @override
  Widget build(BuildContext context) {
    final yesNo = payOvertimeSeparately ? 'Yes' : 'No';
    return AlertDialog(
      title: Text(t.reportTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.csvLabel}: ${csvPath ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text(t.perDayBreakdown),
            const SizedBox(height: 4),
            ...perDayHours.map((e) => Text('${e.key}: ${e.value.toStringAsFixed(2)} h')),
            const Divider(),
            Text('${t.absences}: $absenceCount'),
            const Divider(),
            Text('${t.workingDaysMonth}: ${workingDays.toStringAsFixed(2)}'),
            Text('${t.hoursPerShiftNormal}: ${hoursPerShift.toStringAsFixed(2)} h'),
            const Divider(),
            Text('${t.useOvertimeRate}: $yesNo'),
            Text('${t.normalHours}: ${normalHours.toStringAsFixed(2)} h'),
            Text('${t.overtimeHours}: ${overtimeHours.toStringAsFixed(2)} h'),
            Text('${t.totalHours}: ${(overtimeHours + normalHours).toStringAsFixed(2)} h'),
            const Divider(),
            if (payOvertimeSeparately) ...[
              Text('${t.normalHourlyPayRate}: ${normalHourlyRate.toStringAsFixed(2)}'),
              Text('${t.overtimeRateLabel}: ${overtimeRate.toStringAsFixed(2)}'),
              Text('${t.normalPay}: ${normalPay.toStringAsFixed(2)}'),
              Text('${t.overtimePay}: ${overtimePay.toStringAsFixed(2)}'),
            ] else ...[
              Text(t.overtimeMerged),
              Text('${t.normalPay}: ${normalPay.toStringAsFixed(2)}'),
            ],
            const Divider(),
            Text('${t.totalPay}: ${totalPay.toStringAsFixed(2)}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.close)),
        TextButton(onPressed: () async => onSavePdf(), child: Text(t.downloadReport)),
      ],
    );
  }
}
