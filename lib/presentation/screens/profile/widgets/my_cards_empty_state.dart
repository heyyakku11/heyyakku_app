import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Which "My cards" tab is empty.
enum MyCardsEmptyKind { all, live, closed, saved }

/// The empty state of the My cards screen: a little stack of tilted blank cards, a short headline and
/// line of help, and (when there is something to do about it) one button.
class MyCardsEmptyState extends StatelessWidget {
  const MyCardsEmptyState({super.key, required this.kind, this.onAction});

  final MyCardsEmptyKind kind;

  /// Tapped by the button. The button is hidden when this is null.
  final VoidCallback? onAction;

  ({String title, String message, IconData icon, String? action})
  get _copy => switch (kind) {
    MyCardsEmptyKind.all => (
      title: 'No cards yet',
      message:
          'Ask your first question and it lands here, ready to share and watch the answers roll in.',
      icon: Icons.add_rounded,
      action: 'Ask a question',
    ),
    MyCardsEmptyKind.live => (
      title: 'Nothing live right now',
      message: 'Cards you share that are still taking answers show up here.',
      icon: Icons.bolt_rounded,
      action: 'Ask a question',
    ),
    MyCardsEmptyKind.closed => (
      title: 'No closed cards',
      message:
          'When you close a card so it stops taking answers, you will find it here.',
      icon: Icons.lock_outline_rounded,
      action: null,
    ),
    MyCardsEmptyKind.saved => (
      title: 'No saved cards',
      message: 'Save a question you like and it waits for you here, for later.',
      icon: Icons.bookmark_border_rounded,
      action: null,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    final showAction = onAction != null && copy.action != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CardStack(icon: copy.icon),
          const SizedBox(height: 32),
          Text(
            copy.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          if (showAction) ...[
            const SizedBox(height: 24),
            Material(
              color: YakkuPalette.Ink,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        copy.action!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Three blank cards fanned out behind a front card with [icon], in the app's inked-card style.
class _CardStack extends StatelessWidget {
  const _CardStack({required this.icon});

  final IconData icon;

  static const _width = 132.0;
  static const _height = 164.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(-34, 4),
            child: Transform.rotate(
              angle: -0.18,
              child: const _BlankCard(color: YakkuPalette.accentPurple),
            ),
          ),
          Transform.translate(
            offset: const Offset(34, 2),
            child: Transform.rotate(
              angle: 0.16,
              child: const _BlankCard(color: YakkuPalette.Gold),
            ),
          ),
          Transform.rotate(
            angle: -0.03,
            child: _BlankCard(
              color: YakkuPalette.white,
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: YakkuPalette.Raspberry,
                    shape: BoxShape.circle,
                    border: Border.all(color: YakkuPalette.Ink, width: 2),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlankCard extends StatelessWidget {
  const _BlankCard({required this.color, this.child});

  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _CardStack._width,
      height: _CardStack._height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.Ink, width: 2),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 5)),
        ],
      ),
      child:
          child ??
          // Placeholder lines, like a question that has not been written yet.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final width in const [0.8, 0.55]) ...[
                FractionallySizedBox(
                  widthFactor: width,
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: YakkuPalette.Ink.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
    );
  }
}
