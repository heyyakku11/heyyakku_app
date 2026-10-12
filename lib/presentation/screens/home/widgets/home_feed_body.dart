import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';
import 'package:yakku/presentation/screens/home/widgets/mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/question_worth_asking_card.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';

class HomeFeedBody extends StatelessWidget {
  const HomeFeedBody({
    super.key,
    required this.mirrorChecks,
    required this.questionsWorthAsking,
  });

  final List<MirrorCheck> mirrorChecks;
  final List<QuestionWorthAsking> questionsWorthAsking;

  @override
  Widget build(BuildContext context) {
    final featured = mirrorChecks.isEmpty ? null : mirrorChecks.first;
    final moreChecks = mirrorChecks.length > 1
        ? mirrorChecks.sublist(1)
        : const <MirrorCheck>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const _FeedHeader(),
        const SizedBox(height: 22),
        if (featured != null) ...[
          // Index 0 → current/ongoing design; list order alone picks the widget.
          CurrentMirrorCheckCard(check: featured),
          const SizedBox(height: 28),
        ],
        // Indexes 1..end → SubMirrorCheckCard inside MoreChecksSection.
        MoreChecksSection(checks: moreChecks),
        const SizedBox(height: 28),
        QuestionsWorthAskingSection(questions: questionsWorthAsking),
      ],
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ink = theme.brightness == Brightness.dark
        ? colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Yakku',
            style: TextStyle(
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: ink,
            ),
            children: const [
              TextSpan(
                text: '.',
                style: TextStyle(color: YakkuPalette.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask your friends anything.\nThey answer anonymously.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: ink,
            fontSize: 24,
            height: 1.28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
