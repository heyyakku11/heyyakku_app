import 'package:flutter/material.dart';
import 'package:yakku/core/theme/dark_theme.dart';
import 'package:yakku/core/theme/light_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();
}
