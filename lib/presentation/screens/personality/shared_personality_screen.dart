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
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';

enum _PersonalityIssue {
  notFound,
  unavailable,

  /// The card is no longer collecting votes.
  closed,
  failed,
}

/// Destination of `https://<web host>/personality/{shareCode}` links: a
/// friend's personality card, where the visitor picks 3 traits that describe
/// its owner.
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
        _card = issue == null ? card : null;
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
        setState(() {
          _card = null;
          _issue = _PersonalityIssue.closed;
        });
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

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final Widget body;
    if (card != null) {
      body = card.isOwner
          ? _buildOwn(card)
          : card.hasVoted
          ? _buildVoted()
          : _buildVote(card);
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

  Widget _buildOwn(SharedPersonalityCard card) {
    final (body, action) = switch (card.status) {
      PersonalityCardStatus.draft => (
        'Make your own guess first, then share it with friends.',
        'Make your guess',
      ),
      PersonalityCardStatus.collecting => (
        card.requiredVotes > 0
            ? '${card.totalVotes} of ${card.requiredVotes} friends have voted. '
                  'You cannot vote on your own card.'
            : 'You cannot vote on your own card.',
        'Share again',
      ),
      PersonalityCardStatus.completed => (
        'Your friends have all voted. See how they see you.',
        'View results',
      ),
    };
    return _MessageView(
      key: const ValueKey('personality-own-view'),
      title: 'This is your card',
      body: body,
      primaryLabel: action,
      onPrimary: _openingOwnCard ? null : _openOwnCard,
      primaryLoading: _openingOwnCard,
      onLeave: _leave,
    );
  }

  // ------------------------------------------------------------ voted / issue

  Widget _buildVoted() {
    return _MessageView(
      key: const ValueKey('personality-voted-view'),
      title: 'You already voted',
      body: 'Locked in. Thanks for being honest.',
      onLeave: _leave,
    );
  }

  Widget _buildIssue(_PersonalityIssue issue) {
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
        'Voting is closed',
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
