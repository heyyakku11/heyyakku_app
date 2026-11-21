import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/check_theme.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/card_results_screen.dart';
import 'package:yakku/presentation/screens/share/open_card_share.dart';
import 'package:yakku/presentation/widgets/already_voted_view.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/results_locked_view.dart';

/// Voting screen for someone else's card, opened from a shared link. It runs
/// in two steps, like the website:
///
///  1. the question with lettered answers (the last one is the voter's own
///     words); picking one moves on, and
///  2. an optional, anonymous "Want to tell them why?" with Send / Skip.
///
/// The card keeps the look of the check it was made from (background, colors
/// and the sticker in the top-right corner). Voting needs a login; once the
/// vote is accepted the user goes straight into the app.
class AnswerPollScreen extends StatefulWidget {
  const AnswerPollScreen({super.key, required this.poll});

  final PollResponse poll;

  @override
  State<AnswerPollScreen> createState() => _AnswerPollScreenState();
}

class _AnswerPollScreenState extends State<AnswerPollScreen> {
  static const _addOwnAnswer = 'Add your own answer';

  /// Written-in answers are shown as one group once results are visible.
  static const _somethingElse = 'Something else';

  /// Look of a plain poll, which has no check theme.
  static const _pollTheme = CheckTheme(
    heading: '',
    backgroundColor: YakkuPalette.pinkTint,
    headingColor: YakkuPalette.textPrimary,
    questionColor: YakkuPalette.textPrimary,
    accentColor: YakkuPalette.primary,
    stickerLabel: '',
    stickerColor: YakkuPalette.primary,
    optionBackgroundColor: YakkuPalette.white,
    optionTextColor: YakkuPalette.textPrimary,
  );

  final _customController = TextEditingController();
  final _reasonController = TextEditingController();

  /// 0 = choose an answer, 1 = optional reason.
  int _step = 0;
  String? _selectedOptionId;
  bool _writeOwn = false;
  bool _submitting = false;
  bool _openingResults = false;

  CheckTheme get _theme => widget.poll.checkTheme ?? _pollTheme;

  @override
  void dispose() {
    _customController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Text of the answer the voter picked, for the step-2 chip.
  String get _pickedText {
    if (_writeOwn) return _customController.text.trim();
    for (final option in widget.poll.options) {
      if (option.id == _selectedOptionId) return option.text ?? '';
    }
    return '';
  }

  /// Picking an answer only selects it; the voter moves on with "Next".
  /// Choosing a listed answer also closes the write-your-own field.
  void _pickOption(String id) {
    FocusScope.of(context).unfocus();
    _customController.clear();
    setState(() {
      _selectedOptionId = id;
      _writeOwn = false;
    });
  }

  void _startWriteOwn() => setState(() {
    _selectedOptionId = null;
    _writeOwn = true;
  });

  /// Something is picked: a listed answer, or the voter's own words.
  bool get _showNext => _selectedOptionId != null || _writeOwn;

  bool get _canContinue =>
      !_submitting &&
      (_selectedOptionId != null ||
          (_writeOwn && _customController.text.trim().isNotEmpty));

  void _goNext() {
    if (!_canContinue) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = 1);
  }

  void _backToAnswers() => setState(() => _step = 0);

  Future<void> _onSubmit({bool skipReason = false}) async {
    if (_submitting) return;

    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      // Voting needs an account.
      openSignUp(context);
      return;
    }
    if (_selectedOptionId == null && !(_writeOwn && _pickedText.isNotEmpty)) {
      return;
    }

