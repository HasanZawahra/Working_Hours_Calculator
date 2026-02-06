// Copyright (c) 2026 Hasan Zawahra. All Rights Reserved.
// Unauthorized copying, modification, distribution, or use is prohibited.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'services/csv_parser.dart';
import 'services/calculator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const WorkingHoursApp());
}

class WorkingHoursApp extends StatefulWidget {
  const WorkingHoursApp({super.key});
  @override
  State<WorkingHoursApp> createState() => _WorkingHoursAppState();
}

class _WorkingHoursAppState extends State<WorkingHoursApp> {
  final _localeController = LocaleController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Working Hours Calculator',
          locale: _localeController.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: WorkingHoursPage(toggleLocale: _localeController.toggle),
        );
      },
    );
  }
}

class WorkingHoursPage extends StatefulWidget {
  final VoidCallback toggleLocale;
  const WorkingHoursPage({super.key, required this.toggleLocale});

  @override
  State<WorkingHoursPage> createState() => _WorkingHoursPageState();
}

class _WorkingHoursPageState extends State<WorkingHoursPage> {
  final _salaryCtrl = TextEditingController();
  final _workingDaysCtrl = TextEditingController();
  final _hoursPerShiftCtrl = TextEditingController();
  final _overtimeRateCtrl = TextEditingController();

  final _parser = CsvParser();
  final _calculator = Calculator();

  String? _csvPath;

  double _normalMinutes = 0;
  double _overtimeMinutes = 0;
  double _normalHourlyRate = 0;
  double _normalPay = 0;
  double _overtimePay = 0;
  double _totalPay = 0;
  List<MapEntry<String, double>> _perDayHours = const [];

