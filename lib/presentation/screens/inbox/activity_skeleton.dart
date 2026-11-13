import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/widgets/skeleton.dart';

/// What the Activity tab shows while its notifications load: the real "Activity" title, a section label, and rows
/// laid out like notification rows (a dot column, a round avatar, two lines of text and a time at the right).
class ActivitySkeleton extends StatelessWidget {
  const ActivitySkeleton({super.key});

  static const _rows = 7;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        16,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Activity',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ),
        SkeletonPulse(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: SkeletonBox(width: 58, height: 12, radius: 6),
              ),
              for (var i = 0; i < _rows; i++) _Row(showDivider: i < _rows - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.showDivider});

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: YakkuPalette.roseBorder))
            : null,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Same 20px column as the unread dot in a real row, so the avatar lines up.
          SizedBox(width: 20),
          SkeletonBox.circle(size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, radius: 7),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: SkeletonBox(height: 12, radius: 6),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          SkeletonBox(width: 26, height: 10, radius: 5),
        ],
      ),
    );
  }
}
