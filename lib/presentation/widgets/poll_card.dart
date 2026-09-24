import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/presentation/widgets/app_button.dart';

const double _actionButtonHeight = 52;
const double _pollImageSize = 88;
const double _choiceIconSize = 18;

class PollCard extends StatelessWidget {
  const PollCard({
    super.key,
    required this.poll,
    this.onShare,
    this.onEdit,
    this.showMakeItYours = true,
    this.showVoteCount = false,
    this.showWhyCount = false,
    this.draftedAt,
  });

  final PollModel poll;
  final VoidCallback? onShare;
  final ValueChanged<PollModel>? onEdit;
  final bool showMakeItYours;
  final bool showVoteCount;
  final bool showWhyCount;
  final DateTime? draftedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          spacing: AppSpacing.sm,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Question
            _PollCardHeader(question: poll.question, draftedAt: draftedAt),

            // 2. Poll options
            _PollOptions(options: poll.standardOptions),

            // 3. Footer with vote count
            _PollCardFooter(
              voteCount: showVoteCount ? poll.totalVoteCount : null,
              whyCount: showWhyCount ? poll.totalWhyCount : null,
            ),

            // 4. Make it yours
            if (showMakeItYours)
              _MakeItYoursAction(
                onTap: () => _showMakeItYourSheet(
                  context: context,
                  poll: poll,
                  onShare: onShare,
                  onEdit: onEdit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PollCardHeader extends StatelessWidget {
  const _PollCardHeader({required this.question, this.draftedAt});

  final String question;
  final DateTime? draftedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(
          question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (draftedAt != null)
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Drafted ${_formatDraftedAt(draftedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

String _formatDraftedAt(DateTime date) {
  final local = date.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute $period';
}

class _PollCardFooter extends StatelessWidget {
  const _PollCardFooter({required this.voteCount, required this.whyCount});

  final int? voteCount;
  final int? whyCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        if (voteCount != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                voteCount == 1 ? '1 vote' : '$voteCount votes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],

        if (whyCount != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                whyCount == 1 ? '1 why' : '$whyCount whys',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MakeItYoursAction extends StatelessWidget {
  const _MakeItYoursAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;

    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Make it yours',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward, color: accent, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PollOptions extends StatelessWidget {
  const _PollOptions({required this.options});

  final List<PollOptionModel> options;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              if (option.type == PollOptionType.image)
                _PollImageOption(option: option)
              else if (option.type == PollOptionType.text && option.hasText)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: _PollTextOption(option: option),
                ),
          ],
        );
      },
    );
  }
}

class _PollTextOption extends StatelessWidget {
  const _PollTextOption({required this.option});

  final PollOptionModel option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(option.text!, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PollImageOption extends StatelessWidget {
  const _PollImageOption({required this.option});

  final PollOptionModel option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: _pollImageSize,
      height: _pollImageSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: _PollNetworkImage(
                url: option.imageUrl,
                size: _pollImageSize,
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.86),
              ),
              child: Padding(padding: const EdgeInsets.all(2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollNetworkImage extends StatelessWidget {
  const _PollNetworkImage({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return _PollImagePlaceholder(size: size);
    }

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return _PollImagePlaceholder(
          size: size,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _PollImagePlaceholder(size: size);
      },
    );
  }
}

class _PollImagePlaceholder extends StatelessWidget {
  const _PollImagePlaceholder({required this.size, this.child});

  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: theme.colorScheme.outline.withValues(alpha: 0.35),
        child: Center(
          child:
              child ??
              Icon(
                Icons.image_not_supported_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

void _showMakeItYourSheet({
  required BuildContext context,
  required PollModel poll,
  VoidCallback? onShare,
  ValueChanged<PollModel>? onEdit,
}) {
  final theme = Theme.of(context);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Make it yours', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xl),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Share',
                      icon: Icons.share,
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        onShare?.call();
                      },
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          onEdit?.call(poll);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            _actionButtonHeight,
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
