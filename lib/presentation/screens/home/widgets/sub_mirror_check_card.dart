import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/presentation/screens/home/widgets/check_preview_dialog.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

/// The tilted raspberry label that heads a home feed section ("More checks", "Just for fun").
class SectionTag extends StatelessWidget {
  const SectionTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.rotate(
        angle: -0.05,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: YakkuPalette.Raspberry,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: YakkuPalette.Ink, offset: Offset(3, 3)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class MoreChecksSection extends StatelessWidget {
  const MoreChecksSection({super.key, required this.checks});

  final List<MirrorCheck> checks;

  @override
  Widget build(BuildContext context) {
    if (checks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Flexible(child: SectionTag('More checks'))],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.72;

            return SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: checks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: cardWidth,
                    child: SubMirrorCheckCard(check: checks[index]),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class SubMirrorCheckCard extends StatelessWidget {
  const SubMirrorCheckCard({
    super.key,
    required this.check,
    this.showTitle = true,
    this.compact = false,
  });

  final MirrorCheck check;

  /// The small uppercase check name above the question. Just-for-fun cards leave it out.
  final bool showTitle;

  /// Smaller type and padding, for the grid of all cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final draft = AskFriendsCheck.fromMirrorCheck(check);
    final headline = check.question.isNotEmpty ? check.question : check.title;

    return GestureDetector(
      onTap: () => openAskFriendsCheck(context, draft),
      child: DecoratedBox(
        decoration:
            feedCardDecoration(
              check.backgroundColor,
              gradient: check.backgroundGradient,
            ).copyWith(
              border: Border.all(
                color: check.foregroundColor.withValues(alpha: 0.25),
              ),
            ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle) ...[
                Text(
                  check.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: check.foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                headline,
                maxLines: compact ? 4 : (showTitle ? 2 : 3),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: compact ? 15 : 22,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? -0.2 : -0.4,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _CardPill(
                    label: 'Ask now',
                    filled: true,
                    compact: compact,
                    onTap: () => openAskFriendsCheck(context, draft),
                  ),
                  SizedBox(width: compact ? 6 : 10),
                  _CardPill(
                    label: compact ? null : 'View',
                    icon: Icons.visibility_outlined,
                    compact: compact,
                    onTap: () => showCheckPreviewDialog(context, draft),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPill extends StatelessWidget {
  const _CardPill({
    required this.onTap,
    this.label,
    this.icon,
    this.filled = false,
    this.compact = false,
  });

  final String? label;
  final IconData? icon;
  final bool filled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : YakkuPalette.Ink;
    return Material(
      color: filled ? YakkuPalette.Ink : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: YakkuPalette.Ink, width: filled ? 0 : 1),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null
                ? (compact ? 9 : 12)
                : (compact ? 12 : 18),
            vertical: compact ? 8 : 11,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 16 : 18, color: foreground),
                if (label != null) const SizedBox(width: 6),
              ],
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 12.5 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
