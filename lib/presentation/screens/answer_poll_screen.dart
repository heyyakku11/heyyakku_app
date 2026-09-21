import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/poll_flow_args.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

class AnswerPollScreen extends StatefulWidget {
  const AnswerPollScreen({super.key, required this.poll});

  final PollResponse poll;

  @override
  State<AnswerPollScreen> createState() => _AnswerPollScreenState();
}

class _AnswerPollScreenState extends State<AnswerPollScreen> {
  String? _selectedOptionId;
  bool _isSubmitting = false;

  Future<void> _showError(String message) {
    return showAppAlert(
      context,
      title: 'Could not submit opinion',
      message: message,
    );
  }

  String _errorMessage(Object error) {
    return DioErrorMapper.map(
      error,
      fallback: 'Could not submit opinion. Please try again.',
    ).message;
  }

  Future<void> _onSubmit() async {
    final optionId = _selectedOptionId;
    if (optionId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final vote = await AppScope.of(
        context,
      ).pollApi.castVote(pollId: widget.poll.id, optionId: optionId);
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.pollResults,
        extra: PollResultsArgs(
          poll: widget.poll,
          selectedOptionId: optionId,
          vote: vote,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await _showError(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
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
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() => _selectedOptionId = option.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _selectedOptionId == null || _isSubmitting
                    ? null
                    : _onSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit opinion'),
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
