import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/make_check_request.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/share/card_share_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/check_share_card.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';

/// A check, in two steps: (1) the user picks their own answer first ("you
/// guess first"), then (2) "Ask now" makes the check and opens the share
/// screen so friends can answer it too.
class CheckDetailScreen extends StatefulWidget {
  const CheckDetailScreen({super.key, required this.check});

  final AskFriendsCheck check;

  @override
  State<CheckDetailScreen> createState() => _CheckDetailScreenState();
}

class _CheckDetailScreenState extends State<CheckDetailScreen>
    with SingleTickerProviderStateMixin {
  /// Drives the sticker's shake when a disabled "Ask now" is tapped.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  int? _selectedIndex;
  bool _sending = false;

  AskFriendsCheck get check => widget.check;

  /// Real poll answers only: "Friends add their own" is UI chrome, not an option.
  List<AskFriendsOption> get _answerOptions => [
    for (final option in check.options)
      if (!option.outlined && option.label.trim().isNotEmpty) option,
  ];

  String get _question => check.question.trim().isNotEmpty
      ? check.question.trim()
      : check.title.trim();

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_sending) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  /// "Ask now" before picking an answer: shake the sticker.
  void _nudge() {
    if (_selectedIndex != null || _sending) return;
    HapticFeedback.mediumImpact();
    _shake.forward(from: 0);
  }

  Future<void> _askNow() async {
    final selected = _selectedIndex;
    if (selected == null || _sending) return;

    final answers = _answerOptions;
    if (selected < 0 || selected >= answers.length) return;

    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      openSignUp(context);
      return;
    }

    final options = [for (final option in answers) option.label.trim()];

    setState(() => _sending = true);
    try {
      final next = await _create(scope, answers[selected], selected, options);
      if (!mounted) return;
      // Replace this screen so Back from the share screen doesn't return to a
      // check that has already been sent.
      await Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      AppToast.show(_errorMessage(error));
    }
  }

  /// Makes the check (or a poll, for a question that is not a stored check)
  /// with the user's own answer, and returns the share screen for it. Uses
  /// the passed [scope] so it still works after this screen has been replaced.
  Future<Widget> _create(
    AppScope scope,
    AskFriendsOption answer,
    int selected,
    List<String> options,
  ) async {
    final question = _question;
    final checkId = check.checkId;
    final optionId = answer.id;

    final String shareCode;
    final int minVotes;
    if (checkId != null && optionId != null) {
      final made = await scope.checkApi.makeCheck(
        MakeCheckRequest(
          checkId: checkId,
          checkOptionId: optionId,
          fun: check.isFun,
        ),
      );
      shareCode = made.shareCode;
      minVotes = made.minVotes;
    } else {
      final poll = await scope.pollApi.createTextPoll(
        question: question,
        options: options,
        selectedOptionIndex: selected,
      );
      shareCode = poll.shareCode;
      minVotes = poll.minVotes;
    }

    return CardShareScreen(
      minVotes: minVotes,
      buildPayload: () => SharePayload.create(
        shareCode: shareCode,
        question: question,
        options: options,
      ),
      preview: CheckShareCard(
        title: check.title,
        question: question,
        options: options,
        width: 310,
      ),
      story: CheckStoryCard(
        title: check.title,
        question: question,
        options: options,
      ),
    );
  }

  String _errorMessage(Object error) {
    final api = DioErrorMapper.map(
      error,
      fallback: 'Could not send this check. Please try again.',
    );
    return switch (api.kind) {
      ApiErrorKind.connection ||
      ApiErrorKind.timeout => 'No connection. Check your network and retry.',
      _ => api.message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final picked = _selectedIndex != null;
    final answers = _answerOptions;
    final sameAsQuestion =
        check.title.trim().toLowerCase() == _question.toLowerCase();

    return PopScope(
      // Going back mid-request would orphan the create call.
      canPop: !_sending,
      child: Scaffold(
        // The screen takes the card's own colour, so the check feels like the
        // same card the user tapped on the feed.
        backgroundColor: check.backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _sending
                      ? null
                      : () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: YakkuPalette.Ink,
                  ),
                ),
                GuessStepper(step2: picked),
                const SizedBox(height: 18),
                GuessTag(
                  label: sameAsQuestion || check.title.trim().isEmpty
                      ? 'YOUR QUESTION'
                      : check.title.trim().toUpperCase(),
                ),
                const SizedBox(height: 12),
                Text(
                  _question,
                  style: const TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GuessSticker(
                      text: picked ? 'Your guess' : 'You guess first!',
                      shake: _shake,
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: GuessArrow(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < answers.length; i++) ...[
                          GuessAnswerRow(
                            letter: String.fromCharCode(65 + i),
                            text: answers[i].label.trim(),
                            selected: _selectedIndex == i,
                            onTap: () => _select(i),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const GuessLockedSlot(),
                      ],
                    ),
                  ),
                ),
                const GuessPrivacyNote(),
                const SizedBox(height: 12),
                GuessAskButton(
                  enabled: picked && !_sending,
                  loading: _sending,
                  onPressed: _askNow,
                  onDisabledTap: _nudge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
