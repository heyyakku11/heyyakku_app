import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/utils/date_formatters.dart';
import 'package:yakku/core/utils/number_formatters.dart';
import 'package:yakku/domain/entities/poll_option.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/anonymous_avatar.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';
import 'package:yakku/presentation/widgets/empty_state.dart';
import 'package:yakku/presentation/widgets/poll_option.dart';

class PollDetailScreen extends StatelessWidget {
  const PollDetailScreen({super.key, required this.pollId});

  final String pollId;

  @override
  Widget build(BuildContext context) {
    final polls = AppScope.of(context).polls;

    return Scaffold(
      appBar: AppBar(title: const Text('Poll')),
      body: ListenableBuilder(
        listenable: polls,
        builder: (context, _) {
          final poll = polls.getPoll(pollId);
          if (poll == null) {
            return const EmptyState(
              title: 'Poll not found',
              message: 'This question may have been removed.',
            );
          }

          final showResults = poll.hasVoted;
          final regularOptions = <PollOption>[
            for (final option in poll.options)
              if (!option.isSomethingElse) option,
          ];
          PollOption? somethingElse;
          for (final option in poll.options) {
            if (option.isSomethingElse) {
              somethingElse = option;
              break;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            children: [
              Row(
                children: [
                  AnonymousAvatar(seed: poll.creatorId.hashCode),
                  const SizedBox(width: AppSpacing.md),
                  Column(
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
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                poll.question,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final option in regularOptions) ...[
                PollOptionTile(
                  option: option,
                  selected: poll.selectedOptionIds.contains(option.id),
                  showResults: showResults,
                  percent: poll.percentageFor(option),
                  onTap: () => polls.vote(poll.id, option.id),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (somethingElse != null) ...[
                if (showResults)
                  PollOptionTile(
                    option: somethingElse,
                    selected: poll.selectedOptionIds.contains(somethingElse.id),
                    showResults: true,
                    percent: poll.percentageFor(somethingElse),
                    onTap: () => polls.vote(poll.id, somethingElse!.id),
                  )
                else
                  _SomethingElseAnswerField(
                    onSubmitted: (text) {
                      polls.voteSomethingElse(poll.id, somethingElse!.id, text);
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${compactNumber(poll.totalVotes)} total votes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SomethingElseAnswerField extends StatefulWidget {
  const _SomethingElseAnswerField({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  State<_SomethingElseAnswerField> createState() =>
      _SomethingElseAnswerFieldState();
}

class _SomethingElseAnswerFieldState extends State<_SomethingElseAnswerField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmitted(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      hintText: AppLimits.somethingElseHint,
      maxLength: AppLimits.maxOptionLength,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      suffixIcon: IconButton(
        tooltip: 'Submit answer',
        onPressed: _submit,
        icon: const Icon(Icons.check_circle_outline),
      ),
    );
  }
}
