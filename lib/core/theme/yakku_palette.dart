import 'package:flutter/material.dart';

/// Single source of truth for every color in the app. Screens and widgets
/// must reference these constants instead of declaring their own colors.
abstract final class YakkuPalette {
  // Brand
  static const Color primary = Color(0xFFD02E62);
  static const Color primaryBright = Color(0xFFE94F79);
  static const Color primaryDeep = Color(0xFFC72A5B);
  static const Color cardPink = Color(0xFFD9557F);

  // Surfaces
  static const Color cream = Color(0xFFFFF9F6);
  static const Color mist = Color(0xFFF1F5F4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color chipSand = Color(0xFFF4EBE6);
  static const Color greyBlush = Color(0xFFF6F1F3);
  static const Color settingsTile = Color(0xFFE6D5DA);
  static const Color charcoal = Color(0xFF1B1418);
  static const Color crowdPanel = Color(0xFF2A2227);
  static const Color nearBlack = Color(0xFF111111);

  // Text
  static const Color textPrimary = Color(0xFF21191D);
  static const Color textSecondary = Color(0xFF7C6466);
  static const Color bodyInk = Color(0xFF4A4146);
  static const Color mutedRose = Color(0xFF8A7B80);
  static const Color hint = Color(0xFFB9A8AB);
  static const Color placeholder = Color(0xFFB0A4A7);
  static const Color inkDeep = Color(0xFF0E3A47);
  static const Color slate = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);

  // Borders and dividers
  static const Color border = Color(0xFFE6E1D8);
  static const Color hairline = Color(0xFFF1E7EA);
  static const Color roseBorder = Color(0xFFF3E6EA);
  static const Color outlineLight = Color(0xFFD7E0E3);
  static const Color outlineDark = Color(0xFF2C3E46);
  static const Color disabledMauve = Color(0xFFD5C6C8);
  static const Color mutedMauve = Color(0xFFD0C6C8);
  static const Color stepInactive = Color(0xFFE5DCDF);
  static const Color sheetHandle = Color(0xFFE9B7C6);

  // Pastel fills
  static const Color accentYellow = Color(0xFFFFEFC2);
  static const Color accentPurple = Color(0xFFECE3FF);
  static const Color accentGreen = Color(0xFFDDF3E4);
  static const Color mint = Color(0xFFDCF3E3);
  static const Color mintBright = Color(0xFFB7F8DB);
  static const Color butter = Color(0xFFFFE7A3);
  static const Color lavender = Color(0xFFE4D7FF);
  static const Color skyTint = Color(0xFFD6E8FF);
  static const Color iceBlue = Color(0xFFB8E7FF);
  static const Color skyBlue = Color(0xFF8FD3F4);
  static const Color violetTint = Color(0xFFCDB4FF);
  static const Color violet = Color(0xFFA78BFA);
  static const Color orchid = Color(0xFFFFC6FF);
  static const Color peach = Color(0xFFFFD6A5);
  static const Color salmon = Color(0xFFFF9F9F);
  static const Color blushFill = Color(0xFFF8D6E0);
  static const Color blushSoft = Color(0xFFF8D3E0);
  static const Color pillPink = Color(0xFFFDDDE6);
  static const Color pinkMist = Color(0xFFFCE8EF);
  static const Color pinkTint = Color(0xFFFFDFE8);
  static const Color pinkTintSoft = Color(0xFFFFDDE5);
  static const Color pinkWash = Color(0xFFF7D5E2);
  static const Color avatarPink = Color(0xFFF4A8C4);

  // Accent inks
  static const Color goldInk = Color(0xFF8A6A12);
  static const Color purpleInk = Color(0xFF6B4FBB);
  static const Color forestGreen = Color(0xFF1B5E37);
  static const Color successGreen = Color(0xFF2E7D4F);
  static const Color liveGreen = Color(0xFF4ADE80);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealSoft = Color(0xFF14B8A6);
  static const Color coral = Color(0xFFE07A5F);
  static const Color rose = Color(0xFFE11D48);

  // Status
  static const Color error = Color(0xFFB42318);
  static const Color errorDark = Color(0xFFF97066);
  static const Color danger = Color(0xFF9B2348);
  static const Color dangerDisabled = Color(0xFFE7C5D0);
  static const Color glowRed = Color(0xFFD32F2F);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color red500 = Color(0xFFF44336);

  // Neutral greys
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);

  // Translucent overlays and shadows
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white82 = Color(0xD1FFFFFF);
  static const Color black18 = Color(0x2E000000);
  static const Color black25 = Color(0x40000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black65 = Color(0xA6000000);
  static const Color shadowInk08 = Color(0x1421191D);
  static const Color shadowInk10 = Color(0x1A21191D);

  // Brand colors of third-party share targets
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color snapchatYellow = Color(0xFFFFFC00);
  static const Color instagramPink = Color(0xFFD62976);
  static const Color instagramYellow = Color(0xFFFEDA75);
  static const Color instagramOrange = Color(0xFFFA7E1E);
  static const Color instagramPurple = Color(0xFF962FBF);
  static const Color instagramBlue = Color(0xFF4F5BD5);

  // Dark theme
  static const Color night = Color(0xFF0B1418);
  static const Color nightElevated = Color(0xFF132026);
  static const Color nightCard = Color(0xFF1A2A31);
  static const Color nightMist = Color(0xFF24343C);
  static const Color nightText = Color(0xFFF1F5F4);
  static const Color nightMuted = Color(0xFF94A3B8);
}
