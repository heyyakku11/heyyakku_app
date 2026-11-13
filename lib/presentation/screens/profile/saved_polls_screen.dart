import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/data/models/saved/saved_card.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/profile/widgets/saved_fun_cards_list.dart';
import 'package:yakku/presentation/widgets/remote_poll_list.dart';

enum _SavedTab { cards, polls }

/// Everything the user saved: fun cards (the default) and polls from other people.
class SavedPollsScreen extends StatefulWidget {
  const SavedPollsScreen({super.key});

  @override
  State<SavedPollsScreen> createState() => _SavedPollsScreenState();
}

class _SavedPollsScreenState extends State<SavedPollsScreen> {
  _SavedTab _tab = _SavedTab.cards;

  void _browse() {
    // Back to the dashboard, on its Home tab.
    Navigator.of(context).popUntil((route) => route.isFirst);
    DashboardTabs.showHome();
  }

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
                'Cards and questions you saved to ask later.',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  _SavedTabPill(
                    label: 'Cards',
                    selected: _tab == _SavedTab.cards,
                    onTap: () => setState(() => _tab = _SavedTab.cards),
                  ),
                  const SizedBox(width: 8),
                  _SavedTabPill(
                    label: 'Polls',
                    selected: _tab == _SavedTab.polls,
                    onTap: () => setState(() => _tab = _SavedTab.polls),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tab == _SavedTab.cards
                  ? SavedFunCardsList(
                      loadCards: () async => [
                        for (final item in await _loadAllSavedCards(
                          AppScope.of(context).userRemote,
                        ))
                          if (item.funCard != null) item.funCard!,
                      ],
                      onBrowse: _browse,
                    )
                  : RemotePollList(
                      emptyMessage: 'No saved polls yet',
                      errorFallback: 'Could not load saved polls',
                      loadPolls: () =>
                          _loadAllSavedPolls(AppScope.of(context).userRemote),
                      emptyView: _SavedEmptyState(onBrowse: _browse),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTabPill extends StatelessWidget {
  const _SavedTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? YakkuPalette.Ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: YakkuPalette.Ink, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? YakkuPalette.white : YakkuPalette.Ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
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

/// Every saved card, all pages, polls and fun cards together (the API keeps one list for both).
Future<List<SavedCardItem>> _loadAllSavedCards(
  UserRemoteDataSource remote,
) async {
  final items = <SavedCardItem>[];
  String? cursor;
  final seenCursors = <String>{};

  while (true) {
    final page = await remote.getSavedCards(cursor: cursor);
    items.addAll(page.items);
    final next = page.nextCursor;
    if (!page.hasMore ||
        next == null ||
        next.isEmpty ||
        !seenCursors.add(next)) {
      break;
    }
    cursor = next;
  }

  return items;
}

Future<List<PollModel>> _loadAllSavedPolls(UserRemoteDataSource remote) async {
  final cards = await _loadAllSavedCards(remote);
  return List<PollModel>.unmodifiable([
    for (final card in cards)
      if (card.poll != null) _pollModelFromSavedResponse(card.poll!),
  ]);
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
