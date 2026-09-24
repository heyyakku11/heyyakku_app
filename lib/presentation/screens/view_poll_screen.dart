import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_colors.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/datasources/poll_list_datasource.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/poll_why.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/presentation/widgets/app_segmented_control.dart';

enum _PollDetailTab { summary, whys, somethingElse }

const _optionAccents = <Color>[
  YakkuPalette.coral,
  YakkuPalette.teal,
  YakkuPalette.ink,
  YakkuPalette.tealSoft,
];

/// Dummy vote shares for standard options + mandatory Something else.
const _dummyStandardPercentages = <double>[46, 42, 8];
const _dummySomethingElsePercent = 4.0;

const _dummySomethingElseAnswers = <String>[
  'Go with whatever feels right in the moment',
  'Ask a friend to decide for me',
  'Skip the plan and stay in',
  'Pick based on the weather that day',
];

class _PollDetailDummy {
  const _PollDetailDummy({
    required this.poll,
    required this.somethingElseAnswers,
    required this.somethingElseOptionId,
  });

  final UserPollDetailResponse poll;
  final List<String> somethingElseAnswers;
  final String somethingElseOptionId;
}

class ViewPollScreen extends StatefulWidget {
  const ViewPollScreen({super.key, required this.pollId});

  final String pollId;

  @override
  State<ViewPollScreen> createState() => _ViewPollScreenState();
}

class _ViewPollScreenState extends State<ViewPollScreen> {
  _PollDetailTab _tab = _PollDetailTab.summary;
  late final _PollDetailDummy _detail = _dummyPollDetail(widget.pollId);

  @override
  Widget build(BuildContext context) {
    final poll = _detail.poll;
    final options = [...poll.pollOptions]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final winner = _winningOption(options);

    Widget _buildTab({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      final theme = Theme.of(context);

      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          poll.question.isNotEmpty ? poll.question : 'Poll details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          children: [
            _FinalResultCard(winner: winner),
            const SizedBox(height: AppSpacing.lg),
            _YouVsCrowdCard(comparison: poll.youVsCrowd),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                _buildTab(
                  label: 'Summary',
                  selected: _tab == _PollDetailTab.summary,
                  onTap: () {
                    setState(() => _tab = _PollDetailTab.summary);
                  },
                ),
                _buildTab(
                  label: "Why's (${poll.totalWhyCount})",
                  selected: _tab == _PollDetailTab.whys,
                  onTap: () {
                    setState(() => _tab = _PollDetailTab.whys);
                  },
                ),
                _buildTab(
                  label:
                      'Something else (${_detail.somethingElseAnswers.length})',
                  selected: _tab == _PollDetailTab.somethingElse,
                  onTap: () {
                    setState(() => _tab = _PollDetailTab.somethingElse);
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            switch (_tab) {
              _PollDetailTab.summary => _SummaryTab(
                options: options,
                winnerId: winner?.id,
                somethingElseOptionId: _detail.somethingElseOptionId,
                whys: poll.whys,
                onSeeAllWhys: () => setState(() => _tab = _PollDetailTab.whys),
              ),
              _PollDetailTab.whys => _WhysTab(whys: poll.whys),
              _PollDetailTab.somethingElse => _SomethingElseTab(
                answers: _detail.somethingElseAnswers,
              ),
            },
          ],
        ),
      ),
    );
  }
}

