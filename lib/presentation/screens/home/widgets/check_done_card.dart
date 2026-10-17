import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

/// Replaces the featured card once the user has made this week's check.
class CheckDoneCard extends StatelessWidget {
  const CheckDoneCard({super.key, required this.check});

  final MirrorCheck check;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: feedCardDecoration(check.backgroundColor, radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: check.accentColor,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${check.title} done',
                        style: TextStyle(
                          color: check.accentColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Your result shows as friends vote',
                        style: TextStyle(
                          color: check.foregroundColor.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: check.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Text(
                          'MON',
                          style: TextStyle(
                            color: YakkuPalette.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next drop',
                            style: TextStyle(
                              color: Color(0xFF8A7B80),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'a brand-new check, Monday',
                            style: TextStyle(
                              color: YakkuPalette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
