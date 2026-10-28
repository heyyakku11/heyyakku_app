import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

/// Mint call-to-action shown under the results: suggests the next check to ask
/// friends, or lets the user write their own question.
class AskNextCard extends StatelessWidget {
  const AskNextCard({super.key, required this.check});

  final AskFriendsCheck check;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.accentGreen,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASK YOUR NEXT ONE',
              style: TextStyle(
                color: YakkuPalette.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.wandMagicSparkles,
                  size: 13,
                  color: YakkuPalette.successGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  check.title,
                  style: const TextStyle(
                    color: YakkuPalette.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              check.question,
              style: const TextStyle(
                color: YakkuPalette.charcoal,
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: Material(
                color: YakkuPalette.charcoal,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => openAskFriendsCheck(context, check),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ask my friends',
                        style: TextStyle(
                          color: YakkuPalette.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 10),
                      FaIcon(
                        FontAwesomeIcons.paperPlane,
                        size: 15,
                        color: YakkuPalette.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => showCreatePollSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: YakkuPalette.successGreen,
                ),
                child: const Text(
                  'or write your own question ›',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
