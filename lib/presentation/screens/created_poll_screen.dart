import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/core/share/share_coordinator.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';

/// "Your card is live" screen shown right after a poll is created.
class CreatedPollScreen extends StatefulWidget {
  const CreatedPollScreen({
    super.key,
    required PollResponse this.poll,
    this.categories = const [],
  }) : check = null;

  /// Same screen for a check the user just made.
  const CreatedPollScreen.check({
    super.key,
    required UserCheckResponse this.check,
    this.categories = const [],
  }) : poll = null;

  final PollResponse? poll;
  final UserCheckResponse? check;
  final List<String> categories;

  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.textSecondary;

  @override
  State<CreatedPollScreen> createState() => _CreatedPollScreenState();
}

class _CreatedPollScreenState extends State<CreatedPollScreen> {
  static const _ink = CreatedPollScreen._ink;
  static const _muted = CreatedPollScreen._muted;

  String get _question => widget.poll?.question ?? widget.check!.question;

  /// Votes needed before results are revealed, as sent by the API.
  int get _resultsVoteThreshold =>
      widget.poll?.minVotes ?? widget.check!.minVotes;

  int get _rawOptionCount =>
      widget.poll?.options.length ?? widget.check!.options.length;

  SharePayload _buildPayload() {
    final poll = widget.poll;
    if (poll != null) return SharePayload.fromPollResponse(poll);
    final check = widget.check!;
    return SharePayload.create(
      shareCode: check.shareCode,
      question: check.question.trim().isNotEmpty ? check.question : check.title,
    );
  }

  /// Runs WhatsApp / Copy link through the share module and reports the
  /// real outcome.
  Future<void> _shareVia(BuildContext context, SharePlatformId platform) async {
    String? message;
    try {
      final payload = _buildPayload();
      final result = await ShareCoordinator().share(platform, payload);
      message = switch (result) {
        ShareSuccess(:final feedbackMessage) => feedbackMessage,
        ShareCancelled() => null,
        ShareUnsupported(:final userMessage) => userMessage,
        ShareFailure(:final userMessage) => userMessage,
      };
    } on SharePayloadException {
      message = "This poll can't be shared right now.";
    }
    if (message == null) return;
    AppToast.show(message);
  }

  @override
  Widget build(BuildContext context) {
    final optionCount = _rawOptionCount.clamp(2, 4);

    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Your card is live',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Results show at $_resultsVoteThreshold votes. '
                          'Send it to at least $_resultsVoteThreshold friends.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _PreviewCard(
                          question: _question,
                          optionCount: optionCount,
                        ),
                        const SizedBox(height: 26),
                        _ShareRow(
                          onInstagramDm: () =>
                              _shareVia(context, SharePlatformId.instagramDm),
                          onWhatsApp: () =>
                              _shareVia(context, SharePlatformId.whatsapp),
                          onSnapchat: () =>
                              _shareVia(context, SharePlatformId.snapchat),
                          onCopyLink: () =>
                              _shareVia(context, SharePlatformId.copyLink),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              foregroundColor: _muted,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'Share later',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
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
      ),
    );
  }
}

/// Tilted pink card previewing how friends will see the question.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.question, required this.optionCount});

  final String question;
  final int optionCount;

  static const _cardPink = YakkuPalette.cardPink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.rotate(
        angle: 4 * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _cardPink,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _cardPink.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Yakku.',
                      style: TextStyle(
                        color: YakkuPalette.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: YakkuPalette.white,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < optionCount; i++) ...[
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: YakkuPalette.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
                Text(
                  "Tap to answer. They won't know it was you.",
                  style: const TextStyle(
                    color: YakkuPalette.white,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.onInstagramDm,
    required this.onWhatsApp,
    required this.onSnapchat,
    required this.onCopyLink,
  });

  final VoidCallback onInstagramDm;
  final VoidCallback onWhatsApp;
  final VoidCallback onSnapchat;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ShareTarget(
          label: 'Instagram',
          onTap: onInstagramDm,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                YakkuPalette.instagramYellow,
                YakkuPalette.instagramOrange,
                YakkuPalette.instagramPink,
                YakkuPalette.instagramPurple,
                YakkuPalette.instagramBlue,
              ],
            ),
          ),
          child: const FaIcon(
            FontAwesomeIcons.instagram,
            color: YakkuPalette.white,
            size: 26,
          ),
        ),
        _ShareTarget(
          label: 'WhatsApp',
          onTap: onWhatsApp,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: YakkuPalette.whatsappGreen,
          ),
          child: const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: YakkuPalette.white,
            size: 26,
          ),
        ),
        _ShareTarget(
          label: 'Snapchat',
          onTap: onSnapchat,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: YakkuPalette.snapchatYellow,
          ),
          child: const FaIcon(
            FontAwesomeIcons.snapchat,
            color: YakkuPalette.white,
            size: 26,
          ),
        ),
        _ShareTarget(
          label: 'Copy link',
          onTap: onCopyLink,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: YakkuPalette.charcoal,
          ),
          child: const FaIcon(
            FontAwesomeIcons.link,
            color: YakkuPalette.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.label,
    required this.onTap,
    required this.decoration,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: decoration,
              child: child,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CreatedPollScreen._ink,
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
