import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.dark(
    primary: YakkuPalette.tealSoft,
    onPrimary: YakkuPalette.night,
    secondary: YakkuPalette.coral,
    onSecondary: Colors.white,
    tertiary: YakkuPalette.tealSoft,
    surface: YakkuPalette.nightCard,
    onSurface: YakkuPalette.nightText,
    onSurfaceVariant: YakkuPalette.nightMuted,
    outline: YakkuPalette.nightMist,
    outlineVariant: const Color(0xFF2C3E46),
    error: const Color(0xFFF97066),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: YakkuPalette.night,
    appBarTheme: const AppBarTheme(
      backgroundColor: YakkuPalette.night,
      foregroundColor: YakkuPalette.nightText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: YakkuPalette.nightText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: YakkuPalette.nightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: YakkuPalette.nightMist),
      ),
    ),
    dividerColor: YakkuPalette.nightMist,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: YakkuPalette.nightElevated,
      contentTextStyle: const TextStyle(color: YakkuPalette.nightText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: YakkuPalette.nightElevated,
      selectedItemColor: YakkuPalette.tealSoft,
      unselectedItemColor: YakkuPalette.nightMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: YakkuPalette.nightElevated,
      hintStyle: const TextStyle(color: YakkuPalette.nightMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: YakkuPalette.nightMist),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: YakkuPalette.nightMist),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: YakkuPalette.tealSoft, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: YakkuPalette.tealSoft,
        foregroundColor: YakkuPalette.night,
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
        color: YakkuPalette.nightText,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: YakkuPalette.nightText,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: YakkuPalette.nightText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: YakkuPalette.nightText,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: YakkuPalette.nightText,
        height: 1.4,
      ),
      bodySmall: TextStyle(fontSize: 12, color: YakkuPalette.nightMuted),
    ),
  );
}
