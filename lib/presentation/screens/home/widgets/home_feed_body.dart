import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/fun_card_group.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';
import 'package:yakku/presentation/screens/home/widgets/just_for_fun_section.dart';
import 'package:yakku/presentation/screens/home/widgets/mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/write_own_question_cta.dart';

class HomeFeedBody extends StatelessWidget {
  const HomeFeedBody({
    super.key,
    required this.mirrorChecks,
    this.errorMessage,
    required this.questionsWorthAsking,
    this.funGroups = const [],
    this.leading,
  });

  /// Fun card types, each with a preview row of its cards (the ones already made are not shown).
  final List<FunCardGroup> funGroups;

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
    final fun = [
      for (final group in funGroups)
        if (group.cards.any((card) => !card.used))
          FunCardGroup(
            typeId: group.typeId,
            name: group.name,
            totalCount: group.totalCount,
            cards: [
              for (final card in group.cards)
                if (!card.used) card,
            ],
          ),
    ];
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
        if (moreChecks.isNotEmpty) const SizedBox(height: 28),
        // One row per card type, each starting its own line under the type's name.
        for (final group in fun) ...[
          JustForFunSection(
            title: group.name,
            typeId: group.typeId,
            cards: group.cards,
            totalCount: group.totalCount,
          ),
          const SizedBox(height: 28),
        ],
        const WriteOwnQuestionCta(),
      ],
    );
  }
}
