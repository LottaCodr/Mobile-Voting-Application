import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF102A43);
  static const blue = Color(0xFF1D5FD0);
  static const blueDark = Color(0xFF164E9A);
  static const bluePale = Color(0xFFEAF2FF);
  static const teal = Color(0xFF007C6C);
  static const tealPale = Color(0xFFE2F5F0);
  static const gold = Color(0xFF9A6700);
  static const goldPale = Color(0xFFFFF4D6);
  static const red = Color(0xFFB42318);
  static const redPale = Color(0xFFFFE9E7);
  static const inkMuted = Color(0xFF52677D);
  static const border = Color(0xFFD6DFE9);
  static const canvas = Color(0xFFF6F8FC);
  static const surface = Colors.white;
}

ThemeData buildAppTheme() => _buildTheme(Brightness.light);

ThemeData buildDarkAppTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: brightness,
    primary: isDark ? const Color(0xFF9FC3FF) : AppColors.blue,
    onPrimary: isDark ? const Color(0xFF002C63) : Colors.white,
    secondary: isDark ? const Color(0xFF6FE1CF) : AppColors.teal,
    onSecondary: isDark ? const Color(0xFF003F36) : Colors.white,
    surface: isDark ? const Color(0xFF132235) : AppColors.surface,
    onSurface: isDark ? const Color(0xFFF1F6FC) : AppColors.navy,
    error: isDark ? const Color(0xFFFFB4AB) : AppColors.red,
    onError: isDark ? const Color(0xFF690005) : Colors.white,
  );
  final canvas = isDark ? const Color(0xFF0B1726) : AppColors.canvas;
  final border = isDark ? const Color(0xFF31455B) : AppColors.border;
  final muted = isDark ? const Color(0xFFB4C6DB) : AppColors.inkMuted;
  final card = isDark ? const Color(0xFF132235) : Colors.white;

  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme, fontFamily: 'Montserrat');

  return base.copyWith(
    scaffoldBackgroundColor: canvas,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: TextStyle(color: muted),
      hintStyle: TextStyle(color: muted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: card,
      indicatorColor: isDark ? const Color(0xFF1D416C) : AppColors.bluePale,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected) ? colorScheme.primary : muted,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? colorScheme.primary : muted,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFFEAF2FF) : AppColors.navy,
      contentTextStyle: TextStyle(
        color: isDark ? AppColors.navy : Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: colorScheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
