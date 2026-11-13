import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/presentation/widgets/ask_back_button.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/presentation/screens/share/open_card_share.dart';
import 'package:yakku/presentation/screens/share_result_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/card_actions_sheet.dart';
import 'package:yakku/presentation/widgets/results_locked_view.dart';

/// Results screen: a pick versus the crowd, then every option ranked by votes.
///
/// Three entry points share one design:
/// * the default constructor, shown right after the user answers a poll;
/// * [CardResultsScreen.byPollId], the owner's view of a poll they created;
/// * [CardResultsScreen.check], the owner's view of a check they made.
class CardResultsScreen extends StatefulWidget {
  const CardResultsScreen({
    super.key,
    required PollResponse this.poll,
    required String this.selectedOptionId,
  }) : pollId = null,
       check = null;

  /// Loads the poll by id and shows its current results.
  const CardResultsScreen.byPollId({super.key, required String this.pollId})
    : poll = null,
      selectedOptionId = null,
      check = null;

  const CardResultsScreen.check({
    super.key,
    required UserCheckResponse this.check,
  }) : poll = null,
       pollId = null,
       selectedOptionId = null;

  final PollResponse? poll;
  final String? selectedOptionId;
  final String? pollId;
  final UserCheckResponse? check;

  /// Only the post-answer flow adds the user's own vote and offers the
  /// audience sheet.
  bool get _justVoted => poll != null;

  @override
  State<CardResultsScreen> createState() => _CardResultsScreenState();
}

class _CardResultsScreenState extends State<CardResultsScreen> {
  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.textSecondary;

  /// Set when the poll was closed or deleted, so the caller can refresh.
  bool _changed = false;
  PollResponse? _loadedPoll;
  bool _loading = false;
  String? _error;

  /// Set once the owner closes a made check from the menu.
  bool _checkClosed = false;

