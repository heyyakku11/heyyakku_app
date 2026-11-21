import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Edge UI when a visitor opens someone else's card via an app / share link
/// and voting is no longer open (closed, expired, or filled).
///
/// Same top-aligned shell as [AlreadyVotedView]: status badge under the top
/// bar, optional preview, primary exit CTA.
class VotingClosedView extends StatelessWidget {
  const VotingClosedView({
    super.key,
    required this.onLeave,
    this.title = defaultTitle,
    this.subtitle = defaultSubtitle,
    this.statusLabel,
    this.accentColor = YakkuPalette.primary,
    this.background,
    this.header,
    this.preview,
    this.onClose,
    this.showYakkuMark = true,
  });

  static const defaultTitle = 'Voting is closed';
  static const defaultSubtitle =
      'This card is no longer accepting answers.';

  final VoidCallback onLeave;

  /// Headline in the top status badge.
  final String title;

  /// Supporting line under the title in the badge.
  final String subtitle;

  /// Optional chip under the badge, e.g. "Closed 3h ago".
  final String? statusLabel;

  /// Badge circle, chip, and CTA tint.
  final Color accentColor;

  /// Full-screen backdrop. Defaults to cream.
  final BoxDecoration? background;

  /// Optional top content (check heading / sticker).
  final Widget? header;

  /// Card-type body under the status badge (options, personality card…).
  final Widget? preview;

  /// When set, a close control is shown in the top bar.
  final VoidCallback? onClose;

  /// Poll/check keep the Yakku wordmark; personality can hide it.
  final bool showYakkuMark;

  @override
  Widget build(BuildContext context) {
    final backdrop =
        background ?? const BoxDecoration(color: YakkuPalette.cream);
    final chip = statusLabel?.trim();

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
                              if (chip != null && chip.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _ClosedChip(
                                    label: chip,
                                    accent: accentColor,
                                  ),
                                ),
                              ],
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
                  child: SizedBox(
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
                Icons.lock_clock_rounded,
                color: YakkuPalette.white,
                size: 24,
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

class _ClosedChip extends StatelessWidget {
  const _ClosedChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
