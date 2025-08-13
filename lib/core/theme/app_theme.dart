import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ColorScheme _lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0D47A1),
  brightness: Brightness.light,
);
ColorScheme _darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0D47A1),
  brightness: Brightness.dark,
);

ThemeData buildLightTheme(TextStyle Function({TextStyle? textStyle}) font) {
  final base = ThemeData(colorScheme: _lightColorScheme, useMaterial3: true);
  return base.copyWith(
    textTheme: GoogleFonts.openSansTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.surface,
      foregroundColor: _lightColorScheme.onSurface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

ThemeData buildDarkTheme(TextStyle Function({TextStyle? textStyle}) font) {
  final base = ThemeData(colorScheme: _darkColorScheme, useMaterial3: true);
  return base.copyWith(
    textTheme: GoogleFonts.openSansTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkColorScheme.surface,
      foregroundColor: _darkColorScheme.onSurface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
