import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

enum CardAction { shareAgain, closeNow, delete }

/// Owner menu for a card: share again, close it now, delete.
///
/// Share and close only make sense while the card is live, so they are hidden
/// once it has closed or expired. Returns the chosen action, or null.
Future<CardAction?> showCardActionsSheet(
  BuildContext context, {
  required String question,
  required bool isLive,
  bool canManage = true,
}) {
  return showModalBottomSheet<CardAction>(
    context: context,
    backgroundColor: YakkuPalette.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CardActionsSheet(
      question: question,
      isLive: isLive,
      canManage: canManage,
    ),
  );
}

class _CardActionsSheet extends StatelessWidget {
  const _CardActionsSheet({
    required this.question,
    required this.isLive,
    required this.canManage,
  });

  final String question;
  final bool isLive;

  /// False for cards that can only be shared (no close / delete).
  final bool canManage;

  static const _ink = YakkuPalette.textPrimary;
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: YakkuPalette.sheetHandle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            if (isLive) ...[
              _ActionRow(
                icon: Icons.link_rounded,
                label: 'Share again',
                onTap: () => Navigator.of(context).pop(CardAction.shareAgain),
              ),
              const Divider(height: 1, color: _divider),
              if (canManage) ...[
                _ActionRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Close it now',
                  onTap: () => Navigator.of(context).pop(CardAction.closeNow),
                ),
                const Divider(height: 1, color: _divider),
              ],
            ],
            if (canManage)
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete this card',
                color: YakkuPalette.primary,
                onTap: () => Navigator.of(context).pop(CardAction.delete),
              ),
            const SizedBox(height: 14),
            Material(
              color: YakkuPalette.cream,
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const StadiumBorder(),
                child: const SizedBox(
                  height: 52,
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 15,
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
    required this.label,
    required this.onTap,
    this.color = _CardActionsSheet._ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
