import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

enum _PollOwnerAction { close, delete }

/// Returns true when close or delete finished successfully.
Future<bool> showPollOwnerActionsSheet(
  BuildContext context, {
  required String pollId,
}) async {
  final action = await showModalBottomSheet<_PollOwnerAction>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Close poll'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_PollOwnerAction.close),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete poll'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_PollOwnerAction.delete),
            ),
          ],
        ),
      );
    },
  );
  if (action == null || !context.mounted) return false;

  final closing = action == _PollOwnerAction.close;
  final confirmed = await showAppConfirmDialog(
    context,
    title: closing ? 'Close poll?' : 'Delete poll?',
    message: closing
        ? 'People will no longer be able to answer this poll.'
        : 'This poll will be removed.',
    confirmLabel: closing ? 'Close' : 'Delete',
    cancelLabel: 'Cancel',
  );
  if (confirmed != true || !context.mounted) return false;

  try {
    final users = AppScope.of(context).userRemote;
    if (closing) {
      await users.closePoll(pollId);
    } else {
      await users.deletePoll(pollId);
    }
    return true;
  } catch (error) {
    if (!context.mounted) return false;
    final message = DioErrorMapper.map(
      error,
      fallback: closing ? 'Could not close poll' : 'Could not delete poll',
    ).message;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
}
