import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.light(
    primary: YakkuPalette.ink,
    onPrimary: Colors.white,
    secondary: YakkuPalette.coral,
    onSecondary: Colors.white,
    tertiary: YakkuPalette.teal,
    surface: YakkuPalette.cream,
    onSurface: YakkuPalette.slate,
    onSurfaceVariant: YakkuPalette.muted,
    outline: YakkuPalette.mist,
    outlineVariant: const Color(0xFFD7E0E3),
    error: const Color(0xFFB42318),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: YakkuPalette.sand,
    appBarTheme: const AppBarTheme(
      backgroundColor: YakkuPalette.sand,
      foregroundColor: YakkuPalette.slate,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: YakkuPalette.inkDeep,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: YakkuPalette.cream,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: Color(0xFFE6E1D8)),
      ),
    ),
    dividerColor: const Color(0xFFE6E1D8),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: YakkuPalette.inkDeep,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: YakkuPalette.cream,
      selectedItemColor: YakkuPalette.ink,
      unselectedItemColor: YakkuPalette.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: YakkuPalette.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: Color(0xFFE6E1D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: Color(0xFFE6E1D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: YakkuPalette.ink, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: YakkuPalette.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: YakkuPalette.inkDeep,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: YakkuPalette.inkDeep,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: YakkuPalette.slate,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: YakkuPalette.slate, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, color: YakkuPalette.slate, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, color: YakkuPalette.muted),
    ),
  );
}
