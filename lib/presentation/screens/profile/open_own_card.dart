import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/poll_results_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Opens the results screen of a card the user made. A check needs its full
/// data (colour, sticker, options), so it is looked up in the user's checks.
/// Returns true when the card was changed there and lists should reload.
Future<bool> openOwnCardResults(BuildContext context, PollModel poll) async {
  if (poll.isCheck) {
    try {
      final checks = await AppScope.of(context).checkApi.getMyChecks();
      final check = checks.where((c) => c.id == poll.id).firstOrNull;
      if (check == null) throw StateError('Check not found');
      if (!context.mounted) return false;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PollResultsScreen.check(check: check),
        ),
      );
    } catch (error) {
      if (!context.mounted) return false;
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not open this check',
        ).message,
      );
    }
    return false;
  }

  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => PollResultsScreen.byPollId(pollId: poll.id),
    ),
  );
  return changed == true;
}
