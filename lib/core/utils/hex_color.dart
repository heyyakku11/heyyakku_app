import 'package:flutter/painting.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

Color parseHexColor(
  Object? value, {
  Color fallback = YakkuPalette.textPrimary,
}) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return fallback;

  var hex = raw.startsWith('#') ? raw.substring(1) : raw;
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return fallback;

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}
