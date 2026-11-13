import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/share/adapters/instagram_share_adapter.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/core/share/story_image_service.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/screens/share/share_destinations.dart';
import 'package:yakku/presentation/screens/share/story_shared_screen.dart';
import 'package:yakku/presentation/widgets/instagram_story_tip_sheet.dart';

/// The share step shared by every card type: a preview of what friends see
/// and the destinations to send it to (Instagram Story, Instagram, WhatsApp,
/// Snapchat, Facebook, Copy link).
class CardShareScreen extends StatefulWidget {
  const CardShareScreen({
    super.key,
    required this.buildPayload,
    required this.preview,
    required this.story,
    this.minVotes = AppLimits.minVotesToReveal,
    this.title,
  });

  /// Optional heading shown above the preview (for example "Share your result").
  final String? title;

  /// Votes needed before results show, mentioned on the "sent" screen.
  final int minVotes;

  /// Builds what is shared (the link and headline). May throw a
  /// [SharePayloadException], which is reported as a toast.
  final SharePayload Function() buildPayload;

  /// The card friends will see, shown at the top of the screen.
  final Widget preview;

  /// The same card laid out on a 360x640 canvas, rendered to an image for
  /// Instagram Stories.
  final Widget story;

  @override
  State<CardShareScreen> createState() => _CardShareScreenState();
}

class _CardShareScreenState extends State<CardShareScreen> {
  final _storyImages = StoryImageService();
  late final SharePlatformAdapter _instagramStory = InstagramShareAdapter(
    InstagramDestination.story,
    // The Story image is this card, not the generic poll card.
    renderStoryImage: (_, _) => _storyImages.renderWidget(widget.story),
  );

  SharePlatformAdapter? _busy;

  /// "Share to Instagram Story": every time, first copy the link and explain
  /// how to add it as a Link sticker, then open Instagram from the sheet.
  Future<void> _onStoryTap() async {
    if (_busy != null) return;

    try {
      final url = widget.buildPayload().url.toString();
      await Clipboard.setData(ClipboardData(text: url));
    } catch (_) {
      // The share below copies it again and reports any real problem.
    }
    if (!mounted) return;
    final open = await showInstagramStoryTipSheet(context);
    if (!open || !mounted) return;

    final result = await _share(_instagramStory);
    if (result is! ShareSuccess || !mounted) return;
    // Instagram has been opened with the card: confirm it on a "sent" screen.
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StorySharedScreen(
          buildPayload: widget.buildPayload,
          minVotes: widget.minVotes,
        ),
      ),
    );
  }

  Future<ShareResult?> _share(SharePlatformAdapter adapter) async {
    if (_busy != null) return null;
    setState(() => _busy = adapter);
    try {
      return await runShare(adapter, widget.buildPayload);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                  icon: const FaIcon(
                    FontAwesomeIcons.chevronLeft,
                    size: 18,
                    color: YakkuPalette.Ink,
                  ),
                ),
              ),
            ),
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  widget.title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  child: widget.preview,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: _StoryButton(
                busy: _busy == _instagramStory,
                onPressed: _busy == null ? _onStoryTap : null,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
              child: ShareDestinationRow(
                busy: _busy,
                onTap: _busy == null ? _share : null,
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _StoryButton extends StatelessWidget {
  const _StoryButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 4)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: YakkuPalette.Raspberry,
            disabledBackgroundColor: YakkuPalette.Raspberry.withValues(
              alpha: 0.6,
            ),
            foregroundColor: YakkuPalette.white,
            disabledForegroundColor: YakkuPalette.white,
            shape: const StadiumBorder(),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: YakkuPalette.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.instagram, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Share to Instagram Story',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
