import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'l10n/app_localizations.dart';
import '../models/work_day_row.dart';

class ReportGenerator {
  Future<void> generateAndShare({
    required AppLocalizations t,
    required String? csvPath,

    // Entered data (needed for a comprehensive report)
    required double salary,
    required double workingDays,
    required double hoursPerShift,
    required double overtimeRate,
    required bool payOvertimeSeparately,

    // Detailed table rows
    required List<WorkDayRow> workDayRows,

    // Calculation results
    required double normalHours,
    required double overtimeHours,
    required double normalPay,
    required double overtimePay,
    required double totalPay,
    required double normalHourlyRate,

    // Other
    required int absenceCount,
    String? fileName,
    bool compactOnePage = true,
  }) async {
    final doc = pw.Document();

    final base = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    final arabic = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
    final arabicBold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));

    final bool isArabic = t.localeName.toLowerCase().startsWith('ar');

    // Layout knobs
    final pageMargin = compactOnePage ? 12.0 : 20.0;
    final bodySize = compactOnePage ? 9.0 : 11.0;
    final vGap = compactOnePage ? 2.0 : 8.0;

    // Table compact knobs (especially for Arabic)
    final tableHeaderSize = compactOnePage ? 8.4 : 10.5;
    final tableBodySize = (compactOnePage && isArabic) ? 7.1 : bodySize;
    final tableCellPad = (compactOnePage && isArabic) ? 1.4 : 4.0;
    final tableRowHeight = (compactOnePage && isArabic) ? 17.0 : 0.0;

    // Name shown inside the document (no ".pdf")
    final String? displayName = (fileName == null || fileName.trim().isEmpty)
        ? null
        : fileName.trim().replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

    // ---------- Helpers (defined BEFORE use) ----------
    pw.Widget sectionTitle(String s) => pw.Text(
          s,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
        );

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
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Directionality(
              textDirection: pw.TextDirection.ltr, // keep digits stable
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.left,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ],
        ),
      );
    }

    String _weekdayName(DateTime d) {
      if (!isArabic) {
        const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return en[d.weekday - 1];
      }
      const ar = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      return ar[d.weekday - 1];
    }

    pw.Widget _hdr(String s) {
      return pw.Container(
        height: (tableRowHeight > 0.0) ? tableRowHeight : null,
        alignment: isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Padding(
          padding: pw.EdgeInsets.all(tableCellPad),
          child: pw.Text(
            s,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: tableHeaderSize),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
          ),
        ),
      );
    }

    pw.Widget _cell(
      String s, {
      required bool ltr,
      pw.Alignment? alignment,
    }) {
      final align = alignment ?? (isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft);
      return pw.Container(
        height: (tableRowHeight > 0.0) ? tableRowHeight : null,
        alignment: align,
        child: pw.Padding(
          padding: pw.EdgeInsets.all(tableCellPad),
          child: pw.Directionality(
            textDirection: ltr ? pw.TextDirection.ltr : (isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr),
            child: pw.Text(
              s,
              style: pw.TextStyle(fontSize: tableBodySize),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            ),
          ),
        ),
      );
    }

    // Column labels (avoid relying on missing localization keys)
    final weekdayLabel = isArabic ? 'اليوم' : 'Weekday';
    final dateLabel = t.date; // already localized
    final startLabel = isArabic ? 'بداية' : 'Start';
    final endLabel = isArabic ? 'نهاية' : 'End';
    final workLabel = isArabic ? 'ساعات العمل' : 'Work (h)';
    final otLabel = isArabic ? 'إضافي (h)' : 'OT (h)';

    // ---------- Build PDF ----------
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
                  if (displayName != null) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      displayName,
                      style: pw.TextStyle(
                        fontSize: compactOnePage ? 13 : 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                      textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ],

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  labeledRow( isArabic ? 'الراتب الشهري' :'Monthly salary', salary.toStringAsFixed(2)),
                  labeledRow(t.hoursPerShiftNormal, '${hoursPerShift.toStringAsFixed(2)} h'),
                  labeledRow(t.overtimeRateLabel, overtimeRate.toStringAsFixed(2)),

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  // Working days table (weekday, date, start, end, work, overtime)
                  sectionTitle(isArabic ? 'جدول أيام العمل' : 'Working days table'),
                  pw.SizedBox(height: compactOnePage ? 3 : 6),

                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.0), // weekday
                      1: pw.FlexColumnWidth(2.2), // date
                      2: pw.FlexColumnWidth(1.55), // start
                      3: pw.FlexColumnWidth(1.55), // end
                      4: pw.FlexColumnWidth(1.35), // work
                      5: pw.FlexColumnWidth(1.35), // OT
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _hdr(weekdayLabel),
                          _hdr(dateLabel),
                          _hdr(startLabel),
                          _hdr(endLabel),
                          _hdr(workLabel),
                          _hdr(otLabel),
                        ],
                      ),
                      ...workDayRows.map((r) {
                        final total = r.workedHours;
                        final normal = total.clamp(0, hoursPerShift);
                        final ot = (total - hoursPerShift).clamp(0, double.infinity);

                        final weekday = (r.date == null) ? '-' : _weekdayName(r.date!);

                        return pw.TableRow(
                          children: [
                            _cell(weekday, ltr: false),
                            _cell(r.dateRaw, ltr: true),
                            _cell(r.start, ltr: true),
                            _cell(r.end, ltr: true),
                            _cell(normal.toStringAsFixed(2), ltr: true, alignment: pw.Alignment.center),
                            _cell(ot.toStringAsFixed(2), ltr: true, alignment: pw.Alignment.center),
                          ],
                        );
                      }),
                    ],
                  ),

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  // Hourly pay rates
                  pw.SizedBox(height: compactOnePage ? 3 : 6),
                  labeledRow(t.normalHourlyPayRate, normalHourlyRate.toStringAsFixed(2)),
                  if (payOvertimeSeparately) labeledRow(t.overtimeRateLabel, overtimeRate.toStringAsFixed(2)),

                  pw.SizedBox(height: vGap),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: vGap),

                  // Calculation results
                  pw.SizedBox(height: compactOnePage ? 3 : 6),
                  labeledRow(t.normalHours, '${normalHours.toStringAsFixed(2)} h'),
                  labeledRow(t.overtimeHours, '${overtimeHours.toStringAsFixed(2)} h'),
                  labeledRow(t.absences, absenceCount.toString()),
                  labeledRow(t.totalHours, '${(normalHours + overtimeHours).toStringAsFixed(2)} h'),

                  pw.SizedBox(height: compactOnePage ? 2 : 6),

                  if (payOvertimeSeparately) ...[
                    labeledRow(t.normalPay, normalPay.toStringAsFixed(2)),
                    labeledRow(t.overtimePay, overtimePay.toStringAsFixed(2)),
                  ] else ...[
                    pw.Text(
                      t.overtimeMerged,
                      textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
                    ),
                    labeledRow(t.normalPay, normalPay.toStringAsFixed(2)),
                  ],
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
