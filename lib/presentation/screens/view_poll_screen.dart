import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_colors.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/presentation/app_scope.dart';

class ViewPollScreen extends StatefulWidget {
  const ViewPollScreen({super.key, required this.pollId});

  final String pollId;

  @override
  State<ViewPollScreen> createState() => _ViewPollScreenState();
}

class _ViewPollScreenState extends State<ViewPollScreen> {
  bool _isLoading = true;
  Object? _error;
  UserPollDetailResponse? _poll;
  bool _hasRequestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasRequestedLoad) {
      _hasRequestedLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final poll = await AppScope.of(
        context,
      ).userRemote.getOwnedPollDetails(widget.pollId);
      if (!mounted) return;
      setState(() {
        _poll = poll;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  String _errorMessage(Object error) {
    return DioErrorMapper.map(
      error,
      fallback: 'Could not load this poll. Please try again.',
    ).message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poll details')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage(_error!),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final poll = _poll;
    if (poll == null) {
      return const Center(child: Text('Poll not found.'));
    }

    final options = [...poll.pollOptions]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          poll.question,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          poll.totalVoteCount == 1 ? '1 vote' : '${poll.totalVoteCount} votes',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        _YouVsCrowdCard(comparison: poll.youVsCrowd),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Results',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final option in options) ...[
          _OptionResultTile(
            option: option,
            highlighted: option.id == poll.youVsCrowd.yourOptionId,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _YouVsCrowdCard extends StatelessWidget {
  const _YouVsCrowdCard({required this.comparison});

  final YouVsCrowdResponse comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agrees = comparison.agreesWithCrowd;
    final statusLabel = agrees == null
        ? 'See how your pick stacks up'
        : agrees
        ? 'You agree with the crowd'
        : 'You differ from the crowd';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You vs crowd',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            statusLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ComparisonColumn(
                  label: 'You',
                  optionText: comparison.yourOptionText ?? 'No vote yet',
                  percent: comparison.yourOptionPercentage,
                  accent: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ComparisonColumn(
                  label: 'Crowd',
                  optionText:
                      comparison.crowdLeadingOptionText ?? 'Waiting on votes',
                  percent: comparison.crowdLeadingPercentage,
                  accent: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  const _ComparisonColumn({
    required this.label,
    required this.optionText,
    required this.percent,
    required this.accent,
  });

  final String label;
  final String optionText;
  final double? percent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          optionText,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _formatPercent(percent),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OptionResultTile extends StatelessWidget {
  const _OptionResultTile({required this.option, required this.highlighted});

  final UserPollDetailOptionResponse option;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = option.percentage.clamp(0, 100);
    final voteLabel = option.voteCount == 1
        ? '1 vote'
        : '${option.voteCount} votes';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: highlighted ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.text ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (highlighted)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    'Your pick',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                _formatPercent(percent.toDouble()),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: highlighted ? AppColors.accent : AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            voteLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPercent(double? value) {
  if (value == null) return '—';
  final rounded = value.roundToDouble();
  if (value == rounded) return '${value.round()}%';
  return '${value.toStringAsFixed(1)}%';
}
