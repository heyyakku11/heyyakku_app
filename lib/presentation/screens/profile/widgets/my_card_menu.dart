import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

enum MyCardAction { close, reshare, delete }

/// The "..." menu of a card on My cards: its question, a one-line status, and
/// the actions that apply to it. Returns the chosen action, or null.
Future<MyCardAction?> showMyCardMenu(
  BuildContext context, {
  required String question,
  required String status,
  bool canClose = false,
  bool canReshare = false,
  bool canDelete = false,
}) {
  return showModalBottomSheet<MyCardAction>(
    context: context,
    backgroundColor: YakkuPalette.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _MyCardMenu(
      question: question,
      status: status,
      canClose: canClose,
      canReshare: canReshare,
      canDelete: canDelete,
    ),
  );
}

class _MyCardMenu extends StatelessWidget {
  const _MyCardMenu({
    required this.question,
    required this.status,
    required this.canClose,
    required this.canReshare,
    required this.canDelete,
  });

  final String question;
  final String status;
  final bool canClose;
  final bool canReshare;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (canClose)
        _MenuRow(
          icon: Icons.schedule_rounded,
          title: 'Close card now',
          subtitle: 'Stop votes. Results stay.',
          onTap: () => Navigator.of(context).pop(MyCardAction.close),
        ),
      if (canReshare)
        _MenuRow(
          icon: Icons.replay_rounded,
          title: 'Reshare card',
          subtitle: 'Open it again for 24 hours.',
          onTap: () => Navigator.of(context).pop(MyCardAction.reshare),
        ),
      if (canDelete)
        _MenuRow(
          icon: Icons.delete_outline_rounded,
          title: 'Delete card',
          subtitle: 'Removes it for everyone.',
          color: YakkuPalette.Error,
          onTap: () => Navigator.of(context).pop(MyCardAction.delete),
        ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: YakkuPalette.Raspberry.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              question,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 19,
                height: 1.15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < rows.length; i++) ...[
              const Divider(height: 1, color: YakkuPalette.roseBorder),
              rows[i],
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YakkuPalette.textSecondary,
                  side: const BorderSide(color: YakkuPalette.roseBorder),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = YakkuPalette.Ink,
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
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 12,
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

/// "Delete this card?": spells out what is lost before the user confirms.
/// Returns true only when they tap "Delete card".
Future<bool> showDeleteCardDialog(
  BuildContext context,
  String question, {
  String title = 'Delete this card?',
  List<String> bullets = const [
    'The link stops working. Friends can\u2019t vote on it.',
    'Its votes, reasons and ask back chats are deleted.',
    'This can\u2019t be undone.',
  ],
  String confirmLabel = 'Delete card',
  String keepLabel = 'Keep it',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: YakkuPalette.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: YakkuPalette.Error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: YakkuPalette.Error,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 26,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '“$question”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: YakkuPalette.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < bullets.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _Bullet(bullets[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: YakkuPalette.Error,
                  foregroundColor: YakkuPalette.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  confirmLabel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YakkuPalette.Ink,
                  side: const BorderSide(color: YakkuPalette.Ink, width: 1.2),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  keepLabel,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed == true;
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Text(
            '·',
            style: TextStyle(
              color: YakkuPalette.Raspberry,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
