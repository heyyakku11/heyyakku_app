import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

class MoreChecksSection extends StatelessWidget {
  const MoreChecksSection({super.key, required this.checks});

  final List<MirrorCheck> checks;

  @override
  Widget build(BuildContext context) {
    if (checks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'More checks',
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),

            Flexible(
              child: Text(
                'New every Monday',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.onSurfaceVariant
                      : YakkuPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.82;

            return SizedBox(
              height: 308,
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

    return GestureDetector(
      onTap: () => openAskFriendsCheck(context, draft),
      child: DecoratedBox(
        decoration: feedCardDecoration(check.backgroundColor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (check.sticker != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: FeedSticker(
                    text: check.sticker!,
                    color: check.accentColor,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                check.title,
                style: TextStyle(
                  color: check.foregroundColor,
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (check.question.isNotEmpty &&
                  check.question != check.title) ...[
                const SizedBox(height: 10),
                Text(
                  check.question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: check.foregroundColor,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FeedOptionChips(
                labels: [for (final option in check.options) option.label],
                chipColor: check.chipColor,
                textColor: check.foregroundColor,
              ),
              const Spacer(),
              FeedActionPill(
                label: 'Ask my friends',
                icon: Icons.ios_share,
                onTap: () => openAskFriendsCheck(context, draft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
