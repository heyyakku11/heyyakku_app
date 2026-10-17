import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/presentation/screens/home/check_results_screen.dart';
import 'package:yakku/presentation/screens/home/your_cards_screen.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

/// "Your cards": the checks the user has made, newest first.
class YourCardsSection extends StatelessWidget {
  const YourCardsSection({super.key, required this.cards});

  final List<UserCheckResponse> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

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
            Text(
              'Your cards',
              style: TextStyle(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => YourCardsScreen(cards: cards),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: YakkuPalette.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.78;
            return SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: cards.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: cardWidth,
                  child: UserCheckCard(card: cards[index]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class UserCheckCard extends StatelessWidget {
  const UserCheckCard({super.key, required this.card});

  final UserCheckResponse card;

  @override
  Widget build(BuildContext context) {
    final background = parseHexColor(
      card.backgroundColor,
      fallback: YakkuPalette.cream,
    );
    final ready = card.resultsVisible && (card.totalVotes ?? 0) > 0;
    final label = ready ? 'Your You vs Crowd is ready' : 'Waiting for friends';
    final question = card.question.isNotEmpty ? card.question : card.title;

    return DecoratedBox(
      decoration: feedCardDecoration(background),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              question,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YakkuPalette.textPrimary,
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            FeedActionPill(
              label: 'See result',
              icon: Icons.bar_chart,
              filled: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => CheckResultsScreen(userCheck: card),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
