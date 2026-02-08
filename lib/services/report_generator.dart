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
    String? fileName,
    bool compactOnePage = true, // NEW
  }) async {
    final doc = pw.Document();

    final base = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    final arabic = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final arabicBold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));

    final bool isArabic = t.localeName.toLowerCase().startsWith('ar');

    // Compact tuning knobs
    final pageMargin = compactOnePage ? 14.0 : 24.0;
    final titleSize = compactOnePage ? 16.0 : 20.0;
    final bodySize = compactOnePage ? 9.0 : 11.0;
    final tableHeaderSize = compactOnePage ? 9.0 : 11.0;
    final cellPad = compactOnePage ? 3.0 : 6.0;
    final vGap = compactOnePage ? 4.0 : 12.0;

    // Helper: one labeled row that respects RTL/LTR and keeps numeric values LTR (English digits)
    pw.Widget labeledRow(String label, String value) {
      return pw.Directionality(
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Directionality(
              textDirection: pw.TextDirection.ltr, // keep digits English
              child: pw.Text(value, textAlign: pw.TextAlign.left),
            ),
          ],
        ),
      );
    }

    // Name shown inside the document (no ".pdf")
    final String? displayName = (fileName == null || fileName.trim().isEmpty)
        ? null
        : fileName.trim().replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(pageMargin),
        theme: pw.ThemeData.withFont(
          base: isArabic ? arabic : base,
          bold: isArabic ? arabicBold : bold,
          fontFallback: [arabic, arabicBold, base, bold],
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            child: pw.DefaultTextStyle(
              style: pw.TextStyle(fontSize: bodySize),
              child: pw.Column(
                crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    alignment: isArabic ? pw.Alignment.topRight : pw.Alignment.topLeft,
                    child: pw.Column(
                      crossAxisAlignment: isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                            width: double.infinity,
                            alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                            child: pw.Directionality(
                                textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                                child:
                        pw.Text(
                          t.reportTitle,
                          style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
                          textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                        ),
                        ),
                        ),
                        if (displayName != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Container(
                            width: double.infinity,
                            alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                            child: pw.Directionality(
                              textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                              child: pw.Text(
                                displayName,
                                style: pw.TextStyle(fontSize: 18 , fontWeight: pw.FontWeight.bold , color: PdfColors.grey700),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 6),

                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                    columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(cellPad),
                            child: pw.Text(
                              t.date,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: tableHeaderSize),
                              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(cellPad),
                            child: pw.Text(
                              t.hours,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: tableHeaderSize),
                              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      ...perDayHours.map(
                        (e) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(cellPad),
                              child: pw.Text(
                                e.key,
                                textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(cellPad),
                              child: pw.Container(
                                alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                                child: pw.Directionality(
                                  textDirection: pw.TextDirection.ltr,
                                  child: pw.Text('${e.value.toStringAsFixed(2)} h'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  // Calculations under the table (no extra helpers needed)

                  pw.Text(
                    t.hours,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                  pw.SizedBox(height: compactOnePage ? 3 : 6),

                  labeledRow(t.normalHours, '${normalHours.toStringAsFixed(2)} h'),
                  labeledRow(t.overtimeHours, '${overtimeHours.toStringAsFixed(2)} h'),
                  labeledRow(t.totalHours, '${(normalHours + overtimeHours).toStringAsFixed(2)} h'),

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  pw.Text(
                    t.hourlyRates,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                  ),
                  pw.SizedBox(height: compactOnePage ? 3 : 6),
                  labeledRow(t.normalHourlyPayRate, normalHourlyRate.toStringAsFixed(2)),
                  if (payOvertimeSeparately)
                    labeledRow(t.overtimeRateLabel, overtimeRate.toStringAsFixed(2)),

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  if (payOvertimeSeparately) ...[
                    pw.Text(
                       t.pay,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: compactOnePage ? 3 : 6),
                    labeledRow(t.normalPay, normalPay.toStringAsFixed(2)),
                    labeledRow(t.overtimePay, overtimePay.toStringAsFixed(2)),
                  ] else ...[
                    pw.Text(
                      t.overtimeMerged,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: compactOnePage ? 3 : 6),
                    labeledRow(t.normalPay, normalPay.toStringAsFixed(2)),
                  ],

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  labeledRow(t.totalPay, totalPay.toStringAsFixed(2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final safeName = (fileName == null || fileName.trim().isEmpty)
        ? 'working_hours_report.pdf'
        : (fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf');
    await Printing.sharePdf(bytes: bytes, filename: safeName);
  }
}
