import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';

class SlidablePollCard extends StatelessWidget {
  const SlidablePollCard({
    super.key,
    required this.poll,
    required this.onEdit,
    required this.onDelete,
    this.draftedAt,
  });

  final PollModel poll;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final DateTime? draftedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(poll.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.46,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit_outlined,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(AppRadii.lg),
            ),
          ),
        ],
      ),
      child: PollCard(
        poll: poll,
        showMakeItYours: false,
        showVoteCount: false,
        showWhyCount: false,
        draftedAt: draftedAt,
      ),
    );
  }
}
