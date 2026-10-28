import 'package:flutter/painting.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';

class AskFriendsOption {
  const AskFriendsOption({
    required this.label,
    this.letter,
    this.outlined = false,
    this.id,
  });

  final String label;
  final String? id;
  final String? letter;
  final bool outlined;
}

/// Shared payload for check detail / create-from-card flows.
class AskFriendsCheck {
  const AskFriendsCheck({
    required this.title,
    required this.question,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
    required this.options,
    this.eyebrow,
    this.meta,
    this.sticker,
    this.checkId,
  });

  /// Backend check id; set only for checks that come from the API.
  final String? checkId;
  final String title;
  final String question;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;
  final String? eyebrow;
  final String? meta;
  final String? sticker;
  final List<AskFriendsOption> options;

  factory AskFriendsCheck.fromMirrorCheck(MirrorCheck check) {
    return AskFriendsCheck(
      checkId: check.id,
      title: check.title,
      question: check.question,
      backgroundColor: check.backgroundColor,
      foregroundColor: check.foregroundColor,
      accentColor: check.accentColor,
      eyebrow: check.eyebrow,
      meta: check.meta,
      sticker: check.sticker,
      options: [
        for (final option in check.options)
          if (!option.outlined && option.label.trim().isNotEmpty)
            AskFriendsOption(
              id: option.id,
              label: option.label,
              letter: option.letter,
            ),
      ],
    );
  }

  factory AskFriendsCheck.fromQuestion(QuestionWorthAsking question) {
    return AskFriendsCheck(
      title: question.question,
      question: question.question,
      backgroundColor: YakkuPalette.cream,
      foregroundColor: YakkuPalette.textPrimary,
      accentColor: YakkuPalette.primary,
      options: [
        for (var i = 0; i < question.options.length; i++)
          AskFriendsOption(
            label: question.options[i],
            letter: String.fromCharCode(65 + i),
          ),
      ],
    );
  }

  List<String> get answerableLabels => [
    for (final option in options)
      if (!option.outlined && option.label.trim().isNotEmpty)
        option.label.trim(),
  ];
}
