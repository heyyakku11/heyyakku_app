import 'package:flutter/material.dart';
import 'package:yakku/presentation/widgets/skeleton.dart';

/// What the Friends tab shows while Home is loading: blocks where the content will land (a tag, a wide bar, the
/// featured card, a section tag and two cards), so the page does not jump when the data arrives.
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: SkeletonBox(width: 104, height: 38, radius: 14),
          ),
          SizedBox(height: 12),
          SkeletonBox(height: 52, radius: 16),
          SizedBox(height: 12),
          SkeletonBox(height: 246, radius: 30),
          SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: SkeletonBox(width: 130, height: 22, radius: 11),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 150, radius: 24)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 150, radius: 24)),
            ],
          ),
        ],
      ),
    );
  }
}