_PollDetailDummy _dummyPollDetail(String pollId) {
  final polls = const PollListDataSource().fetchActivePolls();
  PollModel? source;
  for (final poll in polls) {
    if (poll.id == pollId) {
      source = poll;
      break;
    }
  }
  source ??= polls.isEmpty ? null : polls.first;

  final standard = source?.standardOptions ?? const [];
  final somethingElseId = source?.customOption?.id ?? 'option_something_else';
  final totalVotes = source?.totalVoteCount ?? 100;
  final somethingElseAnswers = List<String>.unmodifiable(
    _dummySomethingElseAnswers,
  );

  if (standard.isNotEmpty) {
    final pollOptions = <UserPollDetailOptionResponse>[
      for (var i = 0; i < standard.length; i++)
        UserPollDetailOptionResponse(
          id: standard[i].id,
          text: standard[i].text,
          sortOrder: standard[i].sortOrder,
          voteCount: _dummyVoteCount(
            totalVotes,
            _dummyStandardPercentages[i % _dummyStandardPercentages.length],
          ),
          percentage:
              _dummyStandardPercentages[i % _dummyStandardPercentages.length],
        ),
      UserPollDetailOptionResponse(
        id: somethingElseId,
        text: AppLimits.somethingElseLabel,
        sortOrder: (standard.last.sortOrder) + 1,
        voteCount: _dummyVoteCount(totalVotes, _dummySomethingElsePercent),
        percentage: _dummySomethingElsePercent,
      ),
    ];

    final leadingIndex = _leadingOptionIndex(standard.length);
    final leading = pollOptions[leadingIndex];
    final yours = pollOptions.first;

    return _PollDetailDummy(
      poll: UserPollDetailResponse(
        pollId: pollId,
        question: source!.question,
        status: 'active',
        shareToken: 'local-share',
        optionType: 'text',
        createdAt: DateTime.utc(2026, 1, 1),
        totalVoteCount: totalVotes,
        pollOptions: pollOptions,
        whys: [
          for (final why in source.whys)
            PollWhy(
              id: why.id,
              authorName: '',
              text: why.text,
              optionId: why.optionId,
            ),
        ],
        youVsCrowd: YouVsCrowdResponse(
          yourOptionId: yours.id,
          yourOptionText: yours.text,
          yourOptionPercentage: yours.percentage,
          crowdLeadingOptionId: leading.id,
          crowdLeadingOptionText: leading.text,
          crowdLeadingPercentage: leading.percentage,
          agreesWithCrowd: yours.id == leading.id,
        ),
      ),
      somethingElseAnswers: somethingElseAnswers,
      somethingElseOptionId: somethingElseId,
    );
  }

  const fallbackSomethingElseId = 'asked_opt_something_else';
  return _PollDetailDummy(
    poll: UserPollDetailResponse(
      pollId: pollId,
      question: source?.question ?? 'Which dress should I wear?',
      status: 'active',
      shareToken: 'local-share',
      optionType: 'text',
      createdAt: DateTime.utc(2026, 1, 1),
      totalVoteCount: 100,
      pollOptions: const [
        UserPollDetailOptionResponse(
          id: 'asked_opt_1',
          text: 'Blue Dress 💙',
          sortOrder: 1,
          voteCount: 46,
          percentage: 46,
        ),
        UserPollDetailOptionResponse(
          id: 'asked_opt_2',
          text: 'Black Dress 🖤',
          sortOrder: 2,
          voteCount: 42,
          percentage: 42,
        ),
        UserPollDetailOptionResponse(
          id: 'asked_opt_3',
          text: 'Both are good ✨',
          sortOrder: 3,
          voteCount: 8,
          percentage: 8,
        ),
        UserPollDetailOptionResponse(
          id: fallbackSomethingElseId,
          text: AppLimits.somethingElseLabel,
          sortOrder: 4,
          voteCount: 4,
          percentage: 4,
        ),
      ],
      whys: const [
        PollWhy(
          id: 'why_dummy_1',
          authorName: '',
          text: 'Black looks more classy for a first date ✨',
          optionId: 'asked_opt_2',
        ),
        PollWhy(
          id: 'why_dummy_2',
          authorName: '',
          text: 'Blue is pretty but black is more confident vibe 💯',
          optionId: 'asked_opt_2',
        ),
        PollWhy(
          id: 'why_dummy_3',
          authorName: '',
          text: 'Black dress always wins for evening plans',
          optionId: 'asked_opt_2',
        ),
      ],
      youVsCrowd: const YouVsCrowdResponse(
        yourOptionId: 'asked_opt_1',
        yourOptionText: 'Blue Dress 💙',
        yourOptionPercentage: 46,
        crowdLeadingOptionId: 'asked_opt_1',
        crowdLeadingOptionText: 'Blue Dress 💙',
        crowdLeadingPercentage: 46,
        agreesWithCrowd: true,
      ),
    ),
    somethingElseAnswers: somethingElseAnswers,
    somethingElseOptionId: fallbackSomethingElseId,
  );
}

int _leadingOptionIndex(int optionCount) {
  if (optionCount <= 0) return 0;
  var bestIndex = 0;
  var bestPercent = -1.0;
  for (var i = 0; i < optionCount; i++) {
    final percent =
        _dummyStandardPercentages[i % _dummyStandardPercentages.length];
    if (percent > bestPercent) {
      bestPercent = percent;
      bestIndex = i;
    }
  }
  return bestIndex;
}

int _dummyVoteCount(int totalVotes, double percentage) {
  return ((totalVotes * percentage) / 100).round();
}

