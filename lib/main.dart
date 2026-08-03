import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(const BatteryLabPro());
}

class BatteryLabPro extends StatelessWidget {
  const BatteryLabPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battery LAB Pro',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}