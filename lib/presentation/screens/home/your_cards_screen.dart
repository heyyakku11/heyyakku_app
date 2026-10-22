import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/presentation/screens/home/widgets/your_cards_section.dart';

/// Every check the user has made, newest first.
class YourCardsScreen extends StatelessWidget {
  const YourCardsScreen({super.key, required this.cards});

  final List<UserCheckResponse> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : YakkuPalette.textPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your cards',
          style: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: cards.isEmpty
          ? Center(
              child: Text('No cards yet', style: TextStyle(color: ink)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: cards.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) => SizedBox(
                height: 172,
                child: UserCheckCard(card: cards[index]),
              ),
            ),
    );
  }
}
