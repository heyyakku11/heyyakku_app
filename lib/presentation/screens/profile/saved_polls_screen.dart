import 'package:flutter/material.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/remote_poll_list.dart';

class SavedPollsScreen extends StatelessWidget {
  const SavedPollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved'), centerTitle: true),
      body: RemotePollList(
        emptyMessage: 'No saved polls yet',
        errorFallback: 'Could not load saved polls',
        loadPolls: () => _loadAllSavedPolls(AppScope.of(context).userRemote),
      ),
    );
  }
}

Future<List<PollModel>> _loadAllSavedPolls(UserRemoteDataSource remote) async {
  final items = <PollModel>[];
  String? cursor;
  final seenCursors = <String>{};

  while (true) {
    final page = await remote.getSavedPolls(cursor: cursor);
    items.addAll(page.items.map(_pollModelFromSavedResponse));
    final next = page.nextCursor;
    if (!page.hasMore ||
        next == null ||
        next.isEmpty ||
        !seenCursors.add(next)) {
      break;
    }
    cursor = next;
  }

  return List<PollModel>.unmodifiable(items);
}

PollModel _pollModelFromSavedResponse(PollResponse poll) {
  final isImagePoll = poll.contentType.toLowerCase() == 'image';
  final options = <PollOptionModel>[
    for (final option in poll.options)
      PollOptionModel(
        id: option.id,
        type: isImagePoll ? PollOptionType.image : PollOptionType.text,
        text: option.text,
        imageUrl: poll.media?.url,
        sortOrder: option.sortOrder,
        isCustom: false,
      ),
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return PollModel(
    id: poll.id,
    question: poll.question,
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: false,
    status: _mapStatus(poll.status),
    options: List<PollOptionModel>.unmodifiable(options),
    totalVoteCount: poll.totalVoteCount,
    expiresAt: poll.expiresAt,
  );
}

PollStatus _mapStatus(String status) {
  switch (status.toLowerCase()) {
    case 'active':
    case 'published':
      return PollStatus.active;
    default:
      return PollStatus.inactive;
  }
}
