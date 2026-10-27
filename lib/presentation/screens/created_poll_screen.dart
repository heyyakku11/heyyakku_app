import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/poll_card_image_service.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/core/share/share_coordinator.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/presentation/screens/instagram_story_guide_screen.dart';

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

  static const _ink = Color(0xFF21191D);
  static const _muted = Color(0xFF7C6466);

  @override
  State<CreatedPollScreen> createState() => _CreatedPollScreenState();
}

class _CreatedPollScreenState extends State<CreatedPollScreen> {
  static const _ink = CreatedPollScreen._ink;
  static const _muted = CreatedPollScreen._muted;

  final _cardKey = GlobalKey();
  bool _downloading = false;

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

  /// Opens the "link sticker" guide that precedes the Instagram story composer.
  void _openStoryGuide(BuildContext context) {
    try {
      final payload = _buildPayload();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InstagramStoryGuideScreen(payload: payload),
        ),
      );
    } on SharePayloadException {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("This poll can't be shared right now.")),
        );
    }
  }

  /// Runs WhatsApp / Copy link through the share module and reports the
  /// real outcome.
  Future<void> _shareVia(BuildContext context, SharePlatformId platform) async {
    final messenger = ScaffoldMessenger.of(context);
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
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Renders the poll card to a PNG and saves it to the gallery.
  Future<void> _downloadCard() async {
    if (_downloading) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = true);
    String message;
    try {
      await const PollCardImageService().download(_cardKey);
      message = 'Card saved to your photos';
    } on PollCardImageException catch (e) {
      message = e.message;
    } catch (e, st) {
      debugPrint('Download card failed: $e\n$st');
      message = "Couldn't save the card. Try again.";
    }
    if (mounted) setState(() => _downloading = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final optionCount = _rawOptionCount.clamp(2, 4);

    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: Stack(
        children: [
          // Off-screen copy of the card rendered to a transparent PNG.
          Positioned(
            left: -3000,
            top: 0,
            width: 380,
            child: RepaintBoundary(
              key: _cardKey,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _PreviewCard(
                  question: _question,
                  optionCount: optionCount,
                ),
              ),
            ),
          ),
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
                          onFacebook: () =>
                              _shareVia(context, SharePlatformId.facebook),
                          onCopyLink: () =>
                              _shareVia(context, SharePlatformId.copyLink),
                        ),
                        const SizedBox(height: 22),
                        _StoryButton(onTap: () => _openStoryGuide(context)),
                        const SizedBox(height: 12),
                        _DownloadButton(
                          busy: _downloading,
                          onTap: _downloadCard,
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

  static const _cardPink = Color(0xFFD9557F);

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
                        color: Colors.white,
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
                    color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
                Text(
                  "Tap to answer. They won't know it was you.",
                  style: const TextStyle(
                    color: Colors.white,
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
    required this.onFacebook,
    required this.onCopyLink,
  });

  final VoidCallback onInstagramDm;
  final VoidCallback onWhatsApp;
  final VoidCallback onSnapchat;
  final VoidCallback onFacebook;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ShareTarget(
          label: 'Instagram\nDM',
          onTap: onInstagramDm,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
            ),
          ),
          child: const FaIcon(
            FontAwesomeIcons.instagram,
            color: Colors.white,
            size: 24,
          ),
        ),
        _ShareTarget(
          label: 'WhatsApp',
          onTap: onWhatsApp,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF25D366),
          ),
          child: const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.white,
            size: 24,
          ),
        ),
        _ShareTarget(
          label: 'Snapchat',
          onTap: onSnapchat,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFFC00),
          ),
          child: const FaIcon(
            FontAwesomeIcons.snapchat,
            color: Colors.white,
            size: 24,
          ),
        ),
        _ShareTarget(
          label: 'Facebook',
          onTap: onFacebook,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1877F2),
          ),
          child: const FaIcon(
            FontAwesomeIcons.facebookF,
            color: Colors.white,
            size: 22,
          ),
        ),
        _ShareTarget(
          label: 'Copy link',
          onTap: onCopyLink,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1B1418),
          ),
          child: const FaIcon(
            FontAwesomeIcons.link,
            color: Colors.white,
            size: 20,
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

class _StoryButton extends StatelessWidget {
  const _StoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFD02E62), Color(0xFFC72A5B)],
            ),
            boxShadow: [
              BoxShadow(
                color: YakkuPalette.primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Share to Instagram Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: YakkuPalette.primary,
          side: const BorderSide(color: YakkuPalette.primary, width: 1.5),
          shape: const StadiumBorder(),
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_rounded, size: 20),
        label: const Text(
          'Download card',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
