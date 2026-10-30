import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_mobile_login.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Voting screen for someone else's card, opened from a shared link. Mirrors
/// the website: the question, lettered answers (the last one is the voter's
/// own words), an optional anonymous "what made you choose this?" and a
/// "Send vote" button. Voting needs a login; once the vote is accepted the
/// user goes straight into the app.
class AnswerPollScreen extends StatefulWidget {
  const AnswerPollScreen({super.key, required this.poll});

  final PollResponse poll;

  @override
  State<AnswerPollScreen> createState() => _AnswerPollScreenState();
}

class _AnswerPollScreenState extends State<AnswerPollScreen> {
  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.mutedRose;
  static const _writeYourOwn = 'Write your own answer';

  final _customController = TextEditingController();
  final _reasonController = TextEditingController();

  String? _selectedOptionId;
  bool _writeOwn = false;
  bool _submitting = false;

  @override
  void dispose() {
    _customController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _hasSelection => _selectedOptionId != null || _writeOwn;

  /// Writing your own answer needs the voter's own words.
  bool get _canSubmit =>
      _hasSelection && (!_writeOwn || _customController.text.trim().isNotEmpty);

  void _selectOption(String id) => setState(() {
    _selectedOptionId = id;
    _writeOwn = false;
  });

  void _selectWriteOwn() => setState(() {
    _selectedOptionId = null;
    _writeOwn = true;
  });

  Future<void> _onSubmit() async {
    if (_submitting) return;

    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      // Voting needs a login. When it succeeds the card reloads for the
      // signed-in user and the voter taps Send vote again.
      await openMobileLogin(context);
      return;
    }
    if (!_canSubmit) return;

    final reason = _reasonController.text.trim();
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
      builder: (context, _) => _buildScaffold(options, auth.isLoggedIn),
    );
  }

  Widget _buildScaffold(List<PollOptionResponse> options, bool loggedIn) {
    final enabled = !_submitting;
    final canTap = !_submitting && (!loggedIn || _canSubmit);

    return Scaffold(
      backgroundColor: YakkuPalette.accentYellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AskedByRow(onClose: enabled ? _leave : null),
                  const SizedBox(height: 22),
                  Text(
                    widget.poll.question,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < options.length; i++) ...[
                    _AnswerRow(
                      letter: _letter(i),
                      selected: options[i].id == _selectedOptionId,
                      onTap: enabled
                          ? () => _selectOption(options[i].id)
                          : null,
                      child: Text(
                        options[i].text ?? '',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _AnswerRow(
                    letter: _letter(options.length),
                    selected: _writeOwn,
                    onTap: enabled && !_writeOwn ? _selectWriteOwn : null,
                    child: _writeOwn
                        ? TextField(
                            controller: _customController,
                            enabled: enabled,
                            autofocus: true,
                            maxLength: AppLimits.maxCustomAnswerLength,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                            cursorColor: YakkuPalette.primary,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            buildCounter: _noCounter,
                            decoration: const InputDecoration(
                              hintText: _writeYourOwn,
                              hintStyle: TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w600,
                              ),
                              isDense: true,
                              // The app's input theme adds a fill and borders
                              // per state; the row already is the box.
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        : const Text(
                            _writeYourOwn,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (_hasSelection) ...[
                    const SizedBox(height: 22),
                    _ReasonSection(
                      controller: _reasonController,
                      enabled: enabled,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SendButton(
                    label: _submitting
                        ? 'Sending…'
                        : loggedIn
                        ? 'Send vote'
                        : 'Log in to vote',
                    // Logged-out voters can always tap to log in; the vote
                    // itself needs a pick (and their own words if they wrote
                    // their own answer).
                    onPressed: canTap ? _onSubmit : null,
                  ),
                  const SizedBox(height: 18),
                  const _AnonymousNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _letter(int index) => String.fromCharCode(65 + index);
}

Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;

/// "A friend asked you" with the close button.
class _AskedByRow extends StatelessWidget {
  const _AskedByRow({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: YakkuPalette.peach,
            shape: BoxShape.circle,
          ),
          child: const Text(
            '?',
            style: TextStyle(
              color: YakkuPalette.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'A friend',
                  style: TextStyle(
                    color: YakkuPalette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' asked you',
                  style: TextStyle(
                    color: YakkuPalette.mutedRose,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            style: TextStyle(fontSize: 15),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, color: YakkuPalette.textPrimary),
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// White rounded answer with its letter badge; the selected one is outlined.
class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.letter,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String letter;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: YakkuPalette.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? YakkuPalette.primary : YakkuPalette.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? YakkuPalette.primary
                        : YakkuPalette.pinkMist,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: selected
                          ? YakkuPalette.white
                          : YakkuPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "What made you choose this?" with the optional anonymous reason box.
class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'What made you choose this?',
                style: TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' Anonymous · Optional',
                style: TextStyle(
                  color: YakkuPalette.mutedRose,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: 4,
          maxLines: 6,
          maxLength: AppLimits.maxReasonLength,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: YakkuPalette.primary,
          style: const TextStyle(
            color: YakkuPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          buildCounter: _noCounter,
          decoration: InputDecoration(
            filled: true,
            fillColor: YakkuPalette.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
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
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: YakkuPalette.primary,
          foregroundColor: YakkuPalette.white,
          disabledBackgroundColor: YakkuPalette.primary.withValues(alpha: 0.5),
          disabledForegroundColor: YakkuPalette.white.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
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
          "They'll never know it was you",
          style: TextStyle(
            color: YakkuPalette.mutedRose,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
