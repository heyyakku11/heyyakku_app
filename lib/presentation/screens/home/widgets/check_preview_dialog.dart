import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';

/// Opens a preview of [check] over a blurred feed: the card with its options
/// and the Ask now action. A just-for-fun card also gets Edit (change it in the
/// create form before asking) and Save (add it to, or remove it from, the
/// caller's saved cards). Other checks can't be edited or saved. Tapping
/// outside closes it.
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
    pageBuilder: (dialogContext, animation, secondaryAnimation) => _CheckPreview(
      check: check,
      // Same as the featured "Ask now": close the preview, then open the card.
      onAskNow: () {
        Navigator.of(dialogContext).pop();
        openAskFriendsCheck(context, check);
      },
      // Edit: close the preview, then open the create form filled with the card.
      onEdit: () {
        Navigator.of(dialogContext).pop();
        openAskFriendsInCreateForm(context, check);
      },
    ),
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
  const _CheckPreview({
    required this.check,
    required this.onAskNow,
    required this.onEdit,
  });

  final AskFriendsCheck check;
  final VoidCallback onAskNow;
  final VoidCallback onEdit;

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
                      if (check.isFun && check.checkId != null) ...[
                        _FunCardActions(check: check, onEdit: onEdit),
                        const SizedBox(height: 12),
                      ],
                      _AskNowAction(onTap: onAskNow),
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
        padding: const EdgeInsets.all(12),
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

/// The main action: raspberry with an ink edge. Opens the card, like the featured "Ask now".
class _AskNowAction extends StatelessWidget {
  const _AskNowAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
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
              Icon(
                Icons.ios_share_rounded,
                size: 17,
                color: YakkuPalette.white,
              ),
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
        ),
      ),
    );
  }
}

/// Edit and Save for a just-for-fun card. Save toggles at once and is undone if the request fails.
class _FunCardActions extends StatefulWidget {
  const _FunCardActions({required this.check, required this.onEdit});

  final AskFriendsCheck check;
  final VoidCallback onEdit;

  @override
  State<_FunCardActions> createState() => _FunCardActionsState();
}

class _FunCardActionsState extends State<_FunCardActions> {
  bool? _saved;
  bool _busy = false;
  bool _failed = false;

  String get _id => widget.check.checkId!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This session's saves win over the value the list was loaded with.
    _saved ??= AppScope.of(
      context,
    ).checkApi.isFunCardSaved(_id, fromServer: widget.check.isSaved);
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final before = _saved ?? false;
    setState(() {
      _saved = !before;
      _busy = true;
      _failed = false;
    });
    try {
      await AppScope.of(context).checkApi.setFunCardSaved(_id, saved: !before);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saved = before;
        _failed = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _OutlinedAction(
                icon: saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: saved ? 'Saved' : 'Save',
                onTap: _toggle,
                highlighted: saved,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlinedAction(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: widget.onEdit,
              ),
            ),
          ],
        ),
        if (_failed) ...[
          const SizedBox(height: 8),
          const Text(
            'Could not update your saved cards. Try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ],
    );
  }
}

/// Save / Edit: a white pill with an ink outline and a short ink shadow underneath, like the option pills.
/// When [highlighted] (saved) it fills with ink.
class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? Colors.white : YakkuPalette.Ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted ? YakkuPalette.Ink : YakkuPalette.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: YakkuPalette.Ink, width: 1.5),
            boxShadow: const [
              BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
