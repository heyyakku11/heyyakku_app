import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';

/// "Your card is live" screen shown right after a poll is created.
class CreatedPollScreen extends StatelessWidget {
  const CreatedPollScreen({
    super.key,
    required this.poll,
    this.categories = const [],
  });

  final PollResponse poll;
  final List<String> categories;

  /// Votes needed before results are revealed.
  static const _resultsVoteThreshold = 5;

  static const _ink = Color(0xFF21191D);
  static const _muted = Color(0xFF7C6466);

  String _shareText() => 'Do you have a take on this? "${poll.question}" '
      '— answer on Yakku, your pick stays secret.';

  Future<void> _share() {
    return SharePlus.instance.share(ShareParams(text: _shareText()));
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied')));
  }

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).authController.displayName?.trim() ?? '';
    final asker = name.isEmpty ? 'Someone' : name;
    final optionCount = poll.options.length.clamp(2, 4);

    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
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
                    asker: asker,
                    question: poll.question,
                    optionCount: optionCount,
                  ),
                  const SizedBox(height: 26),
                  _ShareRow(
                    onInstagramDm: _share,
                    onWhatsApp: _share,
                    onSnapchat: _share,
                    onFacebook: _share,
                    onCopyLink: () => _copyLink(context),
                  ),
                  const SizedBox(height: 22),
                  _StoryButton(onTap: _share),
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
    );
  }
}

/// Tilted pink card previewing how friends will see the question.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.asker,
    required this.question,
    required this.optionCount,
  });

  final String asker;
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
                    const Spacer(),
                    Flexible(
                      child: Text(
                        '$asker asked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
                  "Tap to answer. $asker won't know it was you.",
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
          child: const Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        _ShareTarget(
          label: 'WhatsApp',
          onTap: onWhatsApp,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF25D366),
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Color(0xFF0B3D1E),
            size: 22,
          ),
        ),
        _ShareTarget(
          label: 'Snapchat',
          onTap: onSnapchat,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFFC00),
          ),
          child: const Text('👻', style: TextStyle(fontSize: 22, height: 1)),
        ),
        _ShareTarget(
          label: 'Facebook',
          onTap: onFacebook,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1877F2),
          ),
          child: const Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _ShareTarget(
          label: 'Copy link',
          onTap: onCopyLink,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1B1418),
          ),
          child: const Icon(Icons.link_rounded, color: Colors.white, size: 22),
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
