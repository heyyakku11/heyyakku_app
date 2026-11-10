import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';

/// Step two of creating a poll: the user picks their own answer first
/// ("you guess first"), then "Ask now" creates the poll.
///
/// Pops the created [PollResponse], or `null` when the user went back without
/// creating it.
class CreatePollClaimScreen extends StatefulWidget {
  const CreatePollClaimScreen({
    super.key,
    required this.question,
    required this.options,
    this.mediaUploadSessionId,
  });

  final String question;

  /// The filled-in options, in order; the picked index refers to this list.
  final List<String> options;

  /// Set for a photo poll (an image uploaded on the create screen).
  final String? mediaUploadSessionId;

  @override
  State<CreatePollClaimScreen> createState() => _CreatePollClaimScreenState();
}

class _CreatePollClaimScreenState extends State<CreatePollClaimScreen>
    with SingleTickerProviderStateMixin {
  /// Drives the sticker's shake when a disabled "Ask now" is tapped.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  int? _selected;
  bool _submitting = false;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_submitting) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
  }

  /// "Ask now" before picking an answer: shake the sticker.
  void _nudge() {
    if (_selected != null || _submitting) return;
    HapticFeedback.mediumImpact();
    _shake.forward(from: 0);
  }

  Future<void> _askNow() async {
    final picked = _selected;
    if (picked == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      final api = AppScope.of(context).pollApi;
      final sessionId = widget.mediaUploadSessionId;
      final poll = sessionId == null
          ? await api.createTextPoll(
              question: widget.question,
              options: widget.options,
              selectedOptionIndex: picked,
            )
          : await api.createImagePoll(
              question: widget.question,
              options: widget.options,
              selectedOptionIndex: picked,
              mediaUploadSessionId: sessionId,
            );
      if (!mounted) return;
      // The create screen takes it from here and opens the share screen.
      Navigator.of(context).pop(poll);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.show(_errorMessage(error));
    }
  }

  String _errorMessage(Object error) {
    final api = DioErrorMapper.map(
      error,
      fallback: 'Could not create your poll. Please try again.',
    );
    return switch (api.kind) {
      ApiErrorKind.connection ||
      ApiErrorKind.timeout => 'No connection. Check your network and retry.',
      _ => api.message,
    };
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final picked = _selected != null;
    return PopScope(
      // Going back mid-request would orphan the create call.
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: YakkuPalette.pinkTintSoft,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _submitting ? null : _close,
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
                const GuessTag(label: 'YOUR QUESTION'),
                const SizedBox(height: 12),
                Text(
                  widget.question,
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
                        for (var i = 0; i < widget.options.length; i++) ...[
                          GuessAnswerRow(
                            letter: String.fromCharCode(65 + i),
                            text: widget.options[i],
                            selected: _selected == i,
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
                  enabled: picked && !_submitting,
                  loading: _submitting,
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
