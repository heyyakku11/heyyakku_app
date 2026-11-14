import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

enum CardAction { reshare, closeNow, delete }

/// Owner menu for a card: close it while it is live, reshare it once it has
/// ended, or delete it.
///
/// A closed card cannot be shared until it is reshared (expiry moves forward
/// and `closedAt` is cleared). Returns the chosen action, or null.
Future<CardAction?> showCardActionsSheet(
  BuildContext context, {
  required String question,
  required bool isLive,
  String? subtitle,
  bool canManage = true,
}) {
  return showModalBottomSheet<CardAction>(
    context: context,
    backgroundColor: YakkuPalette.cream,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _CardActionsSheet(
      question: question,
      subtitle: subtitle,
      isLive: isLive,
      canManage: canManage,
    ),
  );
}

class _CardActionsSheet extends StatelessWidget {
  const _CardActionsSheet({
    required this.question,
    required this.subtitle,
    required this.isLive,
    required this.canManage,
  });

  final String question;

  /// "26 votes · closes in 3h".
  final String? subtitle;
  final bool isLive;

  /// False for cards that can only be shared (no close / delete).
  final bool canManage;

  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.textSecondary;
  static const _divider = YakkuPalette.hairline;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: YakkuPalette.sheetHandle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              question,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (canManage) ...[
              const Divider(height: 1, color: _divider),
              if (isLive)
                _ActionRow(
                  icon: Icons.access_time_rounded,
                  title: 'Close card now',
                  subtitle: 'Stop votes. Results stay.',
                  onTap: () => Navigator.of(context).pop(CardAction.closeNow),
                )
              else
                _ActionRow(
                  icon: Icons.replay_rounded,
                  title: 'Reshare card',
                  subtitle: 'Open it again for 24 hours.',
                  onTap: () => Navigator.of(context).pop(CardAction.reshare),
                ),
              const Divider(height: 1, color: _divider),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                title: 'Delete card',
                subtitle: 'Removes it for everyone.',
                color: YakkuPalette.Error,
                onTap: () => Navigator.of(context).pop(CardAction.delete),
              ),
            ],
            const SizedBox(height: 18),
            Material(
              color: YakkuPalette.white,
              shape: const StadiumBorder(
                side: BorderSide(color: _divider, width: 1.5),
              ),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const StadiumBorder(),
                child: const SizedBox(
                  height: 54,
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = _CardActionsSheet._ink,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _CardActionsSheet._muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
