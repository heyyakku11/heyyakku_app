import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/screens/personality/personality_share_screen.dart';
import 'package:yakku/presentation/widgets/already_voted_view.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';
import 'package:yakku/presentation/widgets/personality_own_locked_view.dart';
import 'package:yakku/presentation/widgets/voting_closed_view.dart';

enum _PersonalityIssue {
  notFound,
  unavailable,

  /// The card is no longer collecting votes.
  closed,
  failed,
}

/// Destination of `https://<web host>/personality?share_code=…` links (and
/// legacy `/personality/{shareCode}`): a friend's personality card, where the
/// visitor picks 3 traits that describe its owner.
///
/// Mirrors `SharedPollScreen`. The card is loaded through the share-code API
/// (the same one the website uses) and the API's voting state decides what is
/// shown: the voting view, "This is your card" for the owner, or "You already
/// voted". The backend stays the authority on whether a vote is valid; the
/// rejections it can return are mapped back onto these same views.
class SharedPersonalityScreen extends StatefulWidget {
  const SharedPersonalityScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  State<SharedPersonalityScreen> createState() =>
      _SharedPersonalityScreenState();
}

class _SharedPersonalityScreenState extends State<SharedPersonalityScreen> {
  static const _picks = 3;

  SharedPersonalityCard? _card;
  _PersonalityIssue? _issue;
  List<PersonalityTrait> _traits = const [];
  bool _traitsFailed = false;
  bool _started = false;
  bool _submitting = false;
  bool _openingOwnCard = false;
  AuthController? _auth;

  /// Login state the card was loaded with; its voting state is only valid for
  /// that user, so a login mid-screen reloads it.
  bool? _loadedLoggedIn;

