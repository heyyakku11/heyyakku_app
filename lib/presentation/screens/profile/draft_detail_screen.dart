import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/create/create_poll_claim_screen.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/created_poll_screen.dart';
import 'package:yakku/presentation/screens/profile/draft_progress.dart';
import 'package:yakku/presentation/screens/profile/draft_screen.dart';
import 'package:yakku/presentation/screens/profile/widgets/my_card_menu.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';

/// One draft: the card as far as it got, what is still to do, and the way to
/// carry on (make your guess, edit) or delete it.
class DraftDetailScreen extends StatelessWidget {
  const DraftDetailScreen({super.key, required this.draftId});

  final int draftId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).draftPolls;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final draft = store.drafts.where((d) => d.id == draftId).firstOrNull;
        if (draft == null) {
          // Deleted, or taken to be edited: nothing left to show here.
          return const Scaffold(backgroundColor: YakkuPalette.cream);
        }
        return _DraftDetail(draft: draft);
      },
    );
  }
}

class _DraftDetail extends StatefulWidget {
  const _DraftDetail({required this.draft});

  final DraftPoll draft;

  @override
  State<_DraftDetail> createState() => _DraftDetailState();
}

class _DraftDetailState extends State<_DraftDetail> {
  late final DraftProgress _progress = DraftProgress(widget.draft);

  /// The next unfinished step: finish the card, or make the guess.
  Future<void> _primary() async {
    if (!_progress.readyToGuess) {
      await _edit();
      return;
    }

    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      openSignUp(context);
      return;
    }

    final poll = await Navigator.of(context).push<PollResponse>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreatePollClaimScreen(
          question: _progress.question,
          options: _progress.options,
        ),
      ),
    );
    if (poll == null || !mounted) return;

    // Sharing it moves it from Drafts to My cards.
    await scope.draftPolls.delete(widget.draft.id);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => CreatedPollScreen(poll: poll)),
    );
  }

  /// Reopens the write screen with this draft. The draft is saved again when
  /// that screen is closed with something typed.
  Future<void> _edit() async {
    final navigator = Navigator.of(context);
    final taken = await AppScope.of(context).draftPolls.take(widget.draft.id);
    if (!mounted || taken == null) return;
    navigator.pop();
    await showCreatePollSheet(navigator.context, draft: taken);
  }

  Future<void> _delete() async {
    final confirmed = await showDeleteCardDialog(
      context,
      _progress.hasQuestion ? _progress.question : 'Untitled draft',
      title: 'Delete this draft?',
      bullets: const [
        'Your question and options are removed.',
        'Drafts are private, so nobody else is affected.',
        'This can’t be undone.',
      ],
      confirmLabel: 'Delete draft',
      keepLabel: 'Keep it',
    );
    if (!confirmed || !mounted) return;
    final navigator = Navigator.of(context);
    await AppScope.of(context).draftPolls.delete(widget.draft.id);
    if (mounted) navigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                      icon: const FaIcon(
                        FontAwesomeIcons.chevronLeft,
                        size: 16,
                        color: YakkuPalette.Ink,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Draft',
                        style: TextStyle(
                          color: YakkuPalette.Ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Edited ${p.ago.toLowerCase()} · not shared',
                        style: const TextStyle(
                          color: YakkuPalette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DraftCard(progress: p),
                    const SizedBox(height: 16),
                    _Checklist(progress: p),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _primary,
                      style: FilledButton.styleFrom(
                        backgroundColor: YakkuPalette.Raspberry,
                        foregroundColor: YakkuPalette.white,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        p.primaryLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _edit,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: YakkuPalette.Ink,
                              side: const BorderSide(
                                color: YakkuPalette.Ink,
                                width: 1.2,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _delete,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFBE1E6),
                              foregroundColor: YakkuPalette.Raspberry,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Delete draft',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card as it stands: question and the options written so far.
class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.progress});

  final DraftProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: DraftScreen.draftColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              'YOUR QUESTION',
              style: TextStyle(
                color: Color(0xFF4C6B1D),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              p.hasQuestion ? p.question : 'No question yet',
              style: TextStyle(
                color: p.hasQuestion
                    ? YakkuPalette.Ink
                    : YakkuPalette.textSecondary,
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < p.options.length; i++) ...[
            GuessAnswerRow(
              letter: String.fromCharCode(65 + i),
              text: p.options[i],
              selected: false,
              onTap: () {},
            ),
            const SizedBox(height: 12),
          ],
          const GuessLockedSlot(),
        ],
      ),
    );
  }
}

/// "Almost ready to share": what is done and what is still to do.
class _Checklist extends StatelessWidget {
  const _Checklist({required this.progress});

  final DraftProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.readyToGuess ? 'Almost ready to share' : 'Finish your card',
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          _Step(
            done: p.hasQuestion,
            title: p.hasQuestion ? 'Question written' : 'Write your question',
            current: !p.hasQuestion,
          ),
          const SizedBox(height: 12),
          _Step(
            done: p.hasOptions,
            title: p.hasOptions
                ? '${p.options.length} options added'
                : 'Add ${p.optionsMissing} more ${p.optionsMissing == 1 ? 'option' : 'options'}',
            current: p.hasQuestion && !p.hasOptions,
          ),
          const SizedBox(height: 12),
          _Step(
            done: false,
            title: 'Your guess',
            subtitle: 'Pick what you think your friends will say',
            current: p.readyToGuess,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.done,
    required this.title,
    this.subtitle,
    this.current = false,
  });

  final bool done;
  final String title;
  final String? subtitle;

  /// The step to do next: shown in raspberry.
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (done)
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.Ink,
            ),
            child: const FaIcon(
              FontAwesomeIcons.check,
              size: 11,
              color: YakkuPalette.white,
            ),
          )
        else
          CustomPaint(
            foregroundPainter: DashedBorderPainter(
              color: current ? YakkuPalette.Raspberry : YakkuPalette.hint,
              radius: 12,
            ),
            child: const SizedBox(width: 24, height: 24),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  title,
                  style: TextStyle(
                    color: current ? YakkuPalette.Raspberry : YakkuPalette.Ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: YakkuPalette.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
