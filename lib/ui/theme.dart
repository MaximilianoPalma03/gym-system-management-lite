import 'package:flutter/material.dart';

const studioColors = <Color>[
  Color(0xFF355CAD), Color(0xFF0F766E), Color(0xFF7C3AED),
  Color(0xFFB45309), Color(0xFFBE185D), Color(0xFF394150),
];

ThemeData buildAppTheme(int colorIndex, {Brightness brightness = Brightness.light}) {
  final seed = studioColors[colorIndex.clamp(0, studioColors.length - 1).toInt()];
  final dark = brightness == Brightness.dark;
  final surface = dark ? const Color(0xFF191F28) : const Color(0xFFF5F7FA);
  final cardColor = dark ? const Color(0xFF252D38) : Colors.white;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    surface: surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    appBarTheme: AppBarTheme(backgroundColor: surface, scrolledUnderElevation: 0),
    cardTheme: CardThemeData(
      color: cardColor, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor, height: 76,
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
    ),
    dividerColor: dark ? const Color(0xFF37404C) : null,
  );
}
