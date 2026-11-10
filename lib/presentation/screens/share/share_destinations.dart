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
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Runs [adapter] for the payload from [buildPayload] and tells the user how it
/// went (toast). Returns the outcome, or null when the payload could not be
/// built.
Future<ShareResult?> runShare(
  SharePlatformAdapter adapter,
  SharePayload Function() buildPayload,
) async {
  final SharePayload payload;
  try {
    payload = buildPayload();
  } on SharePayloadException {
    AppToast.show('This card can\u2019t be shared right now.');
    return null;
  }

  final result = await adapter.share(payload);
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
  return result;
}

/// The standard share destinations (Instagram inbox, WhatsApp, Snapchat,
/// Facebook, Copy link), as drawn in the share row.
const List<ShareDestination> standardShareDestinations = [
  ShareDestination(
    adapter: const InstagramShareAdapter(InstagramDestination.inbox),
    icon: FontAwesomeIcons.instagram,
    label: 'Instagram',
    gradient: const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
    ),
  ),
  ShareDestination(
    adapter: const WhatsAppShareAdapter(),
    icon: FontAwesomeIcons.whatsapp,
    label: 'WhatsApp',
    color: YakkuPalette.whatsappGreen,
  ),
  ShareDestination(
    adapter: const SnapchatShareAdapter(),
    icon: FontAwesomeIcons.snapchat,
    label: 'Snapchat',
    color: YakkuPalette.snapchatYellow,
    iconColor: YakkuPalette.black,
  ),
  ShareDestination(
    adapter: const FacebookShareAdapter(),
    icon: FontAwesomeIcons.facebookF,
    label: 'Facebook',
    color: const Color(0xFF1877F2),
  ),
  ShareDestination(
    adapter: const CopyLinkShareAdapter(),
    icon: FontAwesomeIcons.link,
    label: 'Copy link',
    color: YakkuPalette.charcoal,
  ),
];

class ShareDestination {
  const ShareDestination({
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

class ShareOption extends StatelessWidget {
  const ShareOption({
    required this.destination,
    required this.busy,
    required this.onTap,
  });

  final ShareDestination destination;
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


/// A row of the standard destinations. [busy] is the adapter currently
/// running (shown as a spinner); taps are ignored while [onTap] is null.
class ShareDestinationRow extends StatelessWidget {
  const ShareDestinationRow({
    super.key,
    required this.busy,
    required this.onTap,
    this.destinations = standardShareDestinations,
  });

  final List<ShareDestination> destinations;
  final SharePlatformAdapter? busy;
  final void Function(SharePlatformAdapter adapter)? onTap;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final destination in destinations)
          ShareOption(
            destination: destination,
            busy: busy == destination.adapter,
            onTap: onTap == null ? null : () => onTap(destination.adapter),
          ),
      ],
    );
  }
}
