class WorkDayRow {
  final String dateRaw;     // original date string from CSV
  final DateTime? date;     // parsed if possible (for weekday)
  final String start;       // HH:mm
  final String end;         // HH:mm
  final double workedHours; // total hours that day (incl. overtime)

  const WorkDayRow({
    required this.dateRaw,
    required this.date,
    required this.start,
    required this.end,
    required this.workedHours,
  });
}