UserPollDetailOptionResponse? _winningOption(
  List<UserPollDetailOptionResponse> options,
) {
  if (options.isEmpty) return null;
  UserPollDetailOptionResponse winner = options.first;
  for (final option in options.skip(1)) {
    if (option.percentage > winner.percentage) {
      winner = option;
    } else if (option.percentage == winner.percentage &&
        option.sortOrder < winner.sortOrder) {
      winner = option;
    }
  }
  return winner;
}

Color _accentForIndex(int index) =>
    _optionAccents[index % _optionAccents.length];

String _formatPercent(double value) {
  final rounded = value.roundToDouble();
  if (value == rounded) return '${value.round()}%';
  return '${value.toStringAsFixed(1)}%';
}

class _FinalResultCard extends StatelessWidget {
  const _FinalResultCard({required this.winner});

  final UserPollDetailOptionResponse? winner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = winner?.percentage ?? 0;
    final optionText = winner?.text?.trim().isNotEmpty == true
        ? winner!.text!
        : 'No votes yet';
    final accent = colorScheme.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Final result',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  winner == null ? optionText : '$optionText wins! 🏆',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  winner == null
                      ? 'Waiting on votes'
                      : '${_formatPercent(percent)} of people chose this',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _DonutChart(
            percent: percent.clamp(0, 100),
            color: accent,
            trackColor: colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.percent,
    required this.color,
    required this.trackColor,
  });

  final double percent;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: _DonutPainter(
          percent: percent / 100,
          color: color,
          trackColor: trackColor,
          strokeWidth: 10,
        ),
        child: Center(
          child: Text(
            _formatPercent(percent),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.percent,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double percent;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (percent <= 0) return;

    final sweep = 2 * math.pi * percent.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _YouVsCrowdCard extends StatelessWidget {
  const _YouVsCrowdCard({required this.comparison});

  final YouVsCrowdResponse comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'You vs crowd',
          //   style: theme.textTheme.titleMedium?.copyWith(
          //     fontWeight: FontWeight.w800,
          //   ),
          // ),
          // const SizedBox(height: AppSpacing.xs),
          Text(
            statusLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
          percent == null ? '—' : _formatPercent(percent!),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    required this.options,
    required this.winnerId,
    required this.somethingElseOptionId,
    required this.whys,
    required this.onSeeAllWhys,
  });

  final List<UserPollDetailOptionResponse> options;
  final String? winnerId;
  final String somethingElseOptionId;
  final List<PollWhy> whys;
  final VoidCallback onSeeAllWhys;

  static const _maxPreviewWhys = 3;

  @override
  Widget build(BuildContext context) {
    final topWhys = whys.take(_maxPreviewWhys).toList(growable: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _OptionResultRow(
            letter: options[i].id == somethingElseOptionId
                ? '+'
                : String.fromCharCode(65 + i),
            option: options[i],
            accent: _accentForIndex(i),
            isWinner: options[i].id == winnerId,
            isSomethingElse: options[i].id == somethingElseOptionId,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Why's (${whys.length})",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (whys.isNotEmpty)
                    GestureDetector(
                      onTap: onSeeAllWhys,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          'See all',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (topWhys.isEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No whys yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < topWhys.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _WhyRow(why: topWhys[i]),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WhysTab extends StatelessWidget {
  const _WhysTab({required this.whys});

  final List<PollWhy> whys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      child: whys.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No whys yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Why's (${whys.length})",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < whys.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _WhyRow(why: whys[i]),
                ],
              ],
            ),
    );
  }
}

class _SomethingElseTab extends StatelessWidget {
  const _SomethingElseTab({required this.answers});

  final List<String> answers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      child: answers.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No custom answers yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < answers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      spacing: 6,
                      children: [
                        CircleAvatar(radius: 3),
                        Expanded(
                          child: Text(
                            answers[i],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );
  }
}

class _OptionResultRow extends StatelessWidget {
  const _OptionResultRow({
    required this.letter,
    required this.option,
    required this.accent,
    required this.isWinner,
    this.isSomethingElse = false,
  });

  final String letter;
  final UserPollDetailOptionResponse option;
  final Color accent;
  final bool isWinner;
  final bool isSomethingElse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = option.percentage.clamp(0, 100).toDouble();
    final label = isSomethingElse
        ? AppLimits.somethingElseLabel
        : (option.text?.trim().isNotEmpty == true
              ? option.text!
              : 'Option $letter');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Text(
              letter,
              style: TextStyle(fontWeight: FontWeight.w800, color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatPercent(percent),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.check_circle, color: accent, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyRow extends StatelessWidget {
  const _WhyRow({required this.why});

  final PollWhy why;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        spacing: 6,
        children: [
          CircleAvatar(radius: 3),
          Expanded(
            child: Text(
              why.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
