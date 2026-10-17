import 'package:flutter/painting.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';
import 'package:yakku/data/models/checks/check_response.dart';

class MirrorCheckOption {
  const MirrorCheckOption({
    required this.label,
    this.letter,
    this.trailing,
    this.outlined = false,
    this.id,
  });

  final String label;

  /// Backend option id; null for dummy / UI-only options.
  final String? id;
  final String? letter;
  final String? trailing;
  final bool outlined;

  /// Accepts either `"Never"` or `{ "label": "Never", ... }`.
  factory MirrorCheckOption.fromJson(Object? raw, {int index = 0}) {
    if (raw is String) {
      return MirrorCheckOption(
        label: raw.trim(),
        letter: String.fromCharCode(65 + index),
      );
    }

    if (raw is Map) {
      final json = Map<String, dynamic>.from(raw);
      final letter = json['letter']?.toString().trim();
      return MirrorCheckOption(
        label: json['label']?.toString().trim() ?? '',
        letter: (letter != null && letter.isNotEmpty)
            ? letter
            : String.fromCharCode(65 + index),
        trailing: json['trailing']?.toString(),
        outlined: json['outlined'] as bool? ?? false,
      );
    }

    return const MirrorCheckOption(label: '');
  }
}

class MirrorCheck {
  const MirrorCheck({
    required this.title,
    required this.question,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.chipColor,
    required this.accentColor,
    required this.options,
    this.eyebrow,
    this.meta,
    this.sticker,
    this.id,
    this.used = false,
  });

  /// Backend check id; null for dummy cards.
  final String? id;

  /// True once the caller has made this check.
  final bool used;
  final String title;
  final String question;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color chipColor;
  final Color accentColor;
  final String? eyebrow;
  final String? meta;
  final String? sticker;
  final List<MirrorCheckOption> options;

  /// The backend only sends the background colour; the rest follows the
  /// shared card palette.
  factory MirrorCheck.fromCheck(CheckResponse check) {
    return MirrorCheck(
      id: check.id,
      used: check.used,
      title: check.title,
      question: check.question,
      backgroundColor: parseHexColor(
        check.backgroundColor,
        fallback: YakkuPalette.cream,
      ),
      foregroundColor: YakkuPalette.textPrimary,
      chipColor: const Color(0xFFFFFFFF),
      accentColor: YakkuPalette.primary,
      sticker: check.sticker.trim().isEmpty ? null : check.sticker,
      options: [
        for (var i = 0; i < check.options.length; i++)
          MirrorCheckOption(
            id: check.options[i].id,
            label: check.options[i].text,
            letter: String.fromCharCode(65 + i),
          ),
      ],
    );
  }

  factory MirrorCheck.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return MirrorCheck(
      title: json['title']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      backgroundColor: parseHexColor(
        json['backgroundColor'],
        fallback: YakkuPalette.cream,
      ),
      foregroundColor: parseHexColor(
        json['foregroundColor'],
        fallback: YakkuPalette.textPrimary,
      ),
      chipColor: parseHexColor(
        json['chipColor'],
        fallback: const Color(0xFFF6F1F3),
      ),
      accentColor: parseHexColor(
        json['accentColor'],
        fallback: YakkuPalette.primary,
      ),
      eyebrow: json['eyebrow']?.toString(),
      meta: json['meta']?.toString(),
      sticker: json['sticker']?.toString(),
      options: [
        for (var i = 0; i < rawOptions.length; i++)
          MirrorCheckOption.fromJson(rawOptions[i], index: i),
      ],
    );
  }

  List<String> get answerableLabels => [
    for (final option in options)
      if (!option.outlined && option.label.trim().isNotEmpty)
        option.label.trim(),
  ];
}
