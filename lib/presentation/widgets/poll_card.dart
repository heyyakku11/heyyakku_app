import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_limits.dart';
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
  });

  final PollModel poll;
  final VoidCallback? onShare;
  final ValueChanged<PollModel>? onEdit;
  final bool showMakeItYours;

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
            _PollCardHeader(
              question: poll.question,
              onMakeItYours: showMakeItYours
                  ? () => _showMakeItYourSheet(
                      context: context,
                      poll: poll,
                      onShare: onShare,
                      onEdit: onEdit,
                    )
                  : null,
            ),
            _PollOptions(
              options: poll.standardOptions,
              isMultipleChoice: poll.isMultipleChoice,
            ),
            _CustomOptionRow(option: poll.customOption),
          ],
        ),
      ),
    );
  }
}

class _PollCardHeader extends StatelessWidget {
  const _PollCardHeader({required this.question, this.onMakeItYours});

  final String question;
  final VoidCallback? onMakeItYours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            question,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (onMakeItYours != null) ...[
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: onMakeItYours,
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
                    'Make it your',
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
        ],
      ],
    );
  }
}

class _PollOptions extends StatelessWidget {
  const _PollOptions({required this.options, required this.isMultipleChoice});

  final List<PollOptionModel> options;
  final bool isMultipleChoice;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              if (option.type == PollOptionType.image)
                _PollImageOption(
                  option: option,
                  isMultipleChoice: isMultipleChoice,
                )
              else if (option.type == PollOptionType.text && option.hasText)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: _PollTextOption(
                    option: option,
                    isMultipleChoice: isMultipleChoice,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _PollTextOption extends StatelessWidget {
  const _PollTextOption({required this.option, required this.isMultipleChoice});

  final PollOptionModel option;
  final bool isMultipleChoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChoiceIndicator(isMultipleChoice: isMultipleChoice),
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
  const _PollImageOption({
    required this.option,
    required this.isMultipleChoice,
  });

  final PollOptionModel option;
  final bool isMultipleChoice;

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
                shape: isMultipleChoice ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isMultipleChoice
                    ? BorderRadius.circular(AppRadii.sm)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _ChoiceIndicator(isMultipleChoice: isMultipleChoice),
              ),
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
        if (progress == null) return child;
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

class _ChoiceIndicator extends StatelessWidget {
  const _ChoiceIndicator({required this.isMultipleChoice});

  final bool isMultipleChoice;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Icon(
      isMultipleChoice
          ? Icons.check_box_outline_blank
          : Icons.radio_button_unchecked,
      size: _choiceIconSize,
      color: color,
    );
  }
}

class _CustomOptionRow extends StatelessWidget {
  const _CustomOptionRow({this.option});

  final PollOptionModel? option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final label = option?.hasText == true
        ? option!.text!
        : AppLimits.somethingElseLabel;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.add_circle_outline, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your friends can add their own answer',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
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
              Text('Make it your', style: theme.textTheme.titleLarge),
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
                          minimumSize: const Size.fromHeight(_actionButtonHeight),
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
