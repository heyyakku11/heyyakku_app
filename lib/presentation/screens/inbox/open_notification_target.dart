import 'package:flutter/material.dart';
import 'package:yakku/data/models/notification/app_notification.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/poll_results_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Opens the results screen of the card a notification is about. Shared by a
/// tap in the Activity list and a tap on the push notification itself.
Future<void> openNotificationTarget(
  BuildContext context,
  NotificationTarget target,
) async {
  try {
    final Widget screen;
    if (target.isCheck) {
      final checks = await AppScope.of(context).checkApi.getMyChecks();
      final check = checks
          .where((candidate) => candidate.id == target.contentId)
          .firstOrNull;
      if (check == null) throw StateError('Check not found');
      screen = PollResultsScreen.check(check: check);
    } else {
      screen = PollResultsScreen.byPollId(pollId: target.contentId);
    }
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  } catch (_) {
    if (!context.mounted) return;
    AppToast.show('This card is no longer available');
  }
}
