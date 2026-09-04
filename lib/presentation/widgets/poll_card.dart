import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/utils/date_formatters.dart';
import 'package:yakku/core/utils/number_formatters.dart';
import 'package:yakku/domain/entities/poll.dart';
import 'package:yakku/presentation/widgets/anonymous_avatar.dart';
import 'package:yakku/presentation/widgets/poll_option.dart';

class PollCard extends StatelessWidget {
  const PollCard({
    super.key,
    required this.poll,
    required this.onVote,
    this.onOpen,
    this.showResultsWhenVoted = true,
  });

  final Poll poll;
  final ValueChanged<String> onVote;
  final VoidCallback? onOpen;
  final bool showResultsWhenVoted;

  @override
  Widget build(BuildContext context) {
    final showResults = showResultsWhenVoted && poll.hasVoted;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  AnonymousAvatar(seed: poll.creatorId.hashCode),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poll.isAnonymous ? 'Anonymous' : 'Yakku user',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          timeAgo(poll.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: onOpen,
              child: Text(
                poll.question,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final option in poll.options) ...[
              PollOptionTile(
                option: option,
                selected: poll.selectedOptionIds.contains(option.id),
                showResults: showResults,
                percent: poll.percentageFor(option),
                onTap: () => onVote(option.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.how_to_vote_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${compactNumber(poll.totalVotes)} votes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
