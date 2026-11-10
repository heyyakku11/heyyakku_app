import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/dashboard.dart';
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
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
              icon: const FaIcon(
                FontAwesomeIcons.chevronLeft,
                size: 16,
                color: YakkuPalette.Ink,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                'Saved questions',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Questions you saved to ask later.',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            Expanded(
              child: RemotePollList(
                emptyMessage: 'No saved polls yet',
                errorFallback: 'Could not load saved polls',
                loadPolls: () =>
                    _loadAllSavedPolls(AppScope.of(context).userRemote),
                emptyView: _SavedEmptyState(
                  onBrowse: () {
                    // Back to the dashboard, on its Home tab.
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    DashboardTabs.showHome();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the user has not saved any question yet.
class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.pinkWash,
            ),
            child: const FaIcon(
              FontAwesomeIcons.bookmark,
              size: 28,
              color: YakkuPalette.Raspberry,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Nothing saved yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap a question on Home to preview it, then tap Save. It waits '
            'here until you\u2019re ready to ask.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBrowse,
            style: FilledButton.styleFrom(
              backgroundColor: YakkuPalette.Ink,
              foregroundColor: YakkuPalette.white,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Browse questions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
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
    shareCode: poll.shareCode,
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