    final reason = skipReason ? '' : _reasonController.text.trim();
    setState(() => _submitting = true);
    try {
      await scope.pollApi.castVote(
        shareCode: widget.poll.shareCode,
        optionId: _writeOwn ? null : _selectedOptionId,
        customAnswer: _writeOwn ? _customController.text.trim() : null,
        reason: reason.isEmpty ? null : reason,
      );
    } catch (e) {
      debugPrint('Cast vote failed: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show("Couldn't submit your vote. Please try again.");
      return;
    }
    if (!mounted) return;
    AppToast.show('Vote submitted');
    context.go(AppRoutes.main);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [...widget.poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final auth = AppScope.of(context).authController;

    // Rebuild when the voter logs in from the prompt below.
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final voted = _alreadyVoted(auth.isLoggedIn);
        final own = widget.poll.isOwner;
        return PopScope(
          // On the reason step, back returns to the answers.
          canPop: voted || own || _step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_submitting) _backToAnswers();
          },
          child: Scaffold(
            backgroundColor: own
                ? YakkuPalette.cream
                : voted || _step == 0
                ? _theme.backgroundColor
                : YakkuPalette.cream,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: own
                  ? _buildOwnLockedView()
                  : voted
                  ? _buildVotedView(options)
                  : _step == 0
                  ? _buildAnswerStep(options)
                  : _buildReasonStep(auth.isLoggedIn),
            ),
          ),
        );
      },
    );
  }

  /// The voting state is only valid for a signed-in user (see
  /// `SharedPollScreen`), and the owner never votes on their own card.
  bool _alreadyVoted(bool loggedIn) =>
      loggedIn &&
      !widget.poll.isOwner &&
      (widget.poll.voting?.hasVoted ?? false);

  // --------------------------------------------------------- own card view

  /// A made check carries a theme; a plain poll does not.
  bool get _isCheck => widget.poll.checkTheme != null;

  void _shareOwnCard() {
    final poll = widget.poll;
    openCardShare(
      context,
      shareCode: poll.shareCode,
      title: _theme.heading.trim(),
      question: poll.question,
      options: [for (final option in poll.options) option.text ?? ''],
      minVotes: poll.minVotes,
    );
  }

  /// Opens the owner's results screen. A made check needs its full data
  /// (colour, sticker, options), so it is looked up in the user's checks; a
  /// poll is loaded by id.
  Future<void> _openOwnResults() async {
    if (_openingResults) return;
    setState(() => _openingResults = true);
    try {
      final Widget screen;
      if (_isCheck) {
        final checks = await AppScope.of(context).checkApi.getMyChecks();
        final check = checks
            .where((candidate) => candidate.id == widget.poll.id)
            .firstOrNull;
        if (check == null) throw StateError('Check not found');
        screen = CardResultsScreen.check(check: check);
      } else {
        screen = CardResultsScreen.byPollId(pollId: widget.poll.id);
      }
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not open your results',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _openingResults = false);
    }
  }

  /// Shown when the card's owner opens their own link: voting is blocked.
  /// It is the card preview with a "This is your card" tag. While the results
  /// are locked it shows the vote progress and "Share again"; once they are
  /// ready it celebrates with confetti and offers "View results" instead.
  Widget _buildOwnLockedView() {
    final poll = widget.poll;
    final heading = _theme.heading.trim();
    final status = poll.status.toLowerCase();

    return DecoratedBox(
      key: const ValueKey('own-locked-view'),
      decoration: const BoxDecoration(color: YakkuPalette.cream),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close,
                        color: YakkuPalette.textPrimary,
                      ),
                      onPressed: _leave,
                    ),
                  ),
                ),
                Expanded(
                  child: ResultsLockedView(
                    question: poll.question,
                    options: [
                      for (final option in poll.options) option.text ?? '',
                    ],
                    progress: poll.voteProgress,
                    minVotes: poll.minVotes,
                    tag: heading.isEmpty ? null : heading,
                    // The card keeps the colours its own theme defines.
                    cardColor: _theme.backgroundColor,
                    tagColor: _theme.headingColor,
                    questionColor: _theme.questionColor,
                    optionColor: _theme.optionBackgroundColor,
                    accentColor: _theme.accentColor,
                    ownerLabel: 'This is your card',
                    sticker: _theme.stickerLabel,
                    stickerColor: _theme.stickerColor,
                    closesAt: poll.expiresAt,
                    closed: status == 'closed' || status == 'expired',
                    onShareAgain: _shareOwnCard,
                    resultsReady: poll.resultsUnlocked,
                    // Celebration confetti is push-only (`cardResultsReady`).
                    showConfetti: false,
                    totalVotes: poll.totalVoteCount,
                    onViewResults: _openingResults ? null : _openOwnResults,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- voted view

  Widget _buildVotedView(List<PollOptionResponse> options) {
    final theme = _theme;
    final poll = widget.poll;
    final myVote = poll.voting?.myVote;
    final myOptionId = myVote?.optionId;
    final myCustom = myVote?.customAnswer?.trim() ?? '';
    final myReason = myVote?.reason?.trim() ?? '';
    final heading = theme.heading.trim();
    final sticker = theme.stickerLabel.trim();
    final showResults = poll.resultsUnlocked;

    Widget? header;
    if (heading.isNotEmpty || sticker.isNotEmpty) {
      header = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: heading.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      heading,
                      style: TextStyle(
                        color: theme.headingColor,
                        fontSize: 34,
                        height: 1.02,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
          ),
          if (sticker.isNotEmpty) ...[
            const SizedBox(width: 12),
            _StickerBanner(text: sticker, color: theme.stickerColor),
          ],
        ],
      );
    }

    return AlreadyVotedView(
      key: const ValueKey('voted-view'),
      onLeave: _leave,
      onClose: _leave,
      accentColor: theme.accentColor,
      background: _themeBackground(theme),
      header: header,
      preview: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            poll.question,
            style: TextStyle(
              color: theme.questionColor,
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < options.length; i++) ...[
            _VotedOptionRow(
              letter: _letter(i),
              text: options[i].text ?? '',
              theme: theme,
              isMine: options[i].id == myOptionId,
              percentage: showResults ? options[i].percentage : null,
            ),
            const SizedBox(height: 10),
          ],
          if (showResults || (myOptionId == null && myCustom.isNotEmpty))
            _VotedOptionRow(
              letter: _letter(options.length),
              // With results shown, written-in answers are one "Something else"
              // group; the voter's own words stay visible under it.
              text: showResults ? _somethingElse : '“$myCustom”',
              subtitle: showResults && myOptionId == null && myCustom.isNotEmpty
                  ? '“$myCustom”'
                  : null,
              theme: theme,
              isMine: myOptionId == null && myCustom.isNotEmpty,
              tag: 'YOUR ANSWER',
              percentage: showResults
                  ? (poll.customAnswerPercentage ?? 0)
                  : null,
            ),
          if (myReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ReasonQuote(reason: myReason, theme: theme),
          ],
          const SizedBox(height: 14),
          if (!showResults && poll.minVotes > 0)
            _UnlockProgress(
              progress: poll.voteProgress,
              needed: poll.minVotes,
              theme: theme,
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ step 1

  Widget _buildAnswerStep(List<PollOptionResponse> options) {
    final theme = _theme;
    final enabled = !_submitting;
    final heading = theme.heading.trim();
    final sticker = theme.stickerLabel.trim();

    return _StepFrame(
      key: const ValueKey('answer-step'),
      background: _themeBackground(theme),
      onClose: enabled ? _leave : null,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Appears once an answer is picked; stays disabled while the own
          // answer is still empty.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child: _showNext
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SendButton(
                      label: 'Next',
                      color: theme.accentColor,
                      onPressed: _canContinue ? _goNext : null,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const _AnonymousNote(),
        ],
      ),
      children: [
        if (heading.isNotEmpty || sticker.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: heading.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          heading,
                          style: TextStyle(
                            color: theme.headingColor,
                            fontSize: 34,
                            height: 1.02,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
              ),
              if (sticker.isNotEmpty) ...[
                const SizedBox(width: 12),
                _StickerBanner(text: sticker, color: theme.stickerColor),
              ],
            ],
          ),
        const SizedBox(height: 14),
        Text(
          widget.poll.question,
          style: TextStyle(
            color: theme.questionColor,
            fontSize: heading.isEmpty ? 30 : 24,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < options.length; i++) ...[
          _AnswerRow(
            letter: _letter(i),
            theme: theme,
            selected: !_writeOwn && options[i].id == _selectedOptionId,
            onTap: enabled ? () => _pickOption(options[i].id) : null,
            child: Text(
              options[i].text ?? '',
              style: TextStyle(
                color: theme.optionTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _buildOwnAnswerRow(options.length, theme, enabled),
        if (_writeOwn)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _customController,
              builder: (context, value, _) => Text(
                '${value.text.characters.length}/${AppLimits.maxCustomAnswerLength}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: theme.headingColor.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOwnAnswerRow(int index, CheckTheme theme, bool enabled) {
    if (!_writeOwn) {
      return _AnswerRow(
        letter: _letter(index),
        theme: theme,
        selected: false,
        dashed: true,
        onTap: enabled ? _startWriteOwn : null,
        trailing: Icon(Icons.add, size: 22, color: theme.accentColor),
        child: const Text(
          _addOwnAnswer,
          style: TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accentColor, width: 1.5),
      ),
      child: TextField(
        controller: _customController,
        enabled: enabled,
        autofocus: true,
        maxLength: AppLimits.maxCustomAnswerLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        // Rebuild so the Next button follows what has been typed.
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _goNext(),
        cursorColor: theme.accentColor,
        style: const TextStyle(
          color: YakkuPalette.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        buildCounter: _noCounter,
        decoration: const InputDecoration(
          hintText: _addOwnAnswer,
          hintStyle: TextStyle(
            color: YakkuPalette.mutedRose,
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          // The app's input theme adds a fill and borders per state; the
          // surrounding box already is the field.
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ step 2

  Widget _buildReasonStep(bool loggedIn) {
    final theme = _theme;
    final accent = theme.accentColor;
    final heading = theme.heading.trim();
    final picked = _pickedText;
    final chipText = [
      if (heading.isNotEmpty) heading.toUpperCase(),
      if (picked.isNotEmpty) 'You picked “$picked”',
    ].join(' · ');

    return _StepFrame(
      key: const ValueKey('reason-step'),
      background: const BoxDecoration(color: YakkuPalette.cream),
      onClose: _submitting ? null : _leave,
      onBack: _submitting ? null : _backToAnswers,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SendButton(
            label: _submitting
                ? 'Sending…'
                : loggedIn
                ? 'Send'
                : 'Log in to vote',
            color: accent,
            onPressed: _submitting ? null : () => _onSubmit(),
          ),
          TextButton(
            onPressed: _submitting ? null : () => _onSubmit(skipReason: true),
            style: TextButton.styleFrom(
              foregroundColor: YakkuPalette.bodyInk,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 14),
        if (chipText.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  chipText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        const Text(
          'Want to tell them why?',
          style: TextStyle(
            color: YakkuPalette.textPrimary,
            fontSize: 30,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Optional. Still anonymous. Reasons are what they'll read first.",
          style: TextStyle(
            color: YakkuPalette.bodyInk,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _reasonController,
          enabled: !_submitting,
          minLines: 4,
          maxLines: 6,
          maxLength: AppLimits.maxReasonLength,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: accent,
          style: const TextStyle(
            color: YakkuPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          buildCounter: _noCounter,
          decoration: InputDecoration(
            hintText: 'Say why you picked this…',
            hintStyle: const TextStyle(
              color: YakkuPalette.placeholder,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: YakkuPalette.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: YakkuPalette.roseBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: YakkuPalette.roseBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _reasonController,
          builder: (context, value, _) => Text(
            '${value.text.characters.length} / ${AppLimits.maxReasonLength}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: YakkuPalette.mutedRose,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  static BoxDecoration _themeBackground(CheckTheme theme) {
    final gradient = theme.backgroundGradient;
    if (gradient != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      );
    }
    return BoxDecoration(color: theme.backgroundColor);
  }

  static String _letter(int index) => String.fromCharCode(65 + index);
}

Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;

/// Shared page layout: the Yakku header with the close icon on top, scrolling
/// [children], and a [footer] pinned to the bottom.
class _StepFrame extends StatelessWidget {
  const _StepFrame({
    super.key,
    required this.background,
    required this.onClose,
    required this.footer,
    required this.children,
    this.onBack,
  });

  final BoxDecoration background;
  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final Widget footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _YakkuHeader(onClose: onClose, onBack: onBack),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: footer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Yakku." wordmark on the left, close icon on the right.
class _YakkuHeader extends StatelessWidget {
  const _YakkuHeader({required this.onClose, this.onBack});

  final VoidCallback? onClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back,
                color: YakkuPalette.textPrimary,
              ),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 12),
          const _Wordmark(),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: YakkuPalette.textPrimary),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Yakku',
          style: TextStyle(
            color: YakkuPalette.textPrimary,
            fontSize: 24,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 2, bottom: 3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: YakkuPalette.Dot,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 5, height: 5),
          ),
        ),
      ],
    );
  }
}

/// The tilted sticker in the top-right corner of a check card.
class _StickerBanner extends StatelessWidget {
  const _StickerBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Transform.rotate(
        angle: 0.08,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: YakkuPalette.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YakkuPalette.black),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pacifico',
                color: color,
                fontSize: 18,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A lettered answer in the card's option colors. The "add your own" row is
/// [dashed] and carries a [trailing] plus.
class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.letter,
    required this.theme,
    required this.selected,
    required this.onTap,
    required this.child,
    this.dashed = false,
    this.trailing,
  });

  final String letter;
  final CheckTheme theme;
  final bool selected;
  final bool dashed;
  final VoidCallback? onTap;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentColor;
    final row = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dashed
                    ? YakkuPalette.white
                    : selected
                    ? accent
                    : accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: selected
                      ? YakkuPalette.white
                      : dashed
                      ? YakkuPalette.Ink
                      : theme.optionTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
            ?trailing,
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: dashed
            ? YakkuPalette.white.withValues(alpha: 0.45)
            : theme.optionBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? accent : YakkuPalette.transparent,
            width: 2,
          ),
        ),
        child: dashed
            ? CustomPaint(
                foregroundPainter: _DashedBorderPainter(
                  color: accent.withAlpha(110),
                  radius: 16,
                ),
                child: row,
              )
            : row,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

/// An answer in the voted view. The voter's own pick is outlined with a tag;
/// the rest are dimmed, or filled to their share once results are visible.
class _VotedOptionRow extends StatelessWidget {
  const _VotedOptionRow({
    required this.letter,
    required this.text,
    required this.theme,
    required this.isMine,
    this.percentage,
    this.tag = 'YOUR PICK',
    this.subtitle,
  });

  final String letter;
  final String text;

  /// Smaller line under [text], e.g. the voter's own words.
  final String? subtitle;
  final CheckTheme theme;
  final bool isMine;

  /// 0-100; null while results are hidden.
  final double? percentage;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentColor;
    final pct = percentage?.clamp(0, 100).toDouble();
    // While results are hidden, answers other than the voter's pick are dimmed.
    final dimmed = !isMine && pct == null;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.optionBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMine ? accent : YakkuPalette.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              if (pct != null)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct / 100,
                    child: ColoredBox(
                      color: accent.withValues(alpha: isMine ? 0.22 : 0.12),
                    ),
                  ),
                ),
              Container(
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isMine ? accent : accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: isMine
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: YakkuPalette.white,
                            )
                          : Text(
                              letter,
                              style: TextStyle(
                                color: theme.optionTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMine)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          Text(
                            text,
                            style: TextStyle(
                              color: theme.optionTextColor,
                              fontSize: 16,
                              fontWeight: isMine
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle!,
                                style: TextStyle(
                                  color: theme.optionTextColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (pct != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          '${pct.round()}%',
                          style: TextStyle(
                            color: isMine ? accent : theme.optionTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the voter wrote as their reason, shown back to them as a quote.
class _ReasonQuote extends StatelessWidget {
  const _ReasonQuote({required this.reason, required this.theme});

  final String reason;
  final CheckTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHAT YOU TOLD THEM',
              style: TextStyle(
                color: theme.accentColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '“$reason”',
              style: const TextStyle(
                color: YakkuPalette.textPrimary,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far the card is from revealing its results.
class _UnlockProgress extends StatelessWidget {
  const _UnlockProgress({
    required this.progress,
    required this.needed,
    required this.theme,
  });

  final int progress;
  final int needed;
  final CheckTheme theme;

  @override
  Widget build(BuildContext context) {
    final accent = theme.accentColor;
    final value = (progress / needed).clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Results unlock at $needed votes',
                    style: const TextStyle(
                      color: YakkuPalette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$progress/$needed',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: YakkuPalette.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          disabledForegroundColor: YakkuPalette.white.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AnonymousNote extends StatelessWidget {
  const _AnonymousNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.visibility_off_outlined,
          size: 18,
          color: YakkuPalette.mutedRose,
        ),
        SizedBox(width: 8),
        Text(
          "Anonymous. They'll never know it was you.",
          style: TextStyle(
            color: YakkuPalette.mutedRose,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
