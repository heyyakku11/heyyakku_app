import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/presentation/screens/home/widgets/check_preview_dialog.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

class MoreChecksSection extends StatelessWidget {
  const MoreChecksSection({super.key, required this.checks});

  final List<MirrorCheck> checks;

  @override
  Widget build(BuildContext context) {
    if (checks.isEmpty) return const SizedBox.shrink();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Transform.rotate(
                  angle: -0.05,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: YakkuPalette.Raspberry,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: YakkuPalette.Ink,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'More checks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.78;

            return SizedBox(
              height: 200,
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
  const SubMirrorCheckCard({super.key, required this.check});

  final MirrorCheck check;

  @override
  Widget build(BuildContext context) {
    final draft = AskFriendsCheck.fromMirrorCheck(check);
    final headline = check.question.isNotEmpty ? check.question : check.title;

    return GestureDetector(
      onTap: () => openAskFriendsCheck(context, draft),
      child: DecoratedBox(
        decoration: feedCardDecoration(check.backgroundColor).copyWith(
          border: Border.all(
            color: check.foregroundColor.withValues(alpha: 0.25),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                headline,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _CardPill(
                    label: 'Ask now',
                    filled: true,
                    onTap: () => openAskFriendsCheck(context, draft),
                  ),
                  const SizedBox(width: 10),
                  _CardPill(
                    label: 'View',
                    icon: Icons.visibility_outlined,
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
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final bool filled;
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
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
