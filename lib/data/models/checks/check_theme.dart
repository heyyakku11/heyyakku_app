import 'dart:ui';

import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';

/// The sticker on every check card. It is fixed in the app; the API no longer sends one.
const kCheckSticker = 'No filter, Just truth';

/// The visual theme of a check, as sent by the backend (`theme.config`).
///
/// The app never hardcodes the Mirror / Vibe / Trust looks: it renders whatever theme
/// the backend assigned to the check. Optional properties fall back to safe defaults,
/// so an older or partial theme can never crash a card.
class CheckTheme {
  const CheckTheme({
    required this.heading,
    required this.backgroundColor,
    required this.headingColor,
    required this.questionColor,
    required this.accentColor,
    required this.stickerLabel,
    required this.stickerColor,
    required this.optionBackgroundColor,
    required this.optionTextColor,
    this.backgroundGradient,
    this.checkType,
    this.isLegacy = false,
  });

  /// Stable type code such as `VIBE_CHECK`; null for legacy checks.
  final String? checkType;
  final bool isLegacy;

  final String heading;
  final Color backgroundColor;

  /// Two or more colors, top to bottom; when set it replaces the flat background.
  final List<Color>? backgroundGradient;
  final Color headingColor;
  final Color questionColor;
  final Color accentColor;
  final String stickerLabel;
  final Color stickerColor;
  final Color optionBackgroundColor;
  final Color optionTextColor;

  /// Theme for checks that came without one (older backend / legacy checks).
  factory CheckTheme.legacy({
    required String title,
    required String backgroundColor,
  }) {
    return CheckTheme(
      isLegacy: true,
      heading: title,
      backgroundColor: parseHexColor(
        backgroundColor,
        fallback: YakkuPalette.cream,
      ),
      headingColor: YakkuPalette.textPrimary,
      questionColor: YakkuPalette.textPrimary,
      accentColor: YakkuPalette.primary,
      stickerLabel: kCheckSticker,
      stickerColor: YakkuPalette.primary,
      optionBackgroundColor: YakkuPalette.white,
      optionTextColor: YakkuPalette.textPrimary,
    );
  }

  /// Parses `{ checkType, isLegacy, config: {...} }`. Returns null when [json] has no usable config.
  static CheckTheme? tryParse(Object? json) {
    if (json is! Map) return null;
    final envelope = Map<String, dynamic>.from(json);
    final rawConfig = envelope['config'];
    if (rawConfig is! Map) return null;
    final c = Map<String, dynamic>.from(rawConfig);

    final accent = parseHexColor(
      c['accentColor'],
      fallback: YakkuPalette.primary,
    );
    final stops = <Color>[
      if (c['backgroundGradient'] is List)
        for (final stop in c['backgroundGradient'] as List)
          parseHexColor(stop, fallback: const Color(0x00000000)),
    ];

    return CheckTheme(
      checkType: envelope['checkType']?.toString(),
      isLegacy: envelope['isLegacy'] as bool? ?? false,
      heading: c['heading']?.toString() ?? '',
      backgroundColor: parseHexColor(
        c['backgroundColor'],
        fallback: YakkuPalette.cream,
      ),
      backgroundGradient: stops.length >= 2 ? stops : null,
      headingColor: parseHexColor(
        c['labelColor'],
        fallback: YakkuPalette.textPrimary,
      ),
      questionColor: parseHexColor(
        c['questionColor'],
        fallback: YakkuPalette.textPrimary,
      ),
      accentColor: accent,
      stickerLabel: kCheckSticker,
      stickerColor: parseHexColor(c['stickerColor'], fallback: accent),
      optionBackgroundColor: parseHexColor(
        c['optionBackgroundColor'],
        fallback: YakkuPalette.white,
      ),
      optionTextColor: parseHexColor(
        c['optionTextColor'],
        fallback: YakkuPalette.textPrimary,
      ),
    );
  }
}
