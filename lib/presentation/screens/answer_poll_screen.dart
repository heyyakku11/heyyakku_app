import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/screens/poll_flow_args.dart';

class AnswerPollScreen extends StatefulWidget {
  const AnswerPollScreen({super.key, required this.poll});

  final PollResponse poll;

  @override
  State<AnswerPollScreen> createState() => _AnswerPollScreenState();
}

class _AnswerPollScreenState extends State<AnswerPollScreen> {
  String? _selectedOptionId;

  void _onSubmit() {
    final optionId = _selectedOptionId;
    if (optionId == null) return;

    context.pushReplacement(
      AppRoutes.pollResults,
      extra: PollResultsArgs(
        poll: widget.poll,
        selectedOptionId: optionId,
        vote: CastVoteResponse(
          id: 'local-vote',
          pollId: widget.poll.id,
          pollOptionId: optionId,
          createdAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [...widget.poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(title: const Text('Your opinion')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.poll.question,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pick the option that matches your view',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return _OptionChoiceTile(
                      option: option,
                      selected: option.id == _selectedOptionId,
                      onTap: () =>
                          setState(() => _selectedOptionId = option.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _selectedOptionId == null ? null : _onSubmit,
                child: const Text('Submit opinion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChoiceTile extends StatelessWidget {
  const _OptionChoiceTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PollOptionResponse option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.text ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
