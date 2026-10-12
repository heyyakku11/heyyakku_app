import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

class DraftScreen extends StatelessWidget {
  const DraftScreen({super.key});

  Future<void> _editDraft(BuildContext context, int id) async {
    final draft = await AppScope.of(context).draftPolls.take(id);
    if (!context.mounted || draft == null) return;
    await showCreatePollSheet(context, draft: draft);
  }

  Future<void> _deleteDraft(BuildContext context, int id) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete draft?',
      message: 'This draft will be removed.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.of(context).draftPolls.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).draftPolls;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Drafts'), centerTitle: true),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (!store.isReady) {
            return const Center(child: CircularProgressIndicator());
          }

          final drafts = store.drafts;
          if (drafts.isEmpty) {
            return Center(
              child: Text(
                'No drafts yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screen),
            itemCount: drafts.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return _DraftWorthAskingCard(
                draft: draft,
                onContinue: () => _editDraft(context, draft.id),
                onDelete: () => _deleteDraft(context, draft.id),
              );
            },
          );
        },
      ),
    );
  }
}

/// Matches [QuestionWorthAskingCard] layout for saved drafts.
class _DraftWorthAskingCard extends StatelessWidget {
  const _DraftWorthAskingCard({
    required this.draft,
    required this.onContinue,
    required this.onDelete,
  });

  final DraftPoll draft;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  static const _chipColor = Color(0xFFF4EBE6);

  @override
  Widget build(BuildContext context) {
    final question = draft.question.trim().isEmpty
        ? 'Untitled draft'
        : draft.question.trim();
    final options = draft.options
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList(growable: false);

    return DecoratedBox(
      decoration: feedCardDecoration(Colors.white),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      color: YakkuPalette.textPrimary,
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                PopupMenuButton<_DraftMenuAction>(
                  tooltip: 'Draft actions',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    color: YakkuPalette.textPrimary,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _DraftMenuAction.continueDraft:
                        onContinue();
                      case _DraftMenuAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _DraftMenuAction.continueDraft,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.arrow_forward_rounded),
                        title: Text('Continue'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _DraftMenuAction.delete,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 14),
              FeedOptionChips(
                labels: options,
                chipColor: _chipColor,
                textColor: YakkuPalette.textPrimary,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Drafted ${_formatDraftedAt(draft.updatedAt)}',
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DraftMenuAction { continueDraft, delete }

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
  final month = months[local.month - 1];
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month · $hour:$minute';
}
