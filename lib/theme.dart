import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness, Color seed) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : const Color(0xFFFFFFFF),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC),
    textTheme: base.textTheme.apply(
      bodyColor: brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF102A2D),
      displayColor: brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF102A2D),
    ),
    cardTheme: CardThemeData(
      color: brightness == Brightness.dark
          ? const Color(0xCC102030)
          : const Color(0xFFFDFCF7),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.dark
          ? const Color(0xFF102436)
          : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

String formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

class AppGradients {
  static List<Color> main(Brightness brightness) =>
      brightness == Brightness.dark
      ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)]
      : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)];

  static const accent = [Color(0xFF6366F1), Color(0xFFA855F7)];
}