  /// Trait ids in the order they were picked.
  final List<String> _selected = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AppScope.of(context).authController;
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_onAuthChanged);
      _auth = auth..addListener(_onAuthChanged);
    }
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted || _loadedLoggedIn == _auth?.isLoggedIn) return;
    _load(silent: true);
  }

  /// [silent] refreshes without replacing the card, so what the user has
  /// picked is kept.
  Future<void> _load({bool silent = false}) async {
    if (!PollDeepLink.isValidShareCode(widget.shareCode)) {
      setState(() => _issue = _PersonalityIssue.notFound);
      return;
    }
    if (!silent) {
      setState(() {
        _card = null;
        _issue = null;
      });
    }
    final scope = AppScope.of(context);
    final loggedIn = scope.authController.isLoggedIn;
    try {
      final card = await scope.userRemote.getSharedPersonalityCard(
        widget.shareCode,
      );
      if (!mounted) return;
      _loadedLoggedIn = loggedIn;
      final issue = _issueFor(card);
      setState(() {
        _issue = issue;
        // Keep the card for the closed edge template (owner name / vote count).
        _card = issue == null || issue == _PersonalityIssue.closed ? card : null;
      });
      if (issue == null && _traits.isEmpty) unawaited(_loadTraits());
    } catch (error) {
      if (!mounted || silent) return;
      final api = DioErrorMapper.map(error);
      setState(() {
        _issue = switch (api.statusCode) {
          400 || 404 => _PersonalityIssue.notFound,
          401 || 403 => _PersonalityIssue.unavailable,
          _ => _PersonalityIssue.failed,
        };
      });
    }
  }

  Future<void> _loadTraits() async {
    setState(() => _traitsFailed = false);
    try {
      final traits = await AppScope.of(
        context,
      ).userRemote.getPersonalityTraits();
      if (!mounted) return;
      setState(() {
        _traits = traits;
        _traitsFailed = traits.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _traitsFailed = true);
    }
  }

  /// UI-level hint only; the backend remains the authority on vote validity.
  _PersonalityIssue? _issueFor(SharedPersonalityCard card) {
    if (card.shareCode.isEmpty) return _PersonalityIssue.notFound;
    // The owner's own card is shown with their progress and actions.
    if (card.isOwner) return null;
    // An already-voted card is shown with the "You already voted" message.
    if (card.hasVoted) return null;
    if (!card.canVote) return _PersonalityIssue.closed;
    return null;
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.main);
    }
  }

  void _toggle(PersonalityTrait trait) {
    if (_submitting) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(trait.id)) {
        _selected.remove(trait.id);
      } else if (_selected.length < _picks) {
        _selected.add(trait.id);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting || _selected.length != _picks) return;
    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      // Voting needs an account.
      openSignUp(context);
      return;
    }

    setState(() => _submitting = true);
    try {
      await scope.userRemote.votePersonalityCard(
        widget.shareCode,
        List.of(_selected),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _onVoteRejected(error);
      return;
    }
    if (!mounted) return;
    AppToast.show('Vote submitted');
    context.go(AppRoutes.main);
  }

  /// Puts a rejected vote back onto the view that explains it.
  void _onVoteRejected(Object error) {
    final api = DioErrorMapper.map(
      error,
      fallback: "Couldn't submit your vote. Please try again.",
    );
    final card = _card;
    switch (api.kind) {
      case ApiErrorKind.conflict when api.code == 'ALREADY_VOTED':
        if (card != null) {
          setState(() => _card = card.copyWith(hasVoted: true, canVote: false));
        }
      case ApiErrorKind.conflict:
        // Not collecting votes any more (the card just got its last vote).
        setState(() => _issue = _PersonalityIssue.closed);
      case ApiErrorKind.forbidden:
        if (card != null) {
          setState(() => _card = card.copyWith(isOwner: true, canVote: false));
        }
      case ApiErrorKind.notFound:
        setState(() {
          _card = null;
          _issue = _PersonalityIssue.notFound;
        });
      case ApiErrorKind.connection || ApiErrorKind.timeout:
        AppToast.show('No connection. Check your network and retry.');
      default:
        AppToast.show(
          api.statusCode == null || api.statusCode! >= 500
              ? "Couldn't submit your vote. Please try again."
              : api.message,
        );
    }
  }

  /// The owner's card, by where it is: the guess screen (draft), the share
  /// screen (collecting) or the result (completed).
  Future<void> _openOwnCard() async {
    if (_openingOwnCard) return;
    setState(() => _openingOwnCard = true);
    try {
      final store = AppScope.of(context).personalityCards;
      await store.refresh();
      final card = store.card;
      if (card == null) throw StateError('Card not found');
      if (!mounted) return;
      await openPersonalityAsk(context, card, store.traits);
    } catch (_) {
      if (!mounted) return;
      AppToast.show('Could not open your card');
    } finally {
      if (mounted) setState(() => _openingOwnCard = false);
    }
  }

  /// Opens the same share destinations friends get for this personality card.
  Future<void> _shareOwnCard(SharedPersonalityCard card) async {
    if (_openingOwnCard) return;
    setState(() => _openingOwnCard = true);
    try {
      final store = AppScope.of(context).personalityCards;
      // Prefer the owner's own picks for the blurred preview; fall back to the
      // catalog so the card still looks filled if the store is cold.
      var traits = [
        for (final trait in store.card?.selfTraits ?? const <PersonalityTrait>[])
          trait.name,
      ];
      if (traits.isEmpty) {
        await store.refresh();
        if (!mounted) return;
        traits = [
          for (final trait in store.card?.selfTraits ?? const <PersonalityTrait>[])
            trait.name,
        ];
      }
      if (traits.isEmpty) {
        traits = [for (final trait in store.traits) trait.name];
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PersonalityShareScreen(
            shareCode: card.shareCode,
            traits: traits,
            minVotes: card.requiredVotes,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show('Could not open share');
    } finally {
      if (mounted) setState(() => _openingOwnCard = false);
    }
  }

  List<String> _previewTraitNames() {
    final store = AppScope.of(context).personalityCards;
    final self = [
      for (final trait in store.card?.selfTraits ?? const <PersonalityTrait>[])
        trait.name,
    ];
    if (self.isNotEmpty) return self;
    return [for (final trait in store.traits) trait.name];
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card != null && !card.isOwner && card.hasVoted) {
      return Scaffold(
        backgroundColor: YakkuPalette.pinkTintSoft,
        body: _buildVoted(),
      );
    }

    if (_issue == _PersonalityIssue.closed) {
      return Scaffold(
        backgroundColor: YakkuPalette.pinkTintSoft,
        body: _buildVotingClosed(card),
      );
    }

    final Widget body;
    if (card != null) {
      body = card.isOwner ? _buildOwn(card) : _buildVote(card);
    } else if (_issue != null) {
      body = _buildIssue(_issue!);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: YakkuPalette.pinkTintSoft,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 0, 0),
                    child: IconButton(
                      onPressed: _submitting ? null : _leave,
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: YakkuPalette.Ink,
                      ),
                    ),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVotingClosed(SharedPersonalityCard? card) {
    final name = card?.ownerAnonymousName.trim() ?? '';
    final votes = card?.totalVotes;
    final needed = card?.requiredVotes;
    final filled = votes != null && needed != null && needed > 0
        ? '$votes of $needed votes in'
        : null;

    return VotingClosedView(
      key: const ValueKey('personality-voting-closed'),
      onLeave: _leave,
      onClose: _leave,
      accentColor: YakkuPalette.Raspberry,
      background: const BoxDecoration(color: YakkuPalette.pinkTintSoft),
      showYakkuMark: false,
      title: VotingClosedView.defaultTitle,
      subtitle: name.isEmpty
          ? 'This card already has all its votes.'
          : "$name's card already has all its votes.",
      statusLabel: filled,
      preview: _ClosedPersonalityPreview(ownerName: name),
    );
  }

  // -------------------------------------------------------------- vote view

  Widget _buildVote(SharedPersonalityCard card) {
    final name = card.ownerAnonymousName.trim();
    final complete = _selected.length == _picks;
    return Padding(
      key: const ValueKey('personality-vote-view'),
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GuessTag(label: 'YOUR TAKE'),
          const SizedBox(height: 12),
          Text(
            name.isEmpty
                ? 'Describe them in 3 words'
                : 'Describe $name in 3 words',
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 32,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${_selected.length} of $_picks',
            style: TextStyle(
              color: complete ? YakkuPalette.Ink : YakkuPalette.Raspberry,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: _buildTraits())),
          const _AnonymousNote(),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: AppScope.of(context).authController.isLoggedIn
                ? 'Send my vote'
                : 'Log in to vote',
            loading: _submitting,
            onPressed: complete && !_submitting ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTraits() {
    if (_traits.isEmpty) {
      if (!_traitsFailed) {
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            const Text(
              'Could not load the traits.',
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(onPressed: _loadTraits, child: const Text('Try again')),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 14,
      children: [
        for (final trait in _traits)
          GuessTraitChip(
            label: trait.name,
            selected: _selected.contains(trait.id),
            onTap: () => _toggle(trait),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- own card

  /// Same pattern as poll/check own links: card preview + progress + action.
  /// Voting stays blocked; the owner can share again or open their flow.
  Widget _buildOwn(SharedPersonalityCard card) {
    return PersonalityOwnLockedView(
      key: const ValueKey('personality-own-view'),
      status: card.status,
      totalVotes: card.totalVotes,
      requiredVotes: card.requiredVotes,
      traitNames: _previewTraitNames(),
      busy: _openingOwnCard,
      onMakeGuess: _openingOwnCard ? null : _openOwnCard,
      onShareAgain: _openingOwnCard ? null : () => _shareOwnCard(card),
      onViewResults: _openingOwnCard ? null : _openOwnCard,
    );
  }

  // ------------------------------------------------------------ voted / issue

  Widget _buildVoted() {
    final pickNames = [
      for (final id in _selected)
        for (final trait in _traits)
          if (trait.id == id) trait.name,
    ];

    return AlreadyVotedView(
      key: const ValueKey('personality-voted-view'),
      onLeave: _leave,
      onClose: _leave,
      accentColor: YakkuPalette.Raspberry,
      background: const BoxDecoration(color: YakkuPalette.pinkTintSoft),
      showYakkuMark: false,
      preview: pickNames.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your picks',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final name in pickNames) _LockedTraitChip(label: name),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildIssue(_PersonalityIssue issue) {
    // Closed must never fall through to the plain text message view.
    if (issue == _PersonalityIssue.closed) {
      return _buildVotingClosed(_card);
    }

    final (title, body) = switch (issue) {
      _PersonalityIssue.notFound => (
        'Card not found',
        'This card may have been removed or the link might be broken.',
      ),
      _PersonalityIssue.unavailable => (
        'Card unavailable',
        "This card isn't available for voting.",
      ),
      _PersonalityIssue.closed => (
        VotingClosedView.defaultTitle,
        'This card already has all its votes.',
      ),
      _PersonalityIssue.failed => (
        "Couldn't load this card",
        'Something went wrong while contacting Yakku. Please try again.',
      ),
    };
    return _MessageView(
      key: ValueKey('personality-issue-${issue.name}'),
      title: title,
      body: body,
      primaryLabel: issue == _PersonalityIssue.failed ? 'Try again' : null,
      onPrimary: issue == _PersonalityIssue.failed ? _load : null,
      onLeave: _leave,
    );
  }
}

/// Compact locked personality card for the closed edge screen. Avoids the
/// share-card CTA row so narrow viewports stay overflow-free.
class _ClosedPersonalityPreview extends StatelessWidget {
  const _ClosedPersonalityPreview({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (ownerName.isNotEmpty) ...[
          Text(
            ownerName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Center(
          child: Transform.rotate(
            angle: -0.04,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.Raspberry,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: YakkuPalette.Ink, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 6)),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Yakku.',
                            style: TextStyle(
                              color: YakkuPalette.white,
                              fontSize: 22,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'WHO YOU ARE',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Describe me in 3 words',
                        style: TextStyle(
                          color: YakkuPalette.white,
                          fontSize: 28,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                      SizedBox(height: 18),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x33FFFFFF),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                color: YakkuPalette.white,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Voting locked · answers are in',
                                  style: TextStyle(
                                    color: YakkuPalette.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A centred title and message with an optional primary action and a
/// "Back to Yakku" button.
class _MessageView extends StatelessWidget {
  const _MessageView({
    super.key,
    required this.title,
    required this.body,
    required this.onLeave,
    this.primaryLabel,
    this.onPrimary,
    this.primaryLoading = false,
  });

  final String title;
  final String body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryLoading;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (primaryLabel != null) ...[
              _PrimaryButton(
                label: primaryLabel!,
                loading: primaryLoading,
                onPressed: onPrimary,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton(
              onPressed: onLeave,
              child: const Text('Back to Yakku'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: YakkuPalette.Raspberry,
          disabledBackgroundColor: YakkuPalette.Raspberry.withValues(
            alpha: 0.18,
          ),
          foregroundColor: YakkuPalette.white,
          disabledForegroundColor: YakkuPalette.Raspberry.withValues(
            alpha: 0.45,
          ),
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: YakkuPalette.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _AnonymousNote extends StatelessWidget {
  const _AnonymousNote();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: YakkuPalette.Ink),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              "Anonymous. They'll never know it was you.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Non-interactive raspberry chip for picks shown on the already-voted screen.
class _LockedTraitChip extends StatelessWidget {
  const _LockedTraitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: YakkuPalette.Raspberry.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: const TextStyle(
            color: YakkuPalette.Raspberry,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
