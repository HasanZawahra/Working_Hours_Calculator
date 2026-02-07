// Dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'l10n/app_localizations.dart';

class ReportGenerator {



  pw.Widget rtlText(String s, {pw.TextStyle? style}) => pw.Directionality(
    textDirection: pw.TextDirection.rtl,
    child: pw.Text(s, style: style, textAlign: pw.TextAlign.right),
  );

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

    // Load fonts (ensure these files exist in `assets/fonts`)
    final base = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    final arabic = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final arabicBold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));

    pw.Widget labeledRowRtl(String label, String value) => pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          rtlText(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          rtlText(value),
        ],
      ),
    );

    pw.Widget labeledRowLtr(String label, String value) => pw.Row(
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
        theme: pw.ThemeData.withFont(
          base: base,
          bold: bold,
          fontFallback: [arabic, arabicBold],
        ),
        build: (context) => [
          // Arabic header block (RTL)
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                rtlText(t.reportTitle, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                rtlText('${t.csvLabel}: ${csvPath ?? 'N/A'}'),
                pw.SizedBox(height: 12),
                rtlText(t.perDayBreakdown, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),

          // Table (LTR for dates/numbers)
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.left),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Hours', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.left),
                  ),
                ],
              ),
              ...perDayHours.map((e) => pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.key, textAlign: pw.TextAlign.left)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${e.value.toStringAsFixed(2)} h', textAlign: pw.TextAlign.left)),
                ],
              )),
            ],
          ),

          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 6),

          // Arabic labeled rows (RTL)
          labeledRowRtl(t.workingDaysMonth, workingDays.toStringAsFixed(2)),
          labeledRowRtl(t.hoursPerShiftNormal, '${hoursPerShift.toStringAsFixed(2)} h'),
          labeledRowRtl(t.absences, absenceCount.toString()),
          labeledRowRtl(t.useOvertimeRate, payOvertimeSeparately ? 'Yes' : 'No'),

          pw.SizedBox(height: 12),
          pw.Divider(),

          // Section titles RTL
          rtlText('Hours', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          labeledRowRtl(t.normalHours, '${normalHours.toStringAsFixed(2)} h'),
          labeledRowRtl(t.overtimeHours, '${overtimeHours.toStringAsFixed(2)} h'),
          labeledRowRtl(t.totalHours, '${(normalHours + overtimeHours).toStringAsFixed(2)} h'),

          pw.SizedBox(height: 12),
          pw.Divider(),

          if (payOvertimeSeparately) ...[
            rtlText('Rates', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            labeledRowRtl(t.normalHourlyPayRate, normalHourlyRate.toStringAsFixed(2)),
            labeledRowRtl(t.overtimeRateLabel, overtimeRate.toStringAsFixed(2)),
            pw.SizedBox(height: 6),
            rtlText('Pay', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            labeledRowRtl(t.normalPay, normalPay.toStringAsFixed(2)),
            labeledRowRtl(t.overtimePay, overtimePay.toStringAsFixed(2)),
          ] else ...[
            rtlText(t.overtimeMerged, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            labeledRowRtl(t.normalPay, normalPay.toStringAsFixed(2)),
          ],

          pw.SizedBox(height: 12),
          pw.Divider(),
          labeledRowRtl(t.totalPay, totalPay.toStringAsFixed(2)),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'working_hours_report.pdf');
  }
}
