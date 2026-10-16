import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/share/share_coordinator.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// "One last tap on Instagram" guide shown before opening the Instagram story
/// composer. Instagram doesn't let apps attach links, so the link is copied
/// here and the user adds it as a link sticker.
class InstagramStoryGuideScreen extends StatefulWidget {
  const InstagramStoryGuideScreen({
    super.key,
    required this.payload,
  });

  final SharePayload payload;

  @override
  State<InstagramStoryGuideScreen> createState() =>
      _InstagramStoryGuideScreenState();
}

class _InstagramStoryGuideScreenState extends State<InstagramStoryGuideScreen> {
  static const _ink = Color(0xFF21191D);
  static const _muted = Color(0xFF7C6466);
  static const _pink = Color(0xFFD02E62);

  bool _copied = false;
  bool _opening = false;

  String get _shortUrl {
    final url = widget.payload.url;
    return '${url.host}${url.path}';
  }

  @override
  void initState() {
    super.initState();
    _copyLink();
  }

  Future<void> _copyLink() async {
    try {
      await Clipboard.setData(
        ClipboardData(text: widget.payload.url.toString()),
      );
      if (mounted) setState(() => _copied = true);
    } catch (e) {
      debugPrint('Story guide: copy failed: $e');
    }
  }

  Future<void> _openInstagram() async {
    if (_opening) return;
    setState(() => _opening = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ShareCoordinator().share(
      SharePlatformId.instagramStory,
      widget.payload,
    );
    if (!mounted) return;
    setState(() => _opening = false);
    final message = switch (result) {
      ShareSuccess() => null,
      ShareCancelled() => null,
      ShareUnsupported(:final userMessage) => userMessage,
      ShareFailure(:final userMessage) => userMessage,
    };
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      appBar: AppBar(
        backgroundColor: YakkuPalette.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _ink,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'One last tap on\nInstagram',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 30,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Instagram doesn't let apps add links for you. "
                    "Without the link sticker, friends can't answer.",
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _StoryPreview(
                      question: widget.payload.question,
                      displayUrl: _shortUrl.toUpperCase(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Step(
                    number: 1,
                    title: 'Tap the sticker icon',
                    subtitle: 'Top of your Story, the square smiley.',
                  ),
                  const _Step(
                    number: 2,
                    title: 'Choose Link',
                    subtitle: 'Your link is already copied.',
                  ),
                  const _Step(
                    number: 3,
                    title: 'Paste and place it on the card',
                    subtitle: 'Put it where people will tap.',
                  ),
                  const SizedBox(height: 4),
                  _CopiedChip(visible: _copied, label: 'Link copied: $_shortUrl'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _opening ? null : _openInstagram,
                      style: FilledButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _opening
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Open Instagram'),
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

/// Dark story-frame mock with the tilted Yakku card and link sticker.
class _StoryPreview extends StatelessWidget {
  const _StoryPreview({
    required this.question,
    required this.displayUrl,
  });

  final String question;
  final String displayUrl;

  static const _cardPink = Color(0xFFD02E62);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF21191D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4A4146),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: _cardPink, width: 2),
                  ),
                  child: const Icon(
                    Icons.add_box_outlined,
                    size: 16,
                    color: Color(0xFF21191D),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: 52,
            child: Transform.rotate(
              angle: -4 * math.pi / 180,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yakku.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < 2; i++) ...[
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 10,
            bottom: 22,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 14, color: _cardPink),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      displayUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _cardPink,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final int number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF21191D),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF21191D),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7C6466),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Link copied" chip that pops in over 200ms.
class _CopiedChip extends StatelessWidget {
  const _CopiedChip({required this.visible, required this.label});

  final bool visible;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedScale(
        scale: visible ? 1 : 0.8,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF3E4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 16, color: Color(0xFF1B5E37)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1B5E37),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
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
