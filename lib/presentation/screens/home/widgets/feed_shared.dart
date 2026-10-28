import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/home/check_detail_screen.dart';

class FeedSticker extends StatelessWidget {
  const FeedSticker({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: YakkuPalette.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YakkuPalette.black.withValues(alpha: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pacifico',
              color: color,
              fontSize: 14,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class FeedActionPill extends StatelessWidget {
  const FeedActionPill({
    super.key,
    required this.label,
    required this.icon,
    this.filled = false,
    this.textOnly = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool textOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ink = YakkuPalette.charcoal;
    final foreground = filled ? YakkuPalette.white : ink;
    final background = filled ? ink : YakkuPalette.transparent;
    final borderColor = textOnly ? YakkuPalette.transparent : YakkuPalette.black;

    return Material(
      color: YakkuPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: textOnly ? 0 : 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: textOnly ? 4 : 14,
              vertical: textOnly ? 8 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeedOptionChips extends StatelessWidget {
  const FeedOptionChips({
    super.key,
    required this.labels,
    required this.chipColor,
    required this.textColor,
  });

  final List<String> labels;
  final Color chipColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          DecoratedBox(
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

BoxDecoration feedCardDecoration(Color background, {double radius = 22}) {
  return BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: YakkuPalette.shadowInk08, blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}

void openAskFriendsCheck(BuildContext context, AskFriendsCheck check) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => CheckDetailScreen(check: check),
    ),
  );
}

void openAskFriendsInCreateForm(BuildContext context, AskFriendsCheck check) {
  final question = check.question.trim().isNotEmpty
      ? check.question.trim()
      : check.title.trim();
  final draft = DraftPoll()
    ..question = question
    ..options = check.answerableLabels
    ..allowComments = true
    ..expiryDays = 0;
  showCreatePollSheet(context, draft: draft);
}
