import 'package:flutter/painting.dart';

enum HomeFeedOptionLayout { lettered, chips }

enum HomeFeedCardActions { askOnly, editAndShare }

class HomeFeedOption {
  const HomeFeedOption({
    required this.label,
    this.letter,
    this.trailing,
    this.outlined = false,
  });

  final String label;
  final String? letter;
  final String? trailing;
  final bool outlined;
}

class HomeFeedCard {
  const HomeFeedCard({
    required this.title,
    required this.question,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.chipColor,
    required this.accentColor,
    required this.options,
    required this.layout,
    required this.actions,
    this.eyebrow,
    this.meta,
    this.sticker,
  });

  final String title;
  final String question;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color chipColor;
  final Color accentColor;
  final String? eyebrow;
  final String? meta;
  final String? sticker;
  final List<HomeFeedOption> options;
  final HomeFeedOptionLayout layout;
  final HomeFeedCardActions actions;
}

class HomeFeedSection {
  const HomeFeedSection({
    required this.title,
    required this.cards,
    this.trailing,
  });

  final String title;
  final String? trailing;
  final List<HomeFeedCard> cards;
}

class HomeFeed {
  const HomeFeed({
    required this.weeklyDrop,
    required this.moreChecks,
    required this.questions,
  });

  final HomeFeedCard weeklyDrop;
  final HomeFeedSection moreChecks;
  final HomeFeedSection questions;
}
