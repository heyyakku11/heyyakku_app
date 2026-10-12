import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/home_feed_card.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/home/check_detail_screen.dart';

class HomeFeedBody extends StatelessWidget {
  const HomeFeedBody({super.key, required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const _FeedHeader(),
        const SizedBox(height: 22),
        WeeklyDropCard(card: feed.weeklyDrop),
        const SizedBox(height: 28),
        MoreChecksSection(section: feed.moreChecks),
        const SizedBox(height: 28),
        QuestionSection(section: feed.questions),
      ],
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ink = theme.brightness == Brightness.dark
        ? colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Yakku',
            style: TextStyle(
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: ink,
            ),
            children: const [
              TextSpan(
                text: '.',
                style: TextStyle(color: YakkuPalette.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask your friends anything\nThey answer anonymously.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: ink,
            fontSize: 24,
            height: 1.28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class WeeklyDropCard extends StatelessWidget {
  const WeeklyDropCard({super.key, required this.card});

  final HomeFeedCard card;

  @override
  Widget build(BuildContext context) {
    final muted = card.foregroundColor.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: () => openCheckDetail(context, card),
      child: DecoratedBox(
        decoration: _cardDecoration(card.backgroundColor, radius: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (card.eyebrow != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: card.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    card.eyebrow!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (card.meta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            card.meta!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (card.sticker != null) ...[
                    const SizedBox(width: 8),
                    FeedSticker(text: card.sticker!, color: card.accentColor),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                card.title,
                style: TextStyle(
                  color: card.foregroundColor,
                  fontSize: 34,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              if (card.question.isNotEmpty && card.question != card.title) ...[
                const SizedBox(height: 8),
                Text(
                  card.question,
                  style: TextStyle(
                    color: card.foregroundColor,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final option in card.options) ...[
                _LetteredOption(option: option, card: card),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              FeedActionPill(
                label: 'Ask my friends',
                icon: Icons.ios_share,
                filled: true,
                onTap: () => openCheckDetail(context, card),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreChecksSection extends StatelessWidget {
  const MoreChecksSection({super.key, required this.section});

  final HomeFeedSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                section.title,
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            if (section.trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  section.trailing!,
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
                itemCount: section.cards.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: cardWidth,
                    child: MoreCheckCard(card: section.cards[index]),
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

class MoreCheckCard extends StatelessWidget {
  const MoreCheckCard({super.key, required this.card});

  final HomeFeedCard card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openCheckDetail(context, card),
      child: DecoratedBox(
        decoration: _cardDecoration(card.backgroundColor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.sticker != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: FeedSticker(
                    text: card.sticker!,
                    color: card.accentColor,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                card.title,
                style: TextStyle(
                  color: card.foregroundColor,
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (card.question.isNotEmpty && card.question != card.title) ...[
                const SizedBox(height: 6),
                Text(
                  card.question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: card.foregroundColor,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _OptionChips(card: card),
              const Spacer(),
              FeedActionPill(
                label: 'Ask my friends',
                icon: Icons.ios_share,
                onTap: () => openCheckDetail(context, card),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionSection extends StatelessWidget {
  const QuestionSection({super.key, required this.section});

  final HomeFeedSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < section.cards.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          QuestionCard(card: section.cards[index]),
        ],
      ],
    );
  }
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.card});

  final HomeFeedCard card;

  @override
  Widget build(BuildContext context) {
    final headline = card.question.isNotEmpty ? card.question : card.title;

    return DecoratedBox(
      decoration: _cardDecoration(card.backgroundColor),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: TextStyle(
                color: card.foregroundColor,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            _OptionChips(card: card),
            const SizedBox(height: 14),
            Row(
              children: [
                FeedActionPill(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  textOnly: true,
                  onTap: () => openCardInCreateForm(context, card),
                ),
                const Spacer(),
                FeedActionPill(
                  label: 'Ask my friends',
                  icon: Icons.ios_share,
                  onTap: () => openCheckDetail(context, card),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeedSticker extends StatelessWidget {
  const FeedSticker({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pacifico',
              color: color,
              fontSize: 15,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class FeedActionPill extends StatelessWidget {
  const FeedActionPill({
    super.key,
    required this.label,
    required this.icon,
    this.filled = false,
    this.textOnly = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool textOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1B1418);
    final foreground = filled ? Colors.white : ink;
    final background = filled
        ? ink
        : textOnly
        ? Colors.transparent
        : Colors.white;
    final borderColor = textOnly ? Colors.transparent : const Color(0xFFE4D7DC);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: textOnly ? 0 : 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: textOnly ? 4 : 14,
              vertical: textOnly ? 8 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

void openCheckDetail(BuildContext context, HomeFeedCard card) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => CheckDetailScreen(card: card),
    ),
  );
}

void openCardInCreateForm(BuildContext context, HomeFeedCard card) {
  final question = card.question.trim().isNotEmpty
      ? card.question.trim()
      : card.title.trim();
  final draft = DraftPoll()
    ..question = question
    ..options = [
      for (final option in card.options)
        if (!option.outlined && option.label.trim().isNotEmpty)
          option.label.trim(),
    ]
    ..allowComments = true
    ..expiryDays = 0;
  showCreatePollSheet(context, draft: draft);
}

class _LetteredOption extends StatelessWidget {
  const _LetteredOption({required this.option, required this.card});

  final HomeFeedOption option;
  final HomeFeedCard card;

  @override
  Widget build(BuildContext context) {
    final letter = option.letter;
    final badgeColor = card.accentColor.withValues(alpha: 0.14);
    final borderColor = const Color(0xFFE6D8DE);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: option.outlined ? Colors.white : card.chipColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: option.outlined ? borderColor : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
        child: Row(
          children: [
            if (letter != null)
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: option.outlined ? Colors.transparent : badgeColor,
                  shape: BoxShape.circle,
                  border: option.outlined
                      ? Border.all(color: borderColor)
                      : null,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    color: card.foregroundColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  color: card.foregroundColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (option.trailing != null)
              Text(
                option.trailing!,
                style: TextStyle(
                  color: card.foregroundColor.withValues(alpha: 0.35),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionChips extends StatelessWidget {
  const _OptionChips({required this.card});

  final HomeFeedCard card;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in card.options)
          DecoratedBox(
            decoration: BoxDecoration(
              color: card.chipColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                option.label,
                style: TextStyle(
                  color: card.foregroundColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

BoxDecoration _cardDecoration(Color background, {double radius = 22}) {
  return BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x1421191D), blurRadius: 18, offset: Offset(0, 8)),
    ],
  );
}
