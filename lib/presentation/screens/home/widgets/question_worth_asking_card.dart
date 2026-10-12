import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

class QuestionsWorthAskingSection extends StatelessWidget {
  const QuestionsWorthAskingSection({super.key, required this.questions});

  final List<QuestionWorthAsking> questions;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions worth asking',
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < questions.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          QuestionWorthAskingCard(question: questions[index]),
        ],
      ],
    );
  }
}

class QuestionWorthAskingCard extends StatelessWidget {
  const QuestionWorthAskingCard({super.key, required this.question});

  final QuestionWorthAsking question;

  static const _chipColor = Color(0xFFF4EBE6);

  @override
  Widget build(BuildContext context) {
    final draft = AskFriendsCheck.fromQuestion(question);

    return DecoratedBox(
      decoration: feedCardDecoration(Colors.white),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: const TextStyle(
                color: YakkuPalette.textPrimary,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            FeedOptionChips(
              labels: question.options,
              chipColor: _chipColor,
              textColor: YakkuPalette.textPrimary,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                FeedActionPill(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  textOnly: true,
                  onTap: () => openAskFriendsInCreateForm(context, draft),
                ),
                const Spacer(),
                FeedActionPill(
                  label: 'Ask my friends',
                  icon: Icons.ios_share,
                  onTap: () => openAskFriendsCheck(context, draft),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
