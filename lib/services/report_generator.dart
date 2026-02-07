import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/l10n/app_localizations.dart';

class ReportGenerator {
  Future<void> generateAndShare({
    required AppLocalizations t,
    required String? csvPath,
    required bool payOvertimeSeparately,
    required double normalHours,
    required double overtimeHours,
    required double normalPay,
    required double overtimePay,
    required double totalPay,
    required double workingDays,
    required double hoursPerShift,
    required double normalHourlyRate,
    required double overtimeRate,
    required List<MapEntry<String, double>> perDayHours,
    required int absenceCount,
  }) async {
    final doc = pw.Document();

    pw.Widget labeledRow(String label, String value) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value),
      ],
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(t.reportTitle, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('${t.csvLabel}: ${csvPath ?? 'N/A'}'),
          pw.SizedBox(height: 12),
          pw.Text(t.perDayBreakdown, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Hours', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...perDayHours.map((e) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.key)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${e.value.toStringAsFixed(2)} h')),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.Text('Settings', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          labeledRow(t.workingDaysMonth, workingDays.toStringAsFixed(2)),
          labeledRow(t.hoursPerShiftNormal, '${hoursPerShift.toStringAsFixed(2)} h'),
          labeledRow('Absences', absenceCount.toString()),
          labeledRow(t.useOvertimeRate, payOvertimeSeparately ? 'Yes' : 'No'),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.Text('Hours', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          labeledRow(t.normalHours, '${normalHours.toStringAsFixed(2)} h'),
          labeledRow(t.overtimeHours, '${overtimeHours.toStringAsFixed(2)} h'),
          labeledRow(t.totalHours, '${(normalHours + overtimeHours).toStringAsFixed(2)} h'),
          pw.SizedBox(height: 12),
          pw.Divider(),
          if (payOvertimeSeparately) ...[
            pw.Text('Rates', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            labeledRow(t.normalHourlyPayRate, normalHourlyRate.toStringAsFixed(2)),
            labeledRow(t.overtimeRateLabel, overtimeRate.toStringAsFixed(2)),
            pw.SizedBox(height: 6),
            pw.Text('Pay', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            labeledRow(t.normalPay, normalPay.toStringAsFixed(2)),
            labeledRow(t.overtimePay, overtimePay.toStringAsFixed(2)),
          ] else ...[
            pw.Text(t.overtimeMerged, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            labeledRow(t.normalPay, normalPay.toStringAsFixed(2)),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(),
          labeledRow(t.totalPay, totalPay.toStringAsFixed(2)),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'working_hours_report.pdf');
  }
}
