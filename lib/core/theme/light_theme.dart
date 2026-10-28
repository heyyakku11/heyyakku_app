import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.light(
    primary: YakkuPalette.primary,
    onPrimary: YakkuPalette.white,
    secondary: YakkuPalette.coral,
    onSecondary: YakkuPalette.white,
    tertiary: YakkuPalette.teal,
    surface: YakkuPalette.cream,
    onSurface: YakkuPalette.slate,
    onSurfaceVariant: YakkuPalette.muted,
    outline: YakkuPalette.mist,
    outlineVariant: YakkuPalette.outlineLight,
    error: YakkuPalette.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: YakkuPalette.cream,
    // Every AppBar back button (and any BackButton) uses this one icon.
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) =>
          const Icon(Icons.arrow_back_ios_new_rounded),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: YakkuPalette.cream,
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
      color: YakkuPalette.white,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dividerColor: YakkuPalette.border,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: YakkuPalette.cream,
      selectedItemColor: YakkuPalette.primary,
      unselectedItemColor: YakkuPalette.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: YakkuPalette.white,
      hintStyle: const TextStyle(color: YakkuPalette.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: YakkuPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: YakkuPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: YakkuPalette.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: YakkuPalette.primary,
        foregroundColor: YakkuPalette.white,
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
      bodyLarge: TextStyle(
        fontSize: 16,
        color: YakkuPalette.slate,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: YakkuPalette.slate,
        height: 1.4,
      ),
      bodySmall: TextStyle(fontSize: 12, color: YakkuPalette.muted),
    ),
  );
}