  bool _payOvertimeSeparately = true;

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _workingDaysCtrl.dispose();
    _hoursPerShiftCtrl.dispose();
    _overtimeRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _csvPath = result.files.single.path!;
      });
    }
  }

  void _clearCsv() {
    setState(() {
      _csvPath = null;
      _normalMinutes = 0;
      _overtimeMinutes = 0;
      _normalHourlyRate = 0;
      _normalPay = 0;
      _overtimePay = 0;
      _totalPay = 0;
    });
  }

  void _compute() async {
    final t = AppLocalizations.of(context);
    if (_csvPath == null) {
      _showError(t.error, t.pleaseSelectCsv);
      return;
    }
    final salary = double.tryParse(_salaryCtrl.text);
    final workingDays = double.tryParse(_workingDaysCtrl.text);
    final hoursPerShift = double.tryParse(_hoursPerShiftCtrl.text);
    final overtimeRate = double.tryParse(_overtimeRateCtrl.text) ?? 0.0;

    if (salary == null || workingDays == null || hoursPerShift == null) {
      _showError(t.error, t.invalidNumbers);
      return;
    }
    if (workingDays > 30) {
      _showError(t.error, t.invalidWorkingDaysNumbers);
      return;
    }
    if (hoursPerShift > 24) {
      _showError(t.error, t.invalidHoursPerShiftNumbers);
      return;
    }
    if (hoursPerShift <= 0 || workingDays <= 0 || salary <= 0 || overtimeRate < 0) {
      _showError(t.error, t.negativeValue);
      return;
    }


    final content = await File(_csvPath!).readAsString();
    final intervals = _parser.parse(content);
    final result = _calculator.compute(
      intervals: intervals,
      salary: salary,
      workingDays: workingDays,
      hoursPerShift: hoursPerShift,
      overtimeRate: overtimeRate,
      payOvertimeSeparately: _payOvertimeSeparately,
    );

    // dart
// File: 'lib/main.dart' (excerpt)
    DateTime? _tryParseDate(String s) {
      final formats = [
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$'),        // yyyy-MM-dd
        RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'),        // dd/MM/yyyy
        RegExp(r'^(\d{2})-(\d{2})-(\d{4})$'),        // dd-MM-yyyy
        RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$'),      // dd.MM.yyyy
        RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$'),  // M/d/yy|yyyy
      ];
      for (final r in formats) {
        final m = r.firstMatch(s);
        if (m != null) {
          int y, mo, d;
          if (r.pattern.startsWith('^(\d{4})')) { // yyyy-MM-dd
            y = int.parse(m.group(1)!);
            mo = int.parse(m.group(2)!);
            d = int.parse(m.group(3)!);
          } else if (r.pattern.contains('M/d')) { // M/d/yy|yyyy
            mo = int.parse(m.group(1)!);
            d = int.parse(m.group(2)!);
            final yy = int.parse(m.group(3)!);
            y = yy < 100 ? (2000 + yy) : yy;
          } else { // dd/\-.\ formats
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
        if (da != null) return -1; // parsed dates first
        if (db != null) return 1;
        return a.key.compareTo(b.key);
      });


    setState(() {
      _normalMinutes = result.normalMinutes;
      _overtimeMinutes = result.overtimeMinutes;
      _normalHourlyRate = result.normalHourlyRate;
      _normalPay = result.normalPay;
      _overtimePay = result.overtimePay;
      _totalPay = result.totalPay;
      _perDayHours = perDay;
    });

    _showReport(
      normalHours: result.normalMinutes / 60.0,
      overtimeHours: result.overtimeMinutes / 60.0,
      normalPay: result.normalPay,
      overtimePay: result.overtimePay,
      totalPay: result.totalPay,
      workingDays: workingDays,
      hoursPerShift: hoursPerShift,
      normalHourlyRate: result.normalHourlyRate,
      overtimeRate: overtimeRate,
      perDayHours: perDay,
    );
  }

  void _showError(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).ok))],
      ),
    );
  }

  Future<void> _generateAndSavePdf({
    required String? csvPath,
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
  }) async {
    final t = AppLocalizations.of(context);
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
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
            },
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
          labeledRow(t.useOvertimeRate, _payOvertimeSeparately ? 'Yes' : 'No'),

          pw.SizedBox(height: 12),
          pw.Divider(),

          pw.Text('Hours', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          labeledRow(t.normalHours, '${normalHours.toStringAsFixed(2)} h'),
          labeledRow(t.overtimeHours, '${overtimeHours.toStringAsFixed(2)} h'),
          labeledRow(t.totalHours, '${(normalHours + overtimeHours).toStringAsFixed(2)} h'),

          pw.SizedBox(height: 12),
          pw.Divider(),

          if (_payOvertimeSeparately) ...[
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

    // Cross-platform save/share dialog (Print, Share, Save As)
    await Printing.sharePdf(bytes: bytes, filename: 'working_hours_report.pdf');
    // Alternatively, use Printing.layoutPdf to print directly:
    // await Printing.layoutPdf(onLayout: (format) async => bytes);
  }


  void _showReport({
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
  }) {
    final t = AppLocalizations.of(context);
    final yesNo = _payOvertimeSeparately ? 'Yes' : 'No';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.reportTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.csvLabel}: ${_csvPath ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(t.perDayBreakdown),
              const SizedBox(height: 4),
              ...perDayHours.map((e) => Text('${e.key}: ${e.value.toStringAsFixed(2)} h')),
              const Divider(),
              Text('${t.workingDaysMonth}: ${workingDays.toStringAsFixed(2)}'),
              Text('${t.hoursPerShiftNormal}: ${hoursPerShift.toStringAsFixed(2)} h'),
              const Divider(),
              Text('${t.useOvertimeRate}: $yesNo'),
              Text('${t.normalHours}: ${normalHours.toStringAsFixed(2)} h'),
              Text('${t.overtimeHours}: ${overtimeHours.toStringAsFixed(2)} h'),
              Text('${t.totalHours}: ${(overtimeHours+normalHours).toStringAsFixed(2)} h'),
              const Divider(),
              if (_payOvertimeSeparately) ...[
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
          TextButton(
            onPressed: () async {
              await _generateAndSavePdf(
                csvPath: _csvPath,
                normalHours: normalHours,
                overtimeHours: overtimeHours,
                normalPay: normalPay,
                overtimePay: overtimePay,
                totalPay: totalPay,
                workingDays: workingDays,
                hoursPerShift: hoursPerShift,
                normalHourlyRate: normalHourlyRate,
                overtimeRate: overtimeRate,
                perDayHours: perDayHours,
              );
            },
            child: Text('Save PDF'),
          ),],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final normalHours = (_normalMinutes / 60.0);
    final overtimeHours = (_overtimeMinutes / 60.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            tooltip: t.toggleLanguage,
            onPressed: widget.toggleLocale,
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickCsv,
                        icon: const Icon(Icons.upload_file),
                        label: Text(_csvPath == null
                            ? t.selectCsv
                            : '${t.selectedCsv}: ${_csvPath!.split(Platform.pathSeparator).last}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: t.clearSelection,
                      onPressed: _clearCsv,
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.salaryPerMonth, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _workingDaysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.workingDaysPerMonth, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hoursPerShiftCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.hoursPerShift, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _overtimeRateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: t.overtimePayPerHour, border: const OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.useOvertimeRate),
                        value: _payOvertimeSeparately,
                        onChanged: (v) => setState(() => _payOvertimeSeparately = v ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _compute,
                  icon: const Icon(Icons.calculate),
                  label: Text(t.calculate),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [
                              Text(t.normalHours),
                              Text(normalHours.toStringAsFixed(2)),
                            ]),
                            Column(children: [
                              Text(t.overtimeHours),
                              Text(overtimeHours.toStringAsFixed(2)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [
                              Text(t.normalPay),
                              Text(_normalPay.toStringAsFixed(2)),
                            ]),
                            Column(children: [
                              Text(t.overtimePay),
                              Text(_overtimePay.toStringAsFixed(2)),
                            ]),
                            Column(children: [
                              Text(t.totalPay),
                              Text(_totalPay.toStringAsFixed(2)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                    alignment: Alignment.center,
                    child: Text(
                      '© 2026 Hasan Zawahra • All Rights Reserved',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
