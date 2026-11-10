import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';
import 'package:yakku/presentation/screens/home/widgets/mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/write_own_question_cta.dart';

class HomeFeedBody extends StatelessWidget {
  const HomeFeedBody({
    super.key,
    required this.mirrorChecks,
    this.errorMessage,
    required this.questionsWorthAsking,
    this.leading,
  });

  /// Shown first, above the checks (the personality card).
  final Widget? leading;

  final List<MirrorCheck> mirrorChecks;
  final String? errorMessage;
  final List<QuestionWorthAsking> questionsWorthAsking;

  @override
  Widget build(BuildContext context) {
    // Checks the user has already made are not shown; keep the API order for
    // the rest.
    final ordered = [
      for (final check in mirrorChecks)
        if (!check.used) check,
    ];
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
          CurrentMirrorCheckCard(check: featured),
          const SizedBox(height: 28),
        ],
        MoreChecksSection(checks: moreChecks),
        const SizedBox(height: 28),
        const WriteOwnQuestionCta(),
      ],
    );
  }
}
