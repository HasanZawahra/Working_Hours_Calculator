# Working Hours Calculator

A Flutter application for calculating working hours from CSV input, reviewing work intervals, and generating shareable PDF reports. It is suitable for tracking daily shifts, overtime, and monthly summaries in both English and Arabic.

## What this app does
- Imports work data from CSV files.
- Calculates work intervals, total working hours, and overtime-related values.
- Generates downloadable PDF reports for sharing or filing.
- Supports Android, iOS, Web, Windows, macOS, and Linux.
- Offers English and Arabic interfaces.

## Features
- CSV import with flexible input formats.
- Work-day interval calculation and summary reporting.
- PDF report generation with printable/shareable output.
- Multi-platform support.
- Bilingual UI (English / Arabic).

## CSV input format
The app accepts CSV data in either of these common styles:

### Option 1: 3-row sheet style
```csv
Date,2026-06-01,2026-06-02
Start,09:00,09:30
End,17:00,16:45
```

### Option 2: Row-per-shift style
```csv
Date,Start,End
2026-06-01,09:00,17:00
2026-06-02,09:30,16:45
```

If a row has invalid or missing times, it will be treated as an absence/invalid entry in the calculation.

## Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A compatible editor such as [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/HasanZawahra/Working_Hours_Calculator.git
   ```
2. Navigate to the project folder:
   ```bash
   cd Working_Hours_Calculator
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Run the app
```bash
flutter run
```

## Folder Structure
- `lib/`: Contains the main application code.
- `assets/`: Stores fonts and other static resources.

## License
This project is licensed under the [MIT License](LICENSE).