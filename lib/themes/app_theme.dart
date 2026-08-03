import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Colors.white;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorSchemeSeed: primary,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Colors.black,
      centerTitle: true,
      elevation: 0,
    ),
  );
}