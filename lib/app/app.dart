import 'package:flutter/material.dart';
import '../services/languege/l10n/app_localizations.dart';
import '../services/languege/localization/locale_controller.dart';
import '../pages/working_hours_page.dart';

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: WorkingHoursPage(toggleLocale: _localeController.toggle),
        );
      },
    );
  }
}
