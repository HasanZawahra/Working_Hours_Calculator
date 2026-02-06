import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/languege/l10n/app_localizations.dart';
import '../controllers/working_hours_controller.dart';
import '../services/report_generator.dart';
import '../widgets/report_dialog.dart';

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

  final _controller = WorkingHoursController();
  final _reportGen = ReportGenerator();

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _workingDaysCtrl.dispose();
    _hoursPerShiftCtrl.dispose();
    _overtimeRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      setState(() => _controller.setCsvPath(result.files.single.path!));
    }
  }

  void _clearCsv() {
    setState(() => _controller.setCsvPath(null));
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

  Future<void> _compute() async {
    final t = AppLocalizations.of(context);
    if (_controller.state.csvPath == null) {
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

    final newState = await _controller.compute(
      salary: salary,
      workingDays: workingDays,
      hoursPerShift: hoursPerShift,
      overtimeRate: overtimeRate,
    );

    setState(() {});
    _showReport(newState, workingDays, hoursPerShift, overtimeRate);
  }

  void _showReport(WorkingHoursState s, double workingDays, double hoursPerShift, double overtimeRate) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => ReportDialog(
        t: t,
        csvPath: s.csvPath,
        payOvertimeSeparately: s.payOvertimeSeparately,
        normalHours: s.normalMinutes / 60.0,
        overtimeHours: s.overtimeMinutes / 60.0,
        normalPay: s.normalPay,
        overtimePay: s.overtimePay,
        totalPay: s.totalPay,
        workingDays: workingDays,
        hoursPerShift: hoursPerShift,
        normalHourlyRate: s.normalHourlyRate,
        overtimeRate: overtimeRate,
        perDayHours: s.perDayHours,
        onSavePdf: () => _reportGen.generateAndShare(
          t: t,
          csvPath: s.csvPath,
          payOvertimeSeparately: s.payOvertimeSeparately,
          normalHours: s.normalMinutes / 60.0,
          overtimeHours: s.overtimeMinutes / 60.0,
          normalPay: s.normalPay,
          overtimePay: s.overtimePay,
          totalPay: s.totalPay,
          workingDays: workingDays,
          hoursPerShift: hoursPerShift,
          normalHourlyRate: s.normalHourlyRate,
          overtimeRate: overtimeRate,
          perDayHours: s.perDayHours,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final normalHours = (_controller.state.normalMinutes / 60.0);
    final overtimeHours = (_controller.state.overtimeMinutes / 60.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(tooltip: t.toggleLanguage, onPressed: widget.toggleLocale, icon: const Icon(Icons.language)),
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
                        label: Text(_controller.state.csvPath == null
                            ? t.selectCsv
                            : '${t.selectedCsv}: ${_controller.state.csvPath!.split(Platform.pathSeparator).last}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(tooltip: t.clearSelection, onPressed: _clearCsv, icon: const Icon(Icons.clear)),
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
                        value: _controller.state.payOvertimeSeparately,
                        onChanged: (v) => setState(() => _controller.setOvertimeSeparately(v ?? true)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(onPressed: _compute, icon: const Icon(Icons.calculate), label: Text(t.calculate)),
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
                            Column(children: [Text(t.normalHours), Text(normalHours.toStringAsFixed(2))]),
                            Column(children: [Text(t.overtimeHours), Text(overtimeHours.toStringAsFixed(2))]),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(children: [Text(t.normalPay), Text(_controller.state.normalPay.toStringAsFixed(2))]),
                            Column(children: [Text(t.overtimePay), Text(_controller.state.overtimePay.toStringAsFixed(2))]),
                            Column(children: [Text(t.totalPay), Text(_controller.state.totalPay.toStringAsFixed(2))]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text('© 2026 Hasan Zawahra • All Rights Reserved', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
