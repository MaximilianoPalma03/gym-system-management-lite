import 'package:flutter/material.dart';

const studioColors = <Color>[
  Color(0xFF355CAD), Color(0xFF0F766E), Color(0xFF7C3AED),
  Color(0xFFB45309), Color(0xFFBE185D), Color(0xFF394150),
];

ThemeData buildAppTheme(int colorIndex) {
  final seed = studioColors[colorIndex.clamp(0, studioColors.length - 1).toInt()];
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF5F7FA), scrolledUnderElevation: 0),
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white, height: 76,
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
    ),
  );
}
