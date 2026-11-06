import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/share/adapters/copy_link_share_adapter.dart';
import 'package:yakku/core/share/adapters/facebook_share_adapter.dart';
import 'package:yakku/core/share/adapters/instagram_share_adapter.dart';
import 'package:yakku/core/share/adapters/snapchat_share_adapter.dart';
import 'package:yakku/core/share/adapters/whatsapp_share_adapter.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/core/share/story_image_service.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/personality_share_card.dart';

/// Share step for the user's personality card: a preview of what friends see
/// and the destinations to send it to.
class PersonalityShareScreen extends StatefulWidget {
  const PersonalityShareScreen({
    super.key,
    required this.shareCode,
    required this.traits,
  });

  final String shareCode;

  /// Trait names for the (blurred) preview chips.
  final List<String> traits;

  @override
  State<PersonalityShareScreen> createState() => _PersonalityShareScreenState();
}

class _PersonalityShareScreenState extends State<PersonalityShareScreen> {
  final _storyImages = StoryImageService();
  late final SharePlatformAdapter _instagramStory = InstagramShareAdapter(
    InstagramDestination.story,
    // The Story image is the personality card, not a poll card.
    renderStoryImage: (_, _) =>
        _storyImages.renderWidget(PersonalityStoryCard(traits: widget.traits)),
  );
  late final List<_Destination> _destinations = [
    _Destination(
      adapter: const InstagramShareAdapter(InstagramDestination.inbox),
      icon: FontAwesomeIcons.instagram,
      label: 'Instagram',
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
      ),
    ),
    _Destination(
      adapter: const WhatsAppShareAdapter(),
      icon: FontAwesomeIcons.whatsapp,
      label: 'WhatsApp',
      color: YakkuPalette.whatsappGreen,
    ),
    _Destination(
      adapter: const SnapchatShareAdapter(),
      icon: FontAwesomeIcons.snapchat,
      label: 'Snapchat',
      color: YakkuPalette.snapchatYellow,
      iconColor: YakkuPalette.black,
    ),
    _Destination(
      adapter: const FacebookShareAdapter(),
      icon: FontAwesomeIcons.facebookF,
      label: 'Facebook',
      color: const Color(0xFF1877F2),
    ),
    _Destination(
      adapter: const CopyLinkShareAdapter(),
      icon: FontAwesomeIcons.link,
      label: 'Copy link',
      color: YakkuPalette.charcoal,
    ),
  ];

  SharePlatformAdapter? _busy;

  Future<void> _share(SharePlatformAdapter adapter) async {
    if (_busy != null) return;

    final SharePayload payload;
    try {
      payload = SharePayload.personality(shareCode: widget.shareCode);
    } on SharePayloadException {
      AppToast.show('This card can’t be shared right now.');
      return;
    }

    setState(() => _busy = adapter);
    final ShareResult result;
    try {
      result = await adapter.share(payload);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
    if (!mounted) return;

    switch (result) {
      case ShareSuccess(:final feedbackMessage):
        if (feedbackMessage != null) AppToast.show(feedbackMessage);
      case ShareFailure(:final userMessage):
        AppToast.show(userMessage);
      case ShareUnsupported(:final userMessage):
        AppToast.show(userMessage);
      case ShareCancelled():
        break;
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
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  child: PersonalityShareCard(
                    traits: widget.traits,
                    width: 310,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: _StoryButton(
                busy: _busy == _instagramStory,
                onPressed: _busy == null ? () => _share(_instagramStory) : null,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final destination in _destinations)
                    _ShareOption(
                      destination: destination,
                      busy: _busy == destination.adapter,
                      onTap: _busy == null
                          ? () => _share(destination.adapter)
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.adapter,
    required this.icon,
    required this.label,
    this.color,
    this.gradient,
    this.iconColor = YakkuPalette.white,
  });

  final SharePlatformAdapter adapter;
  final FaIconData icon;
  final String label;
  final Color? color;
  final Gradient? gradient;
  final Color iconColor;
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.destination,
    required this.busy,
    required this.onTap,
  });

  final _Destination destination;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share via ${destination.label}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 66,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: destination.color,
                  gradient: destination.gradient,
                  shape: BoxShape.circle,
                ),
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: destination.iconColor,
                        ),
                      )
                    : FaIcon(
                        destination.icon,
                        size: 24,
                        color: destination.iconColor,
                      ),
              ),
              const SizedBox(height: 7),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
        height: 56,
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
                    FaIcon(FontAwesomeIcons.instagram, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Share to Instagram Story',
                      style: TextStyle(
                        fontSize: 18,
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
