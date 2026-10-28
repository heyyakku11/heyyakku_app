import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

class YakkuPlanScreen extends StatelessWidget {
  const YakkuPlanScreen({super.key, required this.planName});

  /// Current plan name from the get-user API (e.g. "Free").
  final String planName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Yakku plan'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: YakkuPalette.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR PLAN',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    color: YakkuPalette.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: YakkuPalette.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'More plans are coming soon. We will let you know here as soon as '
            'they are available.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
