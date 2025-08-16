import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ColorScheme _lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1552F0),
  brightness: Brightness.light,
);
ColorScheme _darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1552F0),
  brightness: Brightness.dark,
);

ThemeData buildLightTheme(TextStyle Function({TextStyle? textStyle}) font) {
  final base = ThemeData(colorScheme: _lightColorScheme, useMaterial3: true);
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.surface,
      foregroundColor: _lightColorScheme.onSurface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _lightColorScheme.surface,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _lightColorScheme.primary.withOpacity(.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}

ThemeData buildDarkTheme(TextStyle Function({TextStyle? textStyle}) font) {
  final base = ThemeData(colorScheme: _darkColorScheme, useMaterial3: true);
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkColorScheme.surface,
      foregroundColor: _darkColorScheme.onSurface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _darkColorScheme.surface,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _darkColorScheme.primary.withOpacity(.14),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
