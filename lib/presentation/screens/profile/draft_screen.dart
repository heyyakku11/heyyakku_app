import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/slidable_poll_card.dart';

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
      appBar: AppBar(title: const Text('Draft')),
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

          return SlidableAutoCloseBehavior(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screen),
              itemCount: drafts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return SlidablePollCard(
                  poll: draft.toPollModel(),
                  draftedAt: draft.updatedAt,
                  onEdit: () => _editDraft(context, draft.id),
                  onDelete: () => _deleteDraft(context, draft.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
