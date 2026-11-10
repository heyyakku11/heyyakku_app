import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// "Add the link sticker so friends can answer": shown before the Instagram
/// Story opens, because Instagram cannot attach the link by itself. The link is
/// already on the clipboard when this appears.
///
/// Shown every time the user taps "Share to Instagram Story". Returns true when
/// they tap "Open Instagram"; "Not now" closes it without opening Instagram.
Future<bool> showInstagramStoryTipSheet(BuildContext context) async {
  final open = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => const _InstagramStoryTipSheet(),
  );
  return open ?? false;
}

class _InstagramStoryTipSheet extends StatelessWidget {
  const _InstagramStoryTipSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: YakkuPalette.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YakkuPalette.Raspberry.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _LinkCopiedTag(),
              const SizedBox(height: 14),
              const Text(
                'Add the link sticker so friends can answer',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 20),
              const _Step(
                number: 1,
                child: Text('Tap the sticker icon at the top of your Story'),
              ),
              const SizedBox(height: 14),
              _Step(
                number: 2,
                child: Text.rich(
                  TextSpan(
                    text: 'Pick ',
                    children: [
                      TextSpan(
                        text: 'Link',
                        style: _stepStyle.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _Step(
                number: 3,
                child: Text('Paste. Your link is already copied'),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: YakkuPalette.Raspberry,
                    foregroundColor: YakkuPalette.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.instagram, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Open Instagram',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Not now',
                    style: TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _stepStyle = TextStyle(
  color: YakkuPalette.Ink,
  fontSize: 15,
  height: 1.3,
  fontWeight: FontWeight.w500,
);

class _LinkCopiedTag extends StatelessWidget {
  const _LinkCopiedTag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.whatsappGreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          'LINK COPIED',
          style: TextStyle(
            color: Color(0xFF14663A),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.child});

  final int number;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: YakkuPalette.pinkWash,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: DefaultTextStyle.merge(style: _stepStyle, child: child),
        ),
      ],
    );
  }
}
