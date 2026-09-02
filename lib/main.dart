import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/themes/app_theme.dart';
import 'models/app_preferences.dart';
import 'screens/home_screen.dart';
import 'repository/db_helper.dart';
import 'repository/preferences_repository.dart';
import 'repository/protocol_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await DBHelper.instance.database;
    await DBHelper.instance.restoreSessionIfNeeded();
    await PreferencesRepository.instance.init();
    await ProtocolRepository.instance.init();
    await DBHelper.instance.setSessionValue('last_launch_at', DateTime.now().toIso8601String());
  }
  runApp(const LabCalculatorApp());
}

class LabCalculatorApp extends StatelessWidget {
  const LabCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPreferences>(
      valueListenable: PreferencesRepository.instance.preferencesNotifier,
      builder: (context, prefs, _) {
        ThemeMode mode = ThemeMode.light;
        if (prefs.theme == ThemePreference.system) {
          mode = ThemeMode.system;
        } else if (prefs.theme == ThemePreference.dark) {
          mode = ThemeMode.dark;
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LAB Calculator',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          locale: Locale(prefs.languageCode),
          home: const HomeScreen(),
        );
      },
    );
  }
}