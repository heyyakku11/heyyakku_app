import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Shared shell when a voter opens a card they already answered.
///
/// Used by poll, check, and personality share links. Card-type identity lives
/// in [accentColor], optional [header], and [preview] (options, trait chips…).
class AlreadyVotedView extends StatelessWidget {
  const AlreadyVotedView({
    super.key,
    required this.onLeave,
    this.accentColor = YakkuPalette.primary,
    this.background,
    this.header,
    this.preview,
    this.showAnonymousNote = true,
    this.onClose,
    this.showYakkuMark = true,
  });

  final VoidCallback onLeave;

  /// Badge circle, CTA, and badge border tint.
  final Color accentColor;

  /// Full-screen backdrop. Defaults to cream.
  final BoxDecoration? background;

  /// Optional top content (check heading / sticker).
  final Widget? header;

  /// Card-type body under the status badge (options, traits, question…).
  final Widget? preview;

  final bool showAnonymousNote;

  /// When set, a close control is shown in the top bar.
  final VoidCallback? onClose;

  /// Poll/check keep the Yakku wordmark; personality can hide it.
  final bool showYakkuMark;

  static const title = 'You already voted';
  static const subtitle = 'Locked in. Thanks for being honest.';

  @override
  Widget build(BuildContext context) {
    final backdrop =
        background ?? const BoxDecoration(color: YakkuPalette.cream);

    return DecoratedBox(
      decoration: backdrop,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  onClose: onClose ?? onLeave,
                  showYakkuMark: showYakkuMark,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (header != null) ...[
                                header!,
                                const SizedBox(height: 14),
                              ],
                              _StatusBadge(
                                accent: accentColor,
                                title: title,
                                subtitle: subtitle,
                              ),
                              if (preview != null) ...[
                                const SizedBox(height: 18),
                                preview!,
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: onLeave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: YakkuPalette.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Back to Yakku'),
                        ),
                      ),
                      if (showAnonymousNote) ...[
                        const SizedBox(height: 12),
                        const _AnonymousNote(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.showYakkuMark});

  final VoidCallback onClose;
  final bool showYakkuMark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          if (showYakkuMark)
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'Yakku.',
                style: TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            )
          else
            const SizedBox(width: 12),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: YakkuPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: const Icon(
                Icons.check_rounded,
                color: YakkuPalette.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: YakkuPalette.textPrimary,
                      fontSize: 20,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: YakkuPalette.bodyInk,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
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

class _AnonymousNote extends StatelessWidget {
  const _AnonymousNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.visibility_off_outlined,
          size: 18,
          color: YakkuPalette.mutedRose,
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            "Anonymous. They'll never know it was you.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.mutedRose,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
