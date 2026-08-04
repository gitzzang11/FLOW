import 'dart:math' as math;

import 'package:flutter/material.dart';

void showAppToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_outline_rounded,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final accent = isError
      ? (isDark ? const Color(0xFFFF8A80) : scheme.error)
      : (isDark ? const Color(0xFF80CBC4) : scheme.primary);
  final toastBackground = isDark
      ? const Color(0xFF242629)
      : scheme.surface;
  final toastForeground = isDark ? Colors.white : scheme.onSurface;
  final toastWidth = math.min(
    420.0,
    math.max(260.0, MediaQuery.sizeOf(context).width - 32),
  );
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        width: toastWidth,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: toastBackground,
        elevation: isDark ? 12 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: accent.withOpacity(isDark ? 0.45 : 0.25),
          ),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.18 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : icon,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: toastForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: accent,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

ThemeData buildTheme(Brightness brightness, Color seed) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFFFFFFF),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? Colors.black
        : const Color(0xFFF8FAFC),
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF8FAFC),
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF161618)
          : const Color(0xFFF8FAFC),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
    ),
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
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFFDFCF7),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      showCloseIcon: false,
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.dark
          ? const Color(0xFF1C1C1E)
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
