import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';
import 'package:yakku/presentation/screens/home/widgets/check_done_card.dart';
import 'package:yakku/presentation/screens/poll_results_screen.dart';
import 'package:yakku/presentation/screens/home/widgets/mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/write_own_question_cta.dart';

class HomeFeedBody extends StatelessWidget {
  const HomeFeedBody({
    super.key,
    required this.mirrorChecks,
    this.myChecks = const [],
    this.errorMessage,
    required this.questionsWorthAsking,
    this.leading,
  });

  /// Shown first, above the checks (the personality card).
  final Widget? leading;

  final List<MirrorCheck> mirrorChecks;
  final List<UserCheckResponse> myChecks;
  final String? errorMessage;
  final List<QuestionWorthAsking> questionsWorthAsking;

  /// Opens the user's own card made from [check], if it has loaded.
  void _viewCard(BuildContext context, MirrorCheck check) {
    final matches = myChecks.where((c) => c.checkId == check.id);
    if (matches.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PollResultsScreen.check(check: matches.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the API order, but move checks the user already made to the end.
    final ordered = [
      for (final check in mirrorChecks)
        if (!check.used) check,
      for (final check in mirrorChecks)
        if (check.used) check,
    ];
    // The featured slot only shows as done once every check has been made.
    final featured = ordered.isEmpty ? null : ordered.first;
    final moreChecks = ordered.skip(1).toList();
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (leading != null) ...[leading!, const SizedBox(height: 24)],
        if (errorMessage != null) ...[
          Text(errorMessage!, style: TextStyle(color: ink)),
          const SizedBox(height: 22),
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
            CheckDoneCard(
              check: featured,
              onViewCard: () => _viewCard(context, featured),
            ),
          ] else
            CurrentMirrorCheckCard(check: featured),
          const SizedBox(height: 28),
        ],
        MoreChecksSection(
          checks: moreChecks,
          onViewCard: (check) => _viewCard(context, check),
        ),
        const SizedBox(height: 28),
        const WriteOwnQuestionCta(),
      ],
    );
  }
}