  @override
  void initState() {
    super.initState();
    if (widget.pollId != null) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPoll());
    }
    if (_canSeeReasons) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _markCardNotificationsRead(),
      );
    }
  }

  /// Reasons are anonymous but owner-only: the owner of a poll (opened by id)
  /// or of a made check. A voter who just answered cannot read them.
  bool get _canSeeReasons =>
      widget.pollId != null || (widget.check?.isOwner ?? false);

  /// The owner is looking at the results, so the "new answer" notifications for
  /// this card count as read: they leave the Activity badge and are not repeated
  /// in the 30-minute digest push. Best effort; a failure changes nothing here.
  Future<void> _markCardNotificationsRead() async {
    if (!mounted) return;
    final check = widget.check;
    final contentType = check != null ? 'check' : 'poll';
    final contentId = check?.id ?? widget.pollId;
    if (contentId == null) return;
    try {
      await AppScope.of(
        context,
      ).notifications.markContentRead(contentType, contentId);
    } catch (_) {
      // They stay unread and are marked read the next time the card is opened.
    }
  }

  Future<List<PollCustomAnswer>> _loadCustomAnswers() {
    final scope = AppScope.of(context);
    final check = widget.check;
    if (check != null) return scope.checkApi.getCustomAnswers(check.id);
    return scope.userRemote.getPollCustomAnswers(widget.pollId!);
  }

  Future<List<PollReason>> _loadReasons(String optionId) {
    final scope = AppScope.of(context);
    final check = widget.check;
    if (check != null) {
      return scope.checkApi.getOptionReasons(check.id, optionId);
    }
    return scope.userRemote.getPollOptionReasons(widget.pollId!, optionId);
  }

  /// Confirms, then reports the reason: it is removed and logged server-side.
  /// True when it was reported.
  Future<ReasonReportResult?> _reportReason(String reasonId) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Report this reason?',
      message:
          'It will be removed from your results and sent to us for review.',
      confirmLabel: 'Report',
      cancelLabel: 'Cancel',
    );
    if (confirmed != true || !mounted) return null;
    try {
      final scope = AppScope.of(context);
      final check = widget.check;
      final ReasonReportResult result;
      if (check != null) {
        result = await scope.checkApi.reportReason(check.id, reasonId);
      } else {
        result = await scope.userRemote.reportPollReason(
          widget.pollId!,
          reasonId,
        );
      }
      if (!mounted) return null;
      AppToast.show('Reason reported');
      return result;
    } catch (error) {
      if (!mounted) return null;
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not report this reason',
        ).message,
      );
      return null;
    }
  }

  Future<void> _loadPoll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final poll = await AppScope.of(
        context,
      ).pollApi.getPollById(widget.pollId!);
      if (!mounted) return;
      setState(() {
        _loadedPoll = poll;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load the results.";
        _loading = false;
      });
    }
  }

  void _onBack() {
    if (widget._justVoted || !Navigator.of(context).canPop()) {
      context.go(AppRoutes.main);
    } else {
      Navigator.of(context).pop(_changed);
    }
  }

  /// The owner's "..." menu: close the card now, or delete it. Once a card has ended it cannot be
  /// reshared for more votes, so only Delete is left.
  Future<void> _openMenu() async {
    final check = widget.check;
    final poll = _loadedPoll;
    if (check == null && poll == null) return;

    final data = _data();
    final live = data?.isLive ?? false;
    final votes = data?.voters ?? 0;
    final left = data?.timeLeftLabel();
    final subtitle = live
        ? '$votes vote${votes == 1 ? '' : 's'}${left == null ? '' : ' · closes in $left'}'
        : '$votes vote${votes == 1 ? '' : 's'} · ended';

    final action = await showCardActionsSheet(
      context,
      question: check != null
          ? (check.question.trim().isNotEmpty ? check.question : check.title)
          : poll!.question,
      subtitle: subtitle,
      isLive: live,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case CardAction.closeNow:
        await _confirmAndRun(
          title: 'Close this card?',
          message: 'People will no longer be able to answer it.',
          confirmLabel: 'Close',
          failure: 'Could not close the card',
          run: (users) async {
            if (check != null) {
              await AppScope.of(context).checkApi.closeMyCheck(check.id);
              if (!mounted) return;
              setState(() => _checkClosed = true);
            } else {
              final closed = await users.closePoll(poll!.id);
              if (!mounted) return;
              setState(() => _loadedPoll = closed);
            }
            _changed = true;
          },
        );
      case CardAction.delete:
        await _confirmAndRun(
          title: 'Delete this card?',
          message: 'This card will be removed.',
          confirmLabel: 'Delete',
          failure: 'Could not delete the card',
          run: (users) async {
            if (check != null) {
              await AppScope.of(context).checkApi.deleteMyCheck(check.id);
            } else {
              await users.deletePoll(poll!.id);
            }
            if (!mounted) return;
            _changed = true;
            Navigator.of(context).pop(true);
          },
        );
      case CardAction.shareAgain:
        break;
    }
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required String confirmLabel,
    required String failure,
    required Future<void> Function(UserRemoteDataSource users) run,
  }) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: 'Cancel',
    );
    if (confirmed != true || !mounted) return;
    try {
      await run(AppScope.of(context).userRemote);
    } catch (error) {
      if (!mounted) return;
      AppToast.show(DioErrorMapper.map(error, fallback: failure).message);
    }
  }

  /// Normalises whichever source this screen was opened with.
  _ResultsData? _data() {
    final check = widget.check;
    if (check != null) return _fromCheck(check);
    final poll = widget.poll ?? _loadedPoll;
    if (poll == null) return null;
    return _fromPoll(poll, selectedId: widget.selectedOptionId);
  }

  _ResultsData _fromPoll(PollResponse poll, {String? selectedId}) {
    final options = [...poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // A just-cast vote isn't in the fetched poll yet, so add it here.
    final bonus = selectedId == null ? 0 : 1;
    final total = poll.totalVoteCount + bonus;
    return _ResultsData(
      question: poll.question,
      tallies: _rank([
        for (final option in options)
          _Tally(
            id: option.id,
            label: option.text ?? '',
            votes: option.voteCount + (option.id == selectedId ? 1 : 0),
            whyCount: option.whyCount,
            total: total,
            mine: option.id == (selectedId ?? poll.yourOptionId),
          ),
      ]),
      customPick: poll.yourOptionId == null ? poll.yourOptionText : null,
      voters: total,
      customCount: poll.customAnswerCount,
      expiresAt: poll.expiresAt,
      closed: const {
        'closed',
        'expired',
        '2',
        '3',
      }.contains(poll.status.toLowerCase()),
      showStatus: true,
    );
  }

  _ResultsData _fromCheck(UserCheckResponse check) {
    final total = check.totalVotes ?? 0;
    return _ResultsData(
      question: check.question.trim().isNotEmpty ? check.question : check.title,
      tallies: _rank([
        for (final option in check.options)
          _Tally(
            id: option.id,
            label: option.text,
            votes: option.votes ?? 0,
            whyCount: option.whyCount ?? 0,
            total: total,
            mine: option.id == check.myVoteOptionId,
          ),
      ]),
      customPick: check.myVoteOptionId == null ? check.myCustomAnswer : null,
      voters: total,
      customCount: check.customAnswerVotes ?? 0,
      expiresAt: check.expiresAt,
      closed: check.isClosed || _checkClosed,
      tag: check.title.trim().isEmpty ? null : check.title,
      showStatus: true,
    );
  }

  /// Most votes first; ties keep the original order (the sort is stable).
  List<_Tally> _rank(List<_Tally> tallies) =>
      [...tallies]..sort((a, b) => b.votes.compareTo(a.votes));

  @override
  Widget build(BuildContext context) {
    final data = _data();

    return PopScope(
      // Owner view hands back whether the poll changed; route every back
      // gesture through _onBack so that result is always returned.
      canPop: widget.pollId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: YakkuPalette.cream,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                onBack: _onBack,
                onMenu:
                    (_loadedPoll != null || (widget.check?.isOwner ?? false))
                    ? _openMenu
                    : null,
                // Under the vote limit a made check is titled by its type (for example Trust Check).
                title: _lockedCheckTitle ?? 'Results',
              ),
              Expanded(child: _body(data)),
            ],
          ),
        ),
      ),
    );
  }

  /// The check's type name while its results are still locked; null otherwise.
  String? get _lockedCheckTitle {
    final check = widget.check;
    if (check == null || check.resultsUnlocked) return null;
    return check.title.trim().isEmpty ? null : check.title;
  }

  /// Under the vote limit the server sends no results, only progress.
  Widget? _lockedBody() {
    final check = widget.check;
    if (check != null) {
      if (check.resultsUnlocked) return null;
      return ResultsLockedView(
        question: check.question.trim().isNotEmpty
            ? check.question
            : check.title,
        options: check.options.map((o) => o.text).toList(growable: false),
        progress: check.voteProgress,
        minVotes: check.minVotes,
        tag: check.title,
        backgroundColor: check.backgroundColor,
        closesAt: check.expiresAt,
        closedAt: check.closedAt,
        onShareAgain: () => _shareAgain(checkShareRoute(check)),
      );
    }

    final poll = widget.poll ?? _loadedPoll;
    if (poll == null || poll.resultsUnlocked) return null;
    return ResultsLockedView(
      question: poll.question,
      options: poll.options.map((o) => o.text ?? '').toList(growable: false),
      progress: poll.voteProgress,
      minVotes: poll.minVotes,
      closesAt: poll.expiresAt,
      closedAt: poll.closedAt,
      onShareAgain: () => _shareAgain(pollShareRoute(poll)),
    );
  }

  Future<void> _openSharePoster(
    _ResultsData data,
    List<_Tally> tallies,
    _Tally? mine,
  ) {
    final leader = tallies.first;
    final pick = mine ?? leader;
    final verdict = mine == null
        ? null
        : mine.id == leader.id
        ? 'Bang on.'
        : 'Plot twist.';
    final check = widget.check;
    final poll = widget.poll ?? _loadedPoll;
    final shareCode = check?.shareCode ?? poll?.shareCode ?? '';
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShareResultScreen(
          shareCode: shareCode,
          question: data.question,
          myLabel: pick.label,
          crowdLabel: leader.label,
          crowdPercent: leader.percent,
          verdict: verdict,
          pickLabel: mine != null && mine.id != _Tally.customId
              ? mine.label
              : null,
          tag: data.tag ?? 'Poll',
          options: [for (final t in tallies) t.label],
          minVotes: check?.minVotes ?? poll?.minVotes ?? 3,
        ),
      ),
    );
  }

  Route<void> _shareRoute() {
    final check = widget.check;
    if (check != null) return checkShareRoute(check);
    return pollShareRoute((widget.poll ?? _loadedPoll)!);
  }

  Future<void> _shareAgain(Route<void> route) {
    return Navigator.of(context).push(route);
  }

  Widget _body(_ResultsData? data) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final locked = _lockedBody();
    if (locked != null) return locked;
    if (data == null || data.tallies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? 'No results yet.',
              style: const TextStyle(color: _muted, fontSize: 14),
            ),
            if (_error != null && widget.pollId != null)
              TextButton(onPressed: _loadPoll, child: const Text('Try again')),
          ],
        ),
      );
    }

    // The crowd's answers: every option, plus the written-in answers as one
    // "Something else" entry, so it can be the majority too.
    final custom = data.customCount > 0
        ? _Tally(
            id: _Tally.customId,
            label: 'Something else',
            votes: data.customCount,
            whyCount: 0,
            total: data.voters,
            mine: false,
          )
        : null;
    final tallies = data.tallies;
    final standings = [...tallies, ?custom]
      ..sort((a, b) => b.votes.compareTo(a.votes));
    // The viewer's (or asker's) own pick: a listed option, else their written-in answer.
    final customPick = data.customPick?.trim();
    final mine =
        tallies.where((t) => t.mine).firstOrNull ??
        (customPick == null || customPick.isEmpty
            ? null
            : _Tally(
                id: _Tally.customId,
                label: customPick,
                // Written-in answers share one percentage: the "Something else" group.
                votes: data.customCount,
                whyCount: 0,
                total: data.voters,
                mine: true,
              ));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.tag != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: YakkuPalette.pinkWash,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  data.tag!,
                  style: const TextStyle(
                    color: YakkuPalette.Raspberry,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            data.question,
            style: const TextStyle(
              color: _ink,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 18),
          _VersusCard(
            mine: mine,
            leader: standings.first,
            runnerUp: standings.length > 1 ? standings[1] : null,
            voters: data.voters,
            live: data.isLive,
            timeLeft: data.timeLeft,
            timeLeftLabel: data.timeLeftLabel(),
            canShareMore: _canSeeReasons,
            onShareMore: () => _shareAgain(_shareRoute()),
            onShareResult: () => _openSharePoster(data, standings, mine),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.isLive ? 'How they are voting' : 'How they voted',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tap an answer',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tallies.length; i++) ...[
            _ResultRow(
              tally: tallies[i],
              top: i == 0 && tallies[i].votes > 0,
              loadReasons: _canSeeReasons ? _loadReasons : null,
              onReport: _reportReason,
            ),
            const SizedBox(height: 10),
          ],
          _OwnOptionsRow(
            count: data.customCount,
            total: data.voters,
            loadAnswers: _canSeeReasons ? _loadCustomAnswers : null,
            onReport: _reportReason,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tap an answer to read one reason free. Every other %, reason and added option opens with a plan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the screen renders, independent of where the data came from.
class _ResultsData {
  const _ResultsData({
    required this.question,
    required this.tallies,
    required this.voters,
    required this.customCount,
    required this.showStatus,
    this.expiresAt,
    this.customPick,
    this.tag,
    this.closed = false,
  });

  final String question;
  final List<_Tally> tallies;

  /// The viewer's own custom answer, when they wrote one instead of picking an option.
  final String? customPick;
  final int voters;
  final int customCount;
  final bool showStatus;
  final DateTime? expiresAt;

  /// The check's type name (Mirror Check...), shown above the question.
  final String? tag;

  /// The owner closed it (or it expired), whatever its end time says.
  final bool closed;

  bool get isLive {
    if (closed) return false;
    final at = expiresAt;
    return at == null || at.isAfter(DateTime.now().toUtc());
  }

  /// Time until the card closes; null when it is closed or has no end time.
  Duration? get timeLeft {
    final at = expiresAt;
    if (!isLive || at == null) return null;
    return at.difference(DateTime.now().toUtc());
  }

  /// "2d 5h", "3h", "12m" or "under a minute"; null when not live.
  String? timeLeftLabel() {
    final left = timeLeft;
    if (left == null) return null;
    if (left.inMinutes < 1) return 'under a minute';
    if (left.inHours < 1) return '${left.inMinutes}m';
    if (left.inHours < 24) return '${left.inHours}h';
    final hours = left.inHours % 24;
    return hours == 0 ? '${left.inDays}d' : '${left.inDays}d ${hours}h';
  }

  /// "Live · 2d 5h left", "Live · 3h left", "Live · 12m left", or "Closed".
  String statusLabel() {
    if (!isLive) return 'Closed';
    final at = expiresAt;
    if (at == null) return 'Live';
    final left = at.difference(DateTime.now().toUtc());
    if (left.inMinutes < 1) return 'Live · ending now';
    if (left.inHours < 1) return 'Live · ${left.inMinutes}m left';
    if (left.inHours < 24) return 'Live · ${left.inHours}h left';
    final hours = left.inHours % 24;
    return hours == 0
        ? 'Live · ${left.inDays}d left'
        : 'Live · ${left.inDays}d ${hours}h left';
  }
}

class _Tally {
  const _Tally({
    required this.id,
    required this.label,
    required this.votes,
    required this.whyCount,
    required this.total,
    required this.mine,
  });

  /// Id of the "something else" tally: all the written-in answers together.
  static const customId = '__custom__';

  final String id;
  final String label;
  final int votes;
  final int whyCount;
  final int total;
  final bool mine;

  double get fraction => total == 0 ? 0 : votes / total;
  int get percent => (fraction * 100).round();
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.onMenu, this.title = 'Results'});

  final VoidCallback onBack;
  final String title;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _CardResultsColors.ink,
                size: 18,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: _CardResultsColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onMenu != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onMenu,
                tooltip: 'More',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: _CardResultsColors.ink,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

abstract final class _CardResultsColors {
  static const ink = YakkuPalette.textPrimary;
}

/// Dark card: the viewer's pick vs. their circle. While live the right panel is
/// the clock; once voting is over it shows the circle's answer, and a sticker
/// on the card's edge says "Plot twist." or "Bang on.".
class _VersusCard extends StatelessWidget {
  const _VersusCard({
    required this.mine,
    required this.leader,
    required this.runnerUp,
    required this.voters,
    required this.live,
    required this.timeLeft,
    required this.timeLeftLabel,
    required this.canShareMore,
    required this.onShareMore,
    required this.onShareResult,
  });

  /// The viewer's own pick, when known. Without it the card compares the top
  /// two answers instead.
  final _Tally? mine;
  final _Tally leader;
  final _Tally? runnerUp;
  final int voters;
  final bool live;
  final Duration? timeLeft;
  final String? timeLeftLabel;

  /// Only the owner can ask for more votes.
  final bool canShareMore;
  final VoidCallback onShareMore;
  final VoidCallback onShareResult;

  static const _yellow = Color(0xFFFFC72C);
  static const _yellowEdge = Color(0xFFD99A00);
  static const _night = Color(0xFF1F191C);

  @override
  Widget build(BuildContext context) {
    final pick = mine;
    final left = pick ?? leader;
    final right = pick != null ? leader : runnerUp;
    final bangOn = pick != null && pick.id == leader.id;
    final showSticker = !live && pick != null;
    final fraction = timeLeft == null
        ? 0.0
        : (timeLeft!.inSeconds / const Duration(hours: 24).inSeconds).clamp(
            0.0,
            1.0,
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(top: showSticker ? 14 : 0),
          decoration: BoxDecoration(
            color: _night,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _SidePanel(
                            color: YakkuPalette.cardPink,
                            tag: pick != null ? 'You' : 'Top answer',
                            label: left.label,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: live
                              ? _ClockPanel(
                                  label: timeLeftLabel ?? '',
                                  fraction: fraction,
                                )
                              : _SidePanel(
                                  color: YakkuPalette.white,
                                  tag: pick != null
                                      ? 'Your circle'
                                      : 'Runner-up',
                                  percent: right == null
                                      ? null
                                      : '${right.percent}%',
                                  label: right?.label ?? '-',
                                  light: true,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _night,
                      shape: BoxShape.circle,
                      border: Border.all(color: YakkuPalette.white, width: 2),
                    ),
                    child: const Text(
                      'vs',
                      style: TextStyle(
                        color: YakkuPalette.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 2, 2),
                child: live ? _liveFooter() : _endedFooter(),
              ),
            ],
          ),
        ),
        if (showSticker)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.05,
                child: _Sticker(
                  text: bangOn ? 'Bang on.' : 'Plot twist.',
                  background: bangOn
                      ? const Color(0xFFD7F5E3)
                      : YakkuPalette.white,
                  foreground: bangOn
                      ? const Color(0xFF1E6B3E)
                      : YakkuPalette.Raspberry,
                  border: bangOn ? const Color(0xFF1E6B3E) : _night,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _liveFooter() {
    final shareMore = canShareMore;
    return Row(
      children: [
        Expanded(
          child: shareMore
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not satisfied?',
                      style: TextStyle(
                        color: YakkuPalette.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Get more votes',
                      style: TextStyle(
                        color: YakkuPalette.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                )
              : Text(
                  voters == 1 ? '1 friend voted' : '$voters friends voted',
                  style: const TextStyle(
                    color: YakkuPalette.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        _ShareButton(
          label: shareMore ? 'Share more' : 'Share this',
          onTap: shareMore ? onShareMore : onShareResult,
        ),
      ],
    );
  }

  Widget _endedFooter() {
    return Row(
      children: [
        Expanded(
          child: Text(
            voters == 1
                ? '1 friend voted · ended'
                : '$voters friends voted · ended',
            style: const TextStyle(
              color: YakkuPalette.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ShareButton(label: 'Share result', onTap: onShareResult),
      ],
    );
  }
}

/// Yellow pill with a darker lower edge, like a pressable key.
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: _VersusCard._yellowEdge,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              color: _VersusCard._yellow,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _VersusCard._night, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.ios_share_rounded,
                  size: 16,
                  color: _VersusCard._night,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _VersusCard._night,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The hand-written style tag stuck on the card's top edge.
class _Sticker extends StatelessWidget {
  const _Sticker({
    required this.text,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String text;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 22,
          height: 1.1,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: const ['cursive'],
        ),
      ),
    );
  }
}

/// White right-hand panel while the card is live: LIVE chip, time left, bar.
class _ClockPanel extends StatelessWidget {
  const _ClockPanel({required this.label, required this.fraction});

  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your circle',
              style: TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const _LiveChip(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 22,
                  color: YakkuPalette.Raspberry,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: YakkuPalette.Raspberry,
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'left',
                  style: TextStyle(
                    color: _CardResultsColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 7,
                backgroundColor: YakkuPalette.pinkWash,
                valueColor: const AlwaysStoppedAnimation(
                  YakkuPalette.Raspberry,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE3F6EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF2FB463)),
            SizedBox(width: 6),
            Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xFF1E6B3E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One answer panel: a small tag (and optional percentage) on top, the answer
/// big at the bottom.
class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.color,
    required this.tag,
    required this.label,
    this.percent,
    this.light = false,
  });

  final Color color;
  final String tag;
  final String label;
  final String? percent;

  /// A white panel: grey tag and a raspberry percentage.
  final bool light;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: light
                          ? YakkuPalette.textSecondary
                          : _CardResultsColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (percent != null)
                  Text(
                    percent!,
                    style: const TextStyle(
                      color: YakkuPalette.Raspberry,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _CardResultsColors.ink,
                fontSize: 21,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One "How they voted" row: a tinted bar filled to the vote share, the label
/// (with an optional "You" chip), the percentage and a count pill.
class _ResultBarRow extends StatelessWidget {
  const _ResultBarRow({
    required this.label,
    required this.fraction,
    required this.percent,
    required this.count,
    required this.fill,
    required this.pillColor,
    required this.pillInk,
    required this.pillIcon,
    this.mine = false,
    this.top = false,
    this.onPillTap,
  });

  final String label;
  final double fraction;
  final int percent;
  final int count;
  final bool mine;
  final Color fill;
  final Color pillColor;
  final Color pillInk;
  final IconData pillIcon;
  final bool top;

  /// Makes the count pill tappable (expands the row's reasons).
  final VoidCallback? onPillTap;

  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: top ? YakkuPalette.Raspberry : YakkuPalette.roseBorder,
          width: top ? 1.8 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                heightFactor: 1,
                child: ColoredBox(color: fill),
              ),
            ),
          ),
          // Sizes the row: at least 56 high, taller when the label wraps.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: label,
                        children: [
                          if (mine) ...[
                            const TextSpan(text: '  '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: YakkuPalette.primaryBright,
                                  ),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    color: YakkuPalette.primaryBright,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CardResultsColors.ink,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      color: _CardResultsColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPillTap,
                    child: _CountPill(
                      count: count,
                      icon: pillIcon,
                      background: pillColor,
                      ink: pillInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.count,
    required this.icon,
    required this.background,
    required this.ink,
  });

  final int count;
  final IconData icon;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: ink),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard option row (pink bar, vote-count pill). For the owner, tapping the
/// pill expands the reasons voters gave for this option.
class _ResultRow extends StatefulWidget {
  const _ResultRow({
    required this.tally,
    this.top = false,
    this.loadReasons,
    required this.onReport,
  });

  final _Tally tally;

  /// The leading answer gets a raspberry border and a bolder bar.
  final bool top;

  /// Null when the viewer cannot read reasons (not the owner).
  final Future<List<PollReason>> Function(String optionId)? loadReasons;
  final Future<ReasonReportResult?> Function(String reasonId) onReport;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  bool _expanded = false;
  bool _loading = false;
  bool _failed = false;
  List<PollReason>? _reasons;
  int? _serverCount;

  /// The server's count after a report, otherwise what the screen loaded with.
  int get _count => _serverCount ?? widget.tally.whyCount;

  bool get _canExpand => widget.loadReasons != null && _count > 0;

  Future<void> _toggle() async {
    if (!_canExpand) return;
    setState(() => _expanded = !_expanded);
    if (_expanded && _reasons == null && !_loading) await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final reasons = await widget.loadReasons!(widget.tally.id);
      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _report(PollReason reason) async {
    final result = await widget.onReport(reason.id);
    if (result == null || !mounted) return;
    setState(() {
      _reasons = _reasons?.where((item) => item.id != reason.id).toList();
      _serverCount = result.optionWhyCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: _expanded ? _expandedCard() : _collapsedRow(),
    );
  }

  Widget _collapsedRow() {
    final tally = widget.tally;
    return _ResultBarRow(
      label: tally.label,
      fraction: tally.fraction,
      percent: tally.percent,
      count: _count,
      mine: tally.mine,
      fill: widget.top ? YakkuPalette.pinkWash : YakkuPalette.blushFill,
      pillColor: YakkuPalette.pillPink,
      pillInk: YakkuPalette.primary,
      pillIcon: Icons.chat_bubble_outline_rounded,
      top: widget.top,
      onPillTap: _canExpand ? _toggle : null,
    );
  }

  /// The option and its reasons wrapped in one pink card.
  Widget _expandedCard() {
    final tally = widget.tally;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: YakkuPalette.pillPink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    tally.label,
                    style: const TextStyle(
                      color: _CardResultsColors.ink,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: YakkuPalette.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggle,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: YakkuPalette.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${tally.percent}%',
                style: const TextStyle(
                  color: YakkuPalette.primary,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: YakkuPalette.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.commentDots,
                      size: 13,
                      color: YakkuPalette.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _count == 1 ? '1 reply' : '$_count replies',
                      style: const TextStyle(
                        color: YakkuPalette.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: tally.fraction.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: YakkuPalette.white,
              color: YakkuPalette.primary,
            ),
          ),
          const SizedBox(height: 14),
          _reasonsList(),
        ],
      ),
    );
  }

  Widget _reasonsList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_failed) {
      return Center(
        child: TextButton(
          onPressed: _load,
          child: const Text("Couldn't load the reasons. Try again"),
        ),
      );
    }
    final reasons = _reasons ?? const <PollReason>[];
    if (reasons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            'No reasons to show.',
            style: TextStyle(color: YakkuPalette.textSecondary, fontSize: 13),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final reason in reasons) ...[
          _ReasonCard(reason: reason, onReport: () => _report(reason)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// One anonymous reason: the quote, when it was given, an action menu and Ask back.
class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason, required this.onReport});

  final PollReason reason;
  final VoidCallback onReport;

  static const _months = [
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

  /// e.g. "28 Oct 2026 \u00B7 3:42 PM", in the viewer's local time.
  static String? _when(DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} ${_months[local.month - 1]} ${local.year} '
        '\u00B7 $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final when = _when(reason.createdAt);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 14),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '\u201C${reason.text}\u201D',
                    style: const TextStyle(
                      color: YakkuPalette.textPrimary,
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Reason actions',
                icon: const Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: YakkuPalette.textSecondary,
                ),
                onSelected: (_) => onReport(),
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 18,
                          color: YakkuPalette.primary,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Report',
                          style: TextStyle(
                            color: YakkuPalette.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (when != null) ...[
            const SizedBox(height: 4),
            Text(
              when,
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (reason.canAskBack) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                // The reason's id is the vote's id.
                child: AskBackButton(voteId: reason.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Friends' write-in answers, shown with the lavender bar and pencil pill. For
/// the owner, tapping the pill expands each answer with the reason given.
class _OwnOptionsRow extends StatefulWidget {
  const _OwnOptionsRow({
    required this.count,
    required this.total,
    this.loadAnswers,
    required this.onReport,
  });

  final int count;
  final int total;

  /// Null when the viewer cannot read the answers (not the owner).
  final Future<List<PollCustomAnswer>> Function()? loadAnswers;
  final Future<ReasonReportResult?> Function(String reasonId) onReport;

  @override
  State<_OwnOptionsRow> createState() => _OwnOptionsRowState();
}

class _OwnOptionsRowState extends State<_OwnOptionsRow> {
  bool _expanded = false;
  bool _loading = false;
  bool _failed = false;
  List<PollCustomAnswer>? _answers;

  bool get _canExpand => widget.loadAnswers != null && widget.count > 0;

  double get _fraction =>
      widget.total <= 0 ? 0.0 : (widget.count / widget.total).clamp(0.0, 1.0);

  Future<void> _toggle() async {
    if (!_canExpand) return;
    setState(() => _expanded = !_expanded);
    if (_expanded && _answers == null && !_loading) await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final answers = await widget.loadAnswers!();
      if (!mounted) return;
      setState(() {
        _answers = answers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _report(PollCustomAnswer answer) async {
    final result = await widget.onReport(answer.id);
    if (result == null || !mounted) return;
    setState(() {
      _answers = [
        for (final item in _answers ?? const <PollCustomAnswer>[])
          item.id == answer.id ? item.withoutReason() : item,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: _expanded ? _expandedCard() : _collapsedRow(),
    );
  }

  Widget _collapsedRow() {
    return _ResultBarRow(
      label: 'Their own options',
      fraction: _fraction,
      percent: (_fraction * 100).round(),
      count: widget.count,
      fill: YakkuPalette.accentPurple,
      pillColor: YakkuPalette.accentPurple,
      pillInk: YakkuPalette.purpleInk,
      pillIcon: Icons.edit_outlined,
      onPillTap: _canExpand ? _toggle : null,
    );
  }

  Widget _expandedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: YakkuPalette.accentPurple,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Their own options',
                    style: TextStyle(
                      color: _CardResultsColors.ink,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: YakkuPalette.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggle,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: YakkuPalette.purpleInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${(_fraction * 100).round()}%',
                style: const TextStyle(
                  color: YakkuPalette.purpleInk,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: YakkuPalette.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 13,
                      color: YakkuPalette.purpleInk,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.count == 1
                          ? '1 answer'
                          : '${widget.count} answers',
                      style: const TextStyle(
                        color: YakkuPalette.purpleInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: _fraction,
              minHeight: 9,
              backgroundColor: YakkuPalette.white,
              color: YakkuPalette.purpleInk,
            ),
          ),
          const SizedBox(height: 14),
          _answersList(),
        ],
      ),
    );
  }

  Widget _answersList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_failed) {
      return Center(
        child: TextButton(
          onPressed: _load,
          child: const Text("Couldn't load the answers. Try again"),
        ),
      );
    }
    final answers = _answers ?? const <PollCustomAnswer>[];
    if (answers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            'No answers to show.',
            style: TextStyle(color: YakkuPalette.textSecondary, fontSize: 13),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final answer in answers) ...[
          _CustomAnswerCard(answer: answer, onReport: () => _report(answer)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// One written-in answer with the reason given, when it was submitted, and actions.
class _CustomAnswerCard extends StatelessWidget {
  const _CustomAnswerCard({required this.answer, required this.onReport});

  final PollCustomAnswer answer;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final when = _ReasonCard._when(answer.createdAt);
    final reason = answer.reason;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 14),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '\u201C${answer.answer}\u201D',
                    style: const TextStyle(
                      color: YakkuPalette.textPrimary,
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (reason != null)
                PopupMenuButton<String>(
                  tooltip: 'Reason actions',
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: YakkuPalette.textSecondary,
                  ),
                  onSelected: (_) => onReport(),
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: YakkuPalette.primary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Report reason',
                            style: TextStyle(
                              color: YakkuPalette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(width: 12),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Why: $reason',
                style: const TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (when != null) ...[
            const SizedBox(height: 6),
            Text(
              when,
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (answer.canAskBack) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: AskBackButton(voteId: answer.id),
            ),
          ],
        ],
      ),
    );
  }
}
