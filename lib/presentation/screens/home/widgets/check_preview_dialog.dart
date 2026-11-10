import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';

/// Opens a preview of [check] over a blurred feed: the card with its options
/// and the Save, Edit and Ask now actions. Tapping outside closes it.
///
/// The three actions are shown but not wired up yet.
Future<void> showCheckPreviewDialog(
  BuildContext context,
  AskFriendsCheck check,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close preview',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _CheckPreview(check: check),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 6 * curved.value,
          sigmaY: 6 * curved.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _CheckPreview extends StatelessWidget {
  const _CheckPreview({required this.check});

  final AskFriendsCheck check;

  @override
  Widget build(BuildContext context) {
    final headline = check.question.trim().isNotEmpty
        ? check.question.trim()
        : check.title.trim();
    final options = check.answerableLabels;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: check.backgroundColor,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: YakkuPalette.Ink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          headline,
                          style: const TextStyle(
                            color: YakkuPalette.Ink,
                            fontSize: 24,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < options.length; i++) ...[
                        _OptionPill(
                          letter: String.fromCharCode(65 + i),
                          text: options[i],
                        ),
                        const SizedBox(height: 10),
                      ],
                      _FriendsSlot(
                        letter: String.fromCharCode(65 + options.length),
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(
                            child: _OutlineAction(
                              icon: Icons.bookmark_border_rounded,
                              label: 'Save',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _OutlineAction(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const _AskNowAction(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Tap outside to close',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({required this.letter, required this.text});

  final String letter;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.pinkWash,
            ),
            child: Text(
              letter,
              style: const TextStyle(
                color: YakkuPalette.Raspberry,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The locked slot where friends add their own answer.
class _FriendsSlot extends StatelessWidget {
  const _FriendsSlot({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: YakkuPalette.Ink.withValues(alpha: 0.25),
        radius: 12,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
        decoration: BoxDecoration(
          color: YakkuPalette.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: YakkuPalette.white,
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Friends add their own',
                style: TextStyle(
                  color: YakkuPalette.Ink.withValues(alpha: 0.7),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: YakkuPalette.Ink.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Save / Edit: outlined pills. Not wired up yet, so they take no taps.
class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: YakkuPalette.Ink),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// The main action: raspberry with an ink edge. Not wired up yet.
class _AskNowAction extends StatelessWidget {
  const _AskNowAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 4)),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ios_share_rounded, size: 17, color: YakkuPalette.white),
          SizedBox(width: 8),
          Text(
            'Ask now',
            style: TextStyle(
              color: YakkuPalette.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
