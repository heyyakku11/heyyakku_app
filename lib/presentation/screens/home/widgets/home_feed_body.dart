import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';
import 'package:yakku/presentation/screens/home/widgets/check_done_card.dart';
import 'package:yakku/presentation/screens/home/widgets/mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/your_cards_section.dart';
import 'package:yakku/presentation/screens/home/widgets/question_worth_asking_card.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/write_own_question_cta.dart';

class HomeFeedBody extends StatelessWidget {
  const HomeFeedBody({
    super.key,
    required this.mirrorChecks,
    this.myChecks = const [],
    this.errorMessage,
    required this.questionsWorthAsking,
  });

  final List<MirrorCheck> mirrorChecks;
  final List<UserCheckResponse> myChecks;
  final String? errorMessage;
  final List<QuestionWorthAsking> questionsWorthAsking;

  @override
  Widget build(BuildContext context) {
    final featured = mirrorChecks.isEmpty ? null : mirrorChecks.first;
    // Made checks drop out of "More checks"; a made featured check shows as done.
    final moreChecks = [
      for (final check in mirrorChecks.skip(1))
        if (!check.used) check,
    ];
    final returning = myChecks.isNotEmpty;
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _FeedHeader(showTagline: !returning),
        const SizedBox(height: 22),
        if (errorMessage != null) ...[
          Text(errorMessage!, style: TextStyle(color: ink)),
          const SizedBox(height: 22),
        ],
        if (returning) ...[
          YourCardsSection(cards: myChecks),
          const SizedBox(height: 24),
        ],
        if (featured != null) ...[
          if (featured.used) ...[
            Text(
              "This week's drop",
              style: TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            CheckDoneCard(check: featured),
          ] else
            CurrentMirrorCheckCard(check: featured),
          const SizedBox(height: 28),
        ],
        MoreChecksSection(checks: moreChecks),
        const SizedBox(height: 28),
        QuestionsWorthAskingSection(questions: questionsWorthAsking),
        const SizedBox(height: 14),
        const WriteOwnQuestionCta(),
      ],
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({this.showTagline = true});

  /// Hidden once "Your cards" loads; the cards take its place.
  final bool showTagline;

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
        if (showTagline) ...[
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
      ],
    );
  }
}